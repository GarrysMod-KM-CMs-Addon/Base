// I am too lazy to implement this. We'll need BaseProjectileWeapon first!

DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Rocket Propelled Grenades"
SWEP.PrintName = "#weapon_rpg"

SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "A Hollywood Anti-Tank 4 prop." // "Anti-Tank 4."
SWEP.ViewModel = Model "models/weapons/c_rpg.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_rpg.mdl"
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

sound.Add {
	name = "RPG_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "weapons/ar2/npc_ar2_altfire.wav"
}

function SWEP:Initialize() self:SetHoldType "RPG" end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	self:ShootEffects()
	owner:SetAnimation( PLAYER_ATTACK1 )
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util.Effect( "MuzzleFlash", ed )
	self:EmitSound "RPG_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end
