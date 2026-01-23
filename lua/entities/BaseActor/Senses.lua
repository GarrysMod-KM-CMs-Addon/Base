local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetPos = CEntity.GetPos
local CEntity_GetAngles = CEntity.GetAngles

// ENT.Enemy = NULL
function ENT:SetEnemy( e ) local MyTable = CEntity_GetTable( self ) MyTable.UpdateEnemyMemory( e, CEntity_GetPos( e ), CEntity_GetAngles( e ), MyTable ) end
function ENT:GetEnemy() return CEntity_GetTable( self ).Enemy end

local IsValid = IsValid

function ENT:SetupEnemy( enemy )
	local ent = enemy
	if ent.__ACTOR_BULLSEYE__ then
		while ent.__ACTOR_BULLSEYE__ && IsValid( ent.Enemy ) do
			ent = ent.Enemy
		end
	end
	return enemy, ent
end

local util_TraceLine = util.TraceLine

local math = math
local math_abs = math.abs
local math_AngleDifference = math.AngleDifference

local table_insert = table.insert

local MASK_VISIBLE_AND_NPCS = MASK_VISIBLE_AND_NPCS

local isentity = isentity

local CEntity_OBBCenter = CEntity.OBBCenter
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_GetOwner = CEntity.GetOwner
local CEntity_GetAngles = CEntity.GetAngles

ENT.flLastEnemy = 0

