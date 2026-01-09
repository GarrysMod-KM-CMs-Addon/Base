DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Assault Rifles"
SWEP.PrintName = "#FAMAS"
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Fusil d'Assaut de la Manufacture d'Armes de Saint-Étienne, Assault rifle from the Saint-Étienne Weapon Factory."
SWEP.ViewModel = Model "models/weapons/cstrike/c_rif_famas.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_rif_famas.mdl"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flDelay = .054
SWEP.Primary_flSpreadX = .0058
SWEP.Primary_flSpreadY = .0058
SWEP.Primary_flDamage = 80
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.vViewModelAim = Vector( 0, -6.2, 1 )
SWEP.Crosshair = "Rifle"

sound.Add {
	name = "FAMAS_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^FAMASShot.wav"
}
sound.Add {
	name = "FAMAS_Shot_Auto",
	channel = CHAN_AUTO,
	level = 150,
	pitch = { 90, 110 },
	sound = "^FAMASShot.wav"
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
	self:EmitSound "FAMAS_Shot"
	self:EmitSound "FAMAS_Shot_Auto"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

list.Add( "NPCUsableWeapons", { class = "FAMAS", title = "#FAMAS", category = SWEP.Category } )
