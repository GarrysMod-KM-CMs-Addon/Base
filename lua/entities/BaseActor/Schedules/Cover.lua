local table_IsEmpty = table.IsEmpty
local HasRangeAttack, HasMeleeAttack = HasRangeAttack, HasMeleeAttack
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
local util_DistanceToLine = util.DistanceToLine
local random = math.random
local Rand = math.Rand
local unpack = unpack
local CurTime = CurTime

ENT.tPreScheduleResetVariables.bSuppressing = false
ENT.tPreScheduleResetVariables.bWantsCover = false

function ENT:RangeAttack()
	if self.bHoldFire then return end
	self:WeaponPrimaryVolley()

	self.flWeaponPrimaryVolleyTimeMin = 0
	self.flWeaponPrimaryVolleyTimeMax = 3

	self.flWeaponPrimaryVolleyBreakMin = 0
	self.flWeaponPrimaryVolleyBreakMax = 1

	self.flWeaponPrimaryVolleyNonAutomaticDelayMin = 0
	self.flWeaponPrimaryVolleyNonAutomaticDelayMax = .4

	return true
end

// Small suppressed, does NOT want someone else to help yet
function ENT:DLG_Suppressed() end
// Large suppressed, DOES want someone else to help now
// No functionality here for now, but it'll be here, so do BaseClass.DLG_Pinned( self, MyTable )
function ENT:DLG_Pinned( MyTable ) end

// See the code, I have no easy way of explaining this one
ENT.flSuppressionTraceFraction = .8

local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull

ENT.flHoldFireTime = 48

function ENT:DLG_HoldFire()
	self.bHoldFire = true
	local tAllies = self:GetAlliesByClass()
	if tAllies then
		for ent in pairs( tAllies ) do
			if IsValid( ent ) then ent.bHoldFire = true end
		end
	end
end

ENT.Moving_WEAPON_STANCE = WEAPON_STANCE_DEFAULT

PATH_STABILIZER = 1 / 3

ACTOR_PITCH_ANGLES_UP = { 0 }
for a = 5.625, 90, 5.625 do
	table.insert( ACTOR_PITCH_ANGLES_UP, a )
	table.insert( ACTOR_PITCH_ANGLES_UP, -a )
end

ACTOR_PITCH_ANGLES_DOWN = { 0 }
for a = 5.625, 90, 5.625 do
	table.insert( ACTOR_PITCH_ANGLES_DOWN, -a )
	table.insert( ACTOR_PITCH_ANGLES_DOWN, a )
end

ACTOR_PITCH_ANGLES_LEFT = { 0 }
for a = 5.625, 22.5, 5.625 do
	table.insert( ACTOR_PITCH_ANGLES_LEFT, -a )
	table.insert( ACTOR_PITCH_ANGLES_LEFT, a )
end

ACTOR_PITCH_ANGLES_RIGHT = { 0 }
for a = 5.625, 22.5, 5.625 do
	table.insert( ACTOR_PITCH_ANGLES_RIGHT, a )
	table.insert( ACTOR_PITCH_ANGLES_RIGHT, -a )
end

local STEP = 5.625

ACTOR_PITCH_ANGLES_SHORT_UP = { 0 }
for a = STEP, 22.5, STEP do
	table.insert( ACTOR_PITCH_ANGLES_SHORT_UP, a )
	table.insert( ACTOR_PITCH_ANGLES_SHORT_UP, -a )
end

ACTOR_PITCH_ANGLES_SHORT_DOWN = { 0 }
for a = STEP, 22.5, STEP do
	table.insert( ACTOR_PITCH_ANGLES_SHORT_DOWN, -a )
	table.insert( ACTOR_PITCH_ANGLES_SHORT_DOWN, a )
end

ACTOR_PITCH_ANGLES_SHORT_LEFT = { 0 }
for a = STEP, 22.5, STEP do
	table.insert( ACTOR_PITCH_ANGLES_SHORT_LEFT, -a )
	table.insert( ACTOR_PITCH_ANGLES_SHORT_LEFT, a )
end

ACTOR_PITCH_ANGLES_SHORT_RIGHT = { 0 }
for a = STEP, 22.5, STEP do
	table.insert( ACTOR_PITCH_ANGLES_SHORT_RIGHT, a )
	table.insert( ACTOR_PITCH_ANGLES_SHORT_RIGHT, -a )
end

