local min = math.min
local exp = math.exp

local function FRILerpRate( flRate, flFrameTime ) return min( 1, 1 - exp( -flRate * flFrameTime ) ) end

local CEntity = FindMetaTable "Entity"
local CPlayer = FindMetaTable "Player"

local CEntity_GetTable = CEntity.GetTable
local CEntity_IsOnGround = CEntity.IsOnGround
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local math_Clamp = math.Clamp
local CPlayer_KeyDown = CPlayer.KeyDown
local CEntity_GetVelocity = CEntity.GetVelocity
local CPlayer_GetRunSpeed = CPlayer.GetRunSpeed
local CPlayer_GetWalkSpeed = CPlayer.GetWalkSpeed
local CPlayer_Crouching = CPlayer.Crouching
local CPlayer_InVehicle = CPlayer.InVehicle
local CPlayer_IsSprinting = CPlayer.IsSprinting
local CPlayer_KeyDown = CPlayer.KeyDown

local vFinal, vFinalVel = Vector(), Vector()
local vFinalAngle, vFinalAngleVel = Vector(), Vector()
local vTarget = Vector()
local vTargetAngle = Vector()
local vViewFinal, vViewFinalVel = Vector(), Vector()
local vViewFinalAngle, vViewFinalAngleVel = Vector(), Vector()
local vBezier = Vector()
local vBezierAngle = Vector()
local vInstantTarget, vInstantTargetAngle = Vector(), Vector()
local vFinalRatherQuick, vFinalRatherQuickAngle = Vector(), Vector()
local vFinalRatherQuickVel, vFinalRatherQuickAngleVel = Vector(), Vector()
local vTargetRatherQuick, vTargetRatherQuickAngle = Vector(), Vector()
local vViewFinalRatherQuick, vViewFinalRatherQuickVel = Vector(), Vector()
local vViewFinalRatherQuickAngle, vViewFinalRatherQuickAngleVel = Vector(), Vector()
local vViewTargetRatherQuick, vViewTargetRatherQuickAngle = Vector(), Vector()

local Rand = math.Rand

WEAPON_SWAY = Vector()

local flLandTime, flJumpTime = 0, 0
SWEP.flSwayStabilizer = .415
SWEP.ViewModelFOV = 40
SWEP.flViewModelX = 0
SWEP.flViewModelY = 0
SWEP.flViewModelZ = 0
SWEP.vViewModelAim = false
SWEP.vViewModelAimAngle = false
SWEP.flSwayScale = 50
SWEP.flSway = 4
SWEP.SwayScale = 0
SWEP.BobScale = 0

SWEP.WPN_SHOOT = WPN_RIFLE
SWEP.WPN_COVER = WPN_RIFLE

//	local WEAPON_SPRINT_DEFAULT = Vector( 1.228, 1.358, -.94 )
//	local WEAPON_SPRINT_DEFAULT_ANGLE = Vector( -10.554, 34.167, -20 )

local WEAPON_SPRINT_RIFLE_DEFAULT = Vector( -2, 4, -2 )
local WEAPON_SPRINT_RIFLE_DEFAULT_ANGLE = Vector( -10, 30, -30 )

local WEAPON_SPRINT_RIFLEUP_DEFAULT = Vector( 0, 4, -3 )
local WEAPON_SPRINT_RIFLEUP_DEFAULT_ANGLE = Vector( 2, 35, -10 )

local WEAPON_SPRINT_SNIPER_DEFAULT = Vector( -2, 4, -2 )
local WEAPON_SPRINT_SNIPER_DEFAULT_ANGLE = Vector( -10, 30, -30 )

local WEAPON_SPRINT_PISTOL_DEFAULT = Vector( 0, 2, -4 )
local WEAPON_SPRINT_PISTOL_DEFAULT_ANGLE = Vector( -16, 0, -22.5 )

SWEP.flAimMultiplier = 1
SWEP.flFoV = UNIVERSAL_FOV
SWEP.flLastEyeYaw = 0
SWEP.flBobScale = 1
SWEP.flAimSway = .33
SWEP.flPartiallyModeledAimSway = .33
SNIPER_AIMING_MULTIPLIER = .5
SNIPER_AIMING_SWAY_MULTIPLIER = .5
local SPRING_STIFFNESS_CURRENT, SPRING_DAMPING_CURRENT
local SPRING_CAMERA_STIFFNESS_CURRENT, SPRING_CAMERA_DAMPING_CURRENT
local math_cos = math.cos
local math_sin = math.sin
local math_abs = math.abs
local math_exp = math.exp
local math_AngleDifference = math.AngleDifference
local math_NormalizeAngle = math.NormalizeAngle
local CEntity_WaterLevel = CEntity.WaterLevel
local CPlayer_GetWalkSpeed = CPlayer.GetWalkSpeed
local CPlayer_InVehicle = CPlayer.InVehicle
local bOnGroundLast
local math_Remap = math.Remap
function SWEP:AdjustMouseSensitivity()
	local v = CEntity_GetTable( self ).flFoV
	if v then return v / UNIVERSAL_FOV end
end
local CPlayer_IsSprinting = CPlayer.IsSprinting
local CPlayer_Crouching = CPlayer.Crouching
local CEntity_GetNW2Int = CEntity.GetNW2Int
local function BezierY( f, a, b, c )
	f = f * 3.2258
	return ( 1 - f ) ^ 2 * a + 2 * ( 1 - f ) * f * b + ( f ^ 2 ) * c
end
local util_TraceLine = util.TraceLine
local flLastCalcViewCall = 0

local SPRINT_ANIMATION_CAMERA = {
	[ WPN_PISTOL ] = function( f )
		SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS_CURRENT * 2
		local flBreathe = RealTime() * 18
		vTargetAngle = vTargetAngle + Vector( math_cos( flBreathe ), 0, math_cos( flBreathe * .5 ) ) * f
	end,
	[ WPN_RIFLE ] = function( f )
		SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS_CURRENT * 2
		local flBreathe = RealTime() * 18
		vTargetAngle = vTargetAngle + Vector( math_sin( flBreathe ), 0, math_sin( flBreathe * .5 ) ) * f
	end,
	[ WPN_RIFLEUP ] = function( f )
		SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS_CURRENT * 2
		local flBreathe = RealTime() * 18
		vTargetAngle = vTargetAngle + Vector( math_sin( flBreathe ), 0, math_sin( flBreathe * .5 ) ) * f
	end,
	[ WPN_SNIPER ] = function( f )
		SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS_CURRENT * 2
		local flBreathe = RealTime() * 18
		vTargetAngle = vTargetAngle + Vector( math_sin( flBreathe ), 0, math_sin( flBreathe * .5 ) ) * f
	end
}

local flRecoilCameraShakeLerped = 0

