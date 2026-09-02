local math_Clamp = math.Clamp
local band = bit.band
local util_TraceLine = util.TraceLine
local util_ScreenShake = util.ScreenShake
local util_DistanceToLine = util.DistanceToLine
local min = math.min
local max = math.max
local IsValid = IsValid
local Rand = math.Rand
local random = math.random
local net_Start = net.Start
local net_WriteFloat = net.WriteFloat
local net_WriteVector = net.WriteVector
local net_WriteUInt = net.WriteUInt
local net_Broadcast = net.Broadcast
local net_WriteColor = net.WriteColor
local net_WriteString = net.WriteString
local net_Send = net.Send
local CEntity = FindMetaTable "Entity"
local CEntity_IsOnFire = CEntity.IsOnFire
local CEntity_Ignite = CEntity.Ignite
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_Extinguish = CEntity.Extinguish
local ents_Iterator = ents.Iterator
local util_Decal = util.Decal
local flNextActorQueueCall = 0
local coroutine_resume = coroutine.resume
local coroutine_status = coroutine.status
local physenv_GetLastSimulationTime = physenv.GetLastSimulationTime
local engine_TickInterval = engine.TickInterval
local CEntity_IsOnGround = CEntity.IsOnGround
local CEntity_Remove = CEntity.Remove
local CPlayer = FindMetaTable "Player"
local CPlayer_GetRunSpeed = CPlayer.GetRunSpeed
local CPlayer_Give = CPlayer.Give
local ents_Create = ents.Create
local util_TraceHull = util.TraceHull
local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local CEntity_GetTable = CEntity.GetTable
local CPlayer_KeyDown = CPlayer.KeyDown
local CEntity_SetNW2Bool = CEntity.SetNW2Bool
local CEntity_SetNW2Float = CEntity.SetNW2Float
local CEntity_GetNW2Float = CEntity.GetNW2Float
local SoundDuration = SoundDuration
local Format = Format
local player_Iterator = player.Iterator
local table_insert = table.insert
local table_IsEmpty = table.IsEmpty
local char = string.char
local concat = table.concat
local CEntity_GetClass = CEntity.GetClass
local CEntity_EntIndex = CEntity.EntIndex
local ents_FindAlongRay = ents.FindAlongRay
local game_GetAmmoPlayerDamage = game.GetAmmoPlayerDamage
local game_GetAmmoID = game.GetAmmoID
local math_Remap = math.Remap
local tonumber = tonumber
local lower = string.lower
local Vector = Vector

concommand.Add( "+drop", function() end )
concommand.Add( "-drop", function( ply )
	local pWeapon = ply:GetActiveWeapon()

	if IsValid( pWeapon ) && pWeapon.Holster then
		pWeapon:Holster()
		pWeapon:CallOnClient "Holster"
	end

	ply:DropWeapon()
end )

include "autorun/Improvements.lua"

RunConsoleCommand( "sv_accelerate", ACCELERATION_NORMAL )
RunConsoleCommand( "sv_friction", ACCELERATION_NORMAL )

RunConsoleCommand( "sv_gravity", GRAVITY_NORMAL )

HULL_HUMAN_MINS, HULL_HUMAN_MAXS = Vector( -16, -16, 0 ), Vector( 16, 16, 72 )
HULL_HUMAN_DUCK_MINS, HULL_HUMAN_DUCK_MAXS = Vector( -16, -16, 0 ), Vector( 16, 16, 36 )
HULL_HUMAN_DUCK_HIT_MINS, HULL_HUMAN_DUCK_HIT_MAXS = Vector( -16, -16, 0 ), Vector( 16, 16, 48 )

local CAP_WEAPON_RANGE_ATTACK1 = CAP_WEAPON_RANGE_ATTACK1
local CAP_WEAPON_RANGE_ATTACK2 = CAP_WEAPON_RANGE_ATTACK2

local CAP_INNATE_RANGE_ATTACK1 = CAP_INNATE_RANGE_ATTACK1
local CAP_INNATE_RANGE_ATTACK2 = CAP_INNATE_RANGE_ATTACK2

function InRangeAttack( ent )
	if ent.IN_RANGE_ATTACK then return true end
	if ent.IN_NOT_RANGE_ATTACK then return end

	if ent.CapabilitiesGet then
		local ECapabilities = ent:CapabilitiesGet()
		if band( ECapabilities, CAP_WEAPON_RANGE_ATTACK1 ) != 0 ||
		band( ECapabilities, CAP_WEAPON_RANGE_ATTACK2 ) != 0 ||
		band( ECapabilities, CAP_INNATE_RANGE_ATTACK1 ) != 0 ||
		band( ECapabilities, CAP_INNATE_RANGE_ATTACK2 ) != 0 then return true end
	end

	local fGetActiveWeapon = ent.GetActiveWeapon
	if !fGetActiveWeapon then return end

	local pWeapon = fGetActiveWeapon( ent )
	if !IsValid( pWeapon ) then return end

	if !pWeapon.GetCapabilities then return end

	local ECapabilities = pWeapon:GetCapabilities()
	if band( ECapabilities, CAP_WEAPON_RANGE_ATTACK1 ) != 0 ||
	band( ECapabilities, CAP_WEAPON_RANGE_ATTACK2 ) != 0 ||
	band( ECapabilities, CAP_INNATE_RANGE_ATTACK1 ) != 0 ||
	band( ECapabilities, CAP_INNATE_RANGE_ATTACK2 ) != 0 then return true end
end

function HasRangeAttack( ent )
	if ent.HAS_RANGE_ATTACK then return true end
	if ent.HAS_NOT_RANGE_ATTACK then return end

	if ent.CapabilitiesGet then
		local ECapabilities = ent:CapabilitiesGet()
		if band( ECapabilities, CAP_WEAPON_RANGE_ATTACK1 ) != 0 ||
		band( ECapabilities, CAP_WEAPON_RANGE_ATTACK2 ) != 0 ||
		band( ECapabilities, CAP_INNATE_RANGE_ATTACK1 ) != 0 ||
		band( ECapabilities, CAP_INNATE_RANGE_ATTACK2 ) != 0 then return true end
	end

	if ent.tWeapons then
		for wep in pairs( ent.tWeapons ) do
			if !wep.GetCapabilities then continue end
			local ECapabilities = wep:GetCapabilities()
			if band( ECapabilities, CAP_WEAPON_RANGE_ATTACK1 ) != 0 ||
			band( ECapabilities, CAP_WEAPON_RANGE_ATTACK2 ) != 0 ||
			band( ECapabilities, CAP_INNATE_RANGE_ATTACK1 ) != 0 ||
			band( ECapabilities, CAP_INNATE_RANGE_ATTACK2 ) != 0 then return true end
		end

	elseif ent.GetWeapons then
		for _, wep in ipairs( ent:GetWeapons() ) do
			if !wep.GetCapabilities then continue end
			local ECapabilities = wep:GetCapabilities()
			if band( ECapabilities, CAP_WEAPON_RANGE_ATTACK1 ) != 0 ||
			band( ECapabilities, CAP_WEAPON_RANGE_ATTACK2 ) != 0 ||
			band( ECapabilities, CAP_INNATE_RANGE_ATTACK1 ) != 0 ||
			band( ECapabilities, CAP_INNATE_RANGE_ATTACK2 ) != 0 then return true end
		end
	end
end

local CAP_WEAPON_MELEE_ATTACK1 = CAP_WEAPON_MELEE_ATTACK1
local CAP_WEAPON_MELEE_ATTACK2 = CAP_WEAPON_MELEE_ATTACK2

local CAP_INNATE_MELEE_ATTACK1 = CAP_INNATE_MELEE_ATTACK1
local CAP_INNATE_MELEE_ATTACK2 = CAP_INNATE_MELEE_ATTACK2

function HasMeleeAttack( ent )
	if ent.HAS_MELEE_ATTACK || IsValid( ent.GAME_pVehicle ) then return true end
	if ent.HAS_NOT_MELEE_ATTACK then return end

	if ent.CapabilitiesGet then
		local ECapabilities = ent:CapabilitiesGet()
		if band( ECapabilities, CAP_WEAPON_MELEE_ATTACK1 ) != 0 ||
		band( ECapabilities, CAP_WEAPON_MELEE_ATTACK2 ) != 0 ||
		band( ECapabilities, CAP_INNATE_MELEE_ATTACK1 ) != 0 ||
		band( ECapabilities, CAP_INNATE_MELEE_ATTACK2 ) != 0 then return true end
	end

	if ent.tWeapons then
		for wep in pairs( ent.tWeapons ) do
			if !wep.GetCapabilities then continue end
			local ECapabilities = wep:GetCapabilities()
			if band( ECapabilities, CAP_WEAPON_MELEE_ATTACK1 ) != 0 ||
			band( ECapabilities, CAP_WEAPON_MELEE_ATTACK2 ) != 0 ||
			band( ECapabilities, CAP_INNATE_MELEE_ATTACK1 ) != 0 ||
			band( ECapabilities, CAP_INNATE_MELEE_ATTACK2 ) != 0 then return true end
		end

	elseif ent.GetWeapons then
		for _, wep in ipairs( ent:GetWeapons() ) do
			if !wep.GetCapabilities then continue end
			local ECapabilities = wep:GetCapabilities()
			if band( ECapabilities, CAP_WEAPON_MELEE_ATTACK1 ) != 0 ||
			band( ECapabilities, CAP_WEAPON_MELEE_ATTACK2 ) != 0 ||
			band( ECapabilities, CAP_INNATE_MELEE_ATTACK1 ) != 0 ||
			band( ECapabilities, CAP_INNATE_MELEE_ATTACK2 ) != 0 then return true end
		end
	end
