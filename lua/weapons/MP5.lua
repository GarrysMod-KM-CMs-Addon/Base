DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Submachine Guns"
SWEP.PrintName = "#MP5"

SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Heckler & Koch MP5."
SWEP.ViewModel = Model "models/weapons/cstrike/c_smg_mp5.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_smg_mp5.mdl"
SWEP.Primary.ClipSize = 50
SWEP.Primary.DefaultClip = 50
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flSpreadX = .0092
SWEP.Primary_flSpreadY = .0092
SWEP.Primary_flDelay = .075
SWEP.Primary_flDamage = 60
// SWEP.ViewModelFOV = 45
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.vSprint = Vector( 1.358, -3.228, -.94 )
SWEP.vViewModelAim = Vector( -8, -5.3, 2.3 )
SWEP.Crosshair = "SubMachineGun"
SWEP.sAimSound = "BaseWeapon_Aim_SubMachineGun"

sound.Add {
	name = "MP5_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^MP7Shot.wav" // TODO: Sound
}

function SWEP:Initialize() self:SetHoldType "SMG" end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	self:FireBullets {
		Attacker = owner,
		Src = owner:GetShootPos(),
		Dir = self:GetAimVector(),
		Tracer = 1,
		Spread = Vector( self.Primary_flSpreadX, self.Primary_flSpreadY ),
		Damage = self.Primary_flDamage
	}
	self:ShootEffects()
	owner:SetAnimation( PLAYER_ATTACK1 )
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util.Effect( "MuzzleFlash", ed )
	self:EmitSound "MP5_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

sound.Add {
	name = "MP5_SwitchSemi",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_single.wav"
}
sound.Add {
	name = "MP5_SwitchAuto",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_burst.wav"
}
function SWEP:SecondaryAttack()
	if CurTime() <= self:GetNextSecondaryFire() then return end
	local b = !self.Primary.Automatic
	self.Primary.Automatic = b
	self:EmitSound( b && "MP5_SwitchAuto" || "MP5_SwitchSemi" )
	self:SetNextSecondaryFire( CurTime() + .2 )
end
