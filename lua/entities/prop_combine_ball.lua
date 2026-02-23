// Purpose: ballz
// Anyway, thanks to Regun2 for telling me about his Combine ball addon.
// I rewrote some code from his addon, plus if not him, I might have
// just left the OSIPR without an alt-fire mode which it had in HL2.
// https://github.com/KM-CM/GarrysMod-KM_CMs_Addon/discussions/1
// Also, Combine balls were ALWAYS a nuisance, disintegrating everything.
// Since that was C++, it was hard to make custom handling for said balls.
// Now, since we have a Lua ball, this is finally not a problem anymore!

AddCSLuaFile()
DEFINE_BASECLASS "BaseProjectile"

ENT.PrintName = "#prop_combine_ball"

// A different, less alien, more sciency ball
// as used in Portal. I don't want to write an
// implementation for it, this'll do.
scripted_ents.Alias( "prop_energy_ball", "prop_combine_ball" )

if CLIENT then
	local mSpriteA = Material "effects/ar2_altfire1"
	local mSpriteB = Material "effects/ar2_altfire1b"
	local render_SetMaterial = render.SetMaterial
	local render_DrawSprite = render.DrawSprite
	local DynamicLight = DynamicLight
	local cTrail = Color( 255, 255, 255, 70 )
	function ENT:Draw()
		local vPos = self:GetPos()
		local flSize = self:BoundingRadius()
		render_SetMaterial( mSpriteA )
		render_DrawSprite( vPos, flSize, flSize, color_white )
		render_SetMaterial( mSpriteB )
		render_DrawSprite( vPos, flSize, flSize, color_white )
		local l = self:GetVelocity():Length() * .02
		if l > 40 then l = 40 end
		for i = 1, l do
			local f = 1 - i / l
			render_DrawSprite( self:GetPos() + self:GetVelocity() * ( i * -.002 ), flSize * f, flSize * f, cTrail )
		end
		local pLight = DynamicLight( self:EntIndex() )
		if pLight then
			pLight.pos = self:GetPos()
			pLight.r = 255
			pLight.g = 255
			pLight.b = 255
			local f = self:Health() / self:GetMaxHealth()
			pLight.brightness = 4 * f
			pLight.decay = 1000
			pLight.size = self:BoundingRadius() * f * 4
			pLight.dietime = CurTime() + 1
		end
	end
	return
end

sound.Add {
	name = "CombineEnergyBallLoop",
	channel = CHAN_STATIC,
	level = 120,
	sound = "weapons/physcannon/energy_sing_loop4.wav"
}

sound.Add {
	name = "CombineEnergyBallBounce",
	channel = CHAN_STATIC,
	level = 120,
	sound = {
		"weapons/physcannon/energy_bounce1.wav",
		"weapons/physcannon/energy_bounce2.wav"
	}
}

sound.Add {
	name = "CombineEnergyBallDisintegrate",
	channel = CHAN_STATIC,
	level = 120,
	sound = {
		"weapons/physcannon/energy_disintegrate4.wav",
		"weapons/physcannon/energy_disintegrate5.wav"
	}
}

ENT.__PROJECTILE_ROCKET__ = true
ENT.ROCKET_flSpeed = 2048

ENT.flDensity = 10

ENT.tHit = {}

function ENT:Initialize()
	self:SetModel "models/combine_helicopter/helicopter_bomb01.mdl"
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMaxHealth( 1024 )
	self:SetHealth( 1024 )
	self.flLifeTime = CurTime() + 16
	local pSoundLoop = CreateSound( self, "CombineEnergyBallLoop" )
	self.pSoundLoop = pSoundLoop
	pSoundLoop:PlayEx( .25, 100 )
	local pPhys = self:GetPhysicsObject()
	if IsValid( pPhys ) then
		pPhys:EnableGravity( false )
		pPhys:SetVelocity( self:GetForward() )
	end
end