ENT.bCantSeeUnderWater = true
ENT.bVisNot360 = true
// ENT.flVisionYaw = 99
// ENT.flVisionPitch = 33 // Rougly 99 * ( 6 / 19 ). 31 would be More Exact But 33 Looks Cooler
// Must be half of the actual value, since it's calculated as an absolute difference
local f = UNIVERSAL_FOV * .5
ENT.flVisionYaw = f
ENT.flVisionPitch = f * ( 9 / 16 )
function ENT:CanSee( vec, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	local veh, ent
	if isentity( vec ) then
		if !IsValid( vec ) then return end
		local TheirTable = CEntity_GetTable( vec )
		veh = TheirTable.GAME_pVehicle
		if MyTable.bCantSeeUnderWater && CEntity_WaterLevel( vec ) == 3 then return end
		ent = vec
		vec = CEntity_GetPos( vec ) + CEntity_OBBCenter( vec )
	end
	if MyTable.bVisNot360 then
		local des, aim = ( vec - MyTable.GetShootPos( self ) ):Angle(), MyTable.aAim || CEntity_GetAngles( self )
		if math_abs( math_AngleDifference( des.y, aim.y ) ) > MyTable.flVisionYaw then return end
		if math_abs( math_AngleDifference( des.p, aim.p ) ) > MyTable.flVisionPitch then return end
	end
	local t = { self }
	if IsValid( ent ) then table_insert( t, ent ) end
	if IsValid( veh ) then table_insert( t, veh ) end
	veh = self.GAME_pVehicle
	if IsValid( veh ) then table_insert( t, veh ) end
	return !util_TraceLine( {
		start = MyTable.GetShootPos( self ),
		endpos = vec,
		mask = MASK_VISIBLE_AND_NPCS,
		filter = t
	} ).Hit
end

ENT.tEnemies = {} // Entity ( Even InValid, will be Filtered ) -> true
ENT.tBullseyes = {} // EntityUniqueIdentifier -> { BaseActorBullseye ( Even InValid ), Source Entity ( Even InValid ), Entity ( Even InValid ) }

local CEntity_Remove = CEntity.Remove
function ENT:ReportPositionAsClear( vec, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	local tAllies = MyTable.GetAlliesByClass( self, MyTable )
	if tAllies then
		for pAlly in pairs( tAllies ) do
			for _, tData in pairs( CEntity_GetTable( pAlly ).tBullseyes ) do
				local p = tData[ 1 ]
				if !IsValid( p ) then continue end
				if CEntity_GetPos( p ):DistToSqr( vec ) <= 65536/*256*/ then CEntity_Remove( p ) end
			end
		end
	end
end

// function ENT:UpdateEnemyMemory( enemy, vec ) self:SetupBullseye( enemy, vec, enemy:GetAngles() ) end
function ENT:UpdateEnemyMemory( enemy, vec, ang ) self:SetupBullseye( enemy, vec || enemy:GetPos(), ang || enemy:GetAngles() ) end

local EntityUniqueIdentifier = EntityUniqueIdentifier

function ENT:SetupBullseye( enemy, vec, ang, MyTable )
	if !vec then vec = enemy:GetPos() + enemy:OBBCenter() end
	if !ang then ang = ( enemy.GetAimVector && enemy:GetAimVector() || enemy:GetForward() ):Angle() end
	local ent = enemy
	if ent.__ACTOR_BULLSEYE__ then
		while ent.__ACTOR_BULLSEYE__ && IsValid( ent.Enemy ) do
			ent = ent.Enemy
		end
	end
	local id = EntityUniqueIdentifier( ent )
	local beye = self.tBullseyes[ id ]
	if beye then beye = beye[ 1 ] end
	if !IsValid( beye ) then beye = ents.Create "BaseActorBullseye" beye:Spawn() end
	( MyTable || CEntity_GetTable( self ) ).tBullseyes[ id ] = { beye, enemy, ent }
	local BullseyeTable = CEntity_GetTable( beye )
	BullseyeTable.flTime = CurTime()
	BullseyeTable.Enemy = ent
	BullseyeTable.Owner = self
	beye:SetPos( vec )
	beye:SetAngles( ang )
	BullseyeTable.GAME_BoundMins = ent:OBBMins()
	BullseyeTable.GAME_BoundMaxs = ent:OBBMaxs()
	BullseyeTable.__VELOCITY__ = GetVelocity( enemy )
	if HasRangeAttack( ent ) then
		BullseyeTable.HAS_RANGE_ATTACK = true
		BullseyeTable.HAS_NOT_RANGE_ATTACK = nil
	else
		BullseyeTable.HAS_RANGE_ATTACK = nil
		BullseyeTable.HAS_NOT_RANGE_ATTACK = true
	end
	if HasMeleeAttack( ent ) then
		BullseyeTable.HAS_MELEE_ATTACK = true
		BullseyeTable.HAS_NOT_MELEE_ATTACK = nil
	else
		BullseyeTable.HAS_MELEE_ATTACK = nil
		BullseyeTable.HAS_NOT_MELEE_ATTACK = true
	end
	beye:SetHealth( enemy:Health() )
	beye:SetMaxHealth( enemy:GetMaxHealth() )
	return beye
end

local pairs = pairs

function ENT:OnOtherKilled( ent )
	local n, t = EntityUniqueIdentifier( ent ), self:GetAlliesByClass()
	if t then
		for ally in pairs( t ) do
			if !ally.__ACTOR__ then continue end
			local b = ally.tBullseyes
			if b then
				local t = b[ n ]
				if t then
					local v = t[ 1 ]
					if IsValid( v ) then v:Remove() end
					b[ n ] = nil
				end
			end
		end
	end
end

ENT.flMaxVisionRange = 8192

local math_Remap = math.Remap

function ENT:GetVisionStrengthIncreaseSpeed( VecOrEnt, vEyePos )
	if isentity( VecOrEnt ) then VecOrEnt = VecOrEnt:GetPos() + VecOrEnt:OBBCenter() end
	return 3 * math_Remap( vEyePos:Distance( VecOrEnt ), 0, self.flMaxVisionRange, 1, 0 )
end

local HUGE_Z = Vector( 0, 0, 999999 )

local ents_FindInPVS = ents.FindInPVS

local table_Count = table.Count

local math_Rand = math.Rand

local math_Clamp = math.Clamp

local CurTime = CurTime

// The name is a fluke lmao - you should handle the picking up code here too.
function ENT:ShouldPickUpGun( pWeapon, vEyePos, TheirTable, MyTable )
	if MyTable.bCannotCarryWeapons || pWeapon:NearestPoint( vEyePos ):DistToSqr( vEyePos ) > 9437184/*3072*/ then return end
	local pSchedule = MyTable.Schedule
	if pSchedule && pSchedule.m_sName == "PickUpGun" then return end
	// I already have this gun... but why not take the other too?
	//	local sTargetClass = pWeapon:GetClass()
	//	for wep in pairs( MyTable.tWeapons ) do
	//		if wep:GetClass() == sTargetClass then
	//			return
	//		end
	//	end
	pSchedule = MyTable.SetSchedule( self, "PickUpGun", MyTable )
	pSchedule.pWeapon = pWeapon
end

// If we are in combat with multiple enemies, and we see that there is
// no enemy at a position, can we remove that bullseye?
ENT.bCombatForgetHostiles = true
// ENT.bCombatForgetLastHostile = true // Same as above but for one enemy
ENT.flLastLookTime = 0
ENT.flNextLookTime = 0
// If we've seen something, and then it went out of sight, don't delete the info about it yet!
// Instead, decrease the vision strength of it by this and only delete the info about it when it's zero.
// This way, it's harder for enemies to run away, since every half a second they're re-noticed,
// as opposed to having to wait the whole spot time over and over again when they're a pixel out of sight
//
// NOTE: This does NOT grant the Actors free knowledge! tVisionStrength is only used to determine
// how much we've spotted something, NOT to decide if we can or can't see it.
//
// 1 / Seconds to lose completely
ENT.flLoseSpeed = .2 // 5
ENT.tVisionStrength = {} // Entity ( Even invalid, will be filtered ) -> Float [ 0, 1 ]
ENT.tAlertEntities = {} // Entities that we might wanna be concerned about, such as enemies who won't attack first
ENT.tNextWeaponCheck = {}
local ipairs = ipairs
function ENT:Look( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	if MyTable.m_bScript then return end
	if CurTime() <= MyTable.flNextLookTime then return end
	MyTable.flNextLookTime = CurTime() + math_Rand( .08, .12 )
	local tVisionStrength = {}
	local tVisibleEnemies = {}
	local tAlertEntities = {}
	local iNumEnemies = table_Count( MyTable.tEnemies )
	local tEnemies = {}
	local tOldVisionStrength = MyTable.tVisionStrength
	local flFrameTime = math_abs( CurTime() - MyTable.flLastLookTime )
	local flVisionDistSqr = MyTable.flMaxVisionRange * MyTable.flMaxVisionRange
	local vEyePos = MyTable.GetShootPos( self )
	local tAllies = MyTable.GetAlliesByClass( self )
	local bCombatForgetHostiles = MyTable.bCombatForgetHostiles
	local bCombatForgetLastHostile = MyTable.bCombatForgetLastHostile
	local fReportPositionAsClear = MyTable.ReportPositionAsClear
	local bNotClear = IsValid( MyTable.Enemy )
	local bMelee, bRange
	local tWeapons = {}
	for _, ent in ipairs(
		// This is the piece of shit that is necessary but absolutely CONSUMES the CPU!
		// I am 100% sure, and I have tested it.
		// If you. for example, add
		// if true then ents_FindInPVS( self ) return end
		// below
		// MyTable.flNextLookTime = CurTime() + math_Rand( .08, .12 )
		// it will not become less CPU consuming than it is already.
		// So sadly, major optimizations cannot be done without making the Actors blinder,
		// and that is not something that I will ever do
		ents_FindInPVS( self )
	) do
		if vEyePos:DistToSqr( CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ) ) > flVisionDistSqr then continue end
		local TheirTable = CEntity_GetTable( ent )
		if bNotClear || !TheirTable.__WEAPON__ || IsValid( CEntity_GetOwner( ent ) ) then
			if TheirTable.__PROJECTILE__ ||
			!TheirTable.__FLARE_ACTIVE__ &&
			!TheirTable.__ACTOR_BULLSEYE__ &&
			!MyTable.IsHateDisposition( self, ent ) ||
			!MyTable.CanSee( self, ent ) then continue end
		end
		if tOldVisionStrength[ ent ] then
			if TheirTable.__WEAPON__ && !IsValid( CEntity_GetOwner( ent ) ) then
				if CurTime() > ( MyTable.tNextWeaponCheck[ ent ] || 0 ) && tOldVisionStrength[ ent ] >= 1 then // Omagad, a gun!!!
					table_insert( tWeapons, { ent, ent:GetPos():DistToSqr( vEyePos ) } )
					MyTable.tNextWeaponCheck[ ent ] = CurTime() + 2
					continue
				end
				tVisionStrength[ ent ] = math_Clamp( tOldVisionStrength[ ent ] + MyTable.GetVisionStrengthIncreaseSpeed( self, ent, vEyePos ) * flFrameTime, 0, 1 )
			elseif TheirTable.__ACTOR_BULLSEYE__ then
				if !bMelee && HasMeleeAttack( ent ) then bMelee = true end
				if !bRange && HasRangeAttack( ent ) then bRange = true end
				if tAllies && TheirTable.Owner == self then
					local f = tOldVisionStrength[ ent ]
					if f && f >= 1 then
						if bCombatForgetLastHostile || bCombatForgetHostiles && iNumEnemies > 1 then
							local p = ent.Enemy
							if IsValid( p ) then
								local v = tOldVisionStrength[ p ]
								if v && v >= 1 then continue end
							end
							fReportPositionAsClear( self, CEntity_GetPos( ent ), MyTable )
							iNumEnemies = iNumEnemies - 1
						end
					else tVisionStrength[ ent ] = math.Clamp( f + MyTable.GetVisionStrengthIncreaseSpeed( self, ent, vEyePos ) * flFrameTime, 0, 1 ) end
				end
			elseif ent.__FLARE_ACTIVE__ then
				if ent.Classify then
					if !ent.FLARE_tFoundByClass || !ent.FLARE_tFoundByClass[ self:Classify() ] then
						local f = tOldVisionStrength[ ent ]
						if f && f >= 1 then
							if ent:Classify() == self:Classify() then // Go over to ally flares to help
								if ent:GetPos():DistToSqr( self:GetPos() ) > 9437184/*3072*/ then
									local p = self:SetupBullseye( ent, util_TraceLine( {
										start = CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ),
										endpos = CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ) - HUGE_Z,
										filter = ent,
										mask = MASK_VISIBLE_AND_NPCS
									} ).HitPos, CEntity_GetAngles( ent ) )
									if IsValid( p ) then p.flTime = CurTime() end
								end
							else
								local p = CEntity_GetOwner( ent )
								if IsValid( p ) then
									local p = self:SetupBullseye( p, util_TraceLine( {
										start = CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ),
										endpos = CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ) - HUGE_Z,
										filter = ent,
										mask = MASK_VISIBLE_AND_NPCS
									} ).HitPos, CEntity_GetAngles( ent ) )
									if IsValid( p ) then p.flTime = CurTime() end
								end
							end
							if ent.FLARE_tFoundByClass then ent.FLARE_tFoundByClass[ self:Classify() ] = true
							else ent.FLARE_tFoundByClass = { [ self:Classify() ] = true } end
						else tVisionStrength[ ent ] = math_Clamp( tOldVisionStrength[ ent ] + MyTable.GetVisionStrengthIncreaseSpeed( self, ent, vEyePos ) * flFrameTime, 0, 1 ) end
					end
				end
			else
				if !bMelee && HasMeleeAttack( ent ) then bMelee = true end
				if !bRange && HasRangeAttack( ent ) then bRange = true end
				tVisionStrength[ ent ] = math_Clamp( tOldVisionStrength[ ent ] + MyTable.GetVisionStrengthIncreaseSpeed( self, ent, vEyePos ) * flFrameTime, 0, 1 )
				if tVisionStrength[ ent ] >= 1 then
					MyTable.bHoldFire = nil
					MyTable.flLastEnemy = CurTime()
					if MyTable.WillAttackFirst( self, ent ) then
						tEnemies[ ent ] = true
						tVisibleEnemies[ EntityUniqueIdentifier( ent ) ] = true
						MyTable.SetupBullseye( self, ent, nil, nil, MyTable )
					else tAlertEntities[ ent ] = true end
				end
			end
		else tVisionStrength[ ent ] = 0 end
	end
	table.SortByMember( tWeapons, 2, true )
	for _, t in ipairs( tWeapons ) do
		local ent = t[ 1 ]
		if !IsValid( ent ) then continue end
		MyTable.ShouldPickUpGun( self, ent, vEyePos, TheirTable, MyTable )
	end
	MyTable.tAlertEntities = tAlertEntities
	local f = MyTable.flLoseSpeed
	for ent, flt in pairs( tOldVisionStrength ) do
		if !IsValid( ent ) || flt <= 0 || tVisionStrength[ ent ] then continue end
		tVisionStrength[ ent ] = flt - f * FrameTime()
	end
	local tBullseyes = {}
	for id, data in pairs( MyTable.tBullseyes ) do
		local ent = data[ 1 ]
		if !IsValid( ent ) then continue end
		tBullseyes[ id ] = data
		if tVisibleEnemies[ id ] then continue end
		if !bMelee && HasMeleeAttack( ent ) then bMelee = true end
		if !bRange && HasRangeAttack( ent ) then bRange = true end
		tEnemies[ ent ] = true
	end
	MyTable.bEnemiesHaveMeleeAttack = bMelee
	MyTable.bEnemiesHaveRangeAttack = bRange
	MyTable.tBullseyes = tBullseyes
	local ned, ne = math.huge
	for ent in pairs( MyTable.tEnemies ) do
		if !IsValid( ent ) then continue end
		local d = ( CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ) ):DistToSqr( vEyePos )
		if d >= ned then continue end
		ne, ned = ent, d
	end
	MyTable.Enemy = ne
	MyTable.tEnemies = tEnemies
	MyTable.flLastLookTime = CurTime()
	MyTable.tVisionStrength = tVisionStrength
	if bClear && IsValid( ne ) then MyTable.OnAcquireEnemy( self, MyTable ) end
	local t = {}
	for ent, flTime in pairs( MyTable.tNextWeaponCheck ) do if IsValid( ent ) then t[ ent ] = flTime end end
	MyTable.tNextWeaponCheck = t
