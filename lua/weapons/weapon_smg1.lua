DEFINE_BASECLASS "BaseBulletWeapon"

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
SWEP.Primary_flDamage = 20
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.vViewModelAim = Vector( -4, -6.43, 1.03 )
SWEP.Crosshair = "SubMachineGun"
SWEP.sAimSound = "BaseWeapon_Aim_SubMachineGun"
SWEP.flRecoil = .9
SWEP.flSideWaysRecoilMin = -.22
SWEP.flSideWaysRecoilMax = .22
SWEP.flRecoilGrowMin = .55
SWEP.flRecoilGrowMax = .95
SWEP.flAimShoot = 5

sound.Add {
	name = "MP7Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^MP7Shot.wav"
}
SWEP.sSound = "MP7Shot"

SWEP.sHoldType = "SMG"

sound.Add {
	name = "MP7SwitchSemi",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_single.wav"
}
sound.Add {
	name = "MP7SwitchAuto",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_burst.wav"
}
function SWEP:SecondaryAttack()
	if CurTime() <= self:GetNextSecondaryFire() then return end
	local b = !self.Primary.Automatic
	self.Primary.Automatic = b
	self:EmitSound( b && "MP7SwitchAuto" || "MP7SwitchSemi" )
	self:SetNextSecondaryFire( CurTime() + .2 )
end