function SWEP:CalcView( ply, pos, ang )
	SPRING_CAMERA_STIFFNESS_CURRENT = 225
	SPRING_CAMERA_DAMPING_CURRENT = -20

	local MyTable = CEntity_GetTable( self )

	local f = SysTime()
	local flFrameTime = f - flLastCalcViewCall
	flLastCalcViewCall = f

	vTarget, vTargetAngle = Vector(), Vector()
	vViewTargetRatherQuick, vViewTargetRatherQuickAngle = Vector(), Vector()

	if CEntity_IsOnGround( ply ) then
		if CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) then
		elseif CEntity_GetNW2Bool( ply, "CTRL_bSprinting" ) then
			local flVelocity = CEntity_GetVelocity( ply ):Length()
			if flVelocity > 10 then
				local f = flVelocity / CPlayer_GetRunSpeed( ply ) * MyTable.flBobScale * 2
				local fFunction = SPRINT_ANIMATION_CAMERA[ MyTable.WPN_SPRINT ]
				if fFunction then fFunction( f ) else SPRINT_ANIMATION_CAMERA[ WPN_RIFLE ]( f ) end
			end
		else
			local flVelocity = CEntity_GetVelocity( ply ):Length()
			if flVelocity > 10 then
				local f = flVelocity / CPlayer_GetRunSpeed( ply ) * MyTable.flBobScale

				local flBreathe = RealTime() * 12

				vTargetAngle:Add( Vector( math_sin( flBreathe ) * .5, math_cos( flBreathe * .5 ) * .5 ) * f * MyTable.flAimMultiplier )

				f = f * ( 1 - MyTable.flAimMultiplier )
				vTarget:Add( Vector( 0, -math_sin( flBreathe * .5 ) * .33, ( math_abs( math_cos( flBreathe * .5 ) ) - .5 ) ) * f )
				vTargetAngle:Add( Vector( math_sin( flBreathe ) * -2, 0, math_cos( flBreathe * .5 ) ) * f * .33 )
			end
		end
	end

	local p = CEntity_GetNW2Int( ply, "CTRL_Peek" )
	if p == COVER_FIRE_LEFT then
		vTargetAngle[ 3 ] = vTargetAngle[ 3 ] - 3
	elseif p == COVER_FIRE_RIGHT then
		vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + 3
	elseif p == COVER_BLINDFIRE_LEFT then
		vTargetAngle[ 3 ] = vTargetAngle[ 3 ] - 5
	elseif p == COVER_BLINDFIRE_RIGHT then
		vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + 5
	end

	local pViewModel = ply:GetViewModel()
	if IsValid( pViewModel ) then
		local t = VIEWMODEL_CAMERA_ANIMATIONS[ pViewModel:GetModel() ]
		if t then
			local f = t[ pViewModel:GetSequenceName( pViewModel:GetSequence() ) ]
			if f then
				f( pViewModel, vTarget, vTargetAngle )
			end
		end
	end

	vViewTargetRatherQuick:Add( vBezier )
	vViewTargetRatherQuickAngle:Add( vBezierAngle )

	vViewFinalVel = vViewFinalVel + ( vTarget - vViewFinal ) * SPRING_CAMERA_STIFFNESS_CURRENT * flFrameTime
	vViewFinalVel = vViewFinalVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT * flFrameTime )
	vViewFinal = vViewFinal + vViewFinalVel * flFrameTime

	vViewFinalAngleVel = vViewFinalAngleVel + ( vTargetAngle - vViewFinalAngle ) * SPRING_CAMERA_STIFFNESS_CURRENT * flFrameTime
	vViewFinalAngleVel = vViewFinalAngleVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT * flFrameTime )
	vViewFinalAngle = vViewFinalAngle + vViewFinalAngleVel * flFrameTime

	ang:RotateAroundAxis( ang:Right(), vViewFinalAngle[ 1 ] )
	ang:RotateAroundAxis( ang:Up(), vViewFinalAngle[ 2 ] )
	ang:RotateAroundAxis( ang:Forward(), vViewFinalAngle[ 3 ] )

	pos:Add( vViewFinal[ 1 ] * ang:Forward() )
	pos:Add( vViewFinal[ 2 ] * ang:Right() )
	pos:Add( vViewFinal[ 3 ] * ang:Up() )

	vViewFinalRatherQuickVel = vViewFinalRatherQuickVel + ( vViewTargetRatherQuick - vViewFinalRatherQuick ) * SPRING_CAMERA_STIFFNESS_CURRENT * 2 * flFrameTime
	vViewFinalRatherQuickVel = vViewFinalRatherQuickVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT * flFrameTime )
	vViewFinalRatherQuick = vViewFinalRatherQuick + vViewFinalRatherQuickVel * flFrameTime

	vViewFinalRatherQuickAngleVel = vViewFinalRatherQuickAngleVel + ( vViewTargetRatherQuickAngle - vViewFinalRatherQuickAngle ) * SPRING_CAMERA_STIFFNESS_CURRENT * 2 * flFrameTime
	vViewFinalRatherQuickAngleVel = vViewFinalRatherQuickAngleVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT  * flFrameTime )
	vViewFinalRatherQuickAngle = vViewFinalRatherQuickAngle + vViewFinalRatherQuickAngleVel * flFrameTime

	ang:RotateAroundAxis( ang:Right(), vViewFinalRatherQuickAngle[ 1 ] )
	ang:RotateAroundAxis( ang:Up(), vViewFinalRatherQuickAngle[ 2 ] )
	ang:RotateAroundAxis( ang:Forward(), vViewFinalRatherQuickAngle[ 3 ] )

	pos:Add( vViewFinalRatherQuick[ 1 ] * ang:Forward() )
	pos:Add( vViewFinalRatherQuick[ 2 ] * ang:Right() )
	pos:Add( vViewFinalRatherQuick[ 3 ] * ang:Up() )

	local flMultiplier = MyTable.flAimMultiplier || 0
	if MyTable.bSniper && flMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) && !MyTable.bSniperNoSway then
		flMultiplier = ( MyTable.flSniperAimingSwayMultiplier || SNIPER_AIMING_SWAY_MULTIPLIER )
	else flMultiplier = 0 end

	local flSway = MyTable.flSway * flMultiplier
	local flSwayNeg = -flSway

	ang:RotateAroundAxis( ang:Right(), -math_Clamp( flSway * WEAPON_SWAY[ 1 ] / MyTable.flSwayScale, flSwayNeg, flSway ) )
	ang:RotateAroundAxis( ang:Up(), -math_Clamp( flSwayNeg * WEAPON_SWAY[ 2 ] / MyTable.flSwayScale, flSwayNeg, flSway ) )

	local flSwayVector = flSway * MyTable.flSwayStabilizer
	local flSwayVectorNeg = -flSwayVector

	pos:Sub( math_Clamp( ( flSwayVectorNeg * WEAPON_SWAY[ 1 ] / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Up() )
	pos:Sub( math_Clamp( ( flSwayVectorNeg * WEAPON_SWAY[ 2 ] / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Right() )

	local flRecoilCameraShake = MyTable.flRecoilCameraShake
	local flDelay = min( MyTable.Primary_flDelay, .1 )
	flRecoilCameraShakeLerped = Lerp( FRILerpRate( 3 / flDelay, flFrameTime ), flRecoilCameraShakeLerped, flRecoilCameraShake )
	ang[ 3 ] = ang[ 3 ] + math_sin( RealTime() * ( 2 * math.pi ) / flDelay ) * flRecoilCameraShakeLerped * MyTable.flRecoil
	MyTable.flRecoilCameraShake = Lerp( FRILerpRate( .5 / flDelay, flFrameTime ), flRecoilCameraShake, 0 )

	local v = MyTable.flCustomZoomFoV
	if v then
		if MyTable.bSniper then
			local f = MyTable.flAimMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) && v || UNIVERSAL_FOV
			MyTable.flFoV = f
			ang:Sub( ply:GetViewPunchAngles() * .1 )
			return pos, ang, f
		else
			local f = math_Remap( MyTable.flAimMultiplier, 1, 0, UNIVERSAL_FOV, v )
			MyTable.flFoV = f
			return pos, ang, f
		end
	end

	local f = math_Remap( MyTable.flAimMultiplier, 1, 0, UNIVERSAL_FOV, UNIVERSAL_FOV * .9 )
	MyTable.flFoV = f
	return pos, ang, f
end

SWEP.flViewModelSprint = 0
SWEP.flAimSpeed = 7

local COVER_BLINDFIRE_LEFT_POSE = Vector( 0, -8, 2 )
local COVER_BLINDFIRE_LEFT_POSE_ANGLE = Vector( 0, -2, -30 )

local COVER_BLINDFIRE_RIGHT_POSE = Vector( 0, 3.5, 2 )
local COVER_BLINDFIRE_RIGHT_POSE_ANGLE = Vector( 0, 2, 15 )

local COVER_BLINDFIRE_UP_POSE = Vector( -4, 1.8, 2 )
local COVER_BLINDFIRE_UP_POSE_ANGLE = Vector( 0, 0, -50 )

local math_Approach = math.Approach
local flLastCalcViewModelViewCall = SysTime()

local SPRINT_ANIMATION_VIEWMODEL = {
	[ WPN_PISTOL ] = function( MyTable, f, flViewModelSprint )
		local flBreathe = RealTime() * 8

		vTarget:Add( MyTable.vSprint || WEAPON_SPRINT_PISTOL_DEFAULT * flViewModelSprint )
		vTargetAngle:Add( MyTable.vSprintAngle || WEAPON_SPRINT_PISTOL_DEFAULT_ANGLE * flViewModelSprint )

		vTarget:Add( Vector( math_cos( flBreathe ) * -1, 2, math_cos( flBreathe ) * -2 + math_cos( RealTime() * 10 ) * 2 ) * flViewModelSprint )
		vTargetAngle:Add( Vector( math_cos( flBreathe ) * 22.5, math_cos( flBreathe ) * 11.25, 0 ) * flViewModelSprint )
	end,

	[ WPN_RIFLE ] = function( MyTable, f, flViewModelSprint )
		local flBreathe = RealTime() * 18
		vTarget = vTarget + ( ( MyTable.vSprint || WEAPON_SPRINT_RIFLE_DEFAULT ) + Vector( 0, ( ( math_cos( flBreathe * .5 ) + 1 ) * 1.25 ) * f, -math_cos( flBreathe ) * f ) ) * flViewModelSprint
		vTargetAngle = vTargetAngle + ( ( MyTable.vSprintAngle || WEAPON_SPRINT_RIFLE_DEFAULT_ANGLE ) + Vector( ( ( math_cos( flBreathe * .5 ) + 1 ) * -2.5 ) * f, ( ( math_cos( flBreathe * .5 ) + 1 ) * 7.5 ) * f ) ) * flViewModelSprint
	end,

	[ WPN_RIFLEUP ] = function( MyTable, f, flViewModelSprint )
		local flBreathe = RealTime() * 18
		vTarget = vTarget + ( ( MyTable.vSprint || WEAPON_SPRINT_RIFLEUP_DEFAULT ) + Vector( 0, ( ( math_cos( flBreathe * .5 ) + 1 ) * 1.25 ) * f, -math_cos( flBreathe ) * f ) ) * flViewModelSprint
		vTargetAngle = vTargetAngle + ( ( MyTable.vSprintAngle || WEAPON_SPRINT_RIFLEUP_DEFAULT_ANGLE ) + Vector( ( ( math_cos( flBreathe * .5 ) + 1 ) * -2.5 ) * f, ( ( math_cos( flBreathe * .5 ) + 1 ) * 7.5 ) * f ) ) * flViewModelSprint
	end,

	[ WPN_SNIPER ] = function( MyTable, f, flViewModelSprint )
		local flBreathe = RealTime() * 18
		vTarget = vTarget + ( ( MyTable.vSprint || WEAPON_SPRINT_SNIPER_DEFAULT ) + Vector( 0, ( ( math_cos( flBreathe * .5 ) + 1 ) * 1.25 ) * f, -math_cos( flBreathe ) * f ) ) * flViewModelSprint
		vTargetAngle = vTargetAngle + ( ( MyTable.vSprintAngle || WEAPON_SPRINT_SNIPER_DEFAULT_ANGLE ) + Vector( ( ( math_cos( flBreathe * .5 ) + 1 ) * -2.5 ) * f, ( ( math_cos( flBreathe * .5 ) + 1 ) * 7.5 ) * f ) ) * flViewModelSprint
	end
}


local COVER_CENTER = Vector( -20, 0, -8 )
local COVER_CENTER_ANGLE = Vector( 70, 5, 10 )

local COVER_LEFT = Vector( -20, 6.5, -8 )
local COVER_LEFT_ANGLE = Vector( 70, 5, 25 )

local COVER_RIGHT = Vector( -20, -8, -8 )
local COVER_RIGHT_ANGLE = Vector( 70, 0, -10 )


local COVER_CENTER_ALT = Vector( -15.2, -9, -12 )
local COVER_CENTER_ALT_ANGLE = Vector( 50, 0, -20 )

local COVER_LEFT_ALT = Vector( -11.3, -10, -9 )
local COVER_LEFT_ALT_ANGLE = Vector( 50, -15, -45 )

local COVER_RIGHT_ALT = Vector( -12.8, -14, -5 )
local COVER_RIGHT_ALT_ANGLE = Vector( 50, 15, -40 )


local math_max = math.max
local math_Rand = math.Rand

local flAimingRecoilBack, flAimingRecoilBackLerped = 0, 0
local flAimingRecoilPitchTurn, flAimingRecoilPitchTurnLerped = 0, 0
local flAimingRecoilYawTurn, flAimingRecoilYawTurnLerped = 0, 0

local flHipRecoilBack, flHipRecoilBackLerped = 0, 0

local flHipRecoilRollTurn, flHipRecoilRollTurnLerped = 0, 0

local flHipRecoilPitchTurn, flHipRecoilPitchTurnLerped = 0, 0
local flHipRecoilYawTurn, flHipRecoilYawTurnLerped = 0, 0

local flRecoilPistolJump, flRecoilPistolJumpLerped = 0, 0
local flAimingRecoilPistolJump, flAimingRecoilPistolJumpLerped = 0, 0

local tApplyRecoil = {
	[ WPN_RIFLE ] = function( MyTable, flFrameTime, flAimMultiplier, ply, pos, ang )
		local flDelay = min( MyTable.Primary_flDelay, .2 )
	
		local flAimingFireMul = 1 - flAimMultiplier

		local flPitchTurn, flYawTurn, flRollTurn = 0, 0, 0
	
		for _, tAnimation in ipairs( MyTable.tShootAnimations ) do
			flHipRecoilBack = 2 * flAimMultiplier
			flHipRecoilPitchTurn = tAnimation[ 2 ] * .75 * flAimMultiplier
			flHipRecoilYawTurn = tAnimation[ 3 ] * .75 * flAimMultiplier
			flHipRecoilRollTurn = Rand( -1, 1 ) * 3 * flAimMultiplier
	
			flAimingRecoilBack = 2.5 * flAimingFireMul
			flAimingRecoilPitchTurn = tAnimation[ 2 ] * .05 * flAimingFireMul
			flAimingRecoilYawTurn = tAnimation[ 3 ] * .1 * flAimingFireMul
		end
	
		MyTable.tShootAnimations = {}
	
	
		flHipRecoilBack = Lerp( FRILerpRate( .5 / flDelay, flFrameTime ), flHipRecoilBack, 0 )
		flHipRecoilBackLerped = Lerp( FRILerpRate( 1.5 / flDelay, flFrameTime ), flHipRecoilBackLerped, flHipRecoilBack )
	
		flHipRecoilPitchTurn = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilPitchTurn, 0 )
		flHipRecoilPitchTurnLerped = Lerp( FRILerpRate( 4 / flDelay, flFrameTime ), flHipRecoilPitchTurnLerped, flHipRecoilPitchTurn )
	
		flHipRecoilYawTurn = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilYawTurn, 0 )
		flHipRecoilYawTurnLerped = Lerp( FRILerpRate( 4 / flDelay, flFrameTime ), flHipRecoilYawTurnLerped, flHipRecoilYawTurn )

		flHipRecoilRollTurn = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilRollTurn, 0 )
		flHipRecoilRollTurnLerped = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilRollTurnLerped, flHipRecoilRollTurn )
	
	
		flAimingRecoilBack = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flAimingRecoilBack, 0 )
		flAimingRecoilBackLerped = Lerp( FRILerpRate( 2 / flDelay, flFrameTime ), flAimingRecoilBackLerped, flAimingRecoilBack )
	
		flAimingRecoilPitchTurn = Lerp( FRILerpRate( 1.5 / flDelay, flFrameTime ), flAimingRecoilPitchTurn, 0 )
		flAimingRecoilPitchTurnLerped = Lerp( FRILerpRate( 4 / flDelay, flFrameTime ), flAimingRecoilPitchTurnLerped, flAimingRecoilPitchTurn )
	
		flAimingRecoilYawTurn = Lerp( FRILerpRate( 1.5 / flDelay, flFrameTime ), flAimingRecoilYawTurn, 0 )
		flAimingRecoilYawTurnLerped = Lerp( FRILerpRate( 4 / flDelay, flFrameTime ), flAimingRecoilYawTurnLerped, flAimingRecoilYawTurn )

	
		pos:Sub( ang:Forward() * ( flAimingRecoilBackLerped + flHipRecoilBackLerped ) )

		flPitchTurn = flPitchTurn
		+ flAimingRecoilPitchTurnLerped
		+ flHipRecoilPitchTurnLerped

		flYawTurn = flYawTurn
		+ flAimingRecoilYawTurnLerped
		+ flHipRecoilYawTurnLerped

		flRollTurn = flRollTurn + flHipRecoilRollTurnLerped

		return flPitchTurn, flYawTurn, flRollTurn
	end,

	[ WPN_SUBMACHINEGUN ] = function( MyTable, flFrameTime, flAimMultiplier, ply, pos, ang )
		local flDelay = min( MyTable.Primary_flDelay, .2 )
	
		local flAimingFireMul = 1 - flAimMultiplier
	
		local flPitchTurn, flYawTurn, flRollTurn = 0, 0, 0
	
		for _, tAnimation in ipairs( MyTable.tShootAnimations ) do
			flHipRecoilBack = 4 * flAimMultiplier
			flHipRecoilPitchTurn = tAnimation[ 2 ] * 1.25 * flAimMultiplier
			flHipRecoilYawTurn = tAnimation[ 3 ] * 1.25 * flAimMultiplier
			flHipRecoilRollTurn = Rand( -1, 1 ) * 3 * flAimMultiplier
	
			flAimingRecoilBack = 2 * flAimingFireMul
			flAimingRecoilPitchTurn = tAnimation[ 2 ] * .05 * flAimingFireMul
			flAimingRecoilYawTurn = tAnimation[ 3 ] * .1 * flAimingFireMul
		end
	
		MyTable.tShootAnimations = {}
	
	
		flHipRecoilBack = Lerp( FRILerpRate( .5 / flDelay, flFrameTime ), flHipRecoilBack, 0 )
		flHipRecoilBackLerped = Lerp( FRILerpRate( 1.5 / flDelay, flFrameTime ), flHipRecoilBackLerped, flHipRecoilBack )
	
		flHipRecoilPitchTurn = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilPitchTurn, 0 )
		flHipRecoilPitchTurnLerped = Lerp( FRILerpRate( 4 / flDelay, flFrameTime ), flHipRecoilPitchTurnLerped, flHipRecoilPitchTurn )
	
		flHipRecoilYawTurn = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilYawTurn, 0 )
		flHipRecoilYawTurnLerped = Lerp( FRILerpRate( 4 / flDelay, flFrameTime ), flHipRecoilYawTurnLerped, flHipRecoilYawTurn )

		flHipRecoilRollTurn = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilRollTurn, 0 )
		flHipRecoilRollTurnLerped = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilRollTurnLerped, flHipRecoilRollTurn )
	
	
		flAimingRecoilBack = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flAimingRecoilBack, 0 )
		flAimingRecoilBackLerped = Lerp( FRILerpRate( 2 / flDelay, flFrameTime ), flAimingRecoilBackLerped, flAimingRecoilBack )
	
		flAimingRecoilPitchTurn = Lerp( FRILerpRate( 1.5 / flDelay, flFrameTime ), flAimingRecoilPitchTurn, 0 )
		flAimingRecoilPitchTurnLerped = Lerp( FRILerpRate( 3 / flDelay, flFrameTime ), flAimingRecoilPitchTurnLerped, flAimingRecoilPitchTurn )
	
		flAimingRecoilYawTurn = Lerp( FRILerpRate( 1.5 / flDelay, flFrameTime ), flAimingRecoilYawTurn, 0 )
		flAimingRecoilYawTurnLerped = Lerp( FRILerpRate( 3 / flDelay, flFrameTime ), flAimingRecoilYawTurnLerped, flAimingRecoilYawTurn )

	
		pos:Sub( ang:Forward() * ( flAimingRecoilBackLerped + flHipRecoilBackLerped ) )

		flPitchTurn = flPitchTurn
		+ flAimingRecoilPitchTurnLerped
		+ flHipRecoilPitchTurnLerped

		flYawTurn = flYawTurn
		+ flAimingRecoilYawTurnLerped
		+ flHipRecoilYawTurnLerped

		flRollTurn = flRollTurn + flHipRecoilRollTurnLerped
	
		return flPitchTurn, flYawTurn, flRollTurn
	end,

	[ WPN_PISTOL ] = function( MyTable, flFrameTime, flAimMultiplier, ply, pos, ang )
		local flDelay = min( MyTable.Primary_flDelay, .2 )
	
		local flAimingFireMul = 1 - flAimMultiplier
	
		local flPitchTurn, flYawTurn, flRollTurn = 0, 0, 0

		for _, tAnimation in ipairs( MyTable.tShootAnimations ) do
			flHipRecoilYawTurn = tAnimation[ 3 ] * flAimMultiplier * 1.5
			flHipRecoilRollTurn = Rand( -1, 1 ) * flAimMultiplier * 2

			flRecoilPistolJump = flAimMultiplier
			flAimingRecoilPistolJump = flAimingFireMul
		end

		MyTable.tShootAnimations = {}

		flHipRecoilYawTurn = Lerp( FRILerpRate( 1.5 / flDelay, flFrameTime ), flHipRecoilYawTurn, 0 )
		flHipRecoilYawTurnLerped = Lerp( FRILerpRate( 3 / flDelay, flFrameTime ), flHipRecoilYawTurnLerped, flHipRecoilYawTurn )

		flHipRecoilRollTurn = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilRollTurn, 0 )
		flHipRecoilRollTurnLerped = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilRollTurnLerped, flHipRecoilRollTurn )

		flRecoilPistolJump = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flRecoilPistolJump, 0 )
		flRecoilPistolJumpLerped = Lerp( FRILerpRate( 3 / flDelay, flFrameTime ), flRecoilPistolJumpLerped, flRecoilPistolJump )

		flDelay = min( MyTable.Primary_flDelay, .05 )

		flAimingRecoilPistolJump = Lerp( FRILerpRate( .5 / flDelay, flFrameTime ), flAimingRecoilPistolJump, 0 )
		flAimingRecoilPistolJumpLerped = Lerp( FRILerpRate( 3 / flDelay, flFrameTime ), flAimingRecoilPistolJumpLerped, flAimingRecoilPistolJump )

		pos:Sub( ang:Forward() * ( flAimingRecoilPistolJumpLerped * 3 + flRecoilPistolJumpLerped * 4 ) )
		pos:Add( ang:Up() * ( flAimingRecoilPistolJumpLerped * ( 1 / 3 ) + flRecoilPistolJumpLerped * .8 ) )

		flPitchTurn = flPitchTurn + flAimingRecoilPistolJumpLerped * .8 + flRecoilPistolJumpLerped * .5
	
		flYawTurn = flYawTurn + flHipRecoilYawTurnLerped

		flRollTurn = flRollTurn + flHipRecoilRollTurnLerped

		return flPitchTurn, flYawTurn, flRollTurn
	end,

	[ WPN_SHOTGUN ] = function( MyTable, flFrameTime, flAimMultiplier, ply, pos, ang )
		local flDelay = min( MyTable.Primary_flDelay, .2 )
	
		local flAimingFireMul = 1 - flAimMultiplier
	
		local flPitchTurn, flYawTurn, flRollTurn = 0, 0, 0

		for _, tAnimation in ipairs( MyTable.tShootAnimations ) do
			flHipRecoilYawTurn = tAnimation[ 3 ] * flAimMultiplier * .1
			flHipRecoilRollTurn = Rand( -1, 1 ) * flAimMultiplier * .1

			flRecoilPistolJump = flAimMultiplier
			flAimingRecoilPistolJump = flAimingFireMul
		end

		MyTable.tShootAnimations = {}

		flHipRecoilYawTurn = Lerp( FRILerpRate( 1.5 / flDelay, flFrameTime ), flHipRecoilYawTurn, 0 )
		flHipRecoilYawTurnLerped = Lerp( FRILerpRate( 3 / flDelay, flFrameTime ), flHipRecoilYawTurnLerped, flHipRecoilYawTurn )

		flHipRecoilRollTurn = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilRollTurn, 0 )
		flHipRecoilRollTurnLerped = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flHipRecoilRollTurnLerped, flHipRecoilRollTurn )

		flRecoilPistolJump = Lerp( FRILerpRate( 1 / flDelay, flFrameTime ), flRecoilPistolJump, 0 )
		flRecoilPistolJumpLerped = Lerp( FRILerpRate( 3 / flDelay, flFrameTime ), flRecoilPistolJumpLerped, flRecoilPistolJump )

		flDelay = min( MyTable.Primary_flDelay, .05 )

		flAimingRecoilPistolJump = Lerp( FRILerpRate( .5 / flDelay, flFrameTime ), flAimingRecoilPistolJump, 0 )
		flAimingRecoilPistolJumpLerped = Lerp( FRILerpRate( 3 / flDelay, flFrameTime ), flAimingRecoilPistolJumpLerped, flAimingRecoilPistolJump )

		pos:Sub( ang:Forward() * ( flAimingRecoilPistolJumpLerped * 3 + flRecoilPistolJumpLerped * 4 ) )
		pos:Add( ang:Up() * ( flAimingRecoilPistolJumpLerped * .1 + flRecoilPistolJumpLerped * .8 ) )

		flPitchTurn = flPitchTurn + flAimingRecoilPistolJumpLerped * .4 + flRecoilPistolJumpLerped * .5
	
		flYawTurn = flYawTurn + flHipRecoilYawTurnLerped

		flRollTurn = flRollTurn + flHipRecoilRollTurnLerped

		return flPitchTurn, flYawTurn, flRollTurn
	end
}

