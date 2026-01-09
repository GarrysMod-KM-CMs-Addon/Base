DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Revolvers"
SWEP.PrintName = "#weapon_357"

SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Colt Python."
SWEP.ViewModel = Model "models/weapons/c_357.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_357.mdl"
SWEP.Primary.ClipSize = 6 // Duh
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"
SWEP.Primary_flSpreadX = .0084
SWEP.Primary_flSpreadY = .0084
SWEP.Primary_flDamage = 82
SWEP.Primary_flDelay = .25
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.vViewModelAim = Vector( 0, -4.62, .67 )
SWEP.ViewModelFOV = 54
SWEP.Crosshair = "Revolver"
SWEP.bPistolSprint = true
SWEP.flRecoil = 2.9
SWEP.flSideWaysRecoilMin = -.35
SWEP.flSideWaysRecoilMax = .35
SWEP.flRecoilGrowMin = -.4
SWEP.flRecoilGrowMax = -.85

sound.Add {
	name = "ColyPython_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^ColtPythonShot.wav"
}

function SWEP:Initialize() self:SetHoldType "Revolver" end

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
	self:EmitSound "ColyPython_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end
