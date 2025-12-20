DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Shotguns"
SWEP.PrintName = "#BenelliM4Super90"
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Benelli M4 Super 90, a.k.a XM1014."
SWEP.ViewModel = Model "models/weapons/cstrike/c_shot_xm1014.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_shot_xm1014.mdl"
SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary_iNum = 8
SWEP.Primary_flSpreadX = .036
SWEP.Primary_flSpreadY = .036
SWEP.Primary_flDelay = .16
SWEP.Primary_flDamage = 60
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 3
SWEP.DrawAmmo = true
SWEP.Crosshair = "Shotgun"
SWEP.vSprintArm = Vector( 1.358, -6.228, -.94 )
SWEP.flSideWaysRecoilMin = -.33
SWEP.flSideWaysRecoilMax = .33
SWEP.flRecoil = 5

SWEP.ViewModelFOV = 54
SWEP.flViewModelY = -4
SWEP.flViewModelZ = .5

function SWEP:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Reloading" )
	self:NetworkVar( "Float", 0, "ReloadTimer" )
	local f = BaseClass.SetupDataTables
	if f then return f( self ) end
end

function SWEP:Reload()
	if self:GetReloading() then return end
	if self:Clip1() < self.Primary.ClipSize && ( !self:GetOwner().GetAmmoCount || self:GetOwner():GetAmmoCount( self.Primary.Ammo ) > 0 ) then self:StartReload() end
end

function SWEP:StartReload()
	if self:GetReloading() then return end
	local owner = self:GetOwner()
	if !IsValid( owner ) || owner.GetAmmoCount && owner:GetAmmoCount( self.Primary.Ammo ) <= 0 || self:Clip1() >= self.Primary.ClipSize then return end
	self:SendWeaponAnim( ACT_SHOTGUN_RELOAD_START )
	self:SetReloadTimer( CurTime() + self:SequenceDuration() )
	self:SetReloading( true )
	return true
end

function SWEP:PerformReload()
	local owner = self:GetOwner()
	if !IsValid( owner ) || owner.GetAmmoCount && owner:GetAmmoCount( self.Primary.Ammo ) <= 0 then return end
	if self:Clip1() >= self.Primary.ClipSize then return end
	if owner.RemoveAmmo then owner:RemoveAmmo( 1, self.Primary.Ammo, false ) end
	self:SetClip1( self:Clip1() + 1 )
	self:SendWeaponAnim( ACT_VM_RELOAD )
	local t = CurTime() + self:SequenceDuration()
	self:SetNextPrimaryFire( t )
	self:SetReloadTimer( t )
end

function SWEP:FinishReload()
	self:SetReloading( false )
	self:SendWeaponAnim( ACT_SHOTGUN_RELOAD_FINISH )
	local t = CurTime() + self:SequenceDuration()
	self:SetNextPrimaryFire( t )
	self:SetReloadTimer( t )
end

function SWEP:Think()
	BaseClass.Think( self )
	if self:GetReloading() then
		local owner = self:GetOwner()
		/*// Instantly snap out of reloading
		if owner:KeyDown( IN_ATTACK ) then
			self:SetReloading( false )
			local t = CurTime()
			self:SetNextPrimaryFire( t )
			self:SetReloadTimer( t )*/
		if owner:KeyDown( IN_ATTACK ) then self:FinishReload()
		elseif self:GetReloadTimer() <= CurTime() then
			if owner.GetAmmoCount && owner:GetAmmoCount( self.Primary.Ammo ) <= 0 then self:FinishReload()
			elseif self:Clip1() < self.Primary.ClipSize then self:PerformReload()
			else self:FinishReload() end
		end
	end
end

function SWEP:Deploy()
	self:SetReloading( false )
	self:SetReloadTimer( 0 )
	return BaseClass.Deploy( self )
end

sound.Add {
	name = "BenelliM4Super90_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^BenelliM4Super90Shot.wav"
}

function SWEP:Initialize() self:SetHoldType "Shotgun" end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	self:FireBullets {
		Attacker = owner,
		Src = owner:GetShootPos(),
		Dir = self:GetAimVector(),
		Tracer = 1,
		Num = self.Primary_iNum,
		Spread = Vector( self.Primary_flSpreadX, self.Primary_flSpreadY ),
		Damage = self.Primary_flDamage,
		Force = 2
	}
	self:ShootEffects()
	owner:SetAnimation( PLAYER_ATTACK1 )
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util.Effect( "MuzzleFlash", ed )
	self:EmitSound "BenelliM4Super90_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end
