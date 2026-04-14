DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Pistols"
SWEP.PrintName = "#Glock18"
SWEP.Instructions = "Primary to shoot, secondary to switch semi/auto."
SWEP.Purpose = "Glock-18."
SWEP.ViewModel = Model "models/weapons/cstrike/c_pist_glock18.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_pist_glock18.mdl"
SWEP.Primary.ClipSize = 33
SWEP.Primary.DefaultClip = 33
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"
SWEP.Primary_flSpreadX = .0094
SWEP.Primary_flSpreadY = .0094
SWEP.Primary_flDamage = 30
SWEP.Primary_flDelay = .04285714285
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.Crosshair = "Pistol"
SWEP.sAimSound = "BaseWeapon_Aim_Pistol"
SWEP.sAnimationSet = "Pistol"
SWEP.flViewModelX = -4
SWEP.flViewModelY = -2
SWEP.flViewModelZ = 1
SWEP.vViewModelAim = Vector( -8 - SWEP.flViewModelX, -5.79 - SWEP.flViewModelY, 2.99 - SWEP.flViewModelZ )

sound.Add {
	name = "Glock18Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^Glock18Shot.wav"
}
SWEP.sSound = "Glock18Shot"

SWEP.sHoldType = "Pistol"

sound.Add {
	name = "Glock18SwitchSemi",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_single.wav"
}
sound.Add {
	name = "Glock18SwitchAuto",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_burst.wav"
}
function SWEP:SecondaryAttack()
	if CurTime() <= self:GetNextSecondaryFire() then return end
	local b = !self.Primary.Automatic
	self.Primary.Automatic = b
	self:EmitSound( b && "Glock18SwitchAuto" || "Glock18SwitchSemi" )
	self:SetNextSecondaryFire( CurTime() + .2 )
end
