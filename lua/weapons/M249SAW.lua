DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Light Machine Guns"
SWEP.PrintName = "#M249SAW"

SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "M249 Squad Automatic Weapon."
SWEP.ViewModel = Model "models/weapons/cstrike/c_mach_m249para.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_mach_m249para.mdl"
SWEP.Primary.ClipSize = 200
SWEP.Primary.DefaultClip = 200
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flDelay = .05
SWEP.Primary_flSpreadX = .0087
SWEP.Primary_flSpreadY = .0087
SWEP.Primary_flDamage = 40
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.flZoomSpeedIn = 4
SWEP.flZoomSpeedOut = 1
SWEP.vViewModelAim = Vector( 0, -5.95, 2.35 )
SWEP.Crosshair = "Rifle"
SWEP.sAimSound = "BaseWeapon_Aim_Rifle"
SWEP.flRecoil = 2

sound.Add {
	name = "M249SAWShot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^M249SAWShot.wav"
}
SWEP.sSound = "M249SAWShot"

SWEP.sHoldType = "AR2"

list.Add( "NPCUsableWeapons", { class = "M249SAW", title = "#M249SAW", category = SWEP.Category } )
