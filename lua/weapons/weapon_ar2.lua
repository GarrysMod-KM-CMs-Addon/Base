DEFINE_BASECLASS "BaseWeapon"

if SERVER then ACHIEVEMENT_ACQUIRE "weapon_ar2" end

SWEP.Category = "Assault Rifles"
SWEP.PrintName = "#weapon_ar2"

SWEP.Instructions = "Primary to shoot. Hold secondary to charge up an energy ball."
SWEP.Purpose = "Overwatch Standard Issue Pulse Rifle."
SWEP.ViewModel = Model "models/weapons/c_irifle.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_irifle.mdl"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "AR2"
SWEP.Primary_flSpreadX = .0037
SWEP.Primary_flSpreadY = .0037
SWEP.Primary_flDamage = 95
SWEP.Primary_flDelay = .07
SWEP.Secondary_flDelay = 1
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "AR2AltFire"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.Crosshair = "Rifle"
SWEP.ViewModelFOV = 62
SWEP.flViewModelY = -2
SWEP.vViewModelAim = Vector( -8, -5.82 - SWEP.flViewModelY, 1.255 )
SWEP.vSprint = Vector( -1.228, .6, -1.2 )
SWEP.flRecoil = .7
SWEP.flSideWaysRecoilMin = -.15
SWEP.flSideWaysRecoilMax = .15
SWEP.flRecoilGrowMin = -.8
SWEP.flRecoilGrowMax = -1

sound.Add {
	name = "CombineEnergyBallCharge",
	channel = CHAN_STATIC,
	level = 120,
	sound = "weapons/physcannon/energy_sing_loop4.wav"
}

sound.Add {
	name = "CombineEnergyBallShot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = 100,
	sound = "weapons/irifle/irifle_fire2.wav"
}

sound.Add {
	name = "OSIPR_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "weapons/ar2/fire1.wav"
}

function SWEP:Initialize()
	self:SetHoldType "AR2"
	local pChargeLoop = CreateSound( self, "CombineEnergyBallCharge" )
	pChargeLoop:PlayEx( 0, 0 )
	self.pChargeLoop = pChargeLoop
end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	self:FireBullets {
		Attacker = owner,
		Src = owner:GetShootPos(),
		Dir = self:GetAimVector(),
		Tracer = 1,
		TracerName = "AR2Tracer",
		Spread = Vector( self.Primary_flSpreadX, self.Primary_flSpreadY ),
		Damage = self.Primary_flDamage
	}
	self:ShootEffects()
	owner:SetAnimation( PLAYER_ATTACK1 )
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 5 )
	util.Effect( "MuzzleFlash", ed )
	self:EmitSound "OSIPR_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

if SERVER then
	// Chomp your balls off and throw them at the enemy!!!
	function SWEP:Think()
		if !self:GetOwner():KeyDown( IN_ATTACK2 ) || self.flStartTime && ( CurTime() - self.flStartTime ) > 8 then
			if self.flStartTime && ( CurTime() - self.flStartTime ) > 1 then
				if self:TakeAmmo( self:GetSecondaryAmmoType(), math.ceil( math.max( 0, ( CurTime() - self.flStartTime ) ^ .25 ) ) ) then
					self:EmitSound "CombineEnergyBallShot"
					local pBall = ents.Create "prop_combine_ball"
					local pOwner = self:GetOwner()
					local bOwner = IsValid( pOwner )
					pBall:SetOwner( bOwner && pOwner || self )
					pBall:SetPos( bOwner && pOwner:GetShootPos() || ( self:GetPos() + self:OBBCenter() ) )
					pBall:SetAngles( self:GetAimVector():Angle() )
					local f = CurTime() - self.flStartTime
					pBall:SetModelScale( math.Remap( f, 0, 8, .1, 1 ) )
					pBall:Spawn()
					pBall.ROCKET_flSpeed = pBall.ROCKET_flSpeed * math.Remap( f, 0, 8, .25, 4 )
					f = math.Remap( f, 0, 8, .0000005, 1.25 ) ^ 4
					pBall:SetHealth( pBall:Health() * f )
					pBall:SetMaxHealth( pBall:GetMaxHealth() * f )
				end
			end
			self.flStartTime = nil
			local pChargeLoop = self.pChargeLoop
			if pChargeLoop then
				pChargeLoop:ChangeVolume( 0 )
				pChargeLoop:ChangePitch( 0 )
			end
			return
		end
		self:SetNextPrimaryFire( CurTime() + self.Secondary_flDelay )
		if self.flStartTime then
			local f = CurTime() - self.flStartTime
			self:GetOwner():ViewPunch( AngleRand() * FrameTime() * ( f <= 2 && math.Remap( f, 0, 2, 0, .1 ) || math.Remap( f, 2, 8, .1, .5 ) ) )
			local pChargeLoop = self.pChargeLoop
			if pChargeLoop then
				if f <= 2 then
					f = math.Remap( f, 0, 2, 0, 1 )
				else f = math.Remap( f, 2, 32, 1, 2 ) end
				pChargeLoop:ChangeVolume( f )
				pChargeLoop:ChangePitch( f * 100 )
			end
		else self.flStartTime = CurTime() end
	end

	function SWEP:GAME_Think()
		if !self.flStartTime || IsValid( self:GetOwner() ) && self:GetOwner():IsPlayer() then return end
		self:EmitSound "CombineEnergyBallShot"
		local pBall = ents.Create "prop_combine_ball"
		local pOwner = self:GetOwner()
		local bOwner = IsValid( pOwner )
		pBall:SetOwner( bOwner && pOwner || self )
		pBall:SetPos( bOwner && pOwner:GetShootPos() || ( self:GetPos() + self:OBBCenter() ) )
		pBall:SetAngles( self:GetAimVector():Angle() )
		local f = CurTime() - self.flStartTime
		pBall:SetModelScale( math.Remap( f, 0, 8, .1, 2 ) )
		pBall:Spawn()
		pBall.ROCKET_flSpeed = pBall.ROCKET_flSpeed * math.Remap( f, 0, 8, .25, 8 )
		f = math.Remap( f, 0, 8, .0000005, 1.25 ) ^ 4
		pBall:SetHealth( pBall:Health() * f )
		pBall:SetMaxHealth( pBall:GetMaxHealth() * f )
		self.flStartTime = nil
	end

	function SWEP:OnRemove() local pChargeLoop = self.pChargeLoop if pChargeLoop then pChargeLoop:Stop() self.pChargeLoop = nil end end
end


local EffectData = EffectData
local util_Effect = util.Effect
function SWEP:DoImpactEffect( tr, dt )
	if tr.HitSky then return end
	local p = EffectData()
	local d = tr.HitNormal
	p:SetOrigin( tr.HitPos + d )
	p:SetNormal( d )
	util_Effect( "AR2Impact", p ) 
end
