DEFINE_BASECLASS "BaseWeapon"

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
SWEP.Primary_flDamage = 40
SWEP.Primary_flDelay = .04285714285
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.Crosshair = "Pistol"
SWEP.sAimSound = "BaseWeapon_Aim_Pistol"
SWEP.bPistolSprint = true
SWEP.flViewModelX = -4
SWEP.flViewModelY = -2
SWEP.flViewModelZ = 1
SWEP.vViewModelAim = Vector( -5.79 - SWEP.flViewModelY, -8 - SWEP.flViewModelX, 2.99 - SWEP.flViewModelZ )

sound.Add {
	name = "Glock18_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^Glock18Shot.wav"
}

function SWEP:Initialize() self:SetHoldType "Pistol" end

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
	self:EmitSound "Glock18_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

sound.Add {
	name = "Glock18_SwitchSemi",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_single.wav"
}
sound.Add {
	name = "Glock18_SwitchAuto",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_burst.wav"
}
function SWEP:SecondaryAttack()
	if CurTime() <= self:GetNextSecondaryFire() then return end
	local b = !self.Primary.Automatic
	self.Primary.Automatic = b
	self:EmitSound( b && "Glock18_SwitchAuto" || "Glock18_SwitchSemi" )
	self:SetNextSecondaryFire( CurTime() + .2 )
end
