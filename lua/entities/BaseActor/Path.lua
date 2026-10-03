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

function ENT:DontRepath( pPath, vPos, vGoal, MyTable, bChase )
	local f = math_max( MyTable.flPathTolerance, bChase && ( vPos:Distance( vGoal ) * 1 / 3 ) || ( vPos:Distance( vGoal ) * .1 ) )
	if pPath:GetEnd():DistToSqr( vGoal ) <= f * f then return true end
end

function ENT:ComputePath( Path, vGoal, fWeighter )
	local MyTable = CEntity_GetTable( self )
	local vPos = CEntity_GetPos( self )
	if MyTable.DontRepath( self, Path, vPos, vGoal, MyTable ) then return true end
	if fWeighter then return Path, Path:Compute( self, vGoal, fWeighter ) end
	return Path, Path:Compute( self, vGoal )
end

function ENT:ManageFlankPath( pPath, pEnemy, pSchedule, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )

	local pPathData = pSchedule.m_pPathData
	if !pPathData then
		pPathData = {}
		pSchedule.m_pPathData = pPathData
	end

	local pData = pPathData[ pPath ]
	if !pData then
		pData = {}
		pPathData[ pPath ] = pData
	end

	pData.flThreadTime = CurTime() + 1

	if pData.bStartedThread then return end

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

		coroutine.wait( math.min( 2, self:GetPos():Distance( pEnemy:GetPos() ) / 8192 ) )

		if !IsValid( self ) || !IsValid( pEnemy ) || self.Schedule != pSchedule || CurTime() > pData.flThreadTime then
			pData.bStartedThread = nil
			return true
		end

		if MyTable.DontRepath( self, pPath, vPos, vGoal, MyTable, true ) then return end

		MyTable.ComputePath( self, pPath, vGoal )

		coroutine.wait( math.min( 2, pPath:GetLength() / 8192 ) )

		pData.bStartedThread = nil
		return true
	end )
end

function ENT:ManageFlankPathLockThisCoroutine( pPath, pEnemy, pSchedule, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )

	if !IsValid( self ) || !IsValid( pEnemy ) || MyTable.Schedule != pSchedule then
		return true
	end

	coroutine.wait( math.min( 3, self:GetPos():Distance( pEnemy:GetPos() ) / 8192 ) )

	if !IsValid( self ) || !IsValid( pEnemy ) || MyTable.Schedule != pSchedule then
		return true
	end

	local vPos = CEntity_GetPos( self )
	local vGoal = CEntity_GetPos( pEnemy )

	if MyTable.DontRepath( self, pPath, vPos, vGoal, MyTable, true ) then return end

	MyTable.ComputePath( self, pPath, vGoal )

	coroutine.wait( math.min( 3, pPath:GetLength() / 8192 ) )
end

// This is for your custom functions. Why is it called Internal, then?
// Simple: this is a simple no argument function that plays regardless
// of our jump context, and is primarily meant to be for large things
// emitting sounds when they jump (for example, the IRVING)
function ENT:PostJumpInternal() end

// Tries to jump to vTarget
function ENT:Jump( vTarget, bJumpGap, MyTable )
	vTarget[ 3 ] = vTarget[ 3 ] + 20

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

	pLocomotion:SetJumpHeight( math_Clamp( math.abs( vTarget[ 3 ] - flZ ) * 2, 0, flJumpHeight ) )
	pLocomotion:JumpAcrossGap( vTarget, self:GetForward() )
	pLocomotion:SetJumpHeight( flJumpHeight )

	self:PostJumpInternal()

	self.m_flJumpStartTime = CurTime()
	self.m_bJumping = true
end

local developer = GetConVar "developer"

ENT.flNavigationAvoidTime = 0
ENT.flJumpedTime = 0

