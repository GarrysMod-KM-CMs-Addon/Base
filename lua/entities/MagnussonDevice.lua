DEFINE_BASECLASS "BaseProjectile"
AddCSLuaFile()

scripted_ents.Register( ENT, "MagnussonDevice" )
scripted_ents.Alias( "weapon_striderbuster", "MagnussonDevice" )

sound.Add {
	name = "MagnussonDeviceLoop",
	channel = CHAN_STATIC,
	level = 120,
	sound = "weapons/physcannon/energy_sing_loop4.wav"
}

sound.Add {
	name = "MagnussonDeviceExplosion",
	channel = CHAN_AUTO,
	level = 500,
	volume = 1,
	sound = {
		"weapons/mortar/mortar_explode1.wav",
		"weapons/mortar/mortar_explode2.wav",
		"weapons/mortar/mortar_explode3.wav"
	}
}

if !SERVER then return end

function ENT:Initialize()
	self:SetModel "models/magnusson_device.mdl"
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMaxHealth( 32 )
	self:SetHealth( 32 )
	local pSoundLoop = CreateSound( self, "MagnussonDeviceLoop" )
	self.pSoundLoop = pSoundLoop
	pSoundLoop:PlayEx( .25, 100 )
	ParticleEffectAttach( "striderbuster_smoke", PATTACH_ABSORIGIN_FOLLOW, self, -1 )
end

ENT.__PROJECTILE_COLLISSION_DETONATION__ = true
ENT.COLLISION_DETONATION_flSpeed = 768

ENT.flNextTrail = 0
function ENT:Think()
	if self:WaterLevel() > 0 then self:Detonate() return end
	if CurTime() > self.flNextTrail then
		ParticleEffectAttach( "striderbuster_trail", PATTACH_ABSORIGIN_FOLLOW, self, -1 )
		self.flNextTrail = CurTime() + 10
	end
	local pSoundLoop = self.pSoundLoop
	if pSoundLoop then
		local p = self:GetPhysicsObject()
		if !IsValid( p ) then self:NextThink( CurTime() ) return true end
		local v = p:GetVelocity():Length() / self.COLLISION_DETONATION_flSpeed
		pSoundLoop:ChangeVolume( math.Clamp( v, .25, 1 ) )
		pSoundLoop:ChangePitch( math.Clamp( 100 + v * 25, 100, 125 ) )
	end
	self:NextThink( CurTime() )
	return true
end

ENT.__PROJECTILE_EXPLOSION__ = true
ENT.EXPLOSION_flRadius = 384
ENT.EXPLOSION_flDamage = 24576

function ENT:Detonate()
	local v, a = self:GetPos() + self:OBBCenter(), self:GetAngles()
	ParticleEffect( "striderbuster_explode_core", v, a )
	ParticleEffect( "striderbuster_break", v, a )
	ParticleEffect( "striderbuster_break_flechette", v, a )
	self:EmitSound "MagnussonDeviceExplosion"
	util.BlastDamage( self, self, v, self.EXPLOSION_flRadius, self.EXPLOSION_flDamage )
	self:Remove()
end

function ENT:PhysicsCollide( tData )
	if tData.HitSpeed:Length() > self.COLLISION_DETONATION_flSpeed then
		self:Detonate()
	end
end

function ENT:OnTakeDamage( dDamage )
	if self.bDead then return 0 end
	local f = self:Health() - dDamage:GetDamage()
	self:SetHealth( f )
	if f <= 0 then self.bDead = true self:Detonate() return 0 end
end

function ENT:OnRemove()
	local pSoundLoop = self.pSoundLoop
	if pSoundLoop then pSoundLoop:Stop() end
end
