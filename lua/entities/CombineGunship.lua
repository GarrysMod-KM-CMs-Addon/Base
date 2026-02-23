AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "CombineGunship" )
scripted_ents.Alias( "npc_combinegunship", "CombineGunship" )

ENT.CATEGORIZE = {
	Combine = true,
	Turret = true
}

sound.Add {
	name = "CombineGunshipRotorLoop",
	channel = CHAN_STATIC,
	level = 150,
	pitch = 100,
	sound = "npc/combine_gunship/engine_rotor_loop1.wav"
}
sound.Add {
	name = "CombineGunshipWhineLoop",
	channel = CHAN_STATIC,
	level = 150,
	pitch = 100,
	sound = "npc/combine_gunship/engine_whine_loop1.wav"
}

list.Set( "NPC", "npc_combinegunship", {
	Name = "#CombineGunship",
	Class = "CombineGunship",
	Category = "Combine"
} )

if !SERVER then return end

ENT.TRAVERSES = TRAVERSES_AIR

ENT.flTopSpeed = 0
ENT.flRunSpeed = 0
ENT.flWalkSpeed = 0

ENT.bPhysics = true

ENT.bCantTurnBody = true

ENT.bCombatForgetLastHostile = true

ENT.iDefaultClass = CLASS_COMBINE

ENT.vHullMins = Vector( -321.456696, -130.342514, -57.648781 )
ENT.vHullMaxs = Vector( 236.404907, 130.553619, 91.529099 )

ENT.flRoundsPerMinuteSpeed = 1000
ENT.flRoundsPerMinuteIdle = 400
ENT.flRoundsPerMinute = ENT.flRoundsPerMinuteIdle
ENT.flRoundsPerMinuteLimit = 2500

ENT.flTurnSpeed = 180
ENT.flTurnAcceleration = 240
ENT.flAcceleration = 2048

function ENT:Initialize()
	self:SetModel "models/gunship.mdl"
	self:SetHealth( 131072 )
	self:SetMaxHealth( 131072 )
	self:SetBloodColor( BLOOD_COLOR_MECH )
	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
	self:PhysicsInit( SOLID_OBB )
	self.GAME_pVehicle = self
	self:SetNW2Entity( "GAME_pVehicle", self )
	local p = CreateSound( self, "CombineGunshipRotorLoop" )
	p:PlayEx( 0, 0 )
	self.m_pRotorLoop = p
	local p = CreateSound( self, "CombineGunshipWhineLoop" )
	p:PlayEx( 0, 0 )
	self.m_pWhineLoop = p
	self.m_iRotorLayer = self:AddGestureSequence( self:LookupSequence "prop_turn", false )
	// HACK: The gunship has waaay too many engines on the model,
	// so just pretend this is a helicopter just for the sake of it
	self:GetPhysicsObject():EnableGravity( false )
	BaseClass.Initialize( self )
end

function ENT:Move( vDirection, flSpeed )
	flSpeed = flSpeed * math.abs( self:GetRight():Dot( vDirection ) )
	self.flRoundsPerMinute = math.Approach( self.flRoundsPerMinute, math.max( self.flRoundsPerMinuteIdle, math.Remap( flSpeed, 0, self.flTopSpeed, self.flRoundsPerMinuteIdle, self.flRoundsPerMinuteLimit ) ), self.flRoundsPerMinuteSpeed * FrameTime() )
	self.m_vMove = vDirection * flSpeed
end
function ENT:Stay() self.flRoundsPerMinute = math.Approach( self.flRoundsPerMinute, self.flRoundsPerMinuteIdle, self.flRoundsPerMinuteSpeed * FrameTime() ) end

function ENT:Turn( aDirection ) self.m_aTurn = aDirection end

function ENT:Think()
	local flRoundsPerMinute = self.flRoundsPerMinute
	local flRoundsPerMinuteIdle = self.flRoundsPerMinuteIdle
	local flVolume = flRoundsPerMinute / flRoundsPerMinuteIdle * .5
	local flRoundsPerMinuteLimit = self.flRoundsPerMinuteLimit
	local flPitch = math.Clamp( flRoundsPerMinute / flRoundsPerMinuteIdle, 0, 1 ) * 75 + math.Clamp( ( flRoundsPerMinute - flRoundsPerMinuteIdle ) / flRoundsPerMinuteLimit, 0, 1 ) * 25
	local p = self.m_pRotorLoop
	if p then p:ChangeVolume( flVolume ) p:ChangePitch( flPitch ) end
	local p = self.m_pWhineLoop
	if p then p:ChangeVolume( flVolume ) p:ChangePitch( flPitch ) end
	local flSpeed = math.Clamp( flRoundsPerMinute / flRoundsPerMinuteIdle, 0, 1 ) * 1.5 + math.Clamp( ( flRoundsPerMinute - flRoundsPerMinuteIdle ) / flRoundsPerMinuteLimit, 0, 1 ) * 5
	self:SetLayerPlaybackRate( self.m_iRotorLayer, flSpeed )
	self:SetSkin( flSpeed > 1 && 0 || 1 )
	local vMove = self.m_vMove
	if vMove then
		local pPhys = self:GetPhysicsObject()
		pPhys:AddVelocity( CalculateAcceleration( pPhys:GetVelocity(), vMove, self.flAcceleration ) )
	end
	self.m_vMove = nil
	local aTurn = self.m_aTurn
	if aTurn then
		local pPhys = self:GetPhysicsObject()
		pPhys:AddAngleVelocity( CalculateAngularVelocity( aTurn, self:GetAngles(), pPhys:GetAngleVelocity(), self.flTurnRate, self.flTurnAcceleration ) )
	end
	self.m_aTurn = aTurn
	return BaseClass.Think( self )
end

// Until we implement proper head turning!!!
function ENT:GetShootPos() return self:GetPhysicsObject():GetPos() end

ENT.m_sPitchPoseParameter = "flex_vert"
ENT.m_sYawPoseParameter = "flex_horz"
function ENT:AimWeapon( vTarget )
	self.vaAimTargetPose = vTarget
end

function ENT:OnRemove()
	local p = self.m_pRotorLoop
	if p then p:Stop() self.m_pRotorLoop = nil end
	local p = self.m_pWhineLoop
	if p then p:Stop() self.m_pWhineLoop = nil end
	BaseClass.OnRemove( self )
end

function ENT:OnKilled( dDamage )
	if BaseClass.OnKilled( self, dDamage ) then return end
	self:SetSkin( 1 )
	self:BecomeRagdoll( dDamage )
end
