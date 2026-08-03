// TODO: This whole file is old, awful, and needs to be broken down into smaller files like I've done with FreeMovement!

local table_IsEmpty = table.IsEmpty
local HasRangeAttack, HasMeleeAttack = HasRangeAttack, HasMeleeAttack
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
local util_DistanceToLine = util.DistanceToLine
local random = math.random
local Rand = math.Rand
local unpack = unpack
local CurTime = CurTime

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

// ENT.bMeleeChargeAgainstRange = true // Far Cry 3 Pirate Beheader
// ENT.flMeleeChargeTauntMultiplier = 1

function ENT:DLG_MeleeTaunt() end

ENT.flMaintainFireTime = 0
ENT.flMaintainFireTimeMin = 2
ENT.flMaintainFireTimeMax = 6
ENT.flPathStabilizer = 16

function ENT:DLG_Charge() end

// Fixes a certain bug that I am too lazy to describe rn
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

	return ( tCover.bRight && ( vEnd - vStart ):Angle():Right() || -( vEnd - vStart ):Angle():Right() ):Dot( dTowards ) < 0
end

function ENT:IsValidCoverPoint( vCover, tCover, pEnemy, pEnemyPath, MyTable, vMaxs /* Optional as you may have precomputed them */ )
	vMaxs = vMaxs || MyTable.vHullDuckMaxs || MyTable.vHullMaxs
	local vCrouched = Vector( vCover )
	vCrouched[ 3 ] = vCrouched[ 3 ] + vMaxs[ 3 ]

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

RegisterSchedule( "Combat", { Execute = function( self, sched, MyTable )
	local tEnemies = sched.tEnemies || MyTable.tEnemies
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

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end

	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy ) end

	local bDuck

	if CurTime() > ( sched.flDuckTime || 0 ) then
		// Fun fact: humans are not fans of lactic acid buildup
		if random( 3 ) == 1 then bDuck = true sched.bDuck = true end

		bDuck = false
		sched.bDuck = nil

		sched.flDuckTime = CurTime() + Rand( 0, 4 )
	end

	if bDuck == nil then bDuck = sched.bDuck end

	local flStand = sched.flStand
	if bDuck then
		flStand = 0
		sched.flStand = 0
		// nil means wait before checking, -1 means check ASAP
		sched.flStandCheck = -1

		if LevelOfDetail( sched, "flNextTowardsCheck" ) then
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
		if !flStand || LevelOfDetail( sched, "flStandCheck" ) then
			flStand = 0

			LevelOfDetail( sched, "flNextTowardsCheck" )
	
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
	
			if util_TraceLine( {
				start = vStanding,
				endpos = vStanding + dTowards * vMaxs[ 1 ] * COVER_BOUND_SIZE,
				mask = MASK_SHOT_HULL,
				filter = self
			} ).Hit then flStand = 1 end
		end
	end

	local pPath = sched.pPath
	if !pPath then pPath = Path "Follow" sched.pPath = pPath end

	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputePath( self, pPath, vCover ) end

	MyTable.MoveAlongPath( self, pPath, MyTable.flWalkSpeed, flStand )

	if LevelOfDetail( sched, "flNextCheck" ) then
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
end } )

include "CombatStuff.lua"