end

function EntityUniqueIdentifier( ent )
	if ent.__UNIQUE_IDENTIFIER__ then return ent.__UNIQUE_IDENTIFIER__ end

	local sIdentifier = ""
	for _ = 1, 16 do
		local i = random( 1, 3 )
		if i == 1 then sIdentifier = sIdentifier .. char( random( 65, 90 ) )
		elseif i == 2 then sIdentifier = sIdentifier .. char( random( 97, 122 ) )
		else sIdentifier = sIdentifier .. random( 0, 9 ) end
	end
	
	-- Combine them cleanly
	ent.__UNIQUE_IDENTIFIER__ = CEntity_GetClass( ent ) .. "_" .. CEntity_EntIndex( ent ) .. "_" .. sIdentifier
	return ent.__UNIQUE_IDENTIFIER__
end

local tIgnoreRangeAttackDisp = { [ D_NU ] = true, [ D_LI ] = true }

RANGE_ATTACK_SUPPRESSION_BOUND_SIZE = 512

SUPPRESSION_MIN_BOUND = Vector( -RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, -RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, -RANGE_ATTACK_SUPPRESSION_BOUND_SIZE )
SUPPRESSION_MAX_BOUND = Vector( RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, RANGE_ATTACK_SUPPRESSION_BOUND_SIZE )

local SUPPRESSION_MIN_BOUND = SUPPRESSION_MIN_BOUND
local SUPPRESSION_MAX_BOUND = SUPPRESSION_MAX_BOUND

function DispatchRangeAttack( Owner, vStart, vEnd, flDamage )
	for _, ent in ipairs( ents_FindAlongRay( vStart, vEnd, SUPPRESSION_MIN_BOUND, SUPPRESSION_MAX_BOUND ) ) do
		if ent == Owner || Owner.Disposition && Owner:Disposition( ent ) == D_LI || ent.Disposition && ent:Disposition( Owner ) == D_LI then continue end
	
		local vCenter = ent:GetPos() + ent:OBBCenter()

		local _, v = util_DistanceToLine( vStart, vEnd, vCenter )

		if util_TraceLine( {
			start = v,
			endpos = vCenter,
			mask = MASK_SHOT_HULL,
			filter = SimpleRelatedFilter( ent )
		} ).Hit then continue end

		local f = ent.GAME_OnRangeAttacked
		if f == nil then ent.GAME_flSuppression = ( ent.GAME_flSuppression || 0 ) + flDamage else f( ent, Owner, vStart, vEnd, flDamage ) end
	end

	local aAngle = ( vEnd - vStart ):Angle()
	for pActor in pairs( __ACTOR_LIST__ ) do
		if pActor == Owner || Owner.Disposition && tIgnoreRangeAttackDisp[ Owner:Disposition( pActor ) ] || tIgnoreRangeAttackDisp[ pActor:Disposition( Owner ) ] then continue end
		local _, v = util_DistanceToLine( vStart, vEnd, pActor:EyePos() )
		if pActor:CanSee( v ) && pActor:WillAttackFirst( Owner ) then
			if !IsValid( pActor.Enemy ) && table.IsEmpty( pActor.tEnemies ) && table.IsEmpty( pActor.tBullseyes ) then
				timer.Simple( Rand( 0, 1 ), function()
					if !IsValid( pActor ) then return end
					pActor:DLG_Startle( Owner )
				end )
				pActor.Enemy = pActor:SetupBullseye( Owner, vStart, aAngle )
			else pActor:SetupBullseye( Owner, vStart, aAngle ) end
		end
	end
end

local function fOnKilled( pEntity, pAttacker )
	if pAttacker:IsPlayer() then
		Achievement_Miscellaneous( pAttacker, "Kill" )
		local f = pAttacker:GetNW2Int "CTRL_Peek"
		if f == COVER_BLINDFIRE_LEFT || f == COVER_BLINDFIRE_RIGHT || f == COVER_BLINDFIRE_UP then
			Achievement_Miscellaneous( pAttacker, "CoverBlindFireKill" )
		end
	end
end

hook.Add( "DoPlayerDeath", "GameImprovements", function( ply )
	local pWeapon = ply:GetActiveWeapon()
	if IsValid( pWeapon ) then ply:DropWeapon( pWeapon ) end
	for _, pWeapon in ipairs( ply:GetWeapons() ) do ply:DropWeapon( pWeapon ) end
end )

hook.Add( "PlayerDeath", "GameImprovements", function( ply, _, at )
	if IsValid( ply.GAME_pFlashlight ) then ply.GAME_pFlashlight:Remove() end
	fOnKilled( ply, at )
end )

hook.Add( "PlayerDeathSilent", "GameImprovements", function( ply ) if IsValid( ply.GAME_pFlashlight ) then ply.GAME_pFlashlight:Remove() end end )
hook.Add( "PlayerDeathSound", "GameImprovements", function() return true end )

hook.Add( "OnNPCKilled", "GameImprovements", function( ent, at )
	fOnKilled( ent, at )
end )

hook.Add( "PlayerSwitchFlashlight", "GameImprovements", function( ply )
	if !ply:Alive() then if IsValid( ply.GAME_pFlashlight ) then ply:EmitSound "FlashlightOff" ply.GAME_pFlashlight:Remove() end return end

	if IsValid( ply.GAME_pFlashlight ) then ply:EmitSound "FlashlightOff" ply.GAME_pFlashlight:Remove() else
		local pFlashlight = ents.Create "LightStream"
		pFlashlight:SetPos( ply:GetShootPos() + ply:GetAimVector() * 32 )
		pFlashlight:SetAngles( ply:EyeAngles() )
		pFlashlight:SetOwner( ply )
		pFlashlight:SetParent( ply )
		pFlashlight:SetKeyValue( "lightfov", "30" )
		pFlashlight:SetKeyValue( "lightcolor", "255 255 255 2048" )
		pFlashlight:SetKeyValue( "NearZ", "1" )
		pFlashlight:SetKeyValue( "FarZ", "2048" )
		pFlashlight:Input( "SpotlightTexture", nil, nil, "effects/flashlight/soft" )
		pFlashlight:Spawn()
		ply:EmitSound "FlashlightOn"
		ply.GAME_pFlashlight = pFlashlight
	end

	return false
end )

hook.Add( "OnEntityCreated", "GameImprovements", function( pEntity )
	if IsValid( pEntity ) then
		timer.Simple( .01, function()
			if !IsValid( pEntity ) then return end

			if pEntity:IsWeapon() then pEntity.GAME_bWeaponPickedUpOnce = true end
		end )
	end
end )

local function GrantWeaponAchievement( ply, wep )
	local sAchievement = "Acquire_" .. wep:GetClass()
	if __ACHIEVEMENTS__[ sAchievement ] then
		local s = ply:SteamID64()
		local t = __ACHIEVEMENTS_ACQUIRED__[ s ]
		if t then
			if !t[ sAchievement ] then
				ply:SendLua( "Achievement_Acquire(" .. "\"" .. wep:GetClass() .. "\"" .. ")" )
				t[ sAchievement ] = true
			end
		else
			ply:SendLua( "Achievement_Acquire(" .. "\"" .. wep:GetClass() .. "\"" .. ")" )
			__ACHIEVEMENTS_ACQUIRED__[ s ] = { [ sAchievement ] = true }
		end
		file.Write( "Achievements/" .. engine.ActiveGamemode() .. ".json", util.TableToJSON( __ACHIEVEMENTS_ACQUIRED__ ) )
	end
end

hook.Add( "PlayerCanPickupWeapon", "GameImprovements", function( ply, wep )
	if !wep.GAME_bWeaponPickedUpOnce then
		GrantWeaponAchievement( ply, wep )
		local w = ply:GetWeapon( wep:GetClass() )
		if IsValid( w ) && !w.__GRENADE__ then ply:DropWeapon( w ) end
		wep.GAME_bWeaponPickedUpOnce = true
		return true
	end
	if !ply:KeyDown( IN_USE ) then return false end
	local tr = util_TraceLine {
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:GetAimVector() * 999999,
		filter = ply
	}
	if tr.Entity != wep then return false end
	local c = wep:GetClass()
	local w = ply:GetWeapon( c )
	if w.__GRENADE__ then return true end
	ply:DropObject()
	wep:ForcePlayerDrop()
	// Make them switch to the gun because they CONSCIOUSLY picked it up,
	// not just randomly got it from the floor and accidentally self stunlocked in the deploy animation
	ply.GAME_sRestoreGun = c
	if IsValid( w ) then ply:DropWeapon( w ) end
	GrantWeaponAchievement( ply, wep )
end )

hook.Add( "PlayerCanPickupItem", "GameImprovements", function( ply, item )
	if !ply:KeyDown( IN_USE ) then return false end
	local tr = util_TraceLine {
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:GetAimVector() * 999999,
		filter = ply
	}
	return tr.Entity == item
end )

hook.Add( "PlayerHurt", "GameImprovements", function( ply, pAttacker, flHealth, flDamage )
	ply:SetNW2Float( "GAME_flBleeding", ply:GetNW2Float( "GAME_flBleeding", 0 ) +
	flDamage / ( max( ply:Health(), ply:GetMaxHealth() ) * 112 ) )
end )

