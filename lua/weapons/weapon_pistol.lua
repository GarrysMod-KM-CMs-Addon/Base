DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Pistols"
SWEP.PrintName = "#weapon_pistol"

SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Universal Self-Loading Pistol, Match Variant."
SWEP.ViewModel = Model "models/weapons/c_pistol.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_pistol.mdl"
SWEP.Primary.ClipSize = 15
SWEP.Primary.DefaultClip = 15
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"
SWEP.Primary_flSpreadX = .0094
SWEP.Primary_flSpreadY = .0094
SWEP.Primary_flDamage = 30
SWEP.Primary_flDelay = .08571428571
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.flViewModelX = 2
SWEP.flViewModelY = -2
SWEP.flViewModelZ = .5
SWEP.vViewModelAim = Vector( -12 - SWEP.flViewModelX, -5.71 - SWEP.flViewModelY, 3.145 - SWEP.flViewModelZ )
SWEP.vViewModelAimAngle = Vector( 0, -1.35, 0 )
SWEP.Crosshair = "Pistol"
SWEP.sAimSound = "BaseWeapon_Aim_Pistol"
SWEP.WPN_SPRINT = WPN_PISTOL
SWEP.WPN_SHOOT = WPN_PISTOL
SWEP.flRecoil = 1.6
SWEP.flSidewaysRecoilMin = -.28
SWEP.flSidewaysRecoilMax = .28
SWEP.flUpwardsRecoilMin = .5
SWEP.flUpwardsRecoilMax = .9

if CLIENT then
	local math_abs = math.abs
	local math_sin = math.sin
	local RealTime = RealTime
	VIEWMODEL_CAMERA_ANIMATIONS[ "models/weapons/c_pistol.mdl" ] = {
		reload = function( pViewModel, vTarget, vTargetAngle )
			local flCycle = pViewModel:GetCycle()
			if flCycle < .21 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			elseif flCycle < .4 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 1
			elseif flCycle > .4 && flCycle < .8 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			end
			if flCycle > .68 && flCycle < .78 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			end
			if flCycle < .66 then
				vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + math_abs( math_sin( RealTime() * 6 ) ) * 2
			end
		end
	}

	function SWEP:ReloadSoundInternal() self:EmitSound "USPMatchReload" end
end

local IsValid = IsValid

function SWEP:ReloadEffects()
	local pOwner = self:GetOwner()
	if IsValid( pOwner ) && pOwner:IsPlayer() then self:CallOnClient "ReloadSoundInternal" end
end

sound.Add {
	name = "USPMatchReload",
	channel = CHAN_ITEM,
	level = 60,
	pitch = 100,
	sound = "weapons/pistol/pistol_reload1.wav"
}

sound.Add {
	name = "USPMatchShot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "weapons/pistol/pistol_fire2.wav"
}
SWEP.sSound = "USPMatchShot"

SWEP.sHoldType = "Pistol"
