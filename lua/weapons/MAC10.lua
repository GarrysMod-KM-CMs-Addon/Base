DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Submachine Guns"
SWEP.PrintName = "#MAC10"
SWEP.Purpose = "Military Armament Corporation Model 10, officially abbreviated as \"M10\" or \"M-10\", and more commonly known as the MAC-10."
SWEP.ViewModel = Model "models/weapons/cstrike/c_smg_mac10.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_smg_mac10.mdl"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flSpreadX = .0094
SWEP.Primary_flSpreadY = .0094
SWEP.Primary_flDamage = 20
SWEP.Primary_flDelay = .04
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
	name = "MAC10Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^MAC10Shot.wav"
}
SWEP.sSound = "MAC10Shot"

SWEP.sHoldType = "Pistol"

list.Add( "NPCUsableWeapons", { class = "MAC10", title = "#MAC10", category = SWEP.Category } )
