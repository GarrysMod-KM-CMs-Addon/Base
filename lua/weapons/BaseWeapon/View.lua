local CEntity = FindMetaTable "Entity"
local CPlayer = FindMetaTable "Player"

local CEntity_GetTable = CEntity.GetTable
local CEntity_IsOnGround = CEntity.IsOnGround
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local math_Clamp = math.Clamp
local math_min = math.min
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
	local MyTable = CEntity_GetTable( self )
	local f = CurTime() <= ( ( MyTable.flLastShot || 0 ) + math_min( .5, MyTable.Primary_flDelay ) + ( MyTable.Primary.Automatic && 0 || .2 ) ) && .33 || 1
	local v = MyTable.flFoV
	if v then return v / LocalPlayer():GetInfoNum( "fov_desired", UNIVERSAL_FOV ) * f end
	return f
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
	local flDelay = math_min( MyTable.Primary_flDelay, .1 )
	flRecoilCameraShakeLerped = Lerp( math_min( 1, 3 / flDelay * flFrameTime ), flRecoilCameraShakeLerped, flRecoilCameraShake )
	ang[ 3 ] = ang[ 3 ] + math_sin( RealTime() * ( 2 * math.pi ) / flDelay ) * flRecoilCameraShakeLerped * MyTable.flRecoil
	MyTable.flRecoilCameraShake = Lerp( math_min( 1, .5 / flDelay * flFrameTime ), flRecoilCameraShake, 0 )

	local v = MyTable.flCustomZoomFoV
	if v then
		if MyTable.bSniper then
			local f = MyTable.flAimMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) && v || ply:GetInfoNum( "fov_desired", UNIVERSAL_FOV )
			MyTable.flFoV = f
			ang:Sub( ply:GetViewPunchAngles() * .1 )
			return pos, ang, f
		else
			local f = math_Remap( MyTable.flAimMultiplier, 1, 0, ply:GetInfoNum( "fov_desired", UNIVERSAL_FOV ), v )
			MyTable.flFoV = f
			return pos, ang, f
		end
	else MyTable.flFoV = ply:GetInfoNum( "fov_desired", UNIVERSAL_FOV ) end

	return pos, ang, ply:GetInfoNum( "fov_desired", UNIVERSAL_FOV )
end

SWEP.flViewModelSprint = 0
SWEP.flAimShootTurn = .033
SWEP.flAimSpeed = 5

local COVER_BLINDFIRE_LEFT_POSE = Vector( 0, -11, 3 )
local COVER_BLINDFIRE_LEFT_POSE_ANGLE = Vector( 0, -6, -30 )

local COVER_BLINDFIRE_RIGHT_POSE = Vector( 0, 3.5, 2 )
local COVER_BLINDFIRE_RIGHT_POSE_ANGLE = Vector( 0, 0, 15 )

local COVER_BLINDFIRE_UP_POSE = Vector( 0, 1.8, 2 )
local COVER_BLINDFIRE_UP_POSE_ANGLE = Vector( 0, 0, -60 )

local math_Approach = math.Approach
local flLastCalcViewModelViewCall = SysTime()