end

function ENT:GetStartleSoundLevel( sName )
	local t = self.tSoundHarmless[ sName ]
	return 95 * math.Remap( 1 + ( t && t[ 1 ] || 1 ) * self.flBoldness, 0, 128, 1, 2 )
end

ENT.tSoundHarmless = {}
ENT.tSoundHarmful = {}

function ENT:NoiseReflex( MyTable, Disposition, Other, Data )
	if !self.tSoundHarmful[ Data.SoundName ] then
		local t = self.tSoundHarmless[ Data.SoundName ]
		if Data.Volume <= .33 ||
		Data.SoundLevel <= self:GetStartleSoundLevel( Data.SoundName ) ||
		self:GetStartleSoundTime( Data.SoundName, Data.SoundLevel ) <= .5 then return end
	end
	local pSchedule = MyTable.Schedule
	if pSchedule then
		if pSchedule.m_sName == "StartleNoise" then
			pSchedule.tData = Data
			pSchedule.flConsecutiveSounds = pSchedule.flConsecutiveSounds + 1
			return
		end
	end
	pSchedule = MyTable.SetSchedule( self, "StartleNoise", MyTable )
	pSchedule.tData = Data
	pSchedule.flConsecutiveSounds = 1
	pSchedule.bSoundWasNotHarmless = self.tSoundHarmful[ Data.SoundName ]
