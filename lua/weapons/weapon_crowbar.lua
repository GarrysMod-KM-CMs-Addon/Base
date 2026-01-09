DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Melees"
SWEP.PrintName = "#weapon_crowbar"

SWEP.Instructions = "Primary to swing."
SWEP.Purpose = "A Crowbar. Unknown manufacturer."
SWEP.ViewModel = Model "models/weapons/c_crowbar.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_crowbar.mdl"
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Spawnable = true
SWEP.Slot = 0
SWEP.ViewModelFOV = 54
SWEP.bPistolSprint = true
SWEP.bDontDrawAmmo = true
SWEP.Crosshair = "Special"

sound.Add {
	name = "CrowbarSwing",
	channel = CHAN_WEAPON,
	level = 90,
	pitch = { 90, 110 },
	sound = "weapons/iceaxe/iceaxe_swing1.wav"
}

function SWEP:Initialize() self:SetHoldType "Melee" end

SWEP.Melee_flRangeAdd = 32

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	self:FireBullets {
		Attacker = owner,
		Src = owner:GetShootPos(),
		Dir = self:GetAimVector(),
		Tracer = 0,
		Damage = ( owner.GAME_flHandDamage || 40 ) * 14,
		Distance = ( owner.GAME_flReach || 64 ) + self.Melee_flRangeAdd
	}
	owner:SetAnimation( PLAYER_ATTACK1 )
	self:SendWeaponAnim( ACT_VM_MISSCENTER )
	self:EmitSound "CrowbarSwing"
	self:TakePrimaryAmmo( 0 )
	self:SetNextPrimaryFire( CurTime() + .4 )
end

function SWEP:Reload() end

if !SERVER then return end

local CAP = CAP_INNATE_MELEE_ATTACK1 + CAP_WEAPON_MELEE_ATTACK1
function SWEP:GetCapabilities() return CAP end
