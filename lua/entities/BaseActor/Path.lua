ENT.flPathTolerance = 32

ENT.flJumpHeight = 0

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetPos = CEntity.GetPos

local math_Remap = math.Remap
local math_Clamp = math.Clamp
local math_max = math.max
local math_min = math.min
local math_Round = math.Round

local Format = Format
local IsValid = IsValid
local util_TraceLine = util.TraceLine

// TODO: Somehow, clean up MyTable.m_pPathData? Maybe?
// I wanted to make it global, but that'd be even more leaky. At least entities are removed. Sometimes.

function ENT:DontRepath( pPath, vPos, vGoal, MyTable, bChase, flToleranceOverride )
	if !pPath:IsValid() then return end

	local pPathData = MyTable.m_pPathData
	if !pPathData then
		pPathData = {}
		MyTable.m_pPathData = pPathData
	end

	local pData = pPathData[ pPath ]
	if !pData then
		pData = {}
		pPathData[ pPath ] = pData
	end

	local vIntendedGoal = pData.vIntendedGoal

	local f = flToleranceOverride || math_max( MyTable.flPathTolerance, bChase && ( vPos:Distance( vGoal ) * .5 ) || ( vPos:Distance( vGoal ) * .1 ) )
	if ( vIntendedGoal || pPath:GetEnd() ):DistToSqr( vGoal ) <= f * f then return true end
end

function ENT:ComputePath( pPath, vGoal, fWeighter, flToleranceOverride )
	local MyTable = CEntity_GetTable( self )
	local vPos = CEntity_GetPos( self )

	local pPathData = MyTable.m_pPathData
	if !pPathData then
		pPathData = {}
		MyTable.m_pPathData = pPathData
	end

	local pData = pPathData[ pPath ]
	if !pData then
		pData = {}
		pPathData[ pPath ] = pData
	end

	if MyTable.DontRepath( self, pPath, vPos, vGoal, MyTable, nil, flToleranceOverride ) then return true end

	local bSuccess = pPath:Compute( self, vGoal, fWeighter )

	pData.vIntendedGoal = vGoal

	return pPath, bSuccess
end

function ENT:ManageFlankPath( pPath, pEnemy, pSchedule, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )

	local pPathData = MyTable.m_pPathData
	if !pPathData then
		pPathData = {}
		MyTable.m_pPathData = pPathData
	end

	local pData = pPathData[ pPath ]
	if !pData then
		pData = {}
		pPathData[ pPath ] = pData
	end

	pData.flThreadTime = CurTime() + 1

	if pData.bStartedThread then return end

	if !LevelOfDetail( pSchedule, "flNextFlankPath", .25 ) then return end

	local vPos = CEntity_GetPos( self )
	local vGoal = CEntity_GetPos( pEnemy )

	if MyTable.DontRepath( self, pPath, vPos, vGoal, MyTable, true ) then
		pData.bStartedThread = nil
		return
	end

	pData.bStartedThread = true

	ACTOR_QUEUE_PATH( function()
		if !IsValid( self ) || !IsValid( pEnemy ) || self.Schedule != pSchedule || CurTime() > pData.flThreadTime then
			pData.bStartedThread = nil
			return true
		end

		local flWait = CurTime() + math.min( 1, ( self:GetPos():Distance( pEnemy:GetPos() ) / 16384 ) ^ 3 )
		while CurTime() <= flWait do
			if !IsValid( self ) || !IsValid( pEnemy ) || self.Schedule != pSchedule || CurTime() > pData.flThreadTime then
				pData.bStartedThread = nil
				return true
			end
			coroutine.yield()
		end

		if !IsValid( self ) || !IsValid( pEnemy ) || self.Schedule != pSchedule || CurTime() > pData.flThreadTime then
			pData.bStartedThread = nil
			return true
		end

		local vPos = CEntity_GetPos( self )
		local vGoal = CEntity_GetPos( pEnemy )

		if MyTable.DontRepath( self, pPath, vPos, vGoal, MyTable, true ) then pData.bStartedThread = nil return true end

		MyTable.ComputePath( self, pPath, vGoal )

		local flWait = CurTime() + math.min( 1, ( pPath:GetLength() / 16384 ) ^ 3 )
		while CurTime() <= flWait do
			if !IsValid( self ) || !IsValid( pEnemy ) || self.Schedule != pSchedule || CurTime() > pData.flThreadTime then
				pData.bStartedThread = nil
				return true
			end
			coroutine.yield()
		end

		pData.bStartedThread = nil
		return true
	end )
end

