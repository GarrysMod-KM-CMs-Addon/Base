DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Shotguns"
SWEP.PrintName = "#BenelliM4Super90"
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Benelli M4 Super 90."
if IsMounted "left4dead2" then
	function SWEP:GetDrawActivity() return ACT_VM_DEPLOY end
	SWEP.__VIEWMODEL_FULLY_MODELED__ = true
	SWEP.ViewModel = Model "models/v_models/v_autoshotgun.mdl"
	// I know I'm not supposed to do this (it's one of my core philosophies to never
	// touch FoV and instead use flViewModelX), but oh well, this looks way better
	SWEP.ViewModelFOV = 51
else
	SWEP.flViewModelY = -4
	SWEP.flViewModelZ = .5
	SWEP.ViewModel = Model "models/weapons/cstrike/c_shot_xm1014.mdl"
end
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
SWEP.Primary_flDamage = 20
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 3
SWEP.DrawAmmo = true
SWEP.Crosshair = "Rifle"
SWEP.flRecoil = 6.8
SWEP.flSidewaysRecoilMin = -.45
SWEP.flSidewaysRecoilMax = .45
SWEP.flUpwardsRecoilMin = .6
SWEP.flUpwardsRecoilMax = 1
SWEP.WPN_SHOOT = WPN_SHOTGUN

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
	if owner.RemoveAmmo then owner:RemoveAmmo( 1, self.Primary.Ammo, false ) end
	self:SetClip1( self:Clip1() + 1 )
	self:SendWeaponAnim( ACT_VM_RELOAD )
	local f = self:SequenceDuration()
	self:SetReloadTimer( CurTime() + f )
	if owner:IsPlayer() then self:CallOnClient( "ReloadTime", f + .1 ) end
	self:SetReloading( true )
	return true
end

function SWEP:PerformReload()
	local owner = self:GetOwner()
	if !IsValid( owner ) || owner.GetAmmoCount && owner:GetAmmoCount( self.Primary.Ammo ) <= 0 then return end
	if self:Clip1() >= self.Primary.ClipSize then return end
	if owner.RemoveAmmo then owner:RemoveAmmo( 1, self.Primary.Ammo, false ) end
	self:SetClip1( self:Clip1() + 1 )
	self:SendWeaponAnim( 2047 )
	local f = self:SequenceDuration()
	if owner:IsPlayer() then self:CallOnClient( "ReloadTime", f + .1 ) end
	local t = CurTime() + f
	self:SetNextPrimaryFire( t )
	self:SetReloadTimer( t )
end

function SWEP:FinishReload()
	self:SetReloading( false )
	self:SendWeaponAnim( ACT_VM_RELOAD_END )
	local f = self:SequenceDuration()
	if self:GetOwner():IsPlayer() then self:CallOnClient( "ReloadTime", f + .1 ) end
	local t = CurTime() + f
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

SWEP.sHoldType = "Shotgun"

sound.Add {
	name = "BenelliM4Super90Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = 100,
	sound = "^BenelliM4Super90Shot.wav"
}

SWEP.sSound = "BenelliM4Super90Shot"

sound.Add {
	name = "BenelliM4Super90ShotAuto",
	channel = CHAN_AUTO,
	level = 150,
	pitch = 100,
	sound = "^BenelliM4Super90Shot.wav"
}

SWEP.sSoundAuto = "BenelliM4Super90ShotAuto"

if SERVER then return end

local math_abs = math.abs
local math_sin = math.sin
local RealTime = RealTime
VIEWMODEL_CAMERA_ANIMATIONS[ "models/v_models/v_autoshotgun.mdl" ] = {
	// Raise and load a shell
	reload = function( pViewModel, vTarget, vTargetAngle )
		local flCycle = pViewModel:GetCycle()
		if flCycle < .4 then
			vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 1
		elseif flCycle < .8 then
			vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 1
		end
		vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + math_abs( math_sin( RealTime() * 6 ) ) * 2
	end,
	// Insert shell
	reload_loop = function( pViewModel, vTarget, vTargetAngle )
		local flCycle = pViewModel:GetCycle()
		if flCycle < .33 then
			vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - .33
		elseif flCycle < .66 then
			vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + .66
		end
		vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + math_abs( math_sin( RealTime() * 6 ) ) * 2
	end,
	// Lower
	reload_end = function( pViewModel, vTarget, vTargetAngle )
		local flCycle = pViewModel:GetCycle()
		if flCycle < .33 then
			vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
		elseif flCycle < .66 then
			vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 2
		end
		if flCycle < .66 then
			vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + math_abs( math_sin( RealTime() * 6 ) ) * 2
		end
	end,
}
