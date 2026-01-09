DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Submachine Guns"
SWEP.PrintName = "#UMP45"

SWEP.Instructions = "Primary to shoot."
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
SWEP.Primary_flDamage = 80
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.vSprintArm = Vector( -8.228, 1.358, -.94 )
SWEP.Crosshair = "SubMachineGun"

sound.Add {
	name = "UMP45_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^UMP45Shot.wav"
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
	self:EmitSound "UMP45_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

list.Add( "NPCUsableWeapons", { class = "UMP45", title = "#UMP45", category = SWEP.Category } )