hook.Add( "PlayerCanHearPlayersVoice", "GameImprovements", function( pListener, pSpeaker )
	if pListener:GetPos():DistToSqr( pSpeaker:GetPos() ) > ( pSpeaker.GAME_flSpeakDistanceSqr || 13249600/*3640*/ ) then return false end
	return true, true
end )

hook.Add( "PlayerCanSeePlayersChat", "GameImprovements", function( _/*sText*/, _/*bTeamOnly*/, pListener, pSpeaker )
	if !IsValid( pSpeaker ) then return true end
	return pListener:GetPos():DistToSqr( pSpeaker:GetPos() ) <= ( pSpeaker.GAME_flSpeakDistanceSqr || 13249600/*3640*/ )
end )

hook.Add( "GetFallDamage", "GameImprovements", function( ply, flSpeed )
	local flRatio = flSpeed / ( ply:GetJumpPower() * 1.5 )
	if flRatio <= 1 then return 0 end
	Achievement_Miscellaneous( ply, "Fall" )
	return flRatio ^ 1.5 * 32
end )

hook.Add( "CreateEntityRagdoll", "GameImprovements", function( pOwner, pRagdoll )
	local f = pOwner.PreCreateRagdoll
	if f then f( pOwner, pRagdoll ) end
	local f = pOwner.OnBulletImpact
	if f then pRagdoll.OnBulletImpact = f end
	local f = pOwner.BloodSplatter
	if f then pRagdoll.BloodSplatter = f end
	local f = pOwner.OnCreateRagdoll
	if f then f( pOwner, pRagdoll ) end
	if !pOwner.__ACTOR__ then return end
	pRagdoll:SetNW2Float( "GAME_flBleeding", pOwner:GetNW2Float( "GAME_flBleeding", 0 ) )
	local f = math.max( pOwner:Health(), pOwner:GetMaxHealth() )
	if f <= 0 then f = 100 end
	pRagdoll.GAME_flOldMaxHealth = f
end )

TRACER_COLOR = {
	Bullet = { 255, 48, 0, 1024 },
	AR2Tracer = { 48, 255, 255, 1024 },
	HelicopterTracer = { 48, 255, 255, 2048 }
}

local TRACER_COLOR = TRACER_COLOR

TRACER_SIZE = { Bullet = 4 }
local TRACER_SIZE = TRACER_SIZE

hook.Add( "ScalePlayerDamage", "GameImprovements", function( ply, EHitGroup, dDamage )
	if EHitGroup == HITGROUP_HEAD then dDamage:ScaleDamage( ply.GAME_flHeadshotDamageMultiplier || 5 ) return false end
end )

local cSGT = CreateConVar(
	"SGT",
	0,
	FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_CHEAT,
	"Allow Scummy Game Things (SGT)?",
	0, 1
)

local function fViolentAssRandom() return 1 - .9 * random() * random() * random() * random() * random() * random() * random() * random() * random() * random() * random() * random() end

hook.Add( "EntityFireBullets", "GameImprovements", function( pShooter, Data, COMP )
	if COMP then
		if COMP.KM_CMs_Addon then return
		else COMP.KM_CMs_Addon = true end
	end

	hook.Run( "EntityFireBullets", pShooter, Data, { KM_CMs_Addon = true } )

	if Data.AmmoType != "" then
		Data.Damage = game_GetAmmoPlayerDamage( game_GetAmmoID( Data.AmmoType ) )
		Data.AmmoType = ""
	end

	local fOldCallback = Data.Callback || function() return { damage = true, effects = true } end

	local flDamage = Data.Damage

	local tColor

	if !Data.TracerName then Data.TracerName = "Bullet" end

	local bTracer = Data.Tracer > 0

	if bTracer then tColor = TRACER_COLOR[ Data.TracerName || "Bullet" ] || TRACER_COLOR.Bullet end
	if Data.HullSize == 0 then Data.HullSize = TRACER_SIZE[ Data.TracerName || "Bullet" ] || TRACER_SIZE.Bullet end

	local pOwner = GetOwner( pShooter )

	local bMuzzleFlash = true
	if pShooter.GAME_bNoMuzzleFlash then
		bMuzzleFlash = nil
		pShooter.GAME_bNoMuzzleFlash = nil
	end

	if cSGT:GetBool() && pOwner.__ACTOR__ then
		local vSpread = Data.Spread

		vSpread[ 1 ] = vSpread[ 1 ] * math_Clamp( math_Remap( vSpread[ 1 ], 0, .1, 10, 1 ), 1, 10 )
		vSpread[ 2 ] = vSpread[ 2 ] * math_Clamp( math_Remap( vSpread[ 1 ], 0, .1, 10, 1 ), 1, 10 )

		Data.Damage = Data.Damage * ( 1 / 3 )
	end

	local flMuzzleFlashTime = math_Clamp( ( pShooter.Primary_flDelay || .1 ) * Rand( .1, .15 ), 0, .2 )
	local flForce = max( Data.Force, 1 )
	Data.Callback = function( atk, tr, dmg )
		DispatchRangeAttack( atk, tr.StartPos, tr.HitPos, flDamage )

		local pTarget = tr.Entity
		local bTarget = IsValid( pTarget )

		local dDamage = DamageInfo()
		dDamage:SetAttacker( pOwner )
		// Not setting the inflictor prevents WALK and STEP movetype knockback
		//	dDamage:SetInflictor( pShooter )
		dDamage:SetDamage( dmg:GetDamage() )
		dDamage:SetDamageType( DMG_BULLET )
		dDamage:SetDamagePosition( tr.HitPos )
		dDamage:SetDamageForce( ( tr.HitPos - tr.StartPos ):GetNormalized() * flForce )

		local tCallbackResult = fOldCallback( atk, tr, dDamage ) || { damage = true, effects = true }

		if tCallbackResult.damage && bTarget then
			local f = pTarget.SetLastHitGroup
			if f then f( pTarget, tr.HitGroup ) end
			pTarget:TakeDamageInfo( dDamage )
		end

		local bEffects = tCallbackResult.effects
		if !bTracer || !bEffects then return { damage = false, effects = bEffects } end
	
		local fOnBulletImpact = pTarget.OnBulletImpact
		if fOnBulletImpact then fOnBulletImpact( pTarget, dDamage ) end
	
		if bMuzzleFlash then
			net_Start "EphemeralLight"
				net_WriteFloat( tColor[ 4 ] / 255 * .2 * fViolentAssRandom() ) // Brightness
				net_WriteFloat( 512 * fViolentAssRandom() ) // Size
				local f = flMuzzleFlashTime * fViolentAssRandom()
				net_WriteFloat( f ) // Existence length
				net_WriteFloat( f )
				net_WriteVector( tr.StartPos + ( tr.HitPos - tr.StartPos ):GetNormalized() * 32 ) // Position
				net_WriteUInt( tColor[ 1 ], 8 ) net_WriteUInt( tColor[ 2 ], 8 ) net_WriteUInt( tColor[ 3 ], 8 ) // R, G, B
			net_Broadcast()
		end
	
		return { damage = false, effects = true }
	end
	return true
end )

local cPersistAll = CreateConVar( "bPersistAll", 1, FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_ARCHIVE, "Everything persists", 0, 1 )

hook.Add( "PhysgunPickup", "GameImprovements", function() return true end )

hook.Add( "EntityTakeDamage", "GameImprovements", function( pEntity, dDamage )
	// Bloodloss only works on players for now, so see PlayerHurt for bloodloss code
	local at = dDamage:GetAttacker()
	if IsValid( at ) then
		local f = at.GAME_OnHurtSomething
		if f && f( at, pEntity, dDamage ) then return true end
		if at.GetEnemy && dDamage:GetDamage() > 0 then at.GAME_bHurtEnemy = true end
	end

	if pEntity:IsPlayer() then AddVelocity( pEntity, dDamage:GetDamageForce() / pEntity:GetPhysicsObject():GetMass() ) end

	local fBloodSplatter = pEntity.BloodSplatter
	if fBloodSplatter then fBloodSplatter( pEntity, dDamage ) end

	if pEntity:GetClass() == "prop_ragdoll" && pEntity.GAME_flOldMaxHealth then
		pEntity:SetNW2Float( "GAME_flBleeding", pEntity:GetNW2Float( "GAME_flBleeding", 0 ) +
		dDamage:GetDamage() / ( pEntity.GAME_flOldMaxHealth * 112 ) )
	end

	if pEntity.__WEAPON__ then
		local flHealth = pEntity:Health() - dDamage:GetDamage()
		pEntity:SetHealth( flHealth )
		if flHealth <= 0 then pEntity:Remove() end
	end
end )

hook.Add( "EntityKeyValue", "GameImprovementsGatherSunInformation", function( pEntity, sKey, sValue )
	if !SUN_HAS_A_NAME && CurTime() > 2 then hook.Remove( "EntityKeyValue", "GameImprovementsGatherSunInformation" ) return end

	if pEntity:GetClass() == "light_environment" then
		sKey = lower( sKey )
		if sKey == "targetname" && sValue != "" then SUN_HAS_A_NAME = true
		elseif sKey == "angles" then SUN_ANGLES = Angle( sValue )
		elseif sKey == "pitch" then SUN_PITCH_OVERRIDE = tonumber( sValue ) || 0
		elseif sKey == "_light" then
			local R, G, B, A = sValue:match "(%d+)%s+(%d+)%s+(%d+)%s+(%d+)"
			R, G, B, A = tonumber( R ) || -1, tonumber( G )|| -1, tonumber( B ) || -1, tonumber( A ) || -1
			SUN_COLOR = Color( R, G, B )
			SUN_BRIGHTNESS = A * .008
		end
	end
end )