local function ApplyRecoil( MyTable, flFrameTime, flAimMultiplier, ply, pos, ang )
	local fFunction = tApplyRecoil[ MyTable.WPN_SHOOT ]
	if fFunction then return fFunction( MyTable, flFrameTime, flAimMultiplier, ply, pos, ang )
	else return tApplyRecoil[ WPN_RIFLE ]( MyTable, flFrameTime, flAimMultiplier, ply, pos, ang ) end
end

local vActualSway = Vector()

local function ApplySway( MyTable, pos, ang, flMultiplier, flPitchTurn, flYawTurn, flRollTurn, flFrameTime )
	local flSway = MyTable.flSway
	local flSwayNeg = -flSway
	local flSwayVector = flSway * ( MyTable.flSwayStabilizer * ( 1 - flMultiplier ) + .3 * flMultiplier )
	local flSwayVectorNeg = -flSwayVector

	local flSwayScale = MyTable.flSwayScale

	local flLerpSpeed = FRILerpRate( 3, flFrameTime )

	WEAPON_SWAY[ 1 ] = Lerp( flLerpSpeed, math_Clamp( WEAPON_SWAY[ 1 ], -flSwayScale, flSwayScale ), 0 )
	WEAPON_SWAY[ 2 ] = Lerp( flLerpSpeed, math_Clamp( WEAPON_SWAY[ 2 ], -flSwayScale, flSwayScale ), 0 )

	flLerpSpeed = FRILerpRate( 15, flFrameTime )

	vActualSway[ 1 ] = Lerp( flLerpSpeed, vActualSway[ 1 ], WEAPON_SWAY[ 1 ] )
	vActualSway[ 2 ] = Lerp( flLerpSpeed, vActualSway[ 2 ], WEAPON_SWAY[ 2 ] )

	ang:RotateAroundAxis( ang:Right(), flSway * ( vActualSway[ 1 ] * flMultiplier / flSwayScale + flPitchTurn ) )
	pos:Add( flSwayVectorNeg * ( vActualSway[ 1 ] * flMultiplier / flSwayScale + flPitchTurn ) * ang:Up() )

	ang:RotateAroundAxis( ang:Up(), flSwayNeg * ( vActualSway[ 2 ] * flMultiplier / flSwayScale + flYawTurn ) )
	pos:Add( flSwayVectorNeg * ( vActualSway[ 2 ] * flMultiplier / flSwayScale + flYawTurn ) * ang:Right() )

	ang:RotateAroundAxis( ang:Forward(), flSway * flRollTurn * MyTable.flAimMultiplier )
	pos:Sub( ( flSwayVectorNeg * flRollTurn ) * .2 * MyTable.flAimMultiplier * ang:Up() )
