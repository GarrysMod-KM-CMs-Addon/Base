local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local CurTime = CurTime
local math_abs = math.abs
local coroutine_yield = coroutine.yield

local function fEmpty() end

local min = math.min
local exp = math.exp

local function FRILerpRate( flRate, flFrameTime ) return min( 1, 1 - exp( -flRate * flFrameTime ) ) end

// You might want to call AnimationSystemHalt before these in 99% of cases

function ENT:PlaySequenceAndWait( sSequence, flSpeed, bDontReset, fFunction, bForce )
	flSpeed = flSpeed || 1

	local flLength = self:SetSequence( sSequence )

	self:ResetSequenceInfo()
	self:SetCycle( flSpeed > 0 && 0 || 1 )
	self:SetPlaybackRate( flSpeed )

	local MyTable = CEntity_GetTable( self )

	MyTable.sCallMeInRunBehaviour = sSequence
	MyTable.fCallMeInRunBehaviour = fEmpty

	local flDuration = flLength / math_abs( flSpeed )
	local flStartTime = CurTime()
	local flEndTime = CurTime() + flDuration
	local flInverseDuration = 1 / flDuration

	fFunction = fFunction || fEmpty

	local tSequenceEvents, tCurrentSequenceEvents = MyTable.tSequenceEvents, MyTable.m_tSequenceEvents
	while CurTime() <= flEndTime do
		if !bForce && MyTable.sCallMeInRunBehaviour != sSequence then break end

		self:SetSequence( sSequence )
		self:SetPlaybackRate( flSpeed )

		local flCycle = ( CurTime() - flStartTime ) * flInverseDuration
		self:SetCycle( flSpeed > 0 && flCycle || ( 1 - flCycle ) )

		local pLocomotion = CEntity_GetTable( self ).loco
		pLocomotion:SetDesiredSpeed( 0 )
		pLocomotion:Approach( self:GetPos(), 1 )

		local tData = tSequenceEvents[ sSequence ]
		if tData then
			local flLastCycle = tCurrentSequenceEvents[ sSequence ] || 0
			for flTime, fFunction in pairs( tData ) do
				// Normal progression, passing the event time
				if flCycle > flTime && flLastCycle <= flTime ||
				// Already passed the event time in the new loop
				flCycle < flLastCycle && flCycle >= flTime ||
				// The event was at the very end of the last loop
				flCycle < flLastCycle && flLastCycle <= flTime then fFunction( self, MyTable, 1 ) end
			end
			tCurrentSequenceEvents[ sSequence ] = flCycle
		end

		if fFunction( self, flCycle ) then if !bDontReset then self:SetSequence( 0 ) end break end

		coroutine_yield()
	end

	if !bDontReset then self:SetSequence( 0 ) end
end

