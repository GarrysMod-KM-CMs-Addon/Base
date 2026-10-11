DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Revolvers"
SWEP.PrintName = "#weapon_357"
SWEP.Purpose = "Colt Python."
SWEP.ViewModel = Model "models/weapons/c_357.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_357.mdl"
SWEP.Primary.ClipSize = 6 // Duh
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Automatic = false
SWEP.m_bAllowOneInTheChamber = false
SWEP.Primary.Ammo = "357"
SWEP.Primary_flSpreadX = .0084
SWEP.Primary_flSpreadY = .0084
SWEP.Primary_flDamage = 80
SWEP.Primary_flDelay = 60 / 400
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.vViewModelAim = Vector( 0, -4.71, .67 )
SWEP.vViewModelAimAngle = Vector( 0, -.2 )
SWEP.flIronsightCloseness = 4
SWEP.Crosshair = "Revolver"
SWEP.WPN_SPRINT = WPN_PISTOL
SWEP.WPN_SHOOT = WPN_PISTOL
SWEP.flRecoil = 3
SWEP.flSidewaysRecoilMin = -.2
SWEP.flSidewaysRecoilMax = .2
SWEP.flUpwardsRecoilMin = .4
SWEP.flUpwardsRecoilMax = .85
SWEP.sAimSound = "BaseWeapon_Aim_Pistol"

sound.Add {
	name = "ColtPythonShot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^ColtPythonShot.wav"
}
SWEP.sSound = "ColtPythonShot"

SWEP.sHoldType = "Revolver"

if CLIENT then
	local abs = math.abs
	local sin = math.sin
	local RealTime = RealTime

	VIEWMODEL_CAMERA_ANIMATIONS[ "models/weapons/c_357.mdl" ] = {
		draw = function( pViewModel, vTarget, vTargetAngle )
			local flCycle = pViewModel:GetCycle()

			if flCycle < .2 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 2
			elseif flCycle < .4 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			end

			if flCycle > .2 && flCycle < .4 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 1
				vTargetAngle[ 2 ] = vTargetAngle[ 2 ] + 1
			elseif flCycle >= .4 && flCycle < .6 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 1
				vTargetAngle[ 2 ] = vTargetAngle[ 2 ] - 1
			end

			if flCycle < .8 then
				vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + sin( RealTime() * 8 )
			end
		end,

		reload = function( pViewModel, vTarget, vTargetAngle )
			local flCycle = pViewModel:GetCycle()

			if flCycle > .26 && flCycle < .28 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 4
				vTargetAngle[ 2 ] = vTargetAngle[ 2 ] + 2.5
			elseif flCycle >= .4 && flCycle < .5 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + sin( RealTime() * 8 ) * 3
			end

			if flCycle > .6 && flCycle < .67 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 2
				vTargetAngle[ 2 ] = vTargetAngle[ 2 ] + 2
			elseif flCycle >= .67 && flCycle < .7 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 6
				vTargetAngle[ 2 ] = vTargetAngle[ 2 ] - 6
			end

			if flCycle > .8 && flCycle < .83 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - sin( RealTime() * 4 ) * 3
			elseif flCycle >= .83 && flCycle < .95 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + sin( RealTime() * 8 ) * 3
			end

			if flCycle < .9 then
				vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + abs( sin( RealTime() * 4 ) ) * 2
			end
		end
	}
end