function PhysicsCollide( ent, Data )
	local pOther = Data.HitEntity
	if CEntity_IsOnFire( ent ) || CEntity_IsOnFire( pOther ) then
		CEntity_Ignite( ent, 10 )
		CEntity_Ignite( pOther, 10 )
	end
end

local PhysicsCollide = PhysicsCollide

file.CreateDir "Covers"
file.CreateDir "Achievements"

DONT_CHANGE_DRAW_SHADOW = {
	viewmodel = true,
	predicted_viewmodel = true,
	gmod_hands = true
}

local cActorQueueCallsPerTick = CreateConVar(
	"iActorQueueCallsPerTick",
	1,
	FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_ARCHIVE,
	"Complex calculations (such as finding nearest cover) are enqueued in a Circular Doubly Linked List. This is how much things are updated from it per tick. Bigger is more laggy but Actors are faster. Smaller is less laggy but Actors are slower.",
	1
)

local ACTOR_QUEUE_CURRENT = nil

ENTITY_BY_CLASS = ENTITY_BY_CLASS || {}

local ENTITY_BY_CLASS = ENTITY_BY_CLASS

ENTITY_BY_CLASS.light_environment = function( pEntity ) pEntity:Fire( IsValid( g_pCascadeShadowMapping ) && "turnoff" || "turnon" ) end

ENTITY_BY_CLASS.prop_ragdoll = function( pEntity )
	local flBlood = pEntity:GetNW2Float( "GAME_flBlood", 1 )
	local f = pEntity:GetNW2Float( "GAME_flBleeding", 0 )

	if flBlood > 0 && f > 0 && f > .0016 then
		local flTimeLeft = pEntity.GAME_flBleedTimeLeft || 0
		if flTimeLeft <= 0 then
			local v = pEntity:GetPos()
			v:Add( pEntity:OBBCenter() )
			for i = 1, random( 2 ) do util_Decal( "Blood", v, v + VectorRand():GetNormalized() * pEntity:BoundingRadius() * 4, pEntity ) end
			pEntity.GAME_flBleedTimeLeft = 1
		else pEntity.GAME_flBleedTimeLeft = flTimeLeft - f * 192 * Rand( .9, 1.1 ) * FrameTime() end
	end

	// We cannot regenerate blood if we're dead
	//	flBlood = math.Clamp( flBlood + ( f > 0 && ( .0016 - f ) || .016 ) * FrameTime(), 0, 1 )
	flBlood = math.Clamp( flBlood - f * FrameTime(), 0, 1 )
	pEntity:SetNW2Float( "GAME_flBlood", flBlood )
end

ENTITY_BY_CLASS.env_tonemap_controller = function( pEntity )
	if pEntity != g_pTonemapControllerInternal then
		if IsValid( g_pTonemapControllerInternal ) then
			pEntity:Remove()
		else g_pTonemapControllerInternal = pEntity end
	end
end

hook.Add( "Think", "GameImprovements", function()
	if ACTOR_QUEUE_LAST && SysTime() > flNextActorQueueCall then
		if !ACTOR_QUEUE_CURRENT then ACTOR_QUEUE_CURRENT = ACTOR_QUEUE_LAST.pNext end

		local iCalls = 0
		local flActorQueueCallsPerTick = cActorQueueCallsPerTick:GetInt()

		while iCalls < flActorQueueCallsPerTick && ACTOR_QUEUE_LAST != nil do
			local pNode = ACTOR_QUEUE_CURRENT
			local pNext = pNode.pNext
			local coThread = pNode.coThread
			local bNoErrors, bResult = coroutine_resume( coThread )
			if bResult == true || coroutine_status( coThread ) == "dead" then
				if !bNoErrors then ErrorNoHaltWithStack( bResult ) end
				if pNode.pNext == pNode then
					ACTOR_QUEUE_LAST = nil
					ACTOR_QUEUE_CURRENT = nil
				else
					pNode.pPrev.pNext = pNode.pNext
					pNode.pNext.pPrev = pNode.pPrev
					if pNode == ACTOR_QUEUE_LAST then ACTOR_QUEUE_LAST = pNode.pPrev end
					ACTOR_QUEUE_CURRENT = pNext
				end
			else
				// DO NOT.
				//	ACTOR_QUEUE_CURRENT = pNext
				if bResult != false then iCalls = iCalls + 1 end
			end
			if !ACTOR_QUEUE_LAST then break end
		end

		flNextActorQueueCall = SysTime() + math_Clamp( physenv_GetLastSimulationTime() * 896 - engine_TickInterval(), 0, 1 )
	else ACTOR_QUEUE_CURRENT = nil end

	if IsValid( g_pCascadeShadowMapping ) then
		if SUN_ANGLES then
			g_pCascadeShadowMapping:SetPitch( SUN_ANGLES[ 1 ] )
			g_pCascadeShadowMapping:SetYaw( SUN_ANGLES[ 2 ] )
			g_pCascadeShadowMapping:SetRoll( SUN_ANGLES[ 3 ] )
			SUN_ANGLES = nil
		end

		if SUN_PITCH_OVERRIDE then
			g_pCascadeShadowMapping:SetPitch( SUN_PITCH_OVERRIDE )
			SUN_PITCH_OVERRIDE = nil
		end

		if SUN_BRIGHTNESS then
			g_pCascadeShadowMapping:SetBrightness( SUN_BRIGHTNESS )
			SUN_BRIGHTNESS = nil
		end

		if SUN_COLOR then
			g_pCascadeShadowMapping:SetLightColor( SUN_COLOR:ToVector() )
			SUN_COLOR = nil
		end
	end

	local pTonemapController = g_pTonemapControllerInternal
	if IsValid( pTonemapController ) then
		pTonemapController:Fire( "SetTonemapRate", 1.5 )

		pTonemapController:Fire( "SetBloomScale", 1 )

		pTonemapController:Fire( "SetAutoExposureMin", .75 )
		pTonemapController:Fire( "SetAutoExposureMax", 2 )
	end

	for _, pEntity in ents_Iterator() do
		local sClass = CEntity_GetClass( pEntity )

		local fFunction = ENTITY_BY_CLASS[ sClass ]
		if fFunction then fFunction( pEntity ) end

		local EntityTable = CEntity_GetTable( pEntity )

		if EntityTable.__ACTOR__ then
			local pEnemy = EntityTable.Enemy
			if IsValid( pEnemy ) then
				local pEnemy, pTrueEnemy = EntityTable.SetupEnemy( pEntity, pEnemy )
				if pTrueEnemy:Health() <= 0 || !pEntity:Visible( pTrueEnemy ) then EntityTable.GAME_bHurtEnemy = nil end
			else EntityTable.GAME_bHurtEnemy = nil end
		else
			local fGetEnemy = pEntity.GetEnemy
			if fGetEnemy then
				local pEnemy = fGetEnemy( pEntity )
				if !IsValid( pEnemy ) || pEnemy:Health() <= 0 || !pEntity:Visible( pEnemy ) then EntityTable.GAME_bHurtEnemy = nil end
			end
		end

		if !DONT_CHANGE_DRAW_SHADOW[ sClass ] then pEntity:DrawShadow( !IsValid( g_pCascadeShadowMapping ) ) end

		if EntityTable.GAME_Think then EntityTable.GAME_Think( pEntity, EntityTable ) end

		if !EntityTable.GAME_bPhysCollideHook then
			pEntity:AddCallback( "PhysicsCollide", function( ... ) PhysicsCollide( ... ) end )
			EntityTable.GAME_bPhysCollideHook = true
		end

		// TODO: Custom fire system
		CEntity_Extinguish( pEntity )

		if cPersistAll:GetBool() && pEntity:MapCreationID() == -1 && !pEntity:IsPlayer() && ( !pEntity:IsWeapon() || pEntity:IsWeapon() && ( !IsValid( pEntity:GetOwner() ) || IsValid( pEntity:GetOwner() ) && !pEntity:GetOwner():IsPlayer() ) ) then
			pEntity:SetPersistent( true )
		end
	end
end )

COVER_BOUND_SIZE = 2

local function BloodlossStuff( ply, cmd )
	local flBlood = ply:GetNW2Float( "GAME_flBlood", 1 )
	if flBlood <= .8 then cmd:RemoveKey( IN_SPEED ) end
	if flBlood <= .6 then cmd:AddKey( IN_DUCK ) cmd:AddKey( IN_WALK ) end // Crawling (no proper animation, but that's what I'm trying to simulate)
end

