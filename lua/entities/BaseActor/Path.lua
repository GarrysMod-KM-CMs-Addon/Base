ENT.flPathTolerance = 32

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetPos = CEntity.GetPos

local math = math
local math_Remap = math.Remap
local math_Clamp = math.Clamp
local math_max = math.max
local math_min = math.min

function ENT:DontRePath( pPath, vPos, vGoal, MyTable )
	pPath:MoveCursorToClosestPosition( vPos )
	local f = MyTable.flPathTolerance
	local flCursor = pPath:GetCursorPosition()
	if pPath:GetPositionOnPath( flCursor ):DistToSqr( vPos ) <= f * f then
		pPath:MoveCursorToClosestPosition( vGoal )
		f = math_max( MyTable.flPathTolerance, vPos:Distance( vGoal ) * .1 )
		if pPath:GetPositionOnPath( pPath:GetCursorPosition() ):DistToSqr( vGoal ) <= f * f then return true end
	end
end

function ENT:ComputePath( Path, vGoal, Weighter )
	local MyTable = CEntity_GetTable( self )
	local vPos = CEntity_GetPos( self )
	if MyTable.DontRePath( self, Path, vPos, vGoal, MyTable ) then return true end
	if Weighter then return Path, Path:Compute( self, vGoal, Weighter ) end
	local loco = MyTable.loco
	local bCantClimb = !( MyTable.bCanClimb || MyTable.bCanFly )
	local bDisAllowWater = !MyTable.bCanSwim
	local flDeathDropNeg = -loco:GetDeathDropHeight()
	local flStepHeight = loco:GetStepHeight()
	local flJumpHeight
	if bCantClimb then flJumpHeight = loco:GetMaxJumpHeight() end
	local IsAreaTraversable = loco.IsAreaTraversable
	return Path, Path:Compute( self, vGoal, function( area, from, ladder, elevator, length )
		if !IsValid( from ) then return 0 end
		if !IsAreaTraversable( loco, area ) || bDisAllowWater && area:IsUnderwater() then return -1 end
		local dist = 0
		if IsValid( ladder ) then
			dist = ladder:GetLength()
		elseif length > 0 then
			dist = length
		else
			dist = ( area:GetCenter() - from:GetCenter() ):GetLength()
		end
		local cost = dist + from:GetCostSoFar()
		local d = from:ComputeAdjacentConnectionHeightChange( area )
		if d >= flStepHeight then
			if bCantClimb && d >= flJumpHeight then return -1 end
			cost = cost + 1.5 * dist
		elseif d < flDeathDropNeg then return -1 end
		return cost
	end )
end

// How far do We have to move along the path to be able to suppress anyone? Can return `nil`

