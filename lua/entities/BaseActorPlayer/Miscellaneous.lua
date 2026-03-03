local sv_friction, sv_gravity = GetConVar "sv_friction", GetConVar "sv_gravity"
function ENT:MoveAlongPath( Path, flSpeed, flHeight, tFilter, bAllowSliding )
	if flHeight == nil then flHeight = 1 end
	if !bAllowSliding then self:SetNW2Bool( "CTRL_bSliding", false ) end
	self:SetCrouchTarget( flHeight )
	if flHeight > .5 then flSpeed = math.min( self.flTopSpeed, flSpeed ) else flSpeed = math.min( self.flWalkSpeed, flSpeed ) end
	self.loco:SetDesiredSpeed( flSpeed )
	local f = flSpeed * ACCELERATION_NORMAL
	self.loco:SetAcceleration( f )
	self.loco:SetDeceleration( f )
	self:HandleJumpingAlongPath( Path, flSpeed, tFilter )
end

DEFINE_BASECLASS "BaseActor"

function ENT:Stand( flHeight )
	if flHeight == nil then flHeight = 1 end
	self:SetCrouchTarget( flHeight )
	self:SetNW2Bool( "CTRL_bSliding", false )
	BaseClass.Stand( self )
end

function ENT:Tick()
	local ang = self:GetAngles()
	if ang[ 1 ] != 0 || ang[ 3 ] != 0 then self:SetAngles( Angle( 0, ang[ 2 ], 0 ) ) end
end
