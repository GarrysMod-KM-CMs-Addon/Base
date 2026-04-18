DEFINE_BASECLASS "BaseProjectile"
AddCSLuaFile()

scripted_ents.Register( ENT, "CombineHelicopterMine" )
scripted_ents.Alias( "grenade_helicopter", "CombineHelicopterMine" )

sound.Add {
	name = "CombineHelicopterMineLoop",
	channel = CHAN_STATIC,
	level = 120,
	sound = "npc/attack_helicopter/aheli_mine_seek_loop1.wav"
}

sound.Add {
	name = "CombineHelicopterMineExplosion",
	channel = CHAN_AUTO,
	level = 500,
	volume = 1,
	sound = {
		"ambient/levels/labs/electric_explosion1.wav",
		"ambient/levels/labs/electric_explosion2.wav",
		"ambient/levels/labs/electric_explosion3.wav",
		"ambient/levels/labs/electric_explosion4.wav",
		"ambient/levels/labs/electric_explosion5.wav",
	}
}

if !SERVER then return end

function ENT:Initialize()
	self:SetModel "models/combine_helicopter/helicopter_bomb01.mdl"
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMaxHealth( 32 )
	self:SetHealth( 32 )
end

function ENT:StartFuse()
	if self.flFuseStart then return end
	local t = CurTime()
	self.flFuseStart = t + 6
	self.GRENADE_flTime = t + 8
end

function ENT:StopFuse()
	self.flFuseStart = nil
	self.GRENADE_flTime = nil
end

function ENT:Use() self:StartFuse() end

function ENT:Think()
	local f = self.GRENADE_flTime
	if f && CurTime() > f then self:Detonate() return end
	local pSoundLoop = self.pSoundLoop
	if pSoundLoop then
		local f = self.flFuseStart
		if f then
			pSoundLoop:ChangePitch( math.Clamp( math.Remap( CurTime(), self.flFuseStart, self.GRENADE_flTime, 100, 150 ), 100, 150 ) )
		else pSoundLoop:Stop() self.pSoundLoop = nil end
	else
		if self.flFuseStart then
			local pSoundLoop = CreateSound( self, "CombineHelicopterMineLoop" )
			self.pSoundLoop = pSoundLoop
			pSoundLoop:PlayEx( 1, 0 )
		end
	end
	self:NextThink( CurTime() )
	return true
end

ENT.__PROJECTILE_EXPLOSION__ = true
ENT.EXPLOSION_flRadius = 256
ENT.EXPLOSION_flDamage = 2048

function ENT:Detonate()
	self:EmitSound "CombineHelicopterMineExplosion"
	local pEffectData = EffectData()
	local v = self:GetPos() + self:OBBCenter()
	pEffectData:SetOrigin( v )
	util.Effect( "HelicopterMegaBomb", pEffectData )
	util.BlastDamage( self, self, v, self.EXPLOSION_flRadius, self.EXPLOSION_flDamage )
	self:Remove()
end

function ENT:PhysicsCollide()
	if !self.flFuseStart then return end
	self:Detonate()
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