function ENT:ManageFlankPathLockThisCoroutine( pPath, pEnemy, pSchedule, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )

	local pPathData = MyTable.m_pPathData
	if !pPathData then
		pPathData = {}
		MyTable.m_pPathData = pPathData
	end

	local pData = pPathData[ pPath ]
	if !pData then
		pData = {}
		pPathData[ pPath ] = pData
	end

	pData.flThreadTime = CurTime() + 1

	local vPos = CEntity_GetPos( self )
	local vGoal = CEntity_GetPos( pEnemy )

	if MyTable.DontRepath( self, pPath, vPos, vGoal, MyTable, true ) then
		return
	end

	if !IsValid( self ) || !IsValid( pEnemy ) || MyTable.Schedule != pSchedule then
		return true
	end

	local flWait = CurTime() + math.min( 1, ( self:GetPos():Distance( pEnemy:GetPos() ) / 16384 ) ^ 3 )
	while CurTime() <= flWait do
		if !IsValid( self ) || !IsValid( pEnemy ) || self.Schedule != pSchedule then
			return true
		end
		coroutine.yield()
	end

	if !IsValid( self ) || !IsValid( pEnemy ) || MyTable.Schedule != pSchedule then
		return true
	end

	if MyTable.DontRepath( self, pPath, vPos, vGoal, MyTable, true ) then return end

	MyTable.ComputePath( self, pPath, vGoal )

	local flWait = CurTime() + math.min( 1, ( pPath:GetLength() / 16384 ) ^ 3 )
	while CurTime() <= flWait do
		if !IsValid( self ) || !IsValid( pEnemy ) || self.Schedule != pSchedule then
			return true
		end
		coroutine.yield()
	end
end

// This is for your custom functions. Why is it called Internal, then?
// Simple: this is a simple no argument function that plays regardless
// of our jump context, and is primarily meant to be for large things
// emitting sounds when they jump (for example, the IRVING)
function ENT:PostJumpInternal() end

// Tries to jump to vTarget
function ENT:Jump( vTarget, bJumpGap, MyTable )
	local vStart = self:GetPos()

	local vDirection = vTarget - vStart
	vDirection[ 3 ] = 0

	// Make sure we are
	// "IN HOT!"
	//  - Pequod
	local flMod = ( self:OBBMaxs()[ 1 ] - self:OBBMins()[ 1 ] ) * 1.5
	vTarget[ 3 ] = vTarget[ 3 ] + flMod
	vTarget:Add( vDirection:GetNormalized() * flMod )

	local pLocomotion = self.loco

	local vVelocity = pLocomotion:GetVelocity()
	local flJumpHeight = pLocomotion:GetJumpHeight()

	local vMiddle = LerpVector( .5, vStart, vTarget )
	local flZ = vStart[ 3 ]
	local flTargetZ = vTarget[ 3 ]
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
	} ).HitPos[ 3 ] - vMiddle[ 3 ], util_TraceLine( {
		start = vTarget,
		endpos = vTarget + vJump,
		mask = MASK_SOLID,
		filter = self
	} ).HitPos[ 3 ] - vTarget[ 3 ] )

	local flDelta = flTargetZ - flZ
	if flDelta > flTargetHeight then return end

	flMaxJumpHeight = flMaxJumpHeight || pLocomotion:GetJumpHeight()

	local flJumpHeight = math.min( flDelta, flTargetHeight )
	if flJumpHeight < 0 then flJumpHeight = -flJumpHeight * .5 end

	local flGravity = self:GetMyGravity()

	local flVelocityZ = math.sqrt( 2 * flGravity * flJumpHeight )

	local flTime = ( 2 * flVelocityZ ) / flGravity

	local vDirection = vTarget - vStart
	vDirection[ 3 ] = 0

	local vTravel = vDirection:GetNormalized()

	local vResult = vTravel * ( vDirection:Length() / flTime )
	vResult[ 3 ] = vResult[ 3 ] + flVelocityZ

	pLocomotion:SetJumpHeight( 1 )
	pLocomotion:Jump()
	pLocomotion:SetJumpHeight( flMaxJumpHeight )

	pLocomotion:SetVelocity( vResult )

	self:PostJumpInternal()

	self.m_flJumpStartTime = CurTime()
	self.m_bJumping = true
end

ENT.flDirectAvoidTime = 0
ENT.flNavigationAvoidTime = 0
ENT.flJumpedTime = 0

local function fEmpty() end

// TODO: Replace this so that we only update after reaching a goal and otherwise use Approach
local function fUpdatePath( self, pPath )
	pPath:Update( self )
end

