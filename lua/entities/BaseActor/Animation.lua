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
	for seq, lay in pairs( tSequences ) do
		local s = self:LookupSequence( seq )
		if self:GetLayerSequence( lay ) != s then self:SetLayerSequence( lay, s ) end
		local f = tInstant[ seq ]
		if f then
			self:SetLayerPlaybackRate( lay, f )
			self:SetLayerWeight( lay, 1 )
			continue
		end
		local f = tPromote[ seq ]
		if f then
			self:SetLayerPlaybackRate( lay, f )
			self:SetLayerWeight( lay, math.Clamp( self:GetLayerWeight( lay ) + 4 * FrameTime(), 0, 1 ) )
		else self:SetLayerWeight( lay, math.Clamp( self:GetLayerWeight( lay ) - 4 * FrameTime(), 0, 1 ) ) end
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
