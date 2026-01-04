DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Submachine Guns"
SWEP.PrintName = "#weapon_smg1"
SWEP.Instructions = "Primary to shoot. Secondary to switch fully-automatic and semi-automatic."
SWEP.Purpose = "Heckler & Koch MP7."
SWEP.ViewModel = Model "models/weapons/c_smg1.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_smg1.mdl"
SWEP.Primary.ClipSize = 40
SWEP.Primary.DefaultClip = 40
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flSpreadX = .0083
SWEP.Primary_flSpreadY = .0083
SWEP.Primary_flDelay = .06315789473
SWEP.Primary_flDamage = 68
SWEP.ViewModelFOV = 45
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.vViewModelAim = Vector( -6.43, -4, 1.03 )
SWEP.Crosshair = "SubMachineGun"
SWEP.sAimSound = "BaseWeapon_Aim_SubMachineGun"
SWEP.flRecoil = .9
SWEP.flSideWaysRecoilMin = -.22
SWEP.flSideWaysRecoilMax = .22
SWEP.flRecoilGrowMin = -.55
SWEP.flRecoilGrowMax = -.95

sound.Add {
	name = "MP7_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^MP7Shot.wav"
}

function SWEP:Initialize() self:SetHoldType "SMG" end

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
	self:EmitSound "MP7_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

sound.Add {
	name = "MP7_SwitchSemi",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_single.wav"
}
sound.Add {
	name = "MP7_SwitchAuto",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_burst.wav"
}
function SWEP:SecondaryAttack()
	if CurTime() <= self:GetNextSecondaryFire() then return end
	local b = !self.Primary.Automatic
	self.Primary.Automatic = b
	self:EmitSound( b && "MP7_SwitchAuto" || "MP7_SwitchSemi" )
	self:SetNextSecondaryFire( CurTime() + .2 )
end