function ENT:FindAlarm( MyTable )
	local flAlarm, vPos, pAlarm = math.huge, MyTable.GetShootPos( self ), NULL // NULL because ent.pAlarm ( if nil ) == pAlarm ( which is nil )
	local t = __ALARMS__[ self:Classify() ]
	if t then
		for ent in pairs( t ) do
			if !IsValid( ent ) || ent.bIsOn then continue end
			local d = ent:NearestPoint( vPos ):DistToSqr( vPos )
			// Don't go out of audible range, even if an ally alarm. Why?
			// Because it's not funny to run kilometers away from the battlefield to it like an idiot
			if d >= flAlarm || Either( ent.flAudibleDistSqr == 0, self:Visible( ent ), d >= ent.flAudibleDistSqr ) then continue end
			local f = ent.flCoolDown
			if CurTime() <= f then continue end
			local b
			if tAllies then for ent in pairs( tAllies ) do if ent != self && IsValid( ent ) && ent.pAlarm == pAlarm then b = true break end end end
			if b then continue end
			pAlarm, flAlarm = ent, d
		end
	end
	if IsValid( pAlarm ) then return pAlarm end
	t = __ALARMS__[ CLASS_NONE ]
	if t then
		for ent in pairs( t ) do
			if !IsValid( ent ) || ent.bIsOn then continue end
			local d = ent:NearestPoint( vPos ):DistToSqr( vPos )
			if d >= flAlarm || Either( ent.flAudibleDistSqr == 0, self:Visible( ent ), d >= ent.flAudibleDistSqr ) then continue end
			local f = ent.flCoolDown
			if f && CurTime() <= f then continue end
			local b
			if tAllies then for ent in pairs( tAllies ) do if ent != self && IsValid( ent ) && ent.pAlarm == pAlarm then b = true break end end end
			if b then continue end
			pAlarm, flAlarm = ent, d
		end
	end
	if IsValid( pAlarm ) then return pAlarm end
end

function ENT:PullAlarmIfAvailable( MyTable )
	local pAlarm = MyTable.FindAlarm( self, MyTable )
	if IsValid( pAlarm ) then
		local pSchedule = MyTable.SetSchedule( self, "PullAlarm", MyTable )
		pSchedule.pAlarm = pAlarm
		MyTable.pAlarm = pAlarm
		return true
	end
end

function ENT:DLG_MaintainFire() end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

ENT.flMaintainFireTime = 0
ENT.flMaintainFireTimeMin = 2
ENT.flMaintainFireTimeMax = 6
ENT.flPathStabilizer = 16

function ENT:DLG_Charge() end

// Fixes a certain bug that I'm too lazy to describe rn
// Maybe on the docs, sometime?
function ENT:IsValidCoverCandidate( tCover, pEnemyPath, MyTable )
	local vStart = tCover.vStart
	local vEnd = tCover.vEnd
	local vCenter = ( vStart + vEnd ) * .5

	pEnemyPath:MoveCursorToClosestPosition( vCenter )
	local flCursor = pEnemyPath:GetCursorPosition()
	local dTowards = pEnemyPath:GetPositionOnPath( flCursor )
	pEnemyPath:MoveCursor( Lerp( PATH_STABILIZER, flCursor, pEnemyPath:GetLength() ) )
	dTowards = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - vCenter
	dTowards[ 3 ] = 0
	dTowards:Normalize()

	local flDot = ( vEnd - vStart ):Angle():Right():Dot( dTowards )
	if tCover.bRight then return flDot < 0 else return flDot > 0 end
end

function ENT:IsValidCoverPoint( vCover, tCover, pEnemy, pEnemyPath, MyTable, vMaxs /* Optional as you may have precomputed them */ )
	vMaxs = vMaxs || MyTable.vHullDuckHitCheckMaxs || MyTable.vHullDuckMaxs || MyTable.vHullMaxs
	local vCrouched = Vector( vCover )
	vCrouched[ 3 ] = vCrouched[ 3 ] + vMaxs[ 3 ] * 1.25

	pEnemyPath:MoveCursorToClosestPosition( vCover )
	local flCursor = pEnemyPath:GetCursorPosition()
	local dTowards = pEnemyPath:GetPositionOnPath( flCursor )
	pEnemyPath:MoveCursor( Lerp( PATH_STABILIZER, flCursor, pEnemyPath:GetLength() ) )
	dTowards = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - vCover
	dTowards[ 3 ] = 0
	dTowards:Normalize()

	if dTowards:IsZero() then
		dTowards = pEnemy:GetPos() - vCover
		dTowards[ 3 ] = 0
		dTowards:Normalize()
	end

	return util_TraceLine( {
		start = vCrouched,
		endpos = vCrouched + dTowards * vMaxs[ 1 ] * COVER_BOUND_SIZE,
		mask = MASK_SHOT_HULL,
		filter = self
	} ).Hit
