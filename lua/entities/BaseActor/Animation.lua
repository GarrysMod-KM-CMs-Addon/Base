local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local CurTime = CurTime
local math_abs = math.abs
local coroutine_yield = coroutine.yield

local function fEmpty() end

// You MUST call AnimationSystemHalt before this!

function ENT:PlaySequenceAndWait( sSequence, flSpeed, bDontReset, fFunction )
	local flLength = self:SetSequence( sSequence )

	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( flSpeed )

	self.sCallMeInRunBehaviour = sSequence
	self.fCallMeInRunBehaviour = fEmpty

	local flDuration = flLength / math_abs( flSpeed )
	local flStartTime = CurTime()
	local flEndTime = CurTime() + flDuration
	local flInverseDuration = 1 / flDuration

	fFunction = fFunction || fEmpty

	local tSequenceEvents, tCurrentSequenceEvents = self.tSequenceEvents, self.m_tSequenceEvents
	while CurTime() <= flEndTime do
		if self.sCallMeInRunBehaviour != sSequence then break end

		self:SetSequence( sSequence )
		self:SetPlaybackRate( flSpeed )
		local flCycle = ( CurTime() - flStartTime ) * flInverseDuration
		self:SetCycle( flCycle )

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
				flCycle < flLastCycle && flLastCycle <= flTime then fFunction( self ) end
			end
			tCurrentSequenceEvents[ sSequence ] = flCycle
		end

		if fFunction( self, flCycle ) then break end

		coroutine_yield()
	end
	if !bDontReset then self:SetSequence( 0 ) end
end

ENT.tSequences = {}
ENT.tSequenceEvents = {}
ENT.tPromoteSequences = {}
ENT.tInstantlyPromote = {}

ENT.m_tSequenceEvents = {}

function ENT:PromoteSequence( seq, flSpeed )
	if isnumber( seq ) then seq = self:GetSequenceName( seq ) end
	self.tPromoteSequences[ seq ] = flSpeed || 1
end

function ENT:PromoteSequenceInstant( seq, flSpeed )
	if isnumber( seq ) then seq = self:GetSequenceName( seq ) end
	self.tInstantlyPromote[ seq ] = flSpeed || 1
end

local Lerp = Lerp
local math_min = math.min

ENT.flAnimationSystemStopFor = 0

function ENT:AnimationSystemTick( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )

	if CurTime() <= MyTable.flAnimationSystemStopFor then return end

	local tPromote, tInstant, tSequences = MyTable.tPromoteSequences, MyTable.tInstantlyPromote, MyTable.tSequences

	local s = self.m_sIdleSequence
	if s && table.IsEmpty( tPromote ) && table.IsEmpty( tInstant ) then tPromote = { [ s ] = ( self.m_flIdleSequenceSpeed || 1 ) } end

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

	local flFrameTime, tSequenceEvents, tCurrentSequenceEvents, bReached = self.m_flFrameTime, self.tSequenceEvents, self.m_tSequenceEvents
	for sSequence, iLayer in pairs( tSequences ) do
		local s = self:LookupSequence( sSequence )
		if self:GetLayerSequence( iLayer ) != s then self:SetLayerSequence( iLayer, s ) end

		local flCycle = self:GetLayerCycle( iLayer )
		local tData = tSequenceEvents[ sSequence ]
		if tData then
			local flLastCycle = tCurrentSequenceEvents[ sSequence ] || 0
			for flTime, fFunction in pairs( tData ) do
				// Normal progression, passing the event time
				if flCycle > flTime && flLastCycle <= flTime ||
				// Already passed the event time in the new loop
				flCycle < flLastCycle && flCycle >= flTime ||
				// The event was at the very end of the last loop
				flCycle < flLastCycle && flLastCycle <= flTime then fFunction( self ) end
			end
			tCurrentSequenceEvents[ sSequence ] = flCycle
		end

		local f = tInstant[ sSequence ]
		if f then
			bReached = true
			self:SetLayerPlaybackRate( iLayer, f )
			self:SetLayerWeight( iLayer, 1 )
			continue
		end

		local f = tPromote[ sSequence ]
		if f then
			self:SetLayerPlaybackRate( iLayer, f )
			f = Lerp( math_min( flFrameTime * 5, 1 ), self:GetLayerWeight( iLayer ), 1 )
			self:SetLayerWeight( iLayer, f )
			if f >= .95 then bReached = true end
		end
	end

	if bReached then
		for sSequence, iLayer in pairs( tSequences ) do
			local f = tInstant[ sSequence ]
			if f then
				bReached = true
				self:SetLayerPlaybackRate( iLayer, f )
				self:SetLayerWeight( iLayer, 1 )
				continue
			end

			local f = tPromote[ sSequence ]
			if !f then
				if self:GetLayerWeight( iLayer ) <= .05 then
					self:RemoveLayer( iLayer )
					tSequences[ sSequence ] = nil
					continue
				end
				f = Lerp( math_min( flFrameTime * 5, 1 ), self:GetLayerWeight( iLayer ), 0 )
				self:SetLayerWeight( iLayer, f )
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
local math_min = math.min
local math_AngleDifference = math.AngleDifference

function ENT:CenterTarget( vTarget, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	local iYawPoseParameter = self:LookupPoseParameter( MyTable.m_sYawPoseParameter )
	if iYawPoseParameter == -1 then return end
	local vVelocity = GetVelocity( self )
	local aAlongPath = vVelocity:Angle()
	local vPos = self:GetPos() + self:OBBCenter()
	local flYawComfortableMin, flYawComfortableMax = self:GetPoseParameterRange( iYawPoseParameter )
	flYawComfortableMin = math_max( flYawComfortableMin, -45 )
	flYawComfortableMax = math_min( flYawComfortableMax, 45 )
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
