DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Light Machine Guns"
SWEP.PrintName = "#M249SAW"

SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "M249 Squad Automatic Weapon."
SWEP.ViewModel = Model "models/weapons/cstrike/c_mach_m249para.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_mach_m249para.mdl"
SWEP.Primary.ClipSize = 200
SWEP.Primary.DefaultClip = 200
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flDelay = .05
SWEP.Primary_flSpreadX = .0087
SWEP.Primary_flSpreadY = .0087
SWEP.Primary_flDamage = 80
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.flZoomSpeedIn = 4
SWEP.flZoomSpeedOut = 1
SWEP.vViewModelAim = Vector( 0, -5.95, 2.35 )
SWEP.Crosshair = "Rifle"
SWEP.flAimShoot = 4

sound.Add {
	name = "M249SAW_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^M249SAWShot.wav"
}

function SWEP:Initialize() self:SetHoldType "AR2" end

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
	self:EmitSound "M249SAW_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

list.Add( "NPCUsableWeapons", { class = "M249SAW", title = "#M249SAW", category = SWEP.Category } )