end

RegisterSchedule( "Cover", { Execute = function( self, pSchedule, MyTable )
	local tEnemies = pSchedule.tEnemies || MyTable.tEnemies
	if table_IsEmpty( tEnemies ) then return true end

	//	if !MyTable.bEnemiesHaveRangeAttack && HasRangeAttack( self ) then MyTable.SetSchedule( self, "FreeMovementStand", MyTable ) return end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )

	if !MyTable.bHoldFire && CurTime() > ( MyTable.flLastEnemy + MyTable.flHoldFireTime ) then MyTable.DLG_HoldFire( self, MyTable ) end

	local vCover = MyTable.vCover
	local tCover = MyTable.tCover

	if !tCover || !vCover then
		MyTable.SetSchedule( self, MyTable.CanExpose( self, MyTable ) && "FreeMovementStand" || "TakeCover", MyTable )
		return
	end

	MyTable.WEAPON_STANCE = WEAPON_STANCE_PASSIVE

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end

	if LevelOfDetail( pSchedule, "flNextPath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy ) end

	local bDuck

	if CurTime() > ( pSchedule.flDuckTime || 0 ) then
		// Fun fact: humans are not fans of lactic acid buildup
		if random( 3 ) == 1 then bDuck = true pSchedule.bDuck = true end

		bDuck = false
		pSchedule.bDuck = nil

		pSchedule.flDuckTime = CurTime() + Rand( 0, 4 )
	end

	if bDuck == nil then bDuck = pSchedule.bDuck end

	local flStand = pSchedule.flStand

	if bDuck then
		flStand = 0
		pSchedule.flStand = 0
		// nil means wait before checking, -1 means check ASAP
		pSchedule.flStandCheck = -1

		if LevelOfDetail( pSchedule, "flNextTowardsCheck" ) then
			local vMaxs = MyTable.vHullDuckMaxs || MyTable.vHullMaxs
			local vStanding = Vector( vCover )
			vStanding[ 3 ] = vStanding[ 3 ] + vMaxs[ 3 ]
		
			pEnemyPath:MoveCursorToClosestPosition( vCover )
			local flCursor = pEnemyPath:GetCursorPosition()
			local dTowards = pEnemyPath:GetPositionOnPath( flCursor )
			pEnemyPath:MoveCursor( Lerp( PATH_STABILIZER, flCursor, pEnemyPath:GetLength() ) )
			dTowards = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - vCover
			dTowards[ 3 ] = 0
			dTowards:Normalize()
		
			if dTowards:IsZero() then
				dTowards = pEnemy:GetPos() - vCover
				dTowards[ 3 ] = 0
				dTowards:Normalize()
			end

			MyTable.vaAimTargetBody = dTowards:Angle()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		end
	else
		if !flStand || LevelOfDetail( pSchedule, "flStandCheck" ) then
			flStand = 0

			LevelOfDetail( pSchedule, "flNextTowardsCheck" )
	
			local vMaxs = MyTable.vHullMaxs
			local vStanding = Vector( vCover )
			vStanding[ 3 ] = vStanding[ 3 ] + vMaxs[ 3 ]
		
			pEnemyPath:MoveCursorToClosestPosition( vCover )
			local flCursor = pEnemyPath:GetCursorPosition()
			local dTowards = pEnemyPath:GetPositionOnPath( flCursor )
			pEnemyPath:MoveCursor( Lerp( PATH_STABILIZER, flCursor, pEnemyPath:GetLength() ) )
			dTowards = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - vCover
			dTowards[ 3 ] = 0
			dTowards:Normalize()
		
			if dTowards:IsZero() then
				dTowards = pEnemy:GetPos() - vCover
				dTowards[ 3 ] = 0
				dTowards:Normalize()
			end

			MyTable.vaAimTargetBody = dTowards:Angle()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody

			if util_TraceLine( {
				start = vStanding,
				endpos = vStanding + dTowards * vMaxs[ 1 ] * COVER_BOUND_SIZE,
				mask = MASK_SHOT_HULL,
				filter = self
			} ).Hit then flStand = 1 end
		end
	end

	local pPath = pSchedule.pPath
	if !pPath then pPath = Path "Follow" pSchedule.pPath = pPath end

	if LevelOfDetail( pSchedule, "flNextPath" ) then MyTable.ComputePath( self, pPath, vCover ) end

	MyTable.MoveAlongPath( self, pPath, MyTable.flWalkSpeed, flStand )

	if LevelOfDetail( pSchedule, "flNextCheck" ) then
		local f = MyTable.flPathTolerance
		if self:GetPos():DistToSqr( vCover ) > ( f * f ) then
			MyTable.vCover = nil
			MyTable.tCover = nil
			MyTable.SetSchedule( self, MyTable.CanExpose( self, MyTable ) && "FreeMovementStand" || "TakeCover", MyTable )
			return
		end

		if !MyTable.IsValidCoverCandidate( self, tCover, pEnemyPath, MyTable ) || !MyTable.IsValidCoverPoint( self, vCover, tCover, pEnemy, pEnemyPath, MyTable ) then
			MyTable.vCover = nil
			MyTable.tCover = nil
			MyTable.SetSchedule( self, MyTable.CanExpose( self, MyTable ) && "FreeMovementStand" || "TakeCover", MyTable )
			return
		end
	end

	MyTable.vActualCover = vCover

	if MyTable.GAME_flSuppression > self:Health() then
		flNextPeek = CurTime() + Rand( 0, 2 )
		pSchedule.flNextPeek = flNextPeek
		return
	end

	local flNextPeek = pSchedule.flNextPeek
	if !flNextPeek then
		flNextPeek = CurTime() + Rand( 0, 2 )
		pSchedule.flNextPeek = flNextPeek
	end

	if CurTime() >= flNextPeek && LevelOfDetail( pSchedule, "flNextPeekCheck" ) then
		pSchedule.flNextPeek = CurTime() + Rand( 0, 2 )
		local vStanding = Vector( vCover )
		vStanding[ 3 ] = vStanding[ 3 ] + MyTable.vViewOffset[ 3 ]
	
		pEnemyPath:MoveCursorToClosestPosition( vCover )
		local flCursor = pEnemyPath:GetCursorPosition()
		local dTowards = pEnemyPath:GetPositionOnPath( flCursor )
		pEnemyPath:MoveCursor( Lerp( PATH_STABILIZER, flCursor, pEnemyPath:GetLength() ) )
		dTowards = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - vCover
		dTowards[ 3 ] = 0
		dTowards:Normalize()
	
		if dTowards:IsZero() then
			dTowards = pEnemy:GetPos() - vCover
			dTowards[ 3 ] = 0
			dTowards:Normalize()
		end

		local vEnemy = pEnemy:GetPos()
		vEnemy:Add( pEnemy:OBBCenter() )

		local bCrouchCover = !util_TraceLine( {
			start = vStanding,
			endpos = vStanding + dTowards * MyTable.vHullMaxs[ 1 ] * COVER_BOUND_SIZE,
			mask = MASK_SHOT_HULL,
			filter = self
		} ).Hit

		local tOptions, iOptions = {}, 0

		local dDirection = ( tCover.vEnd - tCover.vStart ):GetNormalized()

		local vLateralOffset = ( tCover.vEnd - tCover.vStart ):Angle():Right()
		if !tCover.bRight then vLateralOffset:Negate() end
		vLateralOffset:Mul( MyTable.vHullMaxs[ 1 ] )

		local vDuckOffset = Vector( 0, 0, MyTable.vViewOffsetDucked[ 3 ] )

		local vStart = tCover.vStart - dDirection * MyTable.vHullMaxs[ 2 ] * 1.25 + vLateralOffset

		local bCheckedStart, bCheckedEnd
		local bStartResults, bEndResults = true, true

		local flTakenDistSqr = self:BoundingRadius()
		flTakenDistSqr = flTakenDistSqr * flTakenDistSqr

		if !util_TraceLine( {
			start = vCover + vDuckOffset,
			endpos = vStart,
			mask = MASK_SHOT_HULL,
			filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
		} ).Hit && !util_TraceLine( {
			start = vStart + vDuckOffset,
			endpos = vEnemy,
			mask = MASK_SHOT_HULL,
			filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
		} ).Hit && vCover:DistToSqr( vStart ) <= MyTable.GetMaxLateralPeekDistSqr( self, MyTable ) then
			if !bCheckedStart then
				local tAllies = MyTable.GetAlliesByClass( self, MyTable ) || {}
				for pAlly in pairs( tAllies ) do
					if self == pAlly then continue end
					if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vStart ) <= flTakenDistSqr || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vStart ) <= flTakenDistSqr then bStartResults = nil break end
				end
				bCheckedStart = true
			end

			if bStartResults then
				table.insert( tOptions, "STARTD" )
				iOptions = iOptions + 1
			end
		end

		local vEnd = tCover.vEnd + dDirection * MyTable.vHullMaxs[ 2 ] * 1.25 + vLateralOffset

		if !util_TraceLine( {
			start = vCover + vDuckOffset,
			endpos = vEnd,
			mask = MASK_SHOT_HULL,
			filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
		} ).Hit && !util_TraceLine( {
			start = vEnd + vDuckOffset,
			endpos = vEnemy,
			mask = MASK_SHOT_HULL,
			filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
		} ).Hit && vCover:DistToSqr( vEnd ) <= MyTable.GetMaxLateralPeekDistSqr( self, MyTable ) then
			if !bCheckedEnd then
				local tAllies = MyTable.GetAlliesByClass( self, MyTable ) || {}
				for pAlly in pairs( tAllies ) do
					if self == pAlly then continue end
					if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vEnd ) <= flTakenDistSqr || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vEnd ) <= flTakenDistSqr then bEndResults = nil break end
				end
				bCheckedEnd = true
			end

			if bEndResults then
				table.insert( tOptions, "ENDD" )
				iOptions = iOptions + 1
			end
		end

		if !util_TraceLine( {
			start = vCover + vStanding,
			endpos = vStart,
			mask = MASK_SHOT_HULL,
			filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
		} ).Hit && !util_TraceLine( {
			start = vStart + vStanding,
			endpos = vEnemy,
			mask = MASK_SHOT_HULL,
			filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
		} ).Hit && vCover:DistToSqr( vStart ) <= MyTable.GetMaxLateralPeekDistSqr( self, MyTable ) then
			if !bCheckedStart then
				local tAllies = MyTable.GetAlliesByClass( self, MyTable ) || {}
				for pAlly in pairs( tAllies ) do
					if self == pAlly then continue end
					if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vStart ) <= flTakenDistSqr || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vStart ) <= flTakenDistSqr then bStartResults = nil break end
				end
				bCheckedStart = true
			end

			if bStartResults then
				table.insert( tOptions, "START" )
				iOptions = iOptions + 1
			end
		end

		if !util_TraceLine( {
			start = vCover + vStanding,
			endpos = vEnd,
			mask = MASK_SHOT_HULL,
			filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
		} ).Hit && !util_TraceLine( {
			start = vEnd + vStanding,
			endpos = vEnemy,
			mask = MASK_SHOT_HULL,
			filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
		} ).Hit && vCover:DistToSqr( vEnd ) <= MyTable.GetMaxLateralPeekDistSqr( self, MyTable ) then
			if !bCheckedEnd then
				local tAllies = MyTable.GetAlliesByClass( self, MyTable ) || {}
				for pAlly in pairs( tAllies ) do
					if self == pAlly then continue end
					if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vEnd ) <= flTakenDistSqr || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vEnd ) <= flTakenDistSqr then bEndResults = nil break end
				end
				bCheckedEnd = true
			end

			if bEndResults then
				table.insert( tOptions, "END" )
				iOptions = iOptions + 1
			end
		end

		if bCrouchCover then
			if !util_TraceLine( {
				start = vStanding,
				endpos = vEnemy,
				mask = MASK_SHOT_HULL,
				filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
			} ).Hit then
				table.insert( tOptions, "UP" )
				iOptions = iOptions + 1
			end
		end

		if iOptions > 0 then
			local sPeek = tOptions[ random( 1, iOptions ) ]
			if sPeek == "UP" then
				local pPeek = MyTable.SetSchedule( self, "PeekIn", MyTable )
				pPeek.bVertical = true
				pPeek.bAtThem = true
				pPeek.vSuppress = vEnemy

			elseif sPeek == "START" then
				local pPeek = MyTable.SetSchedule( self, "PeekIn", MyTable )
				pPeek.bAtThem = true
				pPeek.vPeek = vStart
				pPeek.vSuppress = vEnemy
			elseif sPeek == "END" then
				local pPeek = MyTable.SetSchedule( self, "PeekIn", MyTable )
				pPeek.bAtThem = true
				pPeek.vPeek = vEnd
				pPeek.vSuppress = vEnemy

			elseif sPeek == "STARTD" then
				local pPeek = MyTable.SetSchedule( self, "PeekIn", MyTable )
				pPeek.bAtThem = true
				pPeek.bDuck = true
				pPeek.vPeek = vStart
				pPeek.vSuppress = vEnemy
			elseif sPeek == "ENDD" then
				local pPeek = MyTable.SetSchedule( self, "PeekIn", MyTable )
				pPeek.bAtThem = true
				pPeek.bDuck = true
				pPeek.vPeek = vEnd
				pPeek.vSuppress = vEnemy
			end
		end
	end
end } )