function ENT:PlaySequenceAndMove( sSequence, flSpeed, bDontReset, fFunction, bForce, flPos, flAng )
	flSpeed = flSpeed || 1

	local flLength = self:SetSequence( sSequence )

	self:ResetSequenceInfo()
	self:SetCycle( flSpeed > 0 && 0 || 1 )
	self:SetPlaybackRate( flSpeed )

	local MyTable = CEntity_GetTable( self )

	MyTable.sCallMeInRunBehaviour = sSequence
	MyTable.fCallMeInRunBehaviour = fEmpty

	local flDuration = flLength / math_abs( flSpeed )
	local flStartTime = CurTime()
	local flEndTime = CurTime() + flDuration
	local flInverseDuration = 1 / flDuration

	local flPrevCycle = 0

	fFunction = fFunction || fEmpty

	local vMins, vMaxs = self:OBBMins(), self:OBBMaxs()

	vMins[ 3 ] = vMins[ 3 ] + 12

	flPos = flPos || 1
	flAng = flAng || 1

	local tSequenceEvents, tCurrentSequenceEvents = MyTable.tSequenceEvents, MyTable.m_tSequenceEvents
	while CurTime() <= flEndTime do
		if !bForce && MyTable.sCallMeInRunBehaviour != sSequence then break end

		self:SetSequence( sSequence )
		self:SetPlaybackRate( flSpeed )

		local flCycle = ( CurTime() - flStartTime ) * flInverseDuration
		self:SetCycle( flSpeed > 0 && flCycle || ( 1 - flCycle ) )

		if flPos != 0 || flAng != 0 then
			local _, v, a = self:GetSequenceMovement( self:GetSequence(), flPrevCycle, flCycle )

			local aAngles = self:GetAngles()
			a:Mul( flAng )
			a:Add( aAngles )

			v:Mul( flPos )
			v:Mul( self:GetModelScale() )
			v:Rotate( aAngles )
			v:Add( self:GetPos() )

			flPrevCycle = flCycle

			local tr = util.TraceHull {
				start = v,
				endpos = v,
				mins = vMins,
				maxs = vMaxs,
				filter = function( pEntity )
					if pEntity == self || IsBullshitNonSolidEntity( pEntity ) then return false end
					return true
				end,
				mask = MASK_SOLID
			}

			if !tr.Hit then
				if flPos != 0 then self:SetPos( v ) end
				if flAng != 0 then self:SetAngles( a ) end
			end
		end

		local tData = tSequenceEvents[ sSequence ]
		if tData then
			local flLastCycle = tCurrentSequenceEvents[ sSequence ] || 0
			for flTime, fFunction in pairs( tData ) do
				// Normal progression, passing the event time
				if flCycle > flTime && flLastCycle <= flTime ||
				// Already passed the event time in the new loop
				flCycle < flLastCycle && flCycle >= flTime ||
				// The event was at the very end of the last loop
				flCycle < flLastCycle && flLastCycle <= flTime then fFunction( self, MyTable, 1 ) end
			end
			tCurrentSequenceEvents[ sSequence ] = flCycle
		end

		if fFunction( self, flCycle ) then if !bDontReset then self:SetSequence( 0 ) end break end

		coroutine_yield()
	end

	if !bDontReset then self:SetSequence( 0 ) end
end

ENT.tSequences = {}
ENT.tSequenceEvents = {}
ENT.tPromoteSequences = {}
ENT.tInstantlyPromote = {}
ENT.tLastSequenceData = {}

ENT.m_tSequenceEvents = {}

function ENT:PromoteSequence( sSequence, flSpeed, flWeight, fFunction )
	local MyTable = CEntity_GetTable( self )
	MyTable.tPromoteSequences[ sSequence ] = true
	MyTable.tLastSequenceData[ sSequence ] = { flSpeed || 1, flWeight || 1, fFunction || fEmpty }
end

function ENT:PromoteSequenceInstant( sSequence, flSpeed, flWeight, fFunction )
	local MyTable = CEntity_GetTable( self )
	MyTable.tInstantlyPromote[ sSequence ] = true
	MyTable.tLastSequenceData[ sSequence ] = { flSpeed || 1, flWeight || 1, fFunction || fEmpty }
end

local Lerp = Lerp
local min = min

ENT.flAnimationSystemStopFor = 0