function ENT:Think()
	if CurTime() > self.flLifeTime then
		self.bDead = true
		self:Detonate()
		return
	end
	local p = self:GetPhysicsObject()
	if IsValid( p ) then
		p:SetVelocity( p:GetVelocity():GetNormalized() * self.ROCKET_flSpeed )
		p:SetAngleVelocity( LerpVector( math.min( 1, 100 * FrameTime() ), p:GetAngleVelocity(), vector_origin ) )
	else self:Remove() return end
	local pSoundLoop = self.pSoundLoop
	if pSoundLoop then
		local v = p:GetVelocity():Length() / self.ROCKET_flSpeed
		pSoundLoop:ChangeVolume( math.Clamp( v, .25, 1 ) * math.Clamp( math.Remap( self:GetModelScale(), 0, 1, .25, 1 ), 0, 1 ) )
		pSoundLoop:ChangePitch( math.Clamp( 100 + v, 80, 100 ) )
	end
	self:NextThink( CurTime() )
	return true
end

local util_Effect = util.Effect

function ENT:PhysicsCollide( tData )
	local pEntity = tData.HitEntity
	if !IsValid( pEntity ) then
		local ed = EffectData()
		ed:SetOrigin( tData.HitPos )
		ed:SetNormal( -( tData.HitNormal || tData.OurOldVelocity:GetNormalized() ):GetNormalized() )
		ed:SetRadius( self:BoundingRadius() )
		util_Effect( "AR2Explosion", ed )
		net.Start "DynamicLight"
			net.WriteFloat( 4 ) // Brightness
			net.WriteFloat( self:BoundingRadius() * ( self:Health() / self:GetMaxHealth() ) * 8 ) // Size
			net.WriteFloat( 16 ) // Existence length
			net.WriteVector( tData.HitPos ) // Position
			net.WriteUInt( 255, 8 ) net.WriteUInt( 255, 8 ) net.WriteUInt( 255, 8 ) // R, G, B
		net.Broadcast()
		self:EmitSound "CombineEnergyBallBounce"
		return
	end
	local f = self.tHit[ pEntity ]
	if f && CurTime() <= f then return end
	self.tHit[ pEntity ] = CurTime() + .5
	local b = pEntity.GAME_bOrganic
	if !b then
		local EBlood = pEntity:GetBloodColor()
		if EBlood != DONT_BLEED && EBlood != BLOOD_COLOR_MECH then b = true end
	end
	if b then // Absolutely ANNIHILATE organic shit!
		local dDamage = DamageInfo()
		dDamage:SetDamage( self:Health() * self.flDensity )
		dDamage:SetAttacker( IsValid( self:GetOwner() ) && self:GetOwner() || self )
		dDamage:SetInflictor( self )
		dDamage:SetDamageType( DMG_DISSOLVE )
		self:SetHealth( self:Health() - pEntity:Health() / self.flDensity )
		pEntity:TakeDamageInfo( dDamage )
		if self:Health() <= 0 && !self.bDead then
			self.bDead = true
			self:Detonate()
		else self:EmitSound "CombineEnergyBallDisintegrate" end
		return
	else // Otherwise, only deal damage to them, and bounce
		local ed = EffectData()
		ed:SetOrigin( tData.HitPos )
		ed:SetNormal( -( tData.HitNormal || tData.OurOldVelocity:GetNormalized() ):GetNormalized() )
		ed:SetRadius( self:BoundingRadius() )
		util_Effect( "AR2Explosion", ed )
		local dDamage = DamageInfo()
		dDamage:SetDamage( self:Health() )
		dDamage:SetAttacker( IsValid( self:GetOwner() ) && self:GetOwner() || self )
		dDamage:SetInflictor( self )
		dDamage:SetDamageType( DMG_DISSOLVE )
		pEntity:TakeDamageInfo( dDamage )
		self:EmitSound "CombineEnergyBallBounce"
	end
end

function ENT:Detonate()
	self:Remove()
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