local SPRINT_ANIMATION_VIEWMODEL = {
	[ WPN_PISTOL ] = function( MyTable, f, flViewModelSprint )
		local flBreathe = RealTime() * 8
		vTarget:Add( MyTable.vSprint || WEAPON_SPRINT_PISTOL_DEFAULT * flViewModelSprint )
		vTargetAngle:Add( MyTable.vSprintAngle || WEAPON_SPRINT_PISTOL_DEFAULT_ANGLE * flViewModelSprint )
		vTarget:Add( Vector( math_cos( flBreathe ) * -1, 2, math_cos( flBreathe ) * -2 ) * flViewModelSprint )
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

local math_max = math.max
local math_Rand = math.Rand

local flRecoilBack, flRecoilBackLerped = 0, 0
local flRecoilPitchTurn, flRecoilPitchTurnLerped = 0, 0
local flRecoilYawTurn, flRecoilYawTurnLerped = 0, 0
local function ApplyRecoil( MyTable, flFrameTime, flAimMultiplier, ply, pos, ang )
	local flPitchTurn, flYawTurn = 0, 0

	for _, tAnimation in ipairs( MyTable.tShootAnimations ) do
		flRecoilBack = 3
		flRecoilPitchTurn = tAnimation[ 2 ] * 2
		flRecoilYawTurn = tAnimation[ 3 ] * 3.5
	end

	MyTable.tShootAnimations = {}

	flRecoilBack = Lerp( math_min( 1, 1 / MyTable.Primary_flDelay * flFrameTime ), flRecoilBack, 0 )
	flRecoilBackLerped = Lerp( math_min( 1, 1 / MyTable.Primary_flDelay * flFrameTime ), flRecoilBackLerped, flRecoilBack )

	flRecoilPitchTurn = Lerp( math_min( 1, 1.5 / MyTable.Primary_flDelay * flFrameTime ), flRecoilPitchTurn, 0 )
	flRecoilPitchTurnLerped = Lerp( math_min( 1, 1.5 / MyTable.Primary_flDelay * flFrameTime ), flRecoilPitchTurnLerped, flRecoilPitchTurn )

	flRecoilYawTurn = Lerp( math_min( 1, .5 / MyTable.Primary_flDelay * flFrameTime ), flRecoilYawTurn, 0 )
	flRecoilYawTurnLerped = Lerp( math_min( 1, 2 / MyTable.Primary_flDelay * flFrameTime ), flRecoilYawTurnLerped, flRecoilYawTurn )

	pos:Sub( ang:Forward() * flRecoilBackLerped )
	flPitchTurn = flPitchTurn + flRecoilPitchTurnLerped
	flYawTurn = flYawTurn + flRecoilYawTurnLerped

	return flPitchTurn, flYawTurn
end

// I know that the spring implementation sounds cool on paper, but it's shit in practice
//	local WEAPON_SWAYVelocity = Vector()

local flSwayStiffnessBoost, flSwayDampingBoost = 0, 0

local function ApplySway( MyTable, pos, ang, flMultiplier, flPitchTurn, flYawTurn, flFrameTime )
	local flSway = MyTable.flSway
	local flSwayNeg = -flSway
	local flSwayVector = flSway * ( MyTable.flSwayStabilizer * ( 1 - flMultiplier ) + .3 * flMultiplier )
	local flSwayVectorNeg = -flSwayVector

	//	local flSwayMultiplier = flSway * flMultiplier * 2
	//	local flAsshole = math_max( math_abs( WEAPON_SWAY[ 1 ] ), math_abs( WEAPON_SWAY[ 2 ] ) )
	//	if flAsshole > flSwayMultiplier then flAsshole = flAsshole - flSwayMultiplier else flAsshole = 0 end
	//	
	//	flSwayStiffnessBoost = Lerp( math_min( flFrameTime * 5, 1 ), flSwayStiffnessBoost, 1 + flAsshole * 2 )
	//	flSwayDampingBoost = Lerp( math_min( flFrameTime * 5, 1 ), flSwayDampingBoost, 1 + flAsshole ^ .5 )
	//	
	//	WEAPON_SWAYVelocity:Sub( WEAPON_SWAY * 16 * flSwayStiffnessBoost * flFrameTime )
	//	WEAPON_SWAYVelocity:Mul( math_exp( -6 * flSwayDampingBoost * flFrameTime ) )
	//	WEAPON_SWAY:Add( WEAPON_SWAYVelocity * flFrameTime )

	//	WEAPON_SWAY[ 1 ] = math_Clamp( WEAPON_SWAY[ 1 ], ( -flSway * MyTable.flSwayScale / flSway ) - flYawTurn, ( flSway * MyTable.flSwayScale / flSway ) - flYawTurn )

	local flSwayScale = MyTable.flSwayScale

	WEAPON_SWAY[ 1 ] = Lerp( math_min( 1, 5 * flFrameTime ), math_Clamp( WEAPON_SWAY[ 1 ], -flSwayScale, flSwayScale ), 0 )
	WEAPON_SWAY[ 2 ] = Lerp( math_min( 1, 5 * flFrameTime ), math_Clamp( WEAPON_SWAY[ 2 ], -flSwayScale, flSwayScale ), 0 )

	ang:RotateAroundAxis( ang:Right(), flSway * ( WEAPON_SWAY[ 1 ] * flMultiplier + flPitchTurn ) / flSwayScale )
	pos:Add( ( flSwayVectorNeg * ( WEAPON_SWAY[ 1 ] * flMultiplier + flPitchTurn ) / MyTable.flSwayScale ) * ang:Up() )

	ang:RotateAroundAxis( ang:Up(), flSwayNeg * ( WEAPON_SWAY[ 2 ] * flMultiplier + flYawTurn ) / flSwayScale )
	pos:Add( ( flSwayVectorNeg * ( WEAPON_SWAY[ 2 ] * flMultiplier + flYawTurn ) / MyTable.flSwayScale ) * ang:Right() )
end

function SWEP:CalcViewModelView( _, pos, ang )
	SPRING_STIFFNESS_CURRENT = 225
	SPRING_DAMPING_CURRENT = -20

	local f = SysTime()
	local flFrameTime = f - flLastCalcViewModelViewCall
	flLastCalcViewModelViewCall = f

	local MyTable = CEntity_GetTable( self )
	local ply = LocalPlayer()

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

	local flPitchTurn, flYawTurn = ApplyRecoil( MyTable, flFrameTime, flTrueAimMultiplier, ply, pos, ang )

	vInstantTarget, vInstantTargetAngle = Vector(), Vector()
	if IsValid( ply:GetNW2Entity "GAME_pVehicle" ) then vInstantTarget = vInstantTarget - Vector( 0, 0, 999999 ) end
	vInstantTarget:Sub( Vector( MyTable.flViewModelY, 0, MyTable.flViewModelZ ) * MyTable.flViewModelSprint )

	if !MyTable.bCoverNotAnimated && bInCover then
		MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 )
		if CurTime() > MyTable.flReloadTime then
			if MyTable.__VIEWMODEL_FULLY_MODELED__ then
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
			else
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 45
				vTarget[ 1 ] = vTarget[ 1 ] - 10 - MyTable.flViewModelX + ( MyTable.flCoverY || 0 )
				vTarget[ 2 ] = vTarget[ 2 ] + ( MyTable.vViewModelAim && ( MyTable.vViewModelAim[ 1 ] * .5 ) || 2 )
				vTarget[ 3 ] = vTarget[ 3 ] - 10 - MyTable.flViewModelZ
			end
		end
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
			MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 )
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
				local f = math_min( .5, CEntity_GetVelocity( ply ):Length() / CPlayer_GetRunSpeed( ply ) ) * MyTable.flBobScale
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

				//	if flVelocity > 10 then
				//		local flBreathe = RealTime() * 12
				//		local f = flVelocity / CPlayer_GetWalkSpeed( ply ) * MyTable.flAimMultiplier * MyTable.flBobScale * .5
				//		vTarget:Add( Vector( 0, -math_sin( flBreathe * .5 ) * .5, ( .5 - math_abs( math_cos( flBreathe * .5 ) ) ) * -1 ) * f )
				//		vTargetAngle:Add( Vector( math_sin( flBreathe ), 0, math_cos( flBreathe * .5 ) ) * f )
				//	end
			end
		else
			MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 )
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
				if bWantsToSprint then MyTable.flViewModelSprint = Lerp( math_min( 1, 2 * flFrameTime ), MyTable.flViewModelSprint, 1 ) end
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
				MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 1 )
			else MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 ) end
		elseif bWantsToSprint then
			MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 1 )
		else MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 ) end
	end

	if vAim then
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
	//	if bZoom then flMultiplier = math_Approach( MyTable.flAimMultiplier, 0, MyTable.flAimSpeed * flFrameTime )
	//	else flMultiplier = math_Approach( MyTable.flAimMultiplier, 1, MyTable.flAimSpeed * flFrameTime ) end
	if bZoom then
		flMultiplier = math_max( 0, flMultiplier - flMultiplier ^ .5 * MyTable.flAimSpeed * flFrameTime )
	else
		flMultiplier = math_min( 1, flMultiplier + ( 1 - flMultiplier ) ^ .5 * MyTable.flAimSpeed * flFrameTime )
	end

	MyTable.flAimMultiplier = flMultiplier
	local flTrueAimMultiplier = flMultiplier
	if MyTable.bSniper && flMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then
		vInstantTarget = Vector( 0, 0, 999999 )
		flMultiplier = ( MyTable.flSniperAimingSwayMultiplier || SNIPER_AIMING_SWAY_MULTIPLIER )
	end
	if MyTable.__VIEWMODEL_FULLY_MODELED__ then
		flMultiplier = math_Remap( flMultiplier, 0, 1, MyTable.flAimSway, 1 )
	else
		flMultiplier = math_Remap( flMultiplier, 0, 1, MyTable.flPartiallyModeledAimSway, 1 )
	end

	if bSliding then
		vTarget:Add( WEAPON_SPRINT_RIFLE_DEFAULT )
		vTargetAngle:Add( WEAPON_SPRINT_RIFLE_DEFAULT_ANGLE )
	end

	ApplySway( MyTable, pos, ang, flMultiplier, flPitchTurn, flYawTurn, flFrameTime )

	vInstantTarget:Add( Vector( MyTable.flViewModelX, MyTable.flViewModelY, MyTable.flViewModelZ ) )

	vFinalVel = vFinalVel + ( vTarget - vFinal ) * SPRING_STIFFNESS_CURRENT * flFrameTime
	vFinalVel = vFinalVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
	vFinal = vFinal + vFinalVel * flFrameTime

	vFinalAngleVel = vFinalAngleVel + ( vTargetAngle - vFinalAngle ) * SPRING_STIFFNESS_CURRENT * flFrameTime
	vFinalAngleVel = vFinalAngleVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
	vFinalAngle = vFinalAngle + vFinalAngleVel * flFrameTime

	ang:RotateAroundAxis( ang:Right(), vFinalAngle[ 1 ] )
	ang:RotateAroundAxis( ang:Up(), vFinalAngle[ 2 ] )
	ang:RotateAroundAxis( ang:Forward(), vFinalAngle[ 3 ] )

	ang:RotateAroundAxis( ang:Right(), vInstantTargetAngle[ 1 ] )
	ang:RotateAroundAxis( ang:Up(), vInstantTargetAngle[ 2 ] )
	ang:RotateAroundAxis( ang:Forward(), vInstantTargetAngle[ 3 ] )

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
	pos:Add( vInstantTarget[ 1 ] * ang:Forward() )
	pos:Add( vInstantTarget[ 2 ] * ang:Right() )
	pos:Add( vInstantTarget[ 3 ] * ang:Up() )
	pos:Add( vFinalRatherQuick[ 1 ] * ang:Forward() )
	pos:Add( vFinalRatherQuick[ 2 ] * ang:Right() )
	pos:Add( vFinalRatherQuick[ 3 ] * ang:Up() )

	return pos, ang
end
