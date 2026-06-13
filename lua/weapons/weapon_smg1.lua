DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Submachine Guns"
SWEP.PrintName = "#weapon_smg1"
SWEP.Instructions = "Primary to shoot. Secondary to switch fully-automatic and semi-automatic."
SWEP.Purpose = "Heckler & Koch MP7."
SWEP.ViewModel = Model "models/weapons/c_smg1.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_smg1.mdl"
SWEP.Primary.ClipSize = 40
SWEP.Primary.DefaultClip = 40
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flSpreadX = .0083
SWEP.Primary_flSpreadY = .0083
SWEP.Primary_flDelay = .06315789473
SWEP.Primary_flDamage = 20
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.vViewModelAim = Vector( -4, -6.43, 1.03 )
SWEP.Crosshair = "SubMachineGun"
SWEP.sAimSound = "BaseWeapon_Aim_SubMachineGun"
SWEP.flRecoil = .9
SWEP.flSideWaysRecoilMin = -.22
SWEP.flSideWaysRecoilMax = .22
SWEP.flRecoilGrowMin = .55
SWEP.flRecoilGrowMax = .95
SWEP.flViewModelX = 2

if CLIENT then
	local math_abs = math.abs
	local math_sin = math.sin
	local RealTime = RealTime
	VIEWMODEL_CAMERA_ANIMATIONS[ "models/weapons/c_smg1.mdl" ] = {
		reload = function( pViewModel, vTarget, vTargetAngle )
			local flCycle = pViewModel:GetCycle()
			if flCycle < .25 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			elseif flCycle < .5 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 1
			elseif flCycle > .5 && flCycle < .8 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			end
			if flCycle > .64 && flCycle < .74 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			end
			if flCycle < .66 then
				vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + math_abs( math_sin( RealTime() * 6 ) ) * 2
			end
		end
	}

	function SWEP:ReloadSoundInternal() self:EmitSound "MP7Reload" end
end

local IsValid = IsValid

function SWEP:ReloadEffects()
	local pOwner = self:GetOwner()
	if IsValid( pOwner ) && pOwner:IsPlayer() then self:CallOnClient "ReloadSoundInternal" end
end

sound.Add {
	name = "MP7Reload",
	channel = CHAN_ITEM,
	level = 60,
	pitch = 100,
	sound = "weapons/smg1/smg1_reload.wav"
}

sound.Add {
	name = "MP7Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^MP7Shot.wav"
}
SWEP.sSound = "MP7Shot"

SWEP.sHoldType = "SMG"

sound.Add {
	name = "MP7SwitchSemi",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_single.wav"
}
sound.Add {
	name = "MP7SwitchAuto",
	channel = CHAN_WEAPON,
	level = 60,
	pitch = { 90, 110 },
	sound = "weapons/smg1/switch_burst.wav"
}
function SWEP:SecondaryAttack()
	if CurTime() <= self:GetNextSecondaryFire() then return end
	local b = !self.Primary.Automatic
	self.Primary.Automatic = b
	self:EmitSound( b && "MP7SwitchAuto" || "MP7SwitchSemi" )
	self:SetNextSecondaryFire( CurTime() + .2 )
end
