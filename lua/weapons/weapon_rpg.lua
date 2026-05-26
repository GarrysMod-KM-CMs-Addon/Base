DEFINE_BASECLASS "BaseProjectileWeapon"

SWEP.Category = "Rocket Propelled Grenades"
SWEP.PrintName = "#weapon_rpg"

SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Anti-Tank 4."
SWEP.ViewModel = Model "models/weapons/c_rpg.mdl"
SWEP.WorldModel = Model "models/weapons/w_rocket_launcher.mdl" // NOT w_rpg?! WHAT THE HELL?!
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.m_bAllowOneInTheChamber = false // DUH!
SWEP.Primary.Ammo = "RPG_Round"
SWEP.Primary_flDelay = 2
SWEP.Primary_sProjectile = "rpg_missile"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 4
SWEP.ViewModelFOV = 54
SWEP.flCoverY = -4
SWEP.Crosshair = "Open"
SWEP.flRecoil = 14
SWEP.flViewModelX = -9
SWEP.flViewModelY = -5
SWEP.vSprint = Vector( -12, 1.358, -4 )
SWEP.vViewModelAim = Vector( -15, -17 - SWEP.flViewModelY, -3.1 )
SWEP.Primary_flSpreadX = .05
SWEP.Primary_flSpreadY = .05
SWEP.bSpecial = true
SWEP.bAllowReloadingDuringPrimaryFire = true

if CLIENT then
	local math_abs = math.abs
	local math_sin = math.sin
	local RealTime = RealTime
	VIEWMODEL_CAMERA_ANIMATIONS[ "models/weapons/c_rpg.mdl" ] = {
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
end

sound.Add {
	name = "RPG_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "weapons/ar2/npc_ar2_altfire.wav"
}

SWEP.sSound = "RPG_Shot"
SWEP.sHoldType = "RPG"
