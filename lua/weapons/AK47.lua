DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Assault Rifles"
SWEP.PrintName = "#AK47"
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Автомат Калашникова, also known as the AK-47, with the AK standing for its name, and the 47 being the year it was designed in."
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_rif_ak47.mdl"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flDelay = .08571428571
SWEP.Primary_flSpreadX = .0073
SWEP.Primary_flSpreadY = .0073
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
SWEP.flRecoil = 1.6
SWEP.flSidewaysRecoilMin = -.34
SWEP.flSidewaysRecoilMax = .34
SWEP.flUpwardsRecoilMin = .66
SWEP.flUpwardsRecoilMax = 1
SWEP.sAimSound = "BaseWeapon_Aim_Rifle"
SWEP.sHoldType = "AR2"

if IsMounted "left4dead2" then
	SWEP.flAimShoot = 6
	SWEP.ViewModel = Model "models/v_models/v_rifle_ak47.mdl"
	function SWEP:GetDrawActivity() return ACT_VM_DEPLOY end
	SWEP.__VIEWMODEL_FULLY_MODELED__ = true
	SWEP.flViewModelX = 0
	SWEP.flViewModelY = -4
	SWEP.flViewModelZ = .5
	SWEP.vViewModelAim = Vector( -8 - SWEP.flViewModelX, -6.8 - SWEP.flViewModelY, 2.1 - SWEP.flViewModelZ )
else
	SWEP.flAimShoot = 2
	SWEP.ViewModel = Model "models/weapons/cstrike/c_rif_ak47.mdl"
	SWEP.flViewModelX = -10
	SWEP.flViewModelY = -3
	SWEP.flViewModelZ = 1.5
	SWEP.vViewModelAim = Vector( -12 - SWEP.flViewModelX, -6.61 - SWEP.flViewModelY, 3.4 - SWEP.flViewModelZ )
end

sound.Add {
	name = "AK47Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^AK47Shot.wav",
}
SWEP.sSound = "AK47Shot"
//	sound.Add {
//		name = "AK47ShotAuto",
//		channel = CHAN_AUTO,
//		level = 150,
//		pitch = { 90, 110 },
//		sound = "^AK47Shot.wav",
//	}
//	SWEP.sSoundAuto = "AK47ShotAuto"

list.Add( "NPCUsableWeapons", { class = "AK47", title = "#AK47", category = SWEP.Category } )
