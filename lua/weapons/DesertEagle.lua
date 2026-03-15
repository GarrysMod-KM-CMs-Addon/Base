DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Pistols"
SWEP.PrintName = "#DesertEagle"
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Desert Eagle, .50 Action Express."
SWEP.Primary.ClipSize = 7
SWEP.Primary.DefaultClip = 7
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"
SWEP.Primary_flSpreadX = .0094
SWEP.Primary_flSpreadY = .0094
SWEP.Primary_flDamage = 40
SWEP.Primary_flDelay = .06
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.Crosshair = "Revolver"
SWEP.sAimSound = "BaseWeapon_Aim_Pistol"
SWEP.bPistolSprint = true
SWEP.flSideWaysRecoilMin = -.33
SWEP.flSideWaysRecoilMax = .33
SWEP.flRecoil = 5
SWEP.flAimShoot = 1
SWEP.sHoldType = "Pistol"

if file.Exists( "models/weapons/FC3W/FC3d50w.mdl", "GAME" ) then
	SWEP.ViewModelFOV = 45
	SWEP.ViewModel = "models/weapons/c_d50.mdl"
	SWEP.WorldModel = "models/weapons/FC3W/FC3d50w.mdl"
	SWEP.flViewModelZ = -.5
	SWEP.vViewModelAim = Vector( -7.204, -3.52, .31 - SWEP.flViewModelZ )
	SWEP.vViewModelAimAngle = Vector( .2, -0.35, -2.452 )
else
	SWEP.ViewModel = Model "models/weapons/cstrike/c_pist_deagle.mdl"
	SWEP.WorldModel = Model "models/weapons/w_pist_deagle.mdl"
	SWEP.flViewModelX = -8
	SWEP.flViewModelY = -2
	SWEP.flViewModelZ = 1
	SWEP.vViewModelAim = Vector( -12 - SWEP.flViewModelX, -6.36 - SWEP.flViewModelY, 2.18 - SWEP.flViewModelZ )
end

SWEP.__VIEWMODEL_FULLY_MODELED__ = true

sound.Add {
	name = "DesertEagleShot",
	channel = CHAN_WEAPON,
	volume = .5,
	level = 150,
	pitch = { 90, 110 },
	sound = "^DesertEagleShot.wav"
}
SWEP.sSound = "DesertEagleShot"

sound.Add {
	name = "DesertEagleShotAuto",
	channel = CHAN_AUTO,
	volume = .5,
	level = 150,
	pitch = { 90, 110 },
	sound = "^DesertEagleShot.wav"
}
SWEP.sSoundAuto = "DesertEagleShotAuto"