function GameImprovements_StartCommand( ply, cmd )
	if !ply:Alive() then return end

	local PlyTable = CEntity_GetTable( ply )

	PlyTable.m_iOriginalButtons = cmd:GetButtons()

	local pVehicle = PlyTable.GAME_pVehicle
	if IsValid( pVehicle ) then
		if !PlyTable.GAME_sRestoreGun then
			local pWeapon = ply:GetActiveWeapon()
			if IsValid( pWeapon ) then PlyTable.GAME_sRestoreGun = CEntity_GetClass( pWeapon ) end
		end

		if pVehicle.bDriverHoldingUse then
			if !cmd:KeyDown( IN_USE ) then
				pVehicle.bDriverHoldingUse = nil
			end
		else
			if ply:KeyDown( IN_USE ) && pVehicle:ExitVehicle( ply ) then return end
		end

		pVehicle:PlayerControls( ply, cmd )
		cmd:AddKey( IN_DUCK )

		local pHands = ply:GetWeapon "Hands"
		if !IsValid( pHands ) then pHands = ply:Give "Hands" end
		if IsValid( pHands ) then cmd:SelectWeapon( pHands ) end

		local pSwim = ply:GetWeapon "Swim"
		if IsValid( pSwim ) then pSwim:Remove() end
		return
	end

	BloodlossStuff( ply, cmd )

	ply:SetLadderClimbSpeed( ply:IsSprinting() && ply:GetRunSpeed() || ply:IsWalking() && ply:GetSlowWalkSpeed() || ply:GetWalkSpeed() )
	
	local bGround = CEntity_IsOnGround( ply )
	if !bGround && CEntity_WaterLevel( ply ) > 0 then
		if !PlyTable.GAME_sRestoreGun then
			local pWeapon = ply:GetActiveWeapon()
			if IsValid( pWeapon ) then PlyTable.GAME_sRestoreGun = CEntity_GetClass( pWeapon ) end
		end

		local pHands = ply:GetWeapon "Hands"
		if IsValid( pHands ) then pHands:Remove() end

		local pSwim = ply:GetWeapon "Swim"
		if !IsValid( pSwim ) then pSwim = ply:Give "Swim" end
		if IsValid( pSwim ) then cmd:SelectWeapon( pSwim ) end

		ply:SetNW2Bool( "CTRL_bSliding", false )
		return
	else
		local pHands = ply:GetWeapon "Hands"
		if !IsValid( pHands ) then pHands = ply:Give "Hands" end

		if IsValid( pHands ) && !IsValid( ply:GetActiveWeapon() ) then cmd:SelectWeapon( pHands ) end

		local pSwim = ply:GetWeapon "Swim"
		if IsValid( pSwim ) then pSwim:Remove() end
	end

	local sRestoreGun = PlyTable.GAME_sRestoreGun
	if sRestoreGun then
		local pWeapon = ply:GetWeapon( sRestoreGun )
		if IsValid( pWeapon ) then cmd:SelectWeapon( pWeapon ) end
		PlyTable.GAME_sRestoreGun = nil
	end

	if ply:GetNW2Bool "CTRL_bSliding" then cmd:RemoveKey( IN_ATTACK ) cmd:RemoveKey( IN_ATTACK2 ) end

	if cmd:KeyDown( IN_ZOOM ) then cmd:AddKey( IN_WALK )
	elseif !cmd:KeyDown( IN_SPEED ) then
		if cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) then cmd:AddKey( IN_WALK ) else
			local pWeapon = ply:GetActiveWeapon()
			if IsValid( pWeapon ) && ( CurTime() <= pWeapon:GetNextPrimaryFire() || CurTime() <= pWeapon:GetNextSecondaryFire() ) then cmd:AddKey( IN_WALK ) end
		end
	end

	local bAllDirectionalSprint = PlyTable.CTRL_bAllDirectionalSprint || ply:Crouching()
	if bAllDirectionalSprint then
		ply:SetNW2Bool( "CTRL_bSprinting", false )
		ply:SetCrouchedWalkSpeed( 1 )
	else
		local bCrouchingAndNotSliding = ply:Crouching() && !ply:GetNW2Bool "CTRL_bSliding"

		if bCrouchingAndNotSliding || cmd:KeyDown( IN_ZOOM ) || !( cmd:KeyDown( IN_FORWARD ) || cmd:KeyDown( IN_BACK ) || cmd:KeyDown( IN_MOVELEFT ) || cmd:KeyDown( IN_MOVERIGHT ) ) then cmd:RemoveKey( IN_SPEED ) end

		if !bCrouchingAndNotSliding && cmd:KeyDown( IN_SPEED ) then
			cmd:AddKey( IN_SPEED )
			local pWeapon = ply:GetActiveWeapon()
			if cmd:GetForwardMove() < 0 || cmd:GetForwardMove() <= 0 && cmd:GetSideMove() == 0 || IsValid( pWeapon ) && ( CurTime() <= pWeapon:GetNextPrimaryFire() || CurTime() <= pWeapon:GetNextSecondaryFire() ) then
				cmd:RemoveKey( IN_SPEED )
				ply:SetNW2Bool( "CTRL_bSprinting", false )

			else
				cmd:SetForwardMove( CPlayer_GetRunSpeed( ply ) )
				cmd:SetSideMove( math_Clamp( cmd:GetSideMove(), -cmd:GetForwardMove(), cmd:GetForwardMove() ) )

				local bSprinting = ply:GetVelocity():LengthSqr() > 256

				ply:SetNW2Bool( "CTRL_bSprinting", bSprinting )

				if bSprinting && ( cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) || cmd:KeyDown( IN_ZOOM ) ) then
					cmd:RemoveKey( IN_SPEED )
					ply:SetNW2Bool( "CTRL_bSprinting", false )
				end
			end
		else ply:SetNW2Bool( "CTRL_bSprinting", false ) end
	end

	local s = PlyTable.GAME_sCoverState
	if s then
		if s == "DUCK" then
			if cmd:KeyDown( IN_ZOOM ) then
				PlyTable.GAME_flPeekFireTime = nil
			elseif cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) then
				PlyTable.GAME_flPeekFireTime = CurTime() + .2
			elseif CurTime() > ( PlyTable.GAME_flPeekFireTime || 0 ) then
				PlyTable.GAME_sCoverState = nil
				PlyTable.GAME_flPeekUpMinimumTime = nil
				return
			end
			if !PlyTable.GAME_flPeekUpMinimumTime then PlyTable.GAME_flPeekUpMinimumTime = CurTime() + .25 end
			if CurTime() <= PlyTable.GAME_flPeekUpMinimumTime then
				ply:SetNW2Bool( "CTRL_bPredictedCantShoot", true )
				cmd:RemoveKey( IN_ATTACK )
				cmd:RemoveKey( IN_ATTACK2 )
			else ply:SetNW2Bool "CTRL_bPredictedCantShoot" end
			ply:SetNW2Bool "CTRL_bInCover"
			PlyTable.CTRL_bInCover = nil
			ply:SetNW2Int( "CTRL_Peek", cmd:KeyDown( IN_ZOOM ) && COVER_FIRE_UP || COVER_BLINDFIRE_UP )
			cmd:RemoveKey( IN_DUCK )
			local aEye = ply:EyeAngles()
			local bInCover
			local EyeVector = aEye:Forward()
			local EyeVectorFlat = aEye:Forward()
			EyeVectorFlat.z = 0
			EyeVectorFlat:Normalize()
			local vView = ply:GetPos() + ply:GetViewOffset()
			local trStand = util_TraceLine {
				start = vView,
				endpos = vView + EyeVectorFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = function( pEntity )
					if pEntity == ply || pEntity.__PROJECTILE__ then return end
					return true
				end
			}
			local vViewDucked = ply:GetPos() + ply:GetViewOffsetDucked()
			local trDuck = util_TraceLine {
				start = vViewDucked,
				endpos = vViewDucked + EyeVectorFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = function( pEntity )
					if pEntity == ply || pEntity.__PROJECTILE__ then return end
					return true
				end
			}
			if !trDuck.Hit || trStand.Hit then
				PlyTable.GAME_sCoverState = nil
				PlyTable.GAME_flPeekUpMinimumTime = nil
				return
			end
		elseif s == "MOVE" then
			if cmd:KeyDown( IN_FORWARD ) || cmd:KeyDown( IN_BACK ) || cmd:KeyDown( IN_MOVELEFT ) || cmd:KeyDown( IN_MOVERIGHT ) then ply.GAME_sCoverState = nil return end
			if !PlyTable.GAME_flPeekTime then
				PlyTable.GAME_flPeekTime = CurTime() + .1
			elseif cmd:KeyDown( IN_ZOOM ) then
				PlyTable.GAME_flPeekFireTime = nil
			elseif cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) then
				PlyTable.GAME_flPeekFireTime = CurTime() + .2
			elseif CurTime() > ( PlyTable.GAME_flPeekFireTime || 0 ) && CurTime() > ( PlyTable.GAME_flPeekTime || 0 ) then
				PlyTable.GAME_sCoverState = "FROM"
				PlyTable.GAME_flPeekUpMinimumTime = nil
				return
			end
			cmd:AddKey( IN_WALK )
			ply:SetNW2Bool "CTRL_bInCover"
			PlyTable.CTRL_bInCover = nil
			ply:SetNW2Int( "CTRL_Peek", cmd:KeyDown( IN_ZOOM ) && PlyTable.GAME_EPeek || PlyTable.GAME_EPeekBlind )
			if !PlyTable.GAME_flPeekUpMinimumTime then PlyTable.GAME_flPeekUpMinimumTime = CurTime() + .25 end
			local bPredictedCantShoot
			if CurTime() <= ( PlyTable.GAME_flPeekUpMinimumTime || 0 ) then
				bPredictedCantShoot = true
				cmd:RemoveKey( IN_ATTACK )
				cmd:RemoveKey( IN_ATTACK2 )
			end
			local d = PlyTable.GAME_vPeekTarget - ply:GetPos()
			d[ 3 ] = 0
			d:Normalize()
			local dEyeFlat = ply:GetAimVector()
			dEyeFlat[ 3 ] = 0
			dEyeFlat:Normalize()
			local bMove
			local s = PlyTable.GAME_bPeekForceCrouch
			if s == false then
				cmd:RemoveKey( IN_DUCK )
				local vMins, vMaxs = ply:OBBMins(), ply:OBBMaxs()
				vMins[ 3 ] = 0
				vMaxs[ 3 ] = 0
				bMove = util_TraceHull( {
					start = ply:GetPos() + ply:GetViewOffsetDucked(),
					endpos = ply:GetPos() + ply:GetViewOffset(),
					mask = MASK_SOLID,
					mins = vMins,
					maxs = vMaxs,
					filter = function( pEntity )
						if pEntity == ply || pEntity.__PROJECTILE__ then return end
						return true
					end
				} ).Hit || util_TraceLine( {
					start = ply:GetPos() + ply:GetViewOffset(),
					endpos = ply:GetPos() + ply:GetViewOffset() + dEyeFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = function( pEntity )
						if pEntity == ply || pEntity.__PROJECTILE__ then return end
						return true
					end
				} ).Hit
			elseif s then
				cmd:AddKey( IN_DUCK )
				bMove = util_TraceLine( {
					start = ply:GetPos() + ply:GetViewOffsetDucked(),
					endpos = ply:GetPos() + ply:GetViewOffsetDucked() + dEyeFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = function( pEntity )
						if pEntity == ply || pEntity.__PROJECTILE__ then return end
						return true
					end
				} ).Hit
			elseif PlyTable.GAME_bPeekUnCrouchIfCan then
				bMove = util_TraceLine( {
					start = ply:GetPos() + ply:GetViewOffsetDucked(),
					endpos = ply:GetPos() + ply:GetViewOffsetDucked() + dEyeFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = function( pEntity )
						if pEntity == ply || pEntity.__PROJECTILE__ then return end
						return true
					end
				} ).Hit
				cmd:RemoveKey( IN_DUCK )
			else
				local v = ply:GetPos() + ( cmd:KeyDown( IN_DUCK ) && ply:GetViewOffsetDucked() || ply:GetViewOffset() )
				bMove = util_TraceLine( {
					start = v,
					endpos = v + dEyeFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = function( pEntity )
						if pEntity == ply || pEntity.__PROJECTILE__ then return end
						return true
					end
				} ).Hit
			end
			if bMove then
				PlyTable.GAME_flPeekUpMinimumTime = math.max( ply.GAME_flPeekUpMinimumTime, CurTime() + .15 )
				PlyTable.GAME_flPeekTime = CurTime() + .15
				ply:SetNW2Bool( "CTRL_bPredictedCantShoot", true )
				cmd:RemoveKey( IN_ATTACK )
				cmd:RemoveKey( IN_ATTACK2 )
				cmd:SetForwardMove( ply:GetRunSpeed() * d:Dot( ply:GetForward() ) )
				cmd:SetSideMove( ply:GetRunSpeed() * d:Dot( ply:GetRight() ) )
			else ply:SetNW2Bool( "CTRL_bPredictedCantShoot", bPredictedCantShoot ) end
		else//if s == "FROM" then
			PlyTable.GAME_flPeekTime = nil
			ply:SetNW2Bool "CTRL_bPredictedCantShoot"
			if cmd:KeyDown( IN_FORWARD ) || cmd:KeyDown( IN_BACK ) || cmd:KeyDown( IN_MOVELEFT ) || cmd:KeyDown( IN_MOVERIGHT ) then ply.GAME_sCoverState = nil return end
			local bInCover
			local dEyeFlat = -PlyTable.GAME_vPeekSourceHitNormal
			dEyeFlat.z = 0
			dEyeFlat:Normalize()
			local v = PlyTable.GAME_vPeekSource
			local trOriginalStand, trOriginalDuck = util_TraceLine {
				start = v + ply:GetViewOffset(),
				endpos = v + ply:GetViewOffset() + dEyeFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = function( pEntity )
					if pEntity == ply || pEntity.__PROJECTILE__ then return end
					return true
				end
			}, util_TraceLine {
				start = v + ply:GetViewOffsetDucked(),
				endpos = v + ply:GetViewOffsetDucked() + dEyeFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = function( pEntity )
					if pEntity == ply || pEntity.__PROJECTILE__ then return end
					return true
				end
			}
			if !trOriginalStand.Hit then cmd:AddKey( IN_DUCK ) end
			if !trOriginalDuck.Hit then PlyTable.GAME_sCoverState = nil return end
			local vView = ply:GetPos() + ply:GetViewOffset()
			local trStand = util_TraceLine {
				start = vView,
				endpos = vView + dEyeFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = function( pEntity )
					if pEntity == ply || pEntity.__PROJECTILE__ then return end
					return true
				end
			}
			local vViewDucked = ply:GetPos() + ply:GetViewOffsetDucked()
			local trDuck = util_TraceLine {
				start = vViewDucked,
				endpos = vViewDucked + dEyeFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = function( pEntity )
					if pEntity == ply || pEntity.__PROJECTILE__ then return end
					return true
				end
			}
			local bDuck, tr
			if ply:IsOnGround() then
				if cmd:KeyDown( IN_DUCK ) then
					if trDuck.Hit then
						bDuck = true
						bInCover = true
						tr = trDuck
					end
				else
					if trDuck.Hit && trStand.Hit then
						bInCover = true
						tr = trStand
					end
				end
			end
			if bInCover then
				PlyTable.GAME_sCoverState = nil
				return
			else
				cmd:AddKey( IN_WALK )
				local d = PlyTable.GAME_vPeekSource - ply:GetPos()
				d[ 3 ] = 0
				d:Normalize()
				local dEyeFlat = ply:GetAimVector()
				dEyeFlat[ 3 ] = 0
				dEyeFlat:Normalize()
				cmd:SetForwardMove( ply:GetRunSpeed() * d:Dot( ply:GetForward() ) )
				cmd:SetSideMove( ply:GetRunSpeed() * d:Dot( ply:GetRight() ) )
			end
		end
	else
		PlyTable.GAME_flPeekFireTime = nil
		local wep = ply:GetActiveWeapon()
		if IsValid( wep ) && !cmd:KeyDown( IN_ZOOM ) then
			local cap = wep.GetCapabilities
			if cap then
				cap = cap( wep )
				if bit.band( cap, CAP_INNATE_MELEE_ATTACK1 ) != 0 || bit.band( cap, CAP_WEAPON_MELEE_ATTACK1 ) != 0 then
					ply:SetNW2Bool "CTRL_bInCover"
					ply.CTRL_bInCover = nil
					ply:SetNW2Int( "CTRL_Peek", COVER_PEEK_NONE )
					return
				end
			end
		end
		local aEye = ply:EyeAngles()
		local bInCover
		local EyeVector = aEye:Forward()
		local EyeVectorFlat = aEye:Forward()
		EyeVectorFlat.z = 0
		EyeVectorFlat:Normalize()
		local vView = ply:GetPos() + ply:GetViewOffset()
		local trStand = util_TraceLine {
			start = vView,
			endpos = vView + EyeVectorFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
			mask = MASK_SOLID,
			filter = function( pEntity )
				if pEntity == ply || pEntity.__PROJECTILE__ then return end
				return true
			end
		}
		local vViewDucked = ply:GetPos() + ply:GetViewOffsetDucked()
		local trDuck = util_TraceLine {
			start = vViewDucked,
			endpos = vViewDucked + EyeVectorFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
			mask = MASK_SOLID,
			filter = function( pEntity )
				if pEntity == ply || pEntity.__PROJECTILE__ then return end
				return true
			end
		}
		local bDuck, tr
		if ply:IsOnGround() then
			if cmd:KeyDown( IN_DUCK ) then
				if trDuck.Hit then
					bDuck = true
					bInCover = true
					tr = trDuck
				end
			else
				if trDuck.Hit && trStand.Hit then
					bInCover = true
					tr = trStand
				end
			end
		end
		ply:SetNW2Bool "CTRL_bPredictedCantShoot"
		if bInCover then
			if !Achievement_Has( ply, "Miscellaneous_CoverGrate" ) && bit.band( tr.Contents, CONTENTS_GRATE ) != 0 then Achievement_Miscellaneous_Grant( ply, "CoverGrate" ) end
			// NOTE: Force variables will do nothing when `nil`. This is intended so that
			// covers who allow being both crouched and uncrouched during peeks work!
			local vMins, vMaxs = ply:OBBMins(), ply:OBBMaxs()
			vMins[ 3 ] = 0
			vMaxs[ 3 ] = 0
			local bUp, bLeft, bRight, bLeftForceCrouch, bRightForceCrouch = bDuck && !trStand.Hit && !util_TraceHull( {
				start = ply:GetPos() + ply:GetViewOffsetDucked(),
				endpos = ply:GetPos() + ply:GetViewOffset(),
				mask = MASK_SOLID,
				mins = vMins,
				maxs = vMaxs,
				filter = ply
			} ).Hit
			local vLeft, vRight = ply:GetPos() + tr.HitNormal:Angle():Right() * ply:OBBMaxs()[ 2 ] * 2, ply:GetPos() - tr.HitNormal:Angle():Right() * ply:OBBMaxs()[ 2 ] * 2
			if !util_TraceLine( {
				start = ply:GetPos() + ply:GetViewOffsetDucked(),
				endpos = vLeft + ply:GetViewOffsetDucked(),
				filter = ply,
				mask = MASK_SOLID
			} ).Hit && util_TraceLine( {
				start = vLeft,
				endpos = vLeft - Vector( 0, 0, ply:GetStepSize() ),
				filter = ply,
				mask = MASK_SOLID
			} ).Hit then
				local trDuck = util_TraceLine {
					start = vLeft + ply:GetViewOffsetDucked(),
					endpos = vLeft + ply:GetViewOffsetDucked() + EyeVectorFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				}
				local trStand = util_TraceLine {
					start = vLeft + ply:GetViewOffset(),
					endpos = vLeft + ply:GetViewOffset() + EyeVectorFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				}
				if !trDuck.Hit && !trStand.Hit then bLeft = true
				elseif !trStand.Hit && trDuck.Hit then
				elseif !trDuck.Hit && trStand.Hit then bLeft = true bLeftForceCrouch = true end
			end
			if !util_TraceLine( {
				start = ply:GetPos() + ply:GetViewOffsetDucked(),
				endpos = vRight + ply:GetViewOffsetDucked(),
				filter = ply,
				mask = MASK_SOLID
			} ).Hit && util_TraceLine( {
				start = vRight,
				endpos = vRight - Vector( 0, 0, ply:GetStepSize() ),
				filter = ply,
				mask = MASK_SOLID
			} ).Hit then
				local trDuck = util_TraceLine {
					start = vRight + ply:GetViewOffsetDucked(),
					endpos = vRight + ply:GetViewOffsetDucked() + EyeVectorFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				}
				local trStand = util_TraceLine {
					start = vRight + ply:GetViewOffset(),
					endpos = vRight + ply:GetViewOffset() + EyeVectorFlat * ply:OBBMaxs()[ 1 ] * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				}
				if !trDuck.Hit && !trStand.Hit then bRight = true
				elseif !trStand.Hit && trDuck.Hit then bRightForceCrouch = false
				elseif !trDuck.Hit && trStand.Hit then bRight = true bRightForceCrouch = true end
			end
			if bUp then
				local f = math.NormalizeAngle( math.AngleDifference( ( -trDuck.HitNormal ):Angle()[ 2 ], aEye[ 2 ] ) )
				if bLeft && f < -2 then
					VARIANTS = COVER_VARIANTS_LEFT
				elseif bRight && f > 2 then
					VARIANTS = COVER_VARIANTS_RIGHT
				else
					VARIANTS = COVER_VARIANTS_BOTH
				end
			else
				if bLeft && bRight then
					local f = math.NormalizeAngle( math.AngleDifference( ( -trDuck.HitNormal ):Angle()[ 2 ], aEye[ 2 ] ) )
					if f < -2 then
						VARIANTS = COVER_VARIANTS_LEFT
					elseif f > 2 then
						VARIANTS = COVER_VARIANTS_RIGHT
					end
				elseif bLeft then
					VARIANTS = COVER_VARIANTS_LEFT
				elseif bRight then
					VARIANTS = COVER_VARIANTS_RIGHT
				else VARIANTS = COVER_VARIANTS_BOTH end
			end
			if cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) || cmd:KeyDown( IN_ZOOM ) then
				if VARIANTS == COVER_VARIANTS_BOTH && bUp then
					Achievement_Miscellaneous( ply, cmd:KeyDown( IN_ZOOM ) && "CoverPeek" || "CoverBlindFire" )
					PlyTable.GAME_sCoverState = "DUCK"
					return
				elseif VARIANTS == COVER_VARIANTS_LEFT then
					Achievement_Miscellaneous( ply, cmd:KeyDown( IN_ZOOM ) && "CoverPeek" || "CoverBlindFire" )
					PlyTable.GAME_sCoverState = "MOVE"
					PlyTable.GAME_bPeekForceCrouch = bLeftForceCrouch
					PlyTable.GAME_vPeekTarget = vLeft
					PlyTable.GAME_bPeekUnCrouchIfCan = aEye[ 1 ] < -5.625
					PlyTable.GAME_vPeekSource = ply:GetPos()
					PlyTable.GAME_vPeekSourceHitNormal = tr.HitNormal
					PlyTable.GAME_EPeek = COVER_FIRE_LEFT
					PlyTable.GAME_EPeekBlind = COVER_BLINDFIRE_LEFT
					return
				elseif VARIANTS == COVER_VARIANTS_RIGHT then
					Achievement_Miscellaneous( ply, cmd:KeyDown( IN_ZOOM ) && "CoverPeek" || "CoverBlindFire" )
					PlyTable.GAME_sCoverState = "MOVE"
					PlyTable.GAME_bPeekForceCrouch = bRightForceCrouch
					PlyTable.GAME_vPeekTarget = vRight
					PlyTable.GAME_bPeekUnCrouchIfCan = aEye[ 1 ] < -5.625
					PlyTable.GAME_vPeekSource = ply:GetPos()
					PlyTable.GAME_vPeekSourceHitNormal = tr.HitNormal
					PlyTable.GAME_EPeek = COVER_FIRE_RIGHT
					PlyTable.GAME_EPeekBlind = COVER_BLINDFIRE_RIGHT
					return
				end
			end
			PlyTable.CTRL_bInCover = true
			ply:SetNW2Bool( "CTRL_bInCover", true )
			ply:SetNW2Int( "CTRL_Variants", VARIANTS )
			ply:SetNW2Int( "CTRL_Peek", COVER_PEEK_NONE )
		else
			PlyTable.CTRL_bInCover = nil
			ply:SetNW2Bool "CTRL_bInCover"
			ply:SetNW2Int( "CTRL_Peek", COVER_PEEK_NONE )
		end
	end

	BloodlossStuff( ply, cmd ) // Run it twice so that we neutralize RemoveKey( IN_DUCK ) in case it was called