function ENT:AnimationSystemTick( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )

	if CurTime() <= MyTable.flAnimationSystemStopFor then return end

	local tPromote, tInstant, tSequences = MyTable.tPromoteSequences, MyTable.tInstantlyPromote, MyTable.tSequences

	if self:IsOnGround() then
		local sIdle = MyTable.m_sIdleSequence
		if sIdle && table.IsEmpty( tPromote ) && table.IsEmpty( tInstant ) then
			MyTable.PromoteSequence( self, sIdle, MyTable.m_flIdleSequenceSpeed || 1, MyTable.m_flIdleSequenceWeight || 1 )
		end
	else
		local sIdleAir = MyTable.m_sIdleSequenceAir
		if sIdleAir && table.IsEmpty( tPromote ) && table.IsEmpty( tInstant ) then
			MyTable.PromoteSequence( self, sIdleAir, MyTable.m_flIdleSequenceAirSpeed || 1, MyTable.m_flIdleSequenceAirWeight || 1 )
		else
			local sIdle = MyTable.m_sIdleSequence
			if sIdle && table.IsEmpty( tPromote ) && table.IsEmpty( tInstant ) then
				MyTable.PromoteSequence( self, sIdle, MyTable.m_flIdleSequenceSpeed || 1, MyTable.m_flIdleSequenceWeight || 1 )
			end
		end
	end

	for seq in pairs( tInstant ) do
		if !tSequences[ seq ] then
			local lay = self:AddGestureSequence( self:LookupSequence( seq ), false )
			self:SetLayerWeight( lay, 1 )
			tSequences[ seq ] = lay
		end
	end

	for seq in pairs( tPromote ) do
		if !tSequences[ seq ] then
			local lay = self:AddGestureSequence( self:LookupSequence( seq ), false )
			self:SetLayerWeight( lay, 0 )
			tSequences[ seq ] = lay
		end
	end

	local tLastSequenceData = MyTable.tLastSequenceData

	local flTotalWeight = 0

	local flFrameTime, tSequenceEvents, tCurrentSequenceEvents, bReached = self.m_flFrameTime, self.tSequenceEvents, self.m_tSequenceEvents
	for sSequence, iLayer in pairs( tSequences ) do
		local s = self:LookupSequence( sSequence )
		if self:GetLayerSequence( iLayer ) != s then self:SetLayerSequence( iLayer, s ) end

		local flWeight = self:GetLayerWeight( iLayer )

		local tSequenceData = tLastSequenceData[ sSequence ]

		local f = tInstant[ sSequence ]
		if f then
			bReached = true
			self:SetLayerPlaybackRate( iLayer, tSequenceData[ 1 ] )
			local flTarget = tSequenceData[ 2 ]
			flTargetWeight = 1 / flTarget
			flWeight = flTarget
			tSequenceData[ 4 ] = flTargetWeight
			self:SetLayerWeight( iLayer, flWeight )
		end

		local flTargetWeight = 1
		if tPromote[ sSequence ] then
			self:SetLayerPlaybackRate( iLayer, tSequenceData[ 1 ] )
			local flTarget = tSequenceData[ 2 ]
			flTargetWeight = 1 / flTarget
			flWeight = Lerp( FRILerpRate( 5, flFrameTime ), flWeight, flTarget )
			self:SetLayerWeight( iLayer, flWeight )
			tSequenceData[ 4 ] = flTargetWeight
			if flWeight >= ( flTarget - .05 ) then bReached = true end
		end

		flTotalWeight = flTotalWeight + self:GetLayerWeight( iLayer )
	end

	for sSequence, iLayer in pairs( tSequences ) do
		local tSequenceData = tLastSequenceData[ sSequence ]

		local flCycle = self:GetLayerCycle( iLayer )
		local flLastCycle = tCurrentSequenceEvents[ sSequence ] || 0

		local flWeight = self:GetLayerWeight( iLayer ) * tSequenceData[ 4 ] / flTotalWeight

		tSequenceData[ 3 ]( self, MyTable, flWeight, iLayer, flLastCycle, flCycle )

		local tData = tSequenceEvents[ sSequence ]
		if tData then
			for flTime, fFunction in pairs( tData ) do
				// Normal progression, passing the event time
				if flCycle > flTime && flLastCycle <= flTime ||
				// Already passed the event time in the new loop
				flCycle < flLastCycle && flCycle >= flTime ||
				// The event was at the very end of the last loop
				flCycle < flLastCycle && flLastCycle <= flTime then fFunction( self, MyTable, flWeight ) end
			end
		end

		tCurrentSequenceEvents[ sSequence ] = flCycle
	end

	if bReached then
		for sSequence, iLayer in pairs( tSequences ) do
			if !tInstant[ sSequence ] && !tPromote[ sSequence ] then
				local flWeight = self:GetLayerWeight( iLayer )
				if self:GetLayerWeight( iLayer ) <= .05 then
					self:RemoveLayer( iLayer )
					tSequences[ sSequence ] = nil
					tLastSequenceData[ sSequence ] = nil
					continue
				end
				flWeight = Lerp( FRILerpRate( 5, flFrameTime ), flWeight, 0 )
				self:SetLayerWeight( iLayer, flWeight )
			end
		end
	end

	MyTable.tPromoteSequences = {}
	MyTable.tInstantlyPromote = {}
