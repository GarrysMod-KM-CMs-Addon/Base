ENT.flPathTolerance = 32

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetPos = CEntity.GetPos

local math = math
local math_Remap = math.Remap
local math_Clamp = math.Clamp
local math_max = math.max
local math_min = math.min
local math_Round = math.Round

local Format = Format
local IsValid = IsValid
local sv_gravity = GetConVar "sv_gravity"
local util_TraceLine = util.TraceLine

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

// Tries to jump to vTarget
function ENT:Jump( vTarget, bJumpGap, MyTable )
	local flGravity = sv_gravity:GetFloat()

	local pLocomotion = self.loco
	local vVelocity = pLocomotion:GetVelocity()
	local flJumpHeight = pLocomotion:GetJumpHeight()

	local vStart = self:GetPos()
	local vMiddle = LerpVector( .5, vStart, vTarget )
	local flZ = vStart[ 3 ]
	local vJump = Vector( 0, 0, flJumpHeight )

	local flTargetHeight = math_min( flJumpHeight, util_TraceLine( {
		start = vStart,
		endpos = vStart + vJump,
		mask = MASK_SOLID,
		filter = self
	} ).HitPos[ 3 ] - flZ, util_TraceLine( {
		start = vMiddle,
		endpos = vMiddle + vJump,
		mask = MASK_SOLID,
		filter = self
	} ).HitPos[ 3 ] - flZ, util_TraceLine( {
		start = vTarget,
		endpos = vTarget + vJump,
		mask = MASK_SOLID,
		filter = self
	} ).HitPos[ 3 ] - flZ )

	local flDelta = math.abs( vTarget[ 1 ] - vStart[ 1 ] )
	if flDelta > flTargetHeight then return end

	local flJumpLength = vVelocity:Length() * ( 2 * flGravity * flJumpHeight ) ^ .5 / flGravity
	if vStart:Distance2D( vTarget ) > flJumpLength then return end

	pLocomotion:SetJumpHeight( math_Clamp( math.abs( vTarget[ 3 ] - flZ ) * 2, 0, flJumpHeight ) )
	pLocomotion:JumpAcrossGap( vTarget, self:GetForward() )
	pLocomotion:SetJumpHeight( flJumpHeight )

	self.m_flJumpStartTime = CurTime()
	self.m_bJumping = true
end

ENT.flNavigationAvoidTime = 0
function ENT:HandleJumpingAlongPath( pPath, flSpeed, tFilter )
	local pLocomotion = self.loco

	pLocomotion:SetStepHeight( self.vHullMaxs[ 1 ] * .25 )

	if !self:IsOnGround() then
		// Air acceleration, maybe? I'm too lazy to find out how sv_airaccelerate works
		return
	end

	local pGoal, tNextGoal = pPath:GetCurrentGoal(), pPath:NextSegment()
	if pGoal && tNextGoal then
		if pGoal.type == 2 || pGoal.type == 3 then
			self:Jump( tNextGoal.pos )
			pPath:Update( self )
			return
		end
	end

	if CurTime() <= self.flNavigationAvoidTime then
		pLocomotion:Approach( self:GetPos() + self.vNavigationAvoidDirection, 1 )
		return
	end

	if !pGoal then pPath:Update( self ) return end

	local aVelocity = pGoal.forward:Angle()

	tFilter = tFilter || { self }

	local trHull = util.TraceHull {
		start = self:GetPos(),
		endpos = self:GetPos() + aVelocity:Forward() * self:OBBMaxs()[ 1 ],
		mins = self:OBBMins() + Vector( 0, 0, 12 ),
		maxs = self:OBBMaxs(),
		filter = tFilter
	}

	if trHull.Hit && !trHull.HitWorld then
		local trLeft, trRight = util.TraceHull {
			start = self:GetPos(),
			endpos = self:GetPos() - aVelocity:Right() * self:OBBMaxs()[ 1 ],
			mins = self:OBBMins() + Vector( 0, 0, 12 ),
			maxs = self:OBBMaxs(),
			filter = self
		}, util.TraceHull {
			start = self:GetPos(),
			endpos = self:GetPos() + aVelocity:Right() * self:OBBMaxs()[ 1 ],
			mins = self:OBBMins() + Vector( 0, 0, 12 ),
			maxs = self:OBBMaxs(),
			filter = self
		}

		local bLeft, bRight = trLeft.Hit && !trLeft.HitWorld, trRight.Hit && !trRight.HitWorld
		if bLeft && bRight then
			if math.random( 2 ) == 1 then
				self.vNavigationAvoidDirection = -aVelocity:Right()
			else
				self.vNavigationAvoidDirection = aVelocity:Right()
			end
			self.flNavigationAvoidTime = CurTime() + math.random()
			return
		elseif bLeft then
			self.flNavigationAvoidTime = CurTime() + math.random()
			self.vNavigationAvoidDirection = -aVelocity:Right()
			return
		else
			self.flNavigationAvoidTime = CurTime() + math.random()
			self.vNavigationAvoidDirection = aVelocity:Right()
			return
		end
	end

	pPath:Update( self )
end

function ENT:HandleStuck() self.loco:ClearStuck() end