end

function QuickSlide_Handle( ply )
	local vel = GetVelocity( ply )
	local f = CEntity_GetNW2Float( ply, "CTRL_flSlideSpeed", 0 )
	if CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) && ( !ply.Alive || ply.Alive && ply:Alive() ) && vel:Length() > 8 && CEntity_IsOnGround( ply ) && f > 8 && ( !ply:IsPlayer() || ply:IsPlayer() && CPlayer_KeyDown( ply, IN_DUCK ) && CPlayer_KeyDown( ply, IN_SPEED ) ) then
		local v = ply:GetAimVector()
		v.z = 0
		v:Normalize()

		local flSpeed = ply.GAME_flSlideSpeed || ply:GetRunSpeed() * 1.5
		local t = CEntity_GetTable( ply )
		f = f - flSpeed * ( t.CTRL_flSlideSpeedDecay || ( 2 / 3 ) ) * FrameTime()

		CEntity_SetNW2Float( ply, "CTRL_flSlideSpeed", f )

		local s = t.CTRL_pSlideLoop
		if s then
			s:ChangeVolume( vel:Length() / flSpeed )
			local p = vel:Length() / flSpeed
			s:ChangeVolume( p )
			s:ChangePitch( math.Remap( p, 0, 1, 80, 100 ) )
		end

		t.GAME_flNextSlide = CurTime() + 1

		return v * f
	else
		local t = CEntity_GetTable( ply )
		local v = t.CTRL_pSlideLoop
		if v then
			v:Stop()
			t.CTRL_pSlideLoop = nil
		end
		CEntity_SetNW2Bool( ply, "CTRL_bSliding", false )
	end
