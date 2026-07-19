DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Pistols"
SWEP.PrintName = "#DesertEagle"
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Desert Eagle, .50 Action Express."
SWEP.Primary.ClipSize = 7
SWEP.Primary.DefaultClip = 7
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"
SWEP.Primary_flSpreadX = .0094
SWEP.Primary_flSpreadY = .0094
SWEP.Primary_flDamage = 40
SWEP.Primary_flDelay = .06
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.Crosshair = "Revolver"
SWEP.sAimSound = "BaseWeapon_Aim_Pistol"
SWEP.WPN_SPRINT = WPN_PISTOL
SWEP.WPN_SHOOT = WPN_PISTOL
SWEP.flSidewaysRecoilMin = -.33
SWEP.flSidewaysRecoilMax = .33
SWEP.flRecoil = 5
SWEP.sHoldType = "Pistol"

if file.Exists( "models/weapons/FC3W/FC3d50w.mdl", "GAME" ) then
	SWEP.ViewModelFOV = 45
	SWEP.ViewModel = "models/weapons/c_d50.mdl"
	SWEP.WorldModel = "models/weapons/FC3W/FC3d50w.mdl"
	function SWEP:GetReloadActivity( bOneInTheChamber ) return bOneInTheChamber && ACT_VM_RELOAD || ACT_VM_RELOAD_EMPTY end
	SWEP.flViewModelZ = -.5
	SWEP.vViewModelAim = Vector( -4, -3.55, .31 - SWEP.flViewModelZ )
	SWEP.vViewModelAimAngle = Vector( .2, -0.35, -2.452 )
	sound.Add {
		name = "Weapon_Cd50.MagIn",
		channel = CHAN_ITEM,
		level = 80,
		sound = "DesertEagle/MagIn.wav"
	}
	sound.Add {
		name = "Weapon_Cd50.MagOut",
		channel = CHAN_ITEM,
		level = 80,
		sound = "DesertEagle/MagOut.wav"
	}
	sound.Add {
		name = "Weapon_Cd50.Bolt",
		channel = CHAN_ITEM,
		level = 80,
		sound = "DesertEagle/Bolt.wav"
	}
	function SWEP:DrawWorldModel()
		self:DrewWorldModelAndUsedRenderOverrides()
		local pOwner = self:GetOwner()
		if !IsValid( pOwner ) then self:SetRenderOrigin( nil ) self:SetRenderAngles( nil ) self:DrawModel() return end
		local tHand = pOwner:GetAttachment( pOwner:LookupAttachment "anim_attachment_rh" )
		local ang = tHand.Ang
		local vOffset = ang:Right() * .55 + ang:Forward() * -2 + ang:Up() * -.5
		ang:RotateAroundAxis( ang:Forward(), 10 )
		self:SetRenderOrigin( tHand.Pos + vOffset )
		self:SetRenderAngles( ang )
		self:DrawModel()
	end

	if CLIENT then
		local math_abs = math.abs
		local math_sin = math.sin
		local RealTime = RealTime
		VIEWMODEL_CAMERA_ANIMATIONS[ "models/weapons/c_d50.mdl" ] = {
			reload = function( pViewModel, vTarget, vTargetAngle )
				local flCycle = pViewModel:GetCycle()
				if flCycle < .25 then
					vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
				elseif flCycle < .5 then
					vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 1
				elseif flCycle > .5 && flCycle < .8 then
					vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
				end
				if flCycle > .68 && flCycle < .78 then vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2 end
				if flCycle < .66 then
					vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + math_abs( math_sin( RealTime() * 6 ) ) * 2
				end
			end,
			reload_E = function( pViewModel, vTarget, vTargetAngle )
				local flCycle = pViewModel:GetCycle()
				if flCycle < .25 then
					vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
				elseif flCycle < .5 then
					vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 1
				elseif flCycle > .5 && flCycle < .8 then
					vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
				end
				if flCycle > .68 && flCycle < .78 then vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2 end
				if flCycle < .66 then
					vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + math_abs( math_sin( RealTime() * 6 ) ) * 2
				end
			end
		}
	end
else
	SWEP.ViewModel = Model "models/weapons/cstrike/c_pist_deagle.mdl"
	SWEP.WorldModel = Model "models/weapons/w_pist_deagle.mdl"
	SWEP.flViewModelX = -8
	SWEP.flViewModelY = -2
	SWEP.flViewModelZ = 1
	SWEP.vViewModelAim = Vector( -12 - SWEP.flViewModelX, -6.36 - SWEP.flViewModelY, 2.18 - SWEP.flViewModelZ )
end

SWEP.__VIEWMODEL_FULLY_MODELED__ = true

sound.Add {
	name = "DesertEagle_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^DesertEagleShot.wav"
}
SWEP.sSound = "DesertEagle_Shot"

sound.Add {
	name = "DesertEagle_ShotAuto",
	channel = CHAN_AUTO,
	level = 150,
	pitch = { 90, 110 },
	sound = "^DesertEagleShot.wav"
}
SWEP.sSoundAuto = "DesertEagle_ShotAuto"