end

local function CoverPose( MyTable, ply, vTarget, vTargetAngle )
	if !MyTable.__VIEWMODEL_FULLY_MODELED__ then
		vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 45
		vTarget[ 1 ] = vTarget[ 1 ] - 10 - MyTable.flViewModelX + ( MyTable.flCoverY || 0 )
		vTarget[ 2 ] = vTarget[ 2 ] + ( MyTable.vViewModelAim && ( MyTable.vViewModelAim[ 1 ] * .5 ) || 2 ) - MyTable.flViewModelY * .5
		vTarget[ 3 ] = vTarget[ 3 ] - 10 - MyTable.flViewModelZ
		return
	end

	if MyTable.WPN_COVER == WPN_RIFLEUP then
		local f = CEntity_GetNW2Int( ply, "CTRL_Variants" )
		if f == COVER_VARIANTS_LEFT then
			vTarget:Add( COVER_LEFT_ALT )
			vTargetAngle:Add( COVER_LEFT_ALT_ANGLE )
		elseif f == COVER_VARIANTS_RIGHT then
			vTarget:Add( COVER_RIGHT_ALT )
			vTargetAngle:Add( COVER_RIGHT_ALT_ANGLE )
		else
			vTarget:Add( COVER_CENTER_ALT )
			vTargetAngle:Add( COVER_CENTER_ALT_ANGLE )
		end
	else
		local f = CEntity_GetNW2Int( ply, "CTRL_Variants" )
		if f == COVER_VARIANTS_LEFT then
			vTarget:Add( COVER_LEFT )
			vTargetAngle:Add( COVER_LEFT_ANGLE )
		elseif f == COVER_VARIANTS_RIGHT then
			vTarget:Add( COVER_RIGHT )
			vTargetAngle:Add( COVER_RIGHT_ANGLE )
		else
			vTarget:Add( COVER_CENTER )
			vTargetAngle:Add( COVER_CENTER_ANGLE )
		end
	end