end

function QuickSlide_Start( ply, t )
	if ply:IsPlayer() then Achievement_Miscellaneous( ply, "Slide" ) end
	CEntity_SetNW2Bool( ply, "CTRL_bSliding", true )
	local t = t || CEntity_GetTable( ply )
	local f = t.GAME_flSlideSpeed || ply:GetRunSpeed() * 1.5
	CEntity_SetNW2Float( ply, "CTRL_flSlideSpeed", f )
	local s = CreateSound( ply, t.CTRL_sSlideLoop || "HumanSlideLoop" )
	t.CTRL_pSlideLoop = s
	s:Play()
end

function QuickSlide_CalcLength( ply )
	local v = ply.GAME_flSlideSpeed || ply:GetRunSpeed() * 1.5
	local d = v * ( CEntity_GetTable( ply ).CTRL_flSlideSpeedDecay || ( 2 / 3 ) )
	return ( v * v ) / ( 2 * d )
end

hook.Add( "Move", "GameImprovements", function( ply, mv )
	if !ply:Alive() then return end

	if !CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) && QuickSlide_Can( ply ) then
		local t = CEntity_GetTable( ply )
		if CPlayer_KeyDown( ply, IN_SPEED ) && CPlayer_KeyDown( ply, IN_DUCK ) && QuickSlide_Can( ply, t ) then QuickSlide_Start( ply, t ) end
	end

	local v = QuickSlide_Handle( ply )
	if v then mv:SetVelocity( v ) end
end )

NOT_A_VOICELINE = NOT_A_VOICELINE || {}