function ENT:FindPathBattleLine( Path, tEnemies, flTolerance )
	flTolerance = flTolerance || 256
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local flSuppressionTraceFraction = self.flSuppressionTraceFraction
	for I = 0, Path:GetLength(), flTolerance do
		local vec = Path:GetPositionOnPath( I )
		for enemy in pairs( tEnemies ) do
			if !IsValid( enemy ) then continue end
			local vShoot = enemy:GetPos() + enemy:OBBCenter()
			local tr = util.TraceLine {
				start = vec + vStand,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
			local tr = util.TraceLine {
				start = vec + vDuck,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
		end
	end
end

function ENT:FindPathBattleLineNoAllies( Path, tEnemies, flTolerance )
	flTolerance = flTolerance || 256
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local flSuppressionTraceFraction = self.flSuppressionTraceFraction
	for I = 0, Path:GetLength(), flTolerance do
		local vec = Path:GetPositionOnPath( I )
		for enemy in pairs( tEnemies ) do
			if !IsValid( enemy ) then continue end
			local vShoot = enemy:GetPos() + enemy:OBBCenter()
			local tr = util.TraceLine {
				start = vec + vStand,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
			local tr = util.TraceLine {
				start = vec + vDuck,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
		end
	end
end
function ENT:FindPathBattleLineNoAlliesToVector( Path, vShoot, flTolerance )
	flTolerance = flTolerance || 256
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local flSuppressionTraceFraction = self.flSuppressionTraceFraction
	for I = 0, Path:GetLength(), flTolerance do
		local vec = Path:GetPositionOnPath( I )
		local tr = util.TraceLine {
			start = vec + vStand,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
		local tr = util.TraceLine {
			start = vec + vDuck,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
	end
end

function ENT:FindPathStackUpLineInternal( Path, tEnemies, flTolerance )
end

function ENT:ShouldStackUp( Path, flTolerance )
	flTolerance = flTolerance || 192
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local flSuppressionTraceFraction = self.flSuppressionTraceFraction
	local N
	local pEnemy = self.Enemy
	if !IsValid( pEnemy ) then return end
	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )
	local vEnemy = pEnemy:GetPos() + pEnemy:OBBCenter()
	local tFilter = IsValid( pTrueEnemy ) && { self, pEnemy, pTrueEnemy } || { self, pEnemy }
	for I = 0, math_min( Path:GetLength(), flTolerance * 2.6 ), flTolerance do
		local vec = Path:GetPositionOnPath( I )
		local tr = util.TraceLine {
			start = vec + vStand,
			endpos = vEnemy,
			mask = MASK_SHOT_HULL,
			filter = tFilter
		}
		if tr.Fraction > flSuppressionTraceFraction then return N else N = I end
		if !vDuck then continue end
		local tr = util.TraceLine {
			start = vec + vDuck,
			endpos = vEnemy,
			mask = MASK_SHOT_HULL,
			filter = tFilter
		}
		if tr.Fraction > flSuppressionTraceFraction then return N else N = I end
	end
	return N
end

function ENT:FindPathStackUpLine( pPath, tEnemies, flTolerance )
	flTolerance = flTolerance || 192
	local N = self:FindPathStackUpLineInternal( pPath, tEnemies, flTolerance )
	if N && N <= flTolerance * 2.6 then return end
	return N
end

local bit_band = bit.band
function ENT:ComputeVehiclePath( Path, vGoal )
	local MyTable = CEntity_GetTable( self )
	local f = MyTable.flPathTolerance
	f = f * f
	local veh = MyTable.GAME_pVehicle
	Path:MoveCursorToClosestPosition( veh:GetPos() )
	if Path:GetPositionOnPath( Path:GetCursorPosition() ):Distance2DSqr( veh:GetPos() ) <= f && Path:GetEnd():DistToSqr( vGoal ) <= f then return true end
	local loco = MyTable.loco
	local flStepHeight = loco:GetStepHeight()
	local VehTable = CEntity_GetTable( veh )
	local t = veh.TRAVERSES
	local bDoCheck, bDisAllowWater, bDisAllowGround, bAllowWater = true
	if bit_band( t, TRAVERSES_AIR ) == 0 then
		bDisAllowWater, bDisAllowGround = bit_band( t, TRAVERSES_WATER ) == 0, bit_band( t, TRAVERSES_GROUND ) == 0
		bAllowWater = !bDisAllowWater
	else bDoCheck = nil end
	local flStepHeightNeg
	if bAllowWater then flStepHeightNeg = veh:BoundingRadius() end
	local IsAreaTraversable = loco.IsAreaTraversable
	return Path, Path:Compute( self, vGoal, function( area, from, ladder, elevator, length )
		if !IsValid( fromArea ) then return 0 end
		if !IsAreaTraversable( loco, area ) then return -1 end
		local bUnderwater
		if bDoCheck then
			bUnderwater = area:IsUnderwater()
			if bUnderwater then if bDisAllowWater then return -1 end
			elseif bDisAllowGround then return -1 end
		end
		local dist = 0
		if IsValid( ladder ) then
			dist = ladder:GetLength()
		elseif length > 0 then
			dist = length
		else
			dist = ( area:GetCenter() - from:GetCenter() ):GetLength()
		end
		local cost = dist + from:GetCostSoFar()
		local d = from:ComputeAdjacentConnectionHeightChange( area )
		if ( bDoCheck && bAllowWater && bUnderwater && from:IsUnderwater() || !bDoCheck ) && ( d > flStepHeight ||
		// Don't jump down into water as it usually results in the boat getting flipped over
		bAllowWater && area:IsUnderwater() && d < flStepHeightNeg ) then return -1 end
		return cost
	end )
end

// Done really roughly and needs to be improved... but whatever
local ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE = 256

__ACTOR_FLANK_PATHS__ = __ACTOR_FLANK_PATHS__ || {}
local __ACTOR_FLANK_PATHS_LOCAL__ = __ACTOR_FLANK_PATHS__

hook.Add( "Think", "ActorFlankPath", function()
	local tNew = {}
	for iClass, tPartition in pairs( __ACTOR_FLANK_PATHS_LOCAL__ ) do
		for sPartition, tActorToTable in pairs( tPartition ) do
			for pActor, tData in pairs( tActorToTable ) do
				if !IsValid( pActor ) then continue end
				local v = tNew[ iClass ]
				if v then
					local n = v[ sPartition ]
					if n then
						n[ pActor ] = tData
					else
						v[ sPartition ] = { [ pActor ] = tData }
					end
				else tNew[ iClass ] = { [ sPartition ] = { [ pActor ] = tData } } end
			end
		end
	end
	__ACTOR_FLANK_PATHS__, __ACTOR_FLANK_PATHS_LOCAL__ = tNew, tNew
end )

local math_Round = math.Round

local Format = Format

local IsValid = IsValid

function ENT:ComputeFlankPath( Path, pEnemy )
	local MyTable = CEntity_GetTable( self )
	local vPos = CEntity_GetPos( self )
	local vGoal = CEntity_GetPos( pEnemy )
	if MyTable.DontRePath( self, Path, vPos, vGoal, MyTable ) then return true end
	local tPath, tAlready = {}, {}
	local iClass = self:Classify()
	local iX = math_Round( vGoal[ 1 ] / ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE ) * ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE
	local iY = math_Round( vGoal[ 2 ] / ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE ) * ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE
	local iZ = math_Round( vGoal[ 3 ] / ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE ) * ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE
	local sPartition = tostring( iX ):gsub( "(%d)0+$", "%1" ):gsub( "%.$", "" ) .. "," .. tostring( iY ):gsub( "(%d)0+$", "%1" ):gsub( "%.$", "" ) .. "," .. tostring( iZ ):gsub( "(%d)0+$", "%1" ):gsub( "%.$", "" )
	local iAlliesPathingTotal = 0
	local v = __ACTOR_FLANK_PATHS_LOCAL__[ iClass ]
	if v then
		local n = v[ sPartition ]
		if n then
			for ent, t in pairs( n ) do
				if !IsValid( ent ) || ent == self then continue end
				iAlliesPathingTotal = iAlliesPathingTotal + 1
				for area in pairs( t ) do
					local v = area:GetID()
					local i = tAlready[ v ]
					tAlready[ v ] = i && ( i + 1 ) || 2
				end
			end
			n[ self ] = tPath
		else v[ sPartition ] = { [ self ] = tPath } end
	else __ACTOR_FLANK_PATHS_LOCAL__[ iClass ] = { [ sPartition ] = { [ self ] = tPath } } end
	local loco = MyTable.loco
	local bCantClimb = !( MyTable.bCanClimb || MyTable.bCanFly )
	local bDisAllowWater = !MyTable.bCanSwim
	local flDeathDropNeg = -loco:GetDeathDropHeight()
	local flStepHeight = loco:GetStepHeight()
	local flJumpHeight
	if bCantClimb then flJumpHeight = loco:GetMaxJumpHeight() end
	local IsAreaTraversable = loco.IsAreaTraversable
	local bStatus = Path:Compute( self, vGoal, function( area, from, ladder, elevator, length )
		if !IsValid( from ) then return 0 end
		if !IsAreaTraversable( loco, area ) || bDisAllowWater && area:IsUnderwater() then return -1 end
		local dist = 0
		if IsValid( ladder ) then
			dist = ladder:GetLength()
		elseif length > 0 then
			dist = length
		else
			dist = ( area:GetCenter() - from:GetCenter() ):GetLength()
		end
		local cost = dist + from:GetCostSoFar()
		local d = from:ComputeAdjacentConnectionHeightChange( area )
		if d >= flStepHeight then
			if bCantClimb && d >= flJumpHeight then return -1 end
			cost = cost + 1.5 * dist
		elseif d < flDeathDropNeg then return -1 end
		return cost + ( math_max( 1, tAlready[ area:GetID() ] || 1 ) * 262144 )
	end )
	for _, seg in ipairs( Path:GetAllSegments() || {} ) do tPath[ seg.area ] = true end
	return Path, bStatus
end

local sv_gravity = GetConVar "sv_gravity"

local util_TraceLine = util.TraceLine
local math_min = math.min

// Tries to jump to vTarget
function ENT:Jump( vTarget )
	local flGravity = sv_gravity:GetFloat()
	local vVelocity = self.loco:GetVelocity()
	local flOriginal = self.loco:GetJumpHeight() // NOT flJumpHeight!!!
	if vVelocity:LengthSqr() < self.flWalkSpeed * .5 then vVelocity = ( vTarget - self:GetPos() ):GetNormalized() * flOriginal end
	local vStart = self:GetPos()
	local vMiddle = LerpVector( .5, vStart, vTarget )
	local flZ = vStart.z
	local flJumpHeight = flOriginal * math_min( util_TraceLine( {
		start = vStart,
		endpos = vStart + Vector( 0, 0, flOriginal ),
		mask = MASK_SOLID,
		filter = self
	} ).HitPos.z - flZ, util_TraceLine( {
		start = vMiddle,
		endpos = vMiddle + Vector( 0, 0, flOriginal ),
		mask = MASK_SOLID,
		filter = self
	} ).HitPos.z - flZ, util_TraceLine( {
		start = vTarget,
		endpos = vTarget + Vector( 0, 0, flOriginal ),
		mask = MASK_SOLID,
		filter = self
	} ).HitPos.z - flZ )
	local flJumpLength = vVelocity:Length() * ( 2 * flGravity * flJumpHeight ) ^ .5 / flGravity
	local dVelocityFlat = Vector( vVelocity )
	dVelocityFlat.z = 0
	dVelocityFlat:Normalize()
	local dTargetFlat = vTarget - self:GetPos()
	dTargetFlat.z = 0
	dTargetFlat:Normalize()
	local flFlatDistance = vStart:Distance2D( vTarget )
	local flDifference = ( 1 - math_max( 0, dVelocityFlat:Dot( dTargetFlat ) ) ) * flFlatDistance
	if flDifference > ( self.flPathTolerance * .5 ) then return end
	if self:GetPos():DistToSqr( vTarget ) > ( flJumpLength * flJumpLength ) then return end
	self.loco:SetJumpHeight( math_Clamp( vTarget.z - vStart.z + ( ( ( flFlatDistance + self:OBBMaxs().x ) / vVelocity:Length() ) * .5 * flGravity ) ^ 2 / ( 2 * flGravity ), 0, flOriginal ) )
	self.loco:Jump()
	self.loco:SetJumpHeight( flOriginal )
	self.m_flJumpStartTime = CurTime()
	self.m_bJumping = true
end

ENT.flNextAvoidDirection = 0
function ENT:HandleJumpingAlongPath( Path, flSpeed, tFilter )
	self.loco:SetStepHeight( 16 )
	if !self:IsOnGround() then
		// Air acceleration, maybe? I'm too lazy to find out how sv_airaccelerate works
		return
	end
	local goal, tNextGoal = Path:GetCurrentGoal(), Path:NextSegment()
	if goal && tNextGoal then
		self.loco:Approach( goal.pos, 1 )
		if goal.type == 2 || goal.type == 3 then
			Path:Update( self )
			self:Jump( tNextGoal.pos )
			return
		end
	end
	local vMins, vMaxs = self:OBBMins(), self:OBBMaxs()
	vMins[ 3 ] = self.loco:GetStepHeight()
	vMins[ 1 ] = vMins[ 1 ] * 1.25
	vMaxs[ 1 ] = vMaxs[ 1 ] * 1.25
	vMins[ 2 ] = vMins[ 2 ] * 1.25
	vMaxs[ 2 ] = vMaxs[ 2 ] * 1.25
	if CurTime() <= self.flNextAvoidDirection then
		local dDirection = self.dAvoid
		local vOffset = dDirection * ( vMaxs[ 2 ] - vMins[ 2 ] )
		local tr = util.TraceLine {
			start = self:GetPos() + self:OBBCenter(),
			endpos = self:GetPos() + self:OBBCenter() + vOffset,
			mask = MASK_SOLID,
			filter = self
		}
		if tr.Hit then self.flNextAvoidDirection = -1 return end
		self.loco:Approach( self:GetPos() + dDirection * 4096, 1 )
		return
	end
	if !goal then return end
	local v = Angle( goal.pos - self:GetPos() )
	local tr = util.TraceHull {
		start = self:GetPos(),
		endpos = self:GetPos() + v:Forward() * vMaxs[ 1 ],
		mins = vMins,
		maxs = vMaxs,
		filter = self
	}
	if tr.Hit then
		if ( goal.pos - self:GetPos() ):Angle():Right():Dot( goal.forward:Angle():Right() ) <= 0 then
			self.bAvoidRight = nil
		else self.bAvoidRight = true end
		self.dAvoid = self.bAvoidRight && self:GetRight() || -self:GetRight()
		self.flNextAvoidDirection = CurTime() + vMaxs[ 2 ] / flSpeed * math.Rand( 3, 4 )
	else Path:Update( self ) end
end

function ENT:HandleStuck() self.loco:ClearStuck() end
