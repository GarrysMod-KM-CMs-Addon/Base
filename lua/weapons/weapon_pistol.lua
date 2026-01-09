DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Pistols"
SWEP.PrintName = "#weapon_pistol"

SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Universal Self-Loading Pistol, Match Variant."
SWEP.ViewModel = Model "models/weapons/c_pistol.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_pistol.mdl"
SWEP.Primary.ClipSize = 15
SWEP.Primary.DefaultClip = 15
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"
SWEP.Primary_flSpreadX = .0094
SWEP.Primary_flSpreadY = .0094
SWEP.Primary_flDamage = 62
SWEP.Primary_flDelay = .08571428571
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.vViewModelAim = Vector( -12, -5.51, 3.145 )
SWEP.Crosshair = "Pistol"
SWEP.sAimSound = "BaseWeapon_Aim_Pistol"
SWEP.bPistolSprint = true
SWEP.flRecoil = 1.6
SWEP.flSideWaysRecoilMin = -.28
SWEP.flSideWaysRecoilMax = .28
SWEP.flRecoilGrowMin = -.5
SWEP.flRecoilGrowMax = -.9

sound.Add {
	name = "USP_Match_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^HKP2000Shot.wav"
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
	self:EmitSound "USP_Match_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end