end

function SWEP:CalcViewModelView( _, pos, ang )
	SPRING_STIFFNESS_CURRENT = 225
	SPRING_DAMPING_CURRENT = -20

	local f = SysTime()
	local flFrameTime = f - flLastCalcViewModelViewCall
	flLastCalcViewModelViewCall = f

	local MyTable = CEntity_GetTable( self )
	local ply = LocalPlayer()

	MyTable.ViewModelFOV = math.deg( math.atan( math.tan( math.rad( 41.8 / 2 ) ) * math.tan( math.rad( ply:GetInfoNum( "fov_desired", 75 ) / 2 ) ) / math.tan( math.rad( MyTable.flFoV / 2 ) ) ) * 2.22 )

	local f = math_Clamp( ply:Health() / ply:GetMaxHealth(), 0, 1 )
	vBezier, vBezierAngle = Vector(), Vector()
	vTargetRatherQuick, vTargetRatherQuickAngle = Vector(), Vector()
	MyTable.flBobScale = math_Remap( f, 0, 1, 2, 1 )

	local bSprinting = CEntity_GetNW2Bool( ply, "CTRL_bSprinting" )
	local bSliding = CEntity_GetNW2Bool( ply, "CTRL_bSliding" )
	local bInCover = CEntity_GetNW2Bool( ply, "CTRL_bInCover" ) && !CEntity_GetNW2Bool( ply, "CTRL_bGunUsesCoverStance" )
	local bZoom = !bSprinting && !bSliding && !bInCover && CEntity_IsOnGround( ply ) && CPlayer_KeyDown( ply, IN_ZOOM )

	// This is not how that works lmao
	//	local vAim = MyTable.vViewModelAim
	//	if vAim then
	//		vTarget = vAim * ( 1 - MyTable.flAimMultiplier )
	//		local vAimAngle = MyTable.vViewModelAimAngle
	//		vTargetAngle = vAimAngle && ( vAimAngle * ( 1 - MyTable.flAimMultiplier ) ) || Vector()
	//	else bZoom = nil vTarget, vTargetAngle = Vector(), Vector() end

	local vAim = MyTable.vViewModelAim
	if !vAim then bZoom = nil end
	vTarget:Zero() // Cool ass C++ optimization
	vTargetAngle:Zero() // Hire me rn VALVe I am SO cool with this basic piece of code

	local flPitchTurn, flYawTurn, flRollTurn = ApplyRecoil( MyTable, flFrameTime, MyTable.flAimMultiplier, ply, pos, ang )

	vInstantTarget, vInstantTargetAngle = Vector(), Vector()
	if IsValid( ply:GetNW2Entity "GAME_pVehicle" ) then vInstantTarget = vInstantTarget - Vector( 0, 0, 999999 ) end

	if !MyTable.bCoverNotAnimated && bInCover then
		MyTable.flViewModelSprint = Lerp( FRILerpRate( 5, flFrameTime ), MyTable.flViewModelSprint, 0 )
		if CurTime() > MyTable.flReloadTime then CoverPose( MyTable, ply, vTarget, vTargetAngle ) end
	else
		local p, b = CEntity_GetNW2Int( ply, "CTRL_Peek" )
		if p == COVER_FIRE_LEFT then
			//	vTargetAngle.z = vTargetAngle.z - 22.5
		elseif p == COVER_FIRE_RIGHT then
			//	vTargetAngle.z = vTargetAngle.z + 22.5
		elseif MyTable.__VIEWMODEL_FULLY_MODELED__ then
			if p == COVER_BLINDFIRE_UP then
				vTarget:Add( COVER_BLINDFIRE_UP_POSE )
				vTargetAngle:Add( COVER_BLINDFIRE_UP_POSE_ANGLE )
			elseif p == COVER_BLINDFIRE_LEFT then
				//	if CPlayer_Crouching( ply ) && !bZoom then vTarget = vTarget + Vector( -1, 1, .5 ) b = true end
				b = true
				vTarget:Add( COVER_BLINDFIRE_LEFT_POSE )
				vTargetAngle:Add( COVER_BLINDFIRE_LEFT_POSE_ANGLE )
			elseif p == COVER_BLINDFIRE_RIGHT then
				//	if CPlayer_Crouching( ply ) && !bZoom then vTarget = vTarget + Vector( -1, -1, .5 ) b = true end
				b = true
				vTarget:Add( COVER_BLINDFIRE_RIGHT_POSE )
				vTargetAngle:Add( COVER_BLINDFIRE_RIGHT_POSE_ANGLE )
			end
		elseif p == COVER_BLINDFIRE_LEFT then
			vTargetAngle[ 3 ] = vTargetAngle[ 3 ] - 45
		elseif p == COVER_BLINDFIRE_RIGHT then
			vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + 45
		end

		local bOnGround, bWantsToSprint = CEntity_IsOnGround( ply )
		if IsValid( ply:GetNW2Entity "GAME_pVehicle" ) then
			MyTable.flViewModelSprint = Lerp( FRILerpRate( 5, flFrameTime ), MyTable.flViewModelSprint, 0 )
			bOnGroundLast = true
		elseif bOnGround then
			if !b && CPlayer_Crouching( ply ) && !bZoom then
				// This is basically
				//	vTarget = vTarget + Vector( -1, -1, .5 )
				// but with cocaine induced speed.
				// Don't ask me why I did this even though it absolutely BREEZED as
				//	vTarget:Add( Vector( -1, -1, .5 )
				// I gotta be a badass :)
				vTarget[ 1 ] = vTarget[ 1 ] - 1
				vTarget[ 2 ] = vTarget[ 2 ] - 1
				vTarget[ 3 ] = vTarget[ 3 ] + .5
			end

			bOnGroundLast = true

			if bSliding then
			elseif bSprinting && !MyTable.bSprintNotAnimated then
				bWantsToSprint = true
				local flSprint = MyTable.flViewModelSprint
				local f = min( .5, CEntity_GetVelocity( ply ):Length() / CPlayer_GetRunSpeed( ply ) ) * MyTable.flBobScale
				local fFunction = SPRINT_ANIMATION_VIEWMODEL[ MyTable.WPN_SPRINT ]
				if fFunction then fFunction( MyTable, f, MyTable.flViewModelSprint ) else SPRINT_ANIMATION_VIEWMODEL[ WPN_RIFLE ]( MyTable, f, flSprint ) end
			else
				local flVelocity = CEntity_GetVelocity( ply ):Length()
				if !bZoom then
					if CPlayer_KeyDown( ply, IN_MOVELEFT ) then
						vTargetAngle[ 2 ] = vTargetAngle[ 2 ] - 4 * flVelocity / CPlayer_GetWalkSpeed( ply )
					elseif CPlayer_KeyDown( ply, IN_MOVERIGHT ) then
						vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + 7 * flVelocity / CPlayer_GetWalkSpeed( ply )
					end
				end

				local flVelocity = CEntity_GetVelocity( ply ):Length()
				if flVelocity > 10 then
					local f = flVelocity / CPlayer_GetRunSpeed( ply ) * MyTable.flBobScale * MyTable.flAimMultiplier
					local flBreathe = RealTime() * 13
					vTarget:Add( Vector( 0, math_sin( flBreathe * .5 ) * ( 1 / 3 ), ( 2 / 3 ) - math_abs( math_cos( flBreathe * .5 ) ) * ( 1 + 1 / 3 ) ) * f )
					vTargetAngle:Add( Vector( math_sin( flBreathe ) * 2, 0, math_cos( flBreathe * .5 ) ) * f * ( -1 / 3 ) )
				end
			end
		else
			MyTable.flViewModelSprint = Lerp( FRILerpRate( 5, flFrameTime ), MyTable.flViewModelSprint, 0 )
			flLandTime = RealTime() + .31
			if bOnGroundLast then
				flJumpTime = RealTime() + .31
				flLandTime = 0
				bOnGroundLast = nil
			end
		end

		if CEntity_WaterLevel( ply ) < 1 then
			if RealTime() <= flJumpTime then
				SPRING_STIFFNESS_CURRENT = SPRING_STIFFNESS_CURRENT * 1.5
				local f = .31 - ( flJumpTime - RealTime() )
				local xx = BezierY( f, 0, -4, 0 )
				local yy = 0
				local zz = BezierY( f, 0, -2, -5 )
				local pt = BezierY( f, 0, -4.36, 10 )
				local yw = xx
				local rl = BezierY( f, 0, -10.82, -5 )
				vBezier = Vector( yy, xx, zz * .5 )
				if !MyTable.bJumpingNotAnimated && CurTime() > MyTable.flLastShot + MyTable.Primary_flDelay && !CPlayer_KeyDown( ply, IN_ZOOM ) then
					vTargetRatherQuick:Add( vBezier * 2 )
					vTargetRatherQuickAngle:Add( Vector( pt * .2, yw, rl ) )
				end
				vBezierAngle = Vector( math_cos( RealTime() * 18 ) * 2, math_sin( RealTime() * 22 ) * 4, math_sin( RealTime() * 24 ) * 2 )
			elseif !bOnGround then
				SPRING_STIFFNESS_CURRENT = SPRING_STIFFNESS_CURRENT * 1.5
				local flBreathe = RealTime() * 30
				vBezier = Vector( 0, math_cos( flBreathe * .5 ) * .0625, ( math_sin( flBreathe / 3 ) * .0625 ) )
				vBezierAngle = Vector( ( math_sin( flBreathe / 3 ) * .25 ), math_cos( flBreathe * .5 ) * .25 )
				if !MyTable.bJumpingNotAnimated && CurTime() > MyTable.flLastShot + MyTable.Primary_flDelay && !CPlayer_KeyDown( ply, IN_ZOOM ) then
					vTargetRatherQuick:Add( Vector( 0, math_cos( flBreathe * .5 ) * .0625, -5 * .2 + ( math_sin( flBreathe / 3 ) * .0625 ) ) )
					vTargetRatherQuickAngle:Add( Vector( 10 * .2 - ( math_sin( flBreathe / 3 ) * .25 ), math_cos( flBreathe * .5 ) * .25, -5 ) )
				end
			elseif RealTime() <= flLandTime then
				SPRING_STIFFNESS_CURRENT = SPRING_STIFFNESS_CURRENT * 1.5
				if bWantsToSprint then MyTable.flViewModelSprint = Lerp( FRILerpRate( 2, flFrameTime ), MyTable.flViewModelSprint, 1 ) end
				local f = flLandTime - RealTime()
				local xx = BezierY( f, 0, -4, 0 )
				local yy = 0
				local zz = BezierY( f, 0, 2, -5 )
				local pt = BezierY( f, 0, -34.88, 10 )
				local yw = xx
				local rl = 0 // BezierY( f, 0, -10.82, -5 )
				vBezier = Vector( yy, xx, zz * .5 )
				if !MyTable.bJumpingNotAnimated && CurTime() > MyTable.flLastShot + MyTable.Primary_flDelay && !CPlayer_KeyDown( ply, IN_ZOOM ) then
					vTargetRatherQuick:Add( vBezier * 2 )
					vTargetRatherQuickAngle:Add( Vector( pt * .2, yw, rl ) )
				end
				vBezierAngle = Vector( math_cos( RealTime() * 18 ) * 2, math_sin( RealTime() * 22 ) * 4, math_sin( RealTime() * 24 ) * 2 )
			elseif bWantsToSprint then
				MyTable.flViewModelSprint = Lerp( FRILerpRate( 5, flFrameTime ), MyTable.flViewModelSprint, 1 )
			else MyTable.flViewModelSprint = Lerp( FRILerpRate( 5, flFrameTime ), MyTable.flViewModelSprint, 0 ) end
		elseif bWantsToSprint then
			MyTable.flViewModelSprint = Lerp( FRILerpRate( 5, flFrameTime ), MyTable.flViewModelSprint, 1 )
		else MyTable.flViewModelSprint = Lerp( FRILerpRate( 5, flFrameTime ), MyTable.flViewModelSprint, 0 ) end
	end

	vInstantTarget:Add( Vector( MyTable.flViewModelX, MyTable.flViewModelY, MyTable.flViewModelZ ) )

	ang:RotateAroundAxis( ang:Right(), vInstantTargetAngle[ 1 ] )
	ang:RotateAroundAxis( ang:Up(), vInstantTargetAngle[ 2 ] )
	ang:RotateAroundAxis( ang:Forward(), vInstantTargetAngle[ 3 ] )

	pos:Add( vInstantTarget[ 1 ] * ang:Forward() )
	pos:Add( vInstantTarget[ 2 ] * ang:Right() )
	pos:Add( vInstantTarget[ 3 ] * ang:Up() )

	if vAim then
		local f = MyTable.flIronsightCloseness
		if f then pos:Sub( f * ( 1 - MyTable.flAimMultiplier ) * ang:Forward() ) end

		local vAimAngle = MyTable.vViewModelAimAngle
		if vAimAngle then
			local v = vAimAngle * ( 1 - MyTable.flAimMultiplier )
			ang:RotateAroundAxis( ang:Right(), v[ 1 ] )
			ang:RotateAroundAxis( ang:Up(), v[ 2 ] )
			ang:RotateAroundAxis( ang:Forward(), v[ 3 ] )
		end

		local v = vAim * ( 1 - MyTable.flAimMultiplier )
		pos:Add( v[ 1 ] * ang:Forward() )
		pos:Add( v[ 2 ] * ang:Right() )
		pos:Add( v[ 3 ] * ang:Up() )
	end

	local flMultiplier = MyTable.flAimMultiplier
	if bZoom then
		flMultiplier = math_max( 0, MyTable.flAimMultiplier - MyTable.flAimSpeed * flMultiplier ^ .8 * flFrameTime )
	else
		flMultiplier = min( 1, MyTable.flAimMultiplier + MyTable.flAimSpeed * ( 1 - flMultiplier ) ^ .8 * flFrameTime )
	end

	MyTable.flAimMultiplier = flMultiplier

	if MyTable.bSniper && flMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then
		vInstantTarget = Vector( 0, 0, 999999 )
		flMultiplier = ( MyTable.flSniperAimingSwayMultiplier || SNIPER_AIMING_SWAY_MULTIPLIER )
		pos[ 3 ] = pos[ 3 ] - 1000
	end

	if MyTable.__VIEWMODEL_FULLY_MODELED__ then
		flMultiplier = math_Remap( flMultiplier, 0, 1, MyTable.flAimSway, 1 )
	else
		flMultiplier = math_Remap( flMultiplier, 0, 1, MyTable.flPartiallyModeledAimSway, 1 )
	end

	if bSliding then
		vTarget:Add( MyTable.vSprint || WEAPON_SPRINT_RIFLE_DEFAULT )
		vTargetAngle:Add( MyTable.vSprintAngle || WEAPON_SPRINT_RIFLE_DEFAULT_ANGLE )
	end

	ApplySway( MyTable, pos, ang, flMultiplier, flPitchTurn, flYawTurn, flRollTurn, flFrameTime )

	vFinalVel = vFinalVel + ( vTarget - vFinal ) * SPRING_STIFFNESS_CURRENT * flFrameTime
	vFinalVel = vFinalVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
	vFinal = vFinal + vFinalVel * flFrameTime

	vFinalAngleVel = vFinalAngleVel + ( vTargetAngle - vFinalAngle ) * SPRING_STIFFNESS_CURRENT * flFrameTime
	vFinalAngleVel = vFinalAngleVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
	vFinalAngle = vFinalAngle + vFinalAngleVel * flFrameTime

	ang:RotateAroundAxis( ang:Right(), vFinalAngle[ 1 ] )
	ang:RotateAroundAxis( ang:Up(), vFinalAngle[ 2 ] )
	ang:RotateAroundAxis( ang:Forward(), vFinalAngle[ 3 ] )

	vFinalRatherQuickVel = vFinalRatherQuickVel + ( vTargetRatherQuick - vFinalRatherQuick ) * SPRING_STIFFNESS_CURRENT * flFrameTime
	vFinalRatherQuickVel = vFinalRatherQuickVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
	vFinalRatherQuick = vFinalRatherQuick + vFinalRatherQuickVel * flFrameTime

	vFinalRatherQuickAngleVel = vFinalRatherQuickAngleVel + ( vTargetRatherQuickAngle - vFinalRatherQuickAngle ) * SPRING_STIFFNESS_CURRENT * flFrameTime
	vFinalRatherQuickAngleVel = vFinalRatherQuickAngleVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
	vFinalRatherQuickAngle = vFinalRatherQuickAngle + vFinalRatherQuickAngleVel * flFrameTime

	ang:RotateAroundAxis( ang:Right(), vFinalRatherQuickAngle[ 1 ] )
	ang:RotateAroundAxis( ang:Up(), vFinalRatherQuickAngle[ 2 ] )
	ang:RotateAroundAxis( ang:Forward(), vFinalRatherQuickAngle[ 3 ] )

	pos:Add( vFinal[ 1 ] * ang:Forward() )
	pos:Add( vFinal[ 2 ] * ang:Right() )
	pos:Add( vFinal[ 3 ] * ang:Up() )

	pos:Add( vFinalRatherQuick[ 1 ] * ang:Forward() )
	pos:Add( vFinalRatherQuick[ 2 ] * ang:Right() )
	pos:Add( vFinalRatherQuick[ 3 ] * ang:Up() )

	return pos, ang
end
