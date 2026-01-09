DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Assault Rifles"
SWEP.PrintName = "#AK47"
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Автомат Калашникова, also known as the AK-47, with the AK standing for its name, and the 47 being the year it was designed in."
SWEP.ViewModel = Model( IsMounted "left4dead2" && "models/v_models/v_rifle_ak47.mdl" || "models/weapons/cstrike/c_rif_ak47.mdl" )
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_rif_ak47.mdl"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flDelay = .08571428571
SWEP.Primary_flSpreadX = .0073
SWEP.Primary_flSpreadY = .0073
SWEP.Primary_flDamage = 80
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.Crosshair = "Rifle"
SWEP.flRecoil = 1.6
SWEP.flSideWaysRecoilMin = -.34
SWEP.flSideWaysRecoilMax = .34
SWEP.flRecoilGrowMin = -.66
SWEP.flRecoilGrowMax = -1

if !IsMounted "left4dead2" then
	SWEP.flViewModelX = -10
	SWEP.flViewModelY = -3
	SWEP.flViewModelZ = 1.5
	SWEP.vSprintArm = Vector( 1.358 - SWEP.flViewModelX, .228 - SWEP.flViewModelY, .94 - SWEP.flViewModelZ )
	SWEP.vSprintArmAngle = Vector( -10.554, 34.167, -20 )
	SWEP.vViewModelAim = Vector( -12 - SWEP.flViewModelX, -6.61 - SWEP.flViewModelY, 3.4 - SWEP.flViewModelZ )
else
	SWEP.flDrawActivity = ACT_VM_DEPLOY
	SWEP.flAimShoot = 2
	SWEP.__VIEWMODEL_FULLY_MODELED__ = true
	SWEP.flViewModelX = -2
	SWEP.flViewModelY = -4
	SWEP.flViewModelZ = .5
	SWEP.vSprintArm = Vector( -2.358 - SWEP.flViewModelX, .228 - SWEP.flViewModelY, -1.94 - SWEP.flViewModelZ )
	SWEP.vSprintArmAngle = Vector( -10.554, 34.167, -20 )
	SWEP.vViewModelAim = Vector( -8 - SWEP.flViewModelX, -6.8 - SWEP.flViewModelY, 2.1 - SWEP.flViewModelZ )
end

// We have to do this for technical reasons
sound.Add {
	name = "AK47_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^AK47Shot.wav"
}
sound.Add {
	name = "AK47_Shot_Auto",
	channel = CHAN_AUTO,
	level = 150,
	pitch = { 90, 110 },
	sound = "^AK47Shot.wav"
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
	self:EmitSound "AK47_Shot"
	self:EmitSound "AK47_Shot_Auto"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

list.Add( "NPCUsableWeapons", { class = "AK47", title = "#AK47", category = SWEP.Category } )
