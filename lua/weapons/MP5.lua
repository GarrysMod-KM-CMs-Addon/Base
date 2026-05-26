DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Submachine Guns"
SWEP.PrintName = "#MP5"

SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Heckler & Koch MP5."
SWEP.Primary.ClipSize = 50
SWEP.Primary.DefaultClip = 50
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flSpreadX = .0092
SWEP.Primary_flSpreadY = .0092
SWEP.Primary_flDelay = .06666666666
SWEP.Primary_flDamage = 30
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.Crosshair = "SubMachineGun"
SWEP.sAimSound = "BaseWeapon_Aim_SubMachineGun"
SWEP.sHoldType = "SMG"

SWEP.flAimShoot = 3
if file.Exists( "models/weapons/FC3W/FC3MP5w.mdl", "GAME" ) then
	SWEP.ViewModelFOV = 45
	SWEP.ViewModel = "models/weapons/c_mp5.mdl"
	SWEP.WorldModel = "models/weapons/FC3W/FC3MP5w.mdl"
	SWEP.vViewModelAim = Vector( -9.233, -4.825, 2.049 )
	SWEP.vViewModelAimAngle = Vector( .14, -3.32, -3.004 )
	SWEP.__VIEWMODEL_FULLY_MODELED__ = true
	function SWEP:GetReloadActivity( bOneInTheChamber ) return bOneInTheChamber && ACT_VM_RELOAD || ACT_VM_RELOAD_EMPTY end
	sound.Add {
		name = "Weapon_CMP5.MagIn",
		channel = CHAN_ITEM,
		soundlevel = 80,
		sound = "MP5/MagIn.wav"
	}
	sound.Add {
		name = "Weapon_CMP5.MagOut",
		channel = CHAN_ITEM,
		soundlevel = 80,
		sound = "MP5/MagOut.wav"
	}
	sound.Add {
		name = "Weapon_CMP5.Bolt",
		channel = CHAN_ITEM,
		soundlevel = 80,
		sound = "MP5/Bolt.wav"
	}
else
	SWEP.ViewModel = Model "models/weapons/cstrike/c_smg_mp5.mdl"
	SWEP.WorldModel = Model "models/weapons/w_smg_mp5.mdl"
	SWEP.vViewModelAim = Vector( -8, -5.3, 2.3 )
end

sound.Add {
	name = "MP5Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^MP5Shot.wav"
}
SWEP.sSound = "MP5Shot"

sound.Add {
	name = "MP5ShotAuto",
	channel = CHAN_AUTO,
	level = 150,
	pitch = { 90, 110 },
	sound = "^MP5Shot.wav"
}
SWEP.sSoundAuto = "MP5ShotAuto"

sound.Add {
	name = "MP5SwitchSemi",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_single.wav"
}
sound.Add {
	name = "MP5SwitchAuto",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_burst.wav"
}
function SWEP:SecondaryAttack()
	if CurTime() <= self:GetNextSecondaryFire() then return end
	local b = !self.Primary.Automatic
	self.Primary.Automatic = b
	self:EmitSound( b && "MP5SwitchAuto" || "MP5SwitchSemi" )
	self:SetNextSecondaryFire( CurTime() + .2 )
end
