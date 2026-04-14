DEFINE_BASECLASS "BaseBulletWeapon"

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
SWEP.Primary_flDamage = 30
SWEP.Primary_flDelay = .08571428571
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.flViewModelX = 2
SWEP.flViewModelY = -2
SWEP.flViewModelZ = .5
SWEP.vViewModelAim = Vector( -12 - SWEP.flViewModelX, -5.51 - SWEP.flViewModelY, 3.145 - SWEP.flViewModelZ )
SWEP.flAimShoot = 6
SWEP.Crosshair = "Pistol"
SWEP.sAimSound = "BaseWeapon_Aim_Pistol"
SWEP.sAnimationSet = "Pistol"
SWEP.flRecoil = 1.6
SWEP.flSideWaysRecoilMin = -.28
SWEP.flSideWaysRecoilMax = .28
SWEP.flRecoilGrowMin = .5
SWEP.flRecoilGrowMax = .9

sound.Add {
	name = "USPMatchShot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^HKP2000Shot.wav"
}
SWEP.sSound = "USPMatchShot"

SWEP.sHoldType = "Pistol"
