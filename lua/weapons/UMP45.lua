DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Submachine Guns"
SWEP.PrintName = "#UMP45"
SWEP.Purpose = "Heckler & Koch Universale Maschinenpistole 45."
SWEP.ViewModel = Model "models/weapons/cstrike/c_smg_ump45.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_smg_ump45.mdl"
SWEP.Primary.ClipSize = 25
SWEP.Primary.DefaultClip = 25
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flSpreadX = .009
SWEP.Primary_flSpreadY = .009
SWEP.Primary_flDelay = .08
SWEP.Primary_flDamage = 30
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.Crosshair = "SubMachineGun"

sound.Add {
	name = "UMP45Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^UMP45Shot.wav"
}
SWEP.sSound = "UMP45Shot"

SWEP.sHoldType = "SMG"

list.Add( "NPCUsableWeapons", { class = "UMP45", title = "#UMP45", category = SWEP.Category } )