end

function ENT:AnimationSystemHalt( MyTable )
	for seq, lay in pairs( ( MyTable || CEntity_GetTable( self ) ).tSequences ) do
		local s = self:LookupSequence( seq )
		if self:GetLayerSequence( lay ) != s then self:SetLayerSequence( lay, s ) end
		self:SetLayerWeight( lay, 0 )
	end
end

local math_max = math.max
local math_AngleDifference = math.AngleDifference

function ENT:CenterTarget( vTarget, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )

	local iYawPoseParameter = self:LookupPoseParameter( MyTable.m_sYawPoseParameter )
	if iYawPoseParameter == -1 then return end

	local vVelocity = GetVelocity( self )
	local aAlongPath = vVelocity:Angle()
	local vPos = self:GetPos() + self:OBBCenter()

	local flYawComfortableMin, flYawComfortableMax = self:GetPoseParameterRange( iYawPoseParameter )
	flYawComfortableMin = math_max( flYawComfortableMin, -22.5 )
	flYawComfortableMax = min( flYawComfortableMax, 22.5 )

	local flDelta = math_AngleDifference( aAlongPath[ 2 ], ( vTarget - vPos ):Angle()[ 2 ] )
	if flDelta > flYawComfortableMin && flDelta < flYawComfortableMax then
		MyTable.vaAimTargetBody = aAlongPath
		MyTable.vaAimTargetPose = vTarget
		return
	end

	local aAlongPathNeg = ( -vVelocity ):Angle()

	local flDelta = math_AngleDifference( aAlongPathNeg[ 2 ], ( vTarget - vPos ):Angle()[ 2 ] )
	if flDelta > flYawComfortableMin && flDelta < flYawComfortableMax then
		MyTable.vaAimTargetBody = aAlongPathNeg
		MyTable.vaAimTargetPose = vTarget
		return
	end

	MyTable.vaAimTargetBody = vTarget
	MyTable.vaAimTargetPose = vTarget
end

function ENT:DoRootMotion( sSequence, flSpeed, bInstant, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )

	local pLocomotion = MyTable.loco

	local vMins, vMaxs = self:OBBMins(), self:OBBMaxs()

	vMins[ 3 ] = vMins[ 3 ] + pLocomotion:GetStepHeight()

	pLocomotion:SetDesiredSpeed( 1 )
	pLocomotion:SetAcceleration( 1 )
	pLocomotion:SetDeceleration( 1 )

	local iSequence = self:LookupSequence( sSequence )

	// Yes, the ; is really necessary there :)
	;( bInstant && MyTable.PromoteSequenceInstant || MyTable.PromoteSequence )( self, sSequence,
	flSpeed / self:GetSequenceGroundSpeed( iSequence ),
	nil,
	function( self, MyTable, flWeight, _/*iLayer*/, flPrevCycle, flCycle )
		if flPrevCycle > .75 && flCycle < .25 then
			local _, vResult, aResult = self:GetSequenceMovement( iSequence, flPrevCycle, 1 )
			v = vResult
			a = aResult

			local _, vResult, aResult = self:GetSequenceMovement( iSequence, 0, flCycle )
			v:Add( vResult )
			a:Add( aResult )
		else
			local _, vResult, aResult = self:GetSequenceMovement( iSequence, flPrevCycle, flCycle )
			v = vResult
			a = aResult
		end

		local aAngles = self:GetAngles()
		a:Mul( flWeight )
		a:Add( aAngles )

		v:Mul( flWeight )
		v:Mul( self:GetModelScale() )
		v:Rotate( aAngles )
		v:Add( self:GetPos() )

		local tr = util.TraceHull {
			start = self:GetPos(),
			endpos = v,
			mins = vMins,
			maxs = vMaxs,
			filter = function( pEntity )
				if pEntity == self || IsBullshitNonSolidEntity( pEntity ) then return false end
				return true
			end,
			mask = MASK_SOLID
		}

		if !tr.Hit then
			self:SetPos( v )
			self:SetAngles( a )
		end		
	end )
end
