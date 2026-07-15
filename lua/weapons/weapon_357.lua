DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Revolvers"
SWEP.PrintName = "#weapon_357"
SWEP.Purpose = "Colt Python."
SWEP.ViewModel = Model "models/weapons/c_357.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_357.mdl"
SWEP.Primary.ClipSize = 6 // Duh
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Automatic = false
SWEP.m_bAllowOneInTheChamber = false
SWEP.Primary.Ammo = "357"
SWEP.Primary_flSpreadX = .0084
SWEP.Primary_flSpreadY = .0084
SWEP.Primary_flDamage = 80
SWEP.Primary_flDelay = .25
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.vViewModelAim = Vector( 0, -4.62, .67 )
SWEP.Crosshair = "Revolver"
SWEP.WPN_SPRINT = WPN_PISTOL
SWEP.WPN_SHOOT = WPN_PISTOL
SWEP.flRecoil = 3
SWEP.flSidewaysRecoilMin = -.2
SWEP.flSidewaysRecoilMax = .2
SWEP.flUpwardsRecoilMin = .4
SWEP.flUpwardsRecoilMax = .85
SWEP.sAimSound = "BaseWeapon_Aim_Pistol"

sound.Add {
	name = "ColtPythonShot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^ColtPythonShot.wav"
}
SWEP.sSound = "ColtPythonShot"

SWEP.sHoldType = "Revolver"