NOT_A_VOICELINE[ "npc/antlion_guard/growl_idle.wav" ] = true
NOT_A_VOICELINE[ "npc/antlion_guard/growl_high.wav" ] = true
NOT_A_VOICELINE[ "npc/antlion_guard/confused1.wav" ] = true
NOT_A_VOICELINE[ "npc/antlion/fly1.wav" ] = true
NOT_A_VOICELINE[ "npc/attack_helicopter/aheli_rotor_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/attack_helicopter/aheli_wash_loop3.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/dropship_engine_near_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/dropship_engine_distant_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/dropship_dropping_pod_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/dropship_onground_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/engine_rotor_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/engine_whine_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/gunship_engine_loop3.wav" ] = true
NOT_A_VOICELINE[ "AirRaidSirenOscillatorLoop.wav" ] = true
NOT_A_VOICELINE[ "npc/stalker/laser_burn.wav" ] = true
NOT_A_VOICELINE[ "npc/stalker/laser_flesh.wav" ] = true
NOT_A_VOICELINE[ "npc/fast_zombie/breathe_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/fast_zombie/gurgle_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/manhack/mh_blade_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/manhack/mh_engine_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/manhack/mh_engine_loop2.wav" ] = true
NOT_A_VOICELINE[ "npc/roller/mine/combine_mine_active_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/roller/mine/rmine_movefast_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/roller/mine/rmine_moveslow_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/roller/mine/rmine_seek_loop2.wav" ] = true
NOT_A_VOICELINE[ "npc/zombie/moan_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/zombie/moan_loop2.wav" ] = true
NOT_A_VOICELINE[ "npc/zombie/moan_loop3.wav" ] = true
NOT_A_VOICELINE[ "npc/zombie/moan_loop4.wav" ] = true

util.AddNetworkString "CaptionSound"

hook.Add( "EntityEmitSound", "GameImprovements", function( Data, COMP )
	if COMP then
		if COMP.KM_CMs_Addon then return
		else COMP.KM_CMs_Addon = true end
	end

	hook.Run( "EntityEmitSound", Data, { KM_CMs_Addon = true } )

	local pEntity = Data.Entity
	local pOwner = GetOwner( pEntity )

	local bUnableToPinpointLocation = pEntity.SOUND_CONTEXT_bUnableToPinpointLocation

	pEntity.SOUND_CONTEXT_sContext = nil
	pEntity.SOUND_CONTEXT_bUnableToPinpointLocation = nil

	local fCallOnAllHearers = pEntity.SOUND_CONTEXT_fCallOnAllHearers || function() end

	local sSoundName = Data.SoundName
	pEntity.GAME_sLastSoundPath = sSoundName

	local flDuration = SoundDuration( Data.SoundName )
	pEntity.GAME_flLastSoundDuration = flDuration

	if Data.Volume <= .05 then return true end

	local flDistance = math_Clamp( Data.SoundLevel ^ ( Data.SoundLevel >= 100 && 1.95547 || 1.5 ), 5, 18000 )

	local vPos = Data.Pos || ( pEntity:GetPos() + pEntity:OBBCenter() )

	for pActor in pairs( __ACTOR_LIST__ ) do
		if pActor == pEntity || pActor == pOwner then continue end

		local ActorTable = CEntity_GetTable( pActor )
		if bUnableToPinpointLocation then
			// Nothing, for now
			// TODO: "What was that sound?", based on context
		else
			if ActorTable.flHearingStrength > 0 && ActorTable.GetShootPos( pActor ):Distance( vPos ) <= ( flDistance * ActorTable.flHearingStrength ) then
				fCallOnAllHearers( pActor )
				ActorTable.OnHeardSomething( pActor, pOwner, Data )
			end
		end
	end

	if Data.Flags != SND_CHANGE_VOL && Data.Flags != SND_CHANGE_PITCH && Data.Flags != SND_STOP then
		local sRealSound = sSoundName:match "^[%^%)]*(.*)"

		local cColor
		local fCaptionColor = pOwner.CaptionColor
		if fCaptionColor then
			cColor = fCaptionColor( pOwner )
		else
			local fPlayerColor = pOwner.GetPlayerColor
			if fPlayerColor then
				cColor = fPlayerColor( pOwner ):ToColor()
			else cColor = color_white end
		end

		local flDistSqr = flDistance * flDistance

		local tCaptionPlayers = {}

		for _, ply in player_Iterator() do
			if ply:EyePos():DistToSqr( vPos ) > flDistSqr then continue end

			fCallOnAllHearers( ply )

			table_insert( tCaptionPlayers, ply )

			if NOT_A_VOICELINE[ sRealSound ] then continue end

			if Director_GetThreat( ply, pEntity ) < DIRECTOR_THREAT_HOLD_FIRE && Director_GetThreat( ply, pOwner ) < DIRECTOR_THREAT_HOLD_FIRE then continue end

			local PlyTable = CEntity_GetTable( ply )

			local f = ply:GetNW2Float( "DIRECTOR_MUSIC_VO_WAIT", DIRECTOR_MUSIC_VO_WAIT )

			PlyTable.DIRECTOR_MUSIC_VO_WAIT_RECOVER_TIME = CurTime() + .5

			local t = PlyTable.DR_tSpotted
			if t then t[ pOwner ] = 0
			else PlyTable.DR_tSpotted = { [ pOwner ] = 0 } end
			local t = PlyTable.DR_tMusicEntities

			if t then t[ pOwner ] = true
			else PlyTable.DR_tMusicEntities = { [ pOwner ] = true } end

			if PlyTable.DR_EThreat == DIRECTOR_THREAT_COMBAT then continue end

			if f <= 0 then
				PlyTable.DR_EThreat = DIRECTOR_THREAT_COMBAT
				continue
			end
	
			if ( RealTime() > ( PlyTable.DR_flIAmAlreadyInCombatForSomeTime || 0 ) ) && ( RealTime() > ( PlyTable.DR_flVoWait || 0 ) && PlyTable.DR_EThreat == DIRECTOR_THREAT_HOLD_FIRE || RealTime() <= ( PlyTable.DR_flVoDangerousWait || math.huge ) ) then
				local flVoVait = PlyTable.DR_flVoWait
				if !flVoVait || RealTime() > ( flVoVait + ply:GetNW2Float( "DIRECTOR_MUSIC_VO_WAIT", DIRECTOR_MUSIC_VO_WAIT ) * 2 ) then
					PlyTable.DR_EThreat = DIRECTOR_THREAT_COMBAT

					ply:SendLua( "Director_VoiceLineHookToCombat(\"" .. sSoundName .. "\")" )

					local t = RealTime() + min( SoundDuration( sSoundName ), 8 )

					PlyTable.DR_flIAmAlreadyInCombatForSomeTime = t
					PlyTable.DR_flIAmAlreadyInDangerForSomeTime = t

					if f <= 0 then PlyTable.DR_flVoDangerousWait = RealTime()
					else PlyTable.DR_flVoDangerousWait = t end
				end

				f = math_Clamp( f - DIRECTOR_MUSIC_VO_WAIT * ( 1 / 60 ), 0, DIRECTOR_MUSIC_VO_WAIT )
				ply:SetNW2Float( "DIRECTOR_MUSIC_VO_WAIT", f )

				continue
			end
	
			if ( RealTime() > ( PlyTable.DR_flIAmAlreadyInDangerForSomeTime || 0 ) ) && ( PlyTable.DR_EThreat < DIRECTOR_THREAT_HOLD_FIRE || RealTime() <= ( PlyTable.DR_flVoWait || 0 ) ) then
				PlyTable.DR_EThreat = DIRECTOR_THREAT_HOLD_FIRE

				ply:SendLua( "Director_VoiceLineHook(\"" .. sSoundName .. "\")" )

				local t = RealTime() + math.min( SoundDuration( sSoundName ), 8 ) + ply:GetNW2Float( "DIRECTOR_MUSIC_VO_WAIT", DIRECTOR_MUSIC_VO_WAIT )
				PlyTable.DR_flIAmAlreadyInDangerForSomeTime = t

				if f <= 0 then PlyTable.DR_flVoWait = RealTime()
				else PlyTable.DR_flVoWait = t end

				f = math_Clamp( f - DIRECTOR_MUSIC_VO_WAIT * ( 1 / 60 ), 0, DIRECTOR_MUSIC_VO_WAIT )
				ply:SetNW2Float( "DIRECTOR_MUSIC_VO_WAIT", f )

				continue
			end
	
			f = math_Clamp( f - DIRECTOR_MUSIC_VO_WAIT * .05, 0, DIRECTOR_MUSIC_VO_WAIT )
			ply:SetNW2Float( "DIRECTOR_MUSIC_VO_WAIT", f )
		end

		if !table_IsEmpty( tCaptionPlayers ) then
			net_Start( "CaptionSound", false )
				net_WriteColor( cColor, false )
				net_WriteString( sRealSound )
				net_WriteFloat( flDuration )
			net_Send( tCaptionPlayers )
		end
	end

	return true
end )

hook.Add( "EntityRemoved", "GameImprovements", function( pEntity )
	local t = pEntity.GAME_tIWantACallBackWhenThisIsRemoved
	if t then
		for _, f in ipairs( t ) do
			f()
		end
	end
	pEntity.GAME_tIWantACallBackWhenThisIsRemoved = nil
end )

if !CLASS_HUMAN then Add_NPC_Class "CLASS_HUMAN" end

function CPlayer:GetNPCClass() return CEntity_GetTable( self ).m_iClass || CLASS_HUMAN end
function CPlayer:Classify() return CEntity_GetTable( self ).m_iClass || CLASS_HUMAN end
function CPlayer:SetNPCClass( i ) CEntity_GetTable( self ).m_iClass = i end
