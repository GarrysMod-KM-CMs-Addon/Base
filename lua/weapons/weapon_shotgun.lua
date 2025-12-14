DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Shotguns"
SWEP.PrintName = "#weapon_shotgun"

SWEP.Instructions = "Primary to shoot, secondary to switch semi-automatic and pump-action, reload to pump (when in pump-action)."
SWEP.Purpose = "Franchi Special Purpose Automatic Shotgun 12."
SWEP.ViewModel = Model "models/weapons/c_shotgun.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_shotgun.mdl"
SWEP.Primary.ClipSize = 9
SWEP.Primary.DefaultClip = 9
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary_iNum = 11
SWEP.Primary_flSpreadX = .042
SWEP.Primary_flSpreadY = .042
SWEP.Primary_flDelay = .2
SWEP.Primary_flPumpDelay = .4
SWEP.Primary_flDamage = 40
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
SWEP.flSideWaysRecoilMin = -.33
SWEP.flSideWaysRecoilMax = .33
SWEP.flRecoil = 5
SWEP.flAimRoll = 22.5
SWEP.flCrosshairInAccuracy = .01

SWEP.bSemi = true
SWEP.bPumped = true
SWEP.bWantsToPump = false
SWEP.flPumpTime = 0

SWEP.flViewModelX = -6.5
SWEP.flViewModelY = -6.5
SWEP.flViewModelZ = 2.5

SWEP.vSprintArm = Vector( 1.358, -6.228, -.94 )
SWEP.vViewModelAim = Vector( -8.955 - SWEP.flViewModelY, -10 - SWEP.flViewModelX, 4.2 - SWEP.flViewModelZ )

function SWEP:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Reloading" )
	self:NetworkVar( "Float", 0, "ReloadTimer" )
	local f = BaseClass.SetupDataTables
	if f then return f( self ) end
end

function SWEP:Reload()
	if self:GetReloading() || CurTime() <= self.flPumpTime then return end
	if !self.bSemi && !self.bPumped then
		self.bWantsToPump = true
		self.flPumpTime = CurTime() + self.Primary_flPumpDelay
		return
	end
	if self:Clip1() < self.Primary.ClipSize && ( !self:GetOwner().GetAmmoCount || self:GetOwner():GetAmmoCount( self.Primary.Ammo ) > 0 ) then self:StartReload() end
end

function SWEP:StartReload()
	if self:GetReloading() then return end
	local owner = self:GetOwner()
	if !IsValid( owner ) || owner.GetAmmoCount && owner:GetAmmoCount( self.Primary.Ammo ) <= 0 || self:Clip1() >= self.Primary.ClipSize || !self.bSemi && !self.bPumped then return end
	self:SendWeaponAnim( ACT_SHOTGUN_RELOAD_START )
	self:SetReloadTimer( CurTime() + self:SequenceDuration() )
	self:SetReloading( true )
	return true
end

sound.Add {
	name = "SPAS12_Reload",
	channel = CHAN_AUTO,
	level = 60,
	pitch = { 90, 110 },
	sound = {
		"weapons/shotgun/shotgun_reload1.wav",
		"weapons/shotgun/shotgun_reload2.wav",
		"weapons/shotgun/shotgun_reload3.wav"
	}
}

function SWEP:PerformReload()
	local owner = self:GetOwner()
	if !IsValid( owner ) || owner.GetAmmoCount && owner:GetAmmoCount( self.Primary.Ammo ) <= 0 then return end
	if self:Clip1() >= self.Primary.ClipSize then return end
	self:EmitSound "SPAS12_Reload"
	if owner.RemoveAmmo then owner:RemoveAmmo( 1, self.Primary.Ammo, false ) end
	self:SetClip1( self:Clip1() + 1 )
	self:SendWeaponAnim( ACT_VM_RELOAD )
	local t = CurTime() + self:SequenceDuration()
	self:SetNextPrimaryFire( t )
	self:SetReloadTimer( t )
	self.bPumped = true
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
	if self.bPumped then self.bWantsToPump = nil end
	if self.bWantsToPump then
		if CurTime() > self:GetNextPrimaryFire() then
			self:SendWeaponAnim( ACT_SHOTGUN_PUMP )
			local t = CurTime() + self.Primary_flPumpDelay
			self.flPumpTime = t
			self:SetNextPrimaryFire( t )
			self.bPumped = true
			self:EmitSound "SPAS12_Pump"
		end
		return
	end
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
	name = "SPAS12_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "weapons/shotgun/shotgun_fire6.wav"
}

sound.Add {
	name = "SPAS12_Pump",
	channel = CHAN_AUTO, // CHAN_WEAPON changed so that it doesn't interrupt the firing sound
	level = 150,
	pitch = { 90, 110 },
	sound = "weapons/shotgun/shotgun_cock.wav"
}

sound.Add {
	name = "SPAS12_DryFire",
	channel = CHAN_AUTO,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/shotgun/shotgun_empty.wav"
}

SWEP.Primary_DryFireSound = "SPAS12_DryFire"

function SWEP:Initialize() self:SetHoldType "Shotgun" end

function SWEP:PrimaryAttack()
	if self.bSemi then
		if !self:CanPrimaryAttack() then return end
		self.bPumped = true
	else
		if self.bPumped then
			if !self:CanPrimaryAttack() then return end
			self.bPumped = nil
		else self:EmitSound "SPAS12_DryFire" return end
	end
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
	self:EmitSound "SPAS12_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

sound.Add {
	name = "SPAS12_SwitchPump",
	channel = CHAN_AUTO,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_single.wav"
}
sound.Add {
	name = "SPAS12_SwitchSemi",
	channel = CHAN_AUTO,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_burst.wav"
}

function SWEP:SecondaryAttack()
	if CurTime() <= self:GetNextSecondaryFire() then return end
	local b = !self.bSemi
	if b && !self.bPumped then return end
	self.bSemi = b
	self:EmitSound( b && "SPAS12_SwitchSemi" || "SPAS12_SwitchPump" )
	self:SetNextSecondaryFire( CurTime() + .2 )
end
