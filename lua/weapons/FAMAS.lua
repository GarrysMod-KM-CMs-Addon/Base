DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Assault Rifles"
SWEP.PrintName = "#FAMAS"
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Fusil d'Assaut de la Manufacture d'Armes de Saint-Étienne, Assault rifle from the Saint-Étienne Weapon Factory."
SWEP.ViewModel = Model "models/weapons/cstrike/c_rif_famas.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_rif_famas.mdl"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flDelay = 60 / 900
SWEP.Primary_flSpreadX = .0058
SWEP.Primary_flSpreadY = .0058
SWEP.Primary_flDamage = 40
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.Crosshair = "Rifle"
SWEP.sAimSound = "BaseWeapon_Aim_Rifle"
SWEP.flViewModelY = -1
SWEP.flViewModelZ = 1
SWEP.vViewModelAim = Vector( 0, -6.2 - SWEP.flViewModelY, 1 - SWEP.flViewModelZ )

sound.Add {
	name = "FAMASShot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^FAMASShot.wav"
}
sound.Add {
	name = "FAMASShotAuto",
	channel = CHAN_AUTO,
	level = 150,
	pitch = { 90, 110 },
	sound = "^FAMASShot.wav"
}

SWEP.sSound = "FAMASShot"
SWEP.sSoundAuto = "FAMASShotAuto"

SWEP.sHoldType = "AR2"

list.Add( "NPCUsableWeapons", { class = "FAMAS", title = "#FAMAS", category = SWEP.Category } )
