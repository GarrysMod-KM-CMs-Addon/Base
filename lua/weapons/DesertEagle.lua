DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Pistols"
SWEP.PrintName = "#DesertEagle"
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Desert Eagle, .50 Action Express."
SWEP.ViewModel = Model "models/weapons/cstrike/c_pist_deagle.mdl"
SWEP.WorldModel = Model "models/weapons/w_pist_deagle.mdl"
SWEP.Primary.ClipSize = 7
SWEP.Primary.DefaultClip = 7
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"
SWEP.Primary_flSpreadX = .0094
SWEP.Primary_flSpreadY = .0094
SWEP.Primary_flDamage = 80
SWEP.Primary_flDelay = .06
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.Crosshair = "Pistol"
SWEP.sAimSound = "BaseWeapon_Aim_Pistol"
SWEP.bPistolSprint = true
SWEP.flSideWaysRecoilMin = -.33
SWEP.flSideWaysRecoilMax = .33
SWEP.flRecoil = 5
SWEP.flAimShoot = 1

SWEP.flViewModelX = -8
SWEP.flViewModelY = -2
SWEP.flViewModelZ = 1

SWEP.flBlindFireLeftX = 6
SWEP.flBlindFireRightX = -16

SWEP.vViewModelAim = Vector( -6.36 - SWEP.flViewModelY, -12 - SWEP.flViewModelX, 2.18 - SWEP.flViewModelZ )

SWEP.__VIEWMODEL_FULLY_MODELED__ = true

sound.Add {
	name = "DesertEagle_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^DesertEagleShot.wav"
}

function SWEP:Initialize() self:SetHoldType "Pistol" end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	self:FireBullets {
		Attacker = owner,
		Src = owner:GetShootPos(),
		Dir = self:GetAimVector(),
		Tracer = 1,
		Spread = Vector( self.Primary_flSpreadX, self.Primary_flSpreadY ),
		Damage = self.Primary_flDamage
	}
	self:ShootEffects()
	owner:SetAnimation( PLAYER_ATTACK1 )
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util.Effect( "MuzzleFlash", ed )
	self:EmitSound "DesertEagle_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end