function ENT:GrountMovement( pPath, flSpeed, tFilter, flToleranceOverride )
	local pLocomotion = self.loco

	if developer:GetBool() then pPath:Draw() end

	pPath:SetMinLookAheadDistance( self:OBBMaxs()[ 1 ] * 3 )

	pPath:SetGoalTolerance( flToleranceOverride || self:OBBMaxs()[ 1 ] )

	pLocomotion:SetStepHeight( self.vHullMaxs[ 3 ] * .25 )

	if !self:IsOnGround() then
		// Air acceleration, maybe? I'm too lazy to find out how sv_airaccelerate works
		return
	end

	if CurTime() <= self.flNavigationAvoidTime then
		pLocomotion:Approach( self:GetPos() + self.vNavigationAvoidDirection, 1 )
		return
	end

	local pGoal = pPath:GetCurrentGoal()

	if !pGoal then pPath:Update( self ) return end

	// Allows us to jump more aggressively instead of bumping
	// into walls and triggering avoidance, yet prevents
	// us from being stuck trying to repeatedly jump
	// somewhere that is unjumpable
	if CurTime() > self.flJumpedTime then
		local pNextGoal = pPath:NextSegment()
		if pNextGoal then
			if pGoal.type == 2 || pGoal.type == 3 then
				self:Jump( pNextGoal.pos )
				self.flJumpedTime = CurTime() + math.random()
				pPath:Update( self )
				return
			end
		end
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

	if trHull.Hit && GetVelocity( self ):Length() <= self.flWalkSpeed * .8 then
		local b
		if pNextGoal && ( pGoal.type == 2 || pGoal.type == 3 ) then b = true end

		if b then
			local iRand = math.random( 3 )
			if iRand == 1 then
				self:Jump( pNextGoal.pos )
				pPath:Update( self )
				return
			elseif iRand == 2 then
				self.vNavigationAvoidDirection = aVelocity:Forward()
				self.flNavigationAvoidTime = CurTime() + math.random()
				return
			end
		else
			if math.random( 2 ) == 1 then
				self.vNavigationAvoidDirection = aVelocity:Forward()
				self.flNavigationAvoidTime = CurTime() + math.random()
				return
			end
		end

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

		local bLeft, bRight = trLeft.Hit, trRight.Hit
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

// TODO: The funcs below should clamp the velocity so we can't move farther than flMaxJumpHeight * 3,
// plus the IsInterceptJumpLegal functions should calculate the real intercept position instead of
// just measuring the distance to the target itself.

// Why is this called Legal and not Can? Simple.
// Intercept jumps are cinematic, not physically correct,
// 'cause fuck it, the IRVING's ballin'.
// Thus, we are asking if it's KINDA fair to jump there
function ENT:IsInterceptJumpLegal( pTarget, flJumpHeight )
	if !self:IsOnGround() then return end

	flJumpHeight = flJumpHeight || self.flJumpHeight

	local f = ( flJumpHeight || self.loco:GetJumpHeight() ) * 3
	return self:GetPos():DistToSqr( pTarget:GetPos() + pTarget:OBBCenter() ) <= f * f && self:IsInterceptJumpLegalInternal( pTarget, flJumpHeight )
end

// Only jump if it will be a (relatively) smol jump
function ENT:IsInterceptJumpLegalShort( pTarget, flJumpHeight )
	if !self:IsOnGround() then return end

	flJumpHeight = flJumpHeight || self.flJumpHeight

	local f = ( flJumpHeight || self.loco:GetJumpHeight() ) * .5
	return self:GetPos():DistToSqr( pTarget:GetPos() + pTarget:OBBCenter() ) <= f * f && self:IsInterceptJumpLegalInternal( pTarget, flJumpHeight )
end

function ENT:IsInterceptJumpLegalInternal( pTarget, flJumpHeight )
	return self:Visible( pTarget )
end

function ENT:InterceptJump( pTarget, flDesiredJumpHeight, flMaxJumpHeight )
	if !self:IsOnGround() then return end

	local pLocomotion = self.loco

	local vPos = self:GetPos()
	local vTarget = pTarget:GetPos()

	flMaxJumpHeight = flMaxJumpHeight || pLocomotion:GetJumpHeight()

	local flJumpHeight = math_min(
		flDesiredJumpHeight ||
		math_max( flMaxJumpHeight * .01, ( vPos:Distance( vTarget + pTarget:OBBCenter() ) * ( math.random( 2 ) == 1 && ( 1 / 3 + ( math.random() * math.random() ) * 2 / 3 ) || math.Rand( .1, 2 ) ) ) ),
		flMaxJumpHeight )

	local flEnemyZ, flMyZ = vTarget[ 3 ], vPos[ 3 ]
	if flEnemyZ > flMyZ then flJumpHeight = flJumpHeight + flEnemyZ - flMyZ end

	local flGravity = self:GetMyGravity()

	local flVelocityZ = math.sqrt( 2 * flGravity * flJumpHeight )

	local flTime = ( 2 * flVelocityZ ) / flGravity

	local vIntercept = vTarget + GetVelocity( pTarget ) * flTime

	local vDirection = vIntercept - vPos
	vDirection[ 3 ] = 0

	local flDistance = vDirection:Length()
	local vTravel = vDirection:GetNormalized()
	
	local vResult = vTravel * ( flDistance / flTime )
	vResult[ 3 ] = vResult[ 3 ] + flVelocityZ

	pLocomotion:SetJumpHeight( 1 )
	pLocomotion:Jump()
	pLocomotion:SetJumpHeight( flMaxJumpHeight )

	self:PostJumpInternal()

	pLocomotion:SetVelocity( vResult )

	return vIntercept
end

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
