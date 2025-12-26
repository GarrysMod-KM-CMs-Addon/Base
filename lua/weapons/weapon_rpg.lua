// I am too lazy to implement this. We'll need BaseProjectileWeapon first!

DEFINE_BASECLASS "BaseProjectileWeapon"

SWEP.Category = "Rocket Propelled Grenades"
SWEP.PrintName = "#weapon_rpg"

SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Anti-Tank 4."
SWEP.ViewModel = Model "models/weapons/c_rpg.mdl"
SWEP.WorldModel = Model "models/weapons/w_rocket_launcher.mdl" // NOT w_rpg?! WHAT THE HELL?!
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "RPG_Round"
SWEP.Primary_flDelay = 2
SWEP.Primary_sProjectile = "rpg_missile"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 4
SWEP.ViewModelFOV = 54
SWEP.Crosshair = "Open"
SWEP.flRecoil = 14
SWEP.flViewModelX = -5
SWEP.flViewModelY = -5
SWEP.vSprintArm = Vector( 1.358, -12, -4 )
SWEP.vViewModelAim = Vector( -17 - SWEP.flViewModelY, -15, -3.1 )
SWEP.flCoverY = -8
SWEP.Primary_flSpreadX = .05
SWEP.Primary_flSpreadY = .05

sound.Add {
	name = "RPG_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "weapons/ar2/npc_ar2_altfire.wav"
}

SWEP.sSound = "RPG_Shot"
SWEP.sHoldType = "RPG"
