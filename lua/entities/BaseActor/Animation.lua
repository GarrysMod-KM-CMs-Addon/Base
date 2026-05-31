local coroutine_wait = coroutine.wait
// You MUST call AnimationSystemHalt before this!
function ENT:PlaySequenceAndWait( sName, flSpeed )
	local flLength = self:SetSequence( sName )
	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( flSpeed )
	coroutine_wait( flLength / flSpeed )
	self:SetSequence( 0 )
end

ENT.tSequences = {}
ENT.tPromoteSequences = {}
ENT.tInstantlyPromote = {}

function ENT:PromoteSequence( seq, flSpeed )
	if isnumber( seq ) then seq = self:GetSequenceName( seq ) end
	self.tPromoteSequences[ seq ] = flSpeed || 1
end

function ENT:PromoteSequenceInstant( seq, flSpeed )
	if isnumber( seq ) then seq = self:GetSequenceName( seq ) end
	self.tInstantlyPromote[ seq ] = flSpeed || 1
end

function ENT:PromoteMotionSequence( Sequence )
	if isnumber( Sequence ) then Sequence = self:GetSequenceName( Sequence ) end
	self.tPromoteSequences[ Sequence ] = GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence( Sequence ) )
end

function ENT:AnimationSystemTick()
	local tPromote, tInstant, tSequences = self.tPromoteSequences, self.tInstantlyPromote, self.tSequences
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
	local flFrameTime, bReached = self.m_flFrameTime
	for sSequence, iLayer in pairs( tSequences ) do
		local s = self:LookupSequence( sSequence )
		if self:GetLayerSequence( iLayer ) != s then self:SetLayerSequence( iLayer, s ) end
		local f = tInstant[ sSequence ]
		if f then
			bReached = true
			self:SetLayerPlaybackRate( iLayer, f )
			self:SetLayerWeight( iLayer, 1 )
			continue
		end
		local f = tPromote[ sSequence ]
		if f then
			f = math.Clamp( self:GetLayerWeight( iLayer ) + flFrameTime * 2, 0, 1 )
			self:SetLayerWeight( iLayer, f )
			if f >= 1 then bReached = true end
		end
	end
	if bReached then
		for sSequence, iLayer in pairs( tSequences ) do
			local f = tPromote[ sSequence ]
			if !f then
				if self:GetLayerWeight( iLayer ) <= 0 then
					self:RemoveLayer( iLayer )
					tSequences[ sSequence ] = nil
					continue
				end
				self:SetLayerWeight( iLayer, math.Clamp( self:GetLayerWeight( iLayer ) - flFrameTime * 2, 0, 1 ) )
			end
		end
	end
	table.Empty( tPromote )
	table.Empty( tInstant )
end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

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
	local vVelocity = GetVelocity( self )
	local aAlongPath = vVelocity:Angle()
	local vPos = self:GetPos() + self:OBBCenter()
	local flYawComfortableMin, flYawComfortableMax = self:GetPoseParameterRange( self:LookupPoseParameter( MyTable.m_sYawPoseParameter ) )
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