function ENT:GroundMovement( pPath, flSpeed, tFilter, flToleranceOverride, bNoAvoid, fJump, fDrop )
	local pLocomotion = self.loco

	pPath:SetMinLookAheadDistance( self:OBBMaxs()[ 1 ] * 3 )

	pPath:SetGoalTolerance( flToleranceOverride || self:OBBMaxs()[ 1 ] )

	pLocomotion:SetStepHeight( self.vHullMaxs[ 3 ] * .25 )

	if !self:IsOnGround() then
		// Air acceleration, maybe? I'm too lazy to find out how sv_airaccelerate works
		return
	end

	if CurTime() <= self.flDirectAvoidTime then
		fUpdatePath( self, pPath )
		return
	end

	if CurTime() <= self.flNavigationAvoidTime then
		pLocomotion:Approach( self:GetPos() + self.vNavigationAvoidDirection, 1 )
		return
	end

	local pGoal = pPath:GetCurrentGoal()

	if !pGoal then
		fUpdatePath( self, pPath )
		return
	end

	if pGoal.type == 1 then
		if fDrop && fDrop( self, vNextGoalPos ) then return end
	end

	local pNextGoal = pPath:NextSegment()

	// Allows us to jump more aggressively instead of bumping
	// into walls and triggering avoidance, yet prevents
	// us from being stuck trying to repeatedly jump
	// somewhere that is unjumpable
	if CurTime() > self.flJumpedTime && pNextGoal then
		local vNextGoalPos = pNextGoal.pos
		local flVerticality = vNextGoalPos[ 3 ] - self:GetPos()[ 3 ]

		if pGoal.type == 2 || pGoal.type == 3 || flVerticality >= self.loco:GetStepHeight() && flVerticality > vNextGoalPos:Distance2D( self:GetPos() ) then
			self.flJumpedTime = CurTime() + math.random() * 2

			if fJump && fJump( self, vNextGoalPos ) then return end

			self:Jump( vNextGoalPos )
			fUpdatePath( self, pPath )
			return
		end
	end

	if bNoAvoid then
		fUpdatePath( self, pPath )
		return
	end

	local aVelocity = pGoal.forward:Angle()

	tFilter = tFilter || { self }

	local vMins, vMaxs = self:OBBMins(), self:OBBMaxs()

	vMins[ 3 ] = vMins[ 3 ] + 12

	local trHull = util.TraceHull {
		start = self:GetPos(),
		endpos = self:GetPos() + aVelocity:Forward() * self:OBBMaxs()[ 1 ],
		mins = vMins,
		maxs = vMaxs,
		filter = tFilter
	}

	// TODO: Perhaps add a better in-base version of measuring velocity
	// using current pos, last pos and m_flFrameTime
	local f = self.flWalkSpeed * .5
	if trHull.Hit && GetVelocity( self ):LengthSqr() <= f * f then
		local b
		if pNextGoal && ( pGoal.type == 2 || pGoal.type == 3 || ( pNextGoal.pos[ 3 ] - self:GetPos()[ 3 ] ) >= self.loco:GetStepHeight() ) then b = true end

		if math.random( 3 ) != 1 then
			if b then
				local iRand = math.random( 3 )
				if iRand == 1 then
					self.flDirectAvoidTime = CurTime() + math.random() * math.random() * 2
				else
					self:Jump( pNextGoal.pos )
					fUpdatePath( self, pPath )
				end
				return
			else
				if math.random( 2 ) == 1 then
					self.flDirectAvoidTime = CurTime() + math.random() * math.random() * 2
					return
				end
			end
		end

		local trLeft, trRight, trBack = util.TraceLine {
			start = self:GetPos() + self:OBBCenter(),
			endpos = self:GetPos() + self:OBBCenter() - aVelocity:Right() * self:OBBMaxs()[ 1 ],
			filter = self
		}, util.TraceLine {
			start = self:GetPos() + self:OBBCenter(),
			endpos = self:GetPos() + self:OBBCenter() + aVelocity:Right() * self:OBBMaxs()[ 1 ],
			filter = self
		}, util.TraceLine {
			start = self:GetPos() + self:OBBCenter(),
			endpos = self:GetPos() + self:OBBCenter() - aVelocity:Forward() * self:OBBMaxs()[ 1 ],
			filter = self
		}

		local bLeft, bRight = !trLeft.Hit, !trRight.Hit
		if trBack.Hit then
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
		else
			if bLeft && bRight then
				if math.random( 2 ) == 1 then
					if math.random( 2 ) == 1 then
						self.vNavigationAvoidDirection = -aVelocity:Right()
					else
						self.vNavigationAvoidDirection = aVelocity:Right()
					end
					self.flNavigationAvoidTime = CurTime() + math.random()
					return
				end
			elseif bLeft then
				if math.random( 2 ) == 1 then
					self.flNavigationAvoidTime = CurTime() + math.random()
					self.vNavigationAvoidDirection = -aVelocity:Right()
					return
				end
			elseif bRight then
				if math.random( 2 ) == 1 then
					self.flNavigationAvoidTime = CurTime() + math.random()
					self.vNavigationAvoidDirection = -aVelocity:Right()
					return
				end
			end

			self.flNavigationAvoidTime = CurTime() + math.random()
			self.vNavigationAvoidDirection = -( aVelocity:Forward() )
			return
		end
	end

	fUpdatePath( self, pPath )
end

function ENT:HandleStuck() self.loco:ClearStuck() end

// SHITTY BACKWARDS COMPATIBILITY FUNCTION! DO NOT USE!
// Because I am not in the mood for reworking EVERYTHING.

function ENT:ComputeFlankPath( pPath, pEnemy, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )

	local vPos = CEntity_GetPos( self )
	local vGoal = CEntity_GetPos( pEnemy )

	if MyTable.DontRepath( self, pPath, vPos, vGoal, MyTable, true ) then
		return true
	end

	MyTable.ComputePath( self, pPath, vGoal )
end

include "InterceptJump.lua"