end

local math_max = math.max
function ENT:OnHeardSomething( Other, Data )
	local MyTable = CEntity_GetTable( self )
	if MyTable.m_bScript then return end
	local d = MyTable.Disposition( self, Other, MyTable )
	if MyTable.bCanStartle then MyTable.NoiseReflex( self, MyTable, d, Other, Data ) end
	if d == D_LI then
		local OtherTable = CEntity_GetTable( Other )
		if !OtherTable.__ACTOR__ then return end
		if !OtherTable.bHoldFire then
			MyTable.bHoldFire = nil
			MyTable.flLastEnemy = math_max( MyTable.flLastEnemy, OtherTable.flLastEnemy )
		end
		for k, d in pairs( OtherTable.tBullseyes ) do
			local beye = d[ 1 ]
			if IsValid( beye ) then
				local ent = d[ 2 ]
				if IsValid( ent ) then
					local t = self.tBullseyes[ k ]
					if t then
						local meye = t[ 1 ]
						if IsValid( meye ) && meye.flTime > beye.flTime then
							OtherTable.SetupBullseye( Other, ent, CEntity_GetPos( meye ), CEntity_GetAngles( meye ), OtherTable )
						else MyTable.SetupBullseye( self, ent, CEntity_GetPos( beye ), CEntity_GetAngles( beye ), MyTable ) end
					else
						MyTable.SetupBullseye( self, ent, CEntity_GetPos( beye ), CEntity_GetAngles( beye ), MyTable )
					end
				end
			end
		end
	elseif d == D_HT || d == D_FR then
		if !MyTable.WillAttackFirst( self, Other ) then return end
		MyTable.flLastEnemy = CurTime()
		MyTable.SetupBullseye( self, Other, nil, nil, MyTable )
	end
end
