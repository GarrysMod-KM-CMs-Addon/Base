AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "CombineGunship" )
scripted_ents.Alias( "npc_combinegunship", "CombineGunship" )

ENT.CATEGORIZE = {
	Combine = true,
	Turret = true
}

ENT.bPhysics = true

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

sound.Add {
	name = "CombineGunshipPulseCannonShot",
	channel = CHAN_STATIC,
	level = 150,
	pitch = { 90, 110 },
	sound = { "npc/strider/strider_minigun.wav", "npc/strider/strider_minigun.wav2" }
}

if !SERVER then return end

ENT.Primary_flDelay = .08
ENT.Primary_flDamage = 80
ENT.Primary_flSpreadX = .02
ENT.Primary_flSpreadY = .02

function ENT:HasWeapon() return true end

ENT.sWeaponAttachment = "muzzle"

function ENT:DoesWeaponHit( v, pClear )
	local at = self:GetAttachment( self:LookupAttachment( self.sWeaponAttachment ) )
	if !at then return end
	local d = ( v - at.Pos ):Angle()
	local a = LerpAngle( 1, at.Ang, d )
	if math.AngleDifference( a[ 1 ], d[ 1 ] ) > 1 || math.AngleDifference( a[ 2 ], d[ 2 ] ) > 1 then return end
	if util.TraceLine( {
		start = at.Pos,
		endpos = v,
		filter = IsValid( pClear ) && { self, pClear } || { self },
		mask = MASK_SHOT_HULL
	} ).Hit then return end
	return true
end

ENT.flNextShot = 0
function ENT:FireWeapon()
	if CurTime() <= self.flNextShot then return end
	local l = self:LookupAttachment( self.sWeaponAttachment )
	local at = self:GetAttachment( l )
	local vAimingAt = self.vAimingAt
	if !at then return end
	self:FireBullets {
		Src = at.Pos,
		// Help a bit because the gunship's aim sucks lmao
		Dir = vAimingAt && LerpVector( 1, at.Ang:Forward(), ( vAimingAt - at.Pos ):GetNormalized() ):GetNormalized() || at.Ang:Forward(),
		Damage = self.Primary_flDamage,
		Spread = Vector( self.Primary_flSpreadX, self.Primary_flSpreadY ),
		Attacker = IsValid( self.pDriver ) && self.pDriver || self,
		TracerName = "HelicopterTracer"
	}
	self:EmitSound "CombineGunshipPulseCannonShot"
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( l )
	util.Effect( "GunshipMuzzleFlash", ed )
	self.flNextShot = CurTime() + self.Primary_flDelay
end

ENT.TRAVERSES = TRAVERSES_AIR

ENT.flTopSpeed = 2048

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
	self.pDriver = self
	local p = CreateSound( self, "CombineGunshipRotorLoop" )
	p:PlayEx( 0, 0 )
	self.m_pRotorLoop = p
	local p = CreateSound( self, "CombineGunshipWhineLoop" )
	p:PlayEx( 0, 0 )
	self.m_pWhineLoop = p
	// TODO: Doesn't seem to work in multiplayer, for... some... reason...?
	// FIXME: This doesn't work in singleplayer too... watafak?
	self.m_iRotorLayer = self:AddGestureSequence( self:LookupSequence "prop_turn", false )
	// HACK: The gunship has waaay too many engines on the model,
	// so just pretend this is a helicopter just for the sake of it
	self:GetPhysicsObject():EnableGravity( false )
	BaseClass.Initialize( self )
end

function ENT:Move( vMove )
	self.flRoundsPerMinute = math.Approach( self.flRoundsPerMinute, math.max( self.flRoundsPerMinuteIdle, math.Remap( vMove:Length(), 0, self.flTopSpeed, self.flRoundsPerMinuteIdle, self.flRoundsPerMinuteLimit ) ), self.flRoundsPerMinuteSpeed * FrameTime() )
	self.m_vMove = vMove
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
ENT.sWeaponPitchPoseParameter = "flex_vert"
ENT.sWeaponYawPoseParameter = "flex_horz"
ENT.flAimSpeed = 80
function ENT:AimWeapon( vAim )
	self.vAimingAt = vAim
	local at = self:GetAttachment( self:LookupAttachment( self.sWeaponAttachment ) )
	if !at then return end
	local a = ( vAim - at.Pos ):Angle()
	local flDesiredYaw = a.yaw
	local flYaw = self:GetPoseParameter( self.sWeaponYawPoseParameter )
	self:SetPoseParameter( self.sWeaponYawPoseParameter, math.Approach( flYaw + math.AngleDifference( flDesiredYaw, at.Ang.y ) * .9, flYaw, .5 * FrameTime() ) )
	local flDesiredPitch = a.pitch
	local flPitch = self:GetPoseParameter( self.sWeaponPitchPoseParameter )
	self:SetPoseParameter( self.sWeaponPitchPoseParameter, math.Approach( flPitch + math.AngleDifference( flDesiredPitch, at.Ang.x ) * .9, flPitch, .5 * FrameTime() ) )
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
