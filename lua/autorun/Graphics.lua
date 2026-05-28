// This is shared for a reason, and includes more than just client graphics

// Gets the human percieved brightness of a color
function GetBrightness( r, g, b ) return r * .00083372549 + g * .00280470588 + b * .00028313725 end
// Same as above but uses Colors
function GetBrightnessColor( c ) return c.r * .00083372549 + c.g * .00280470588 + c.b * .00028313725 end
// Same as above but uses Vectors
function GetBrightnessVector( v ) return v[ 1 ]  * .2126 + v[ 2 ] * .7152  + v[ 3 ] * .0722 end

if SERVER then
	CreateConVar(
		"bAllowThirdPerson",
		0,
		FCVAR_CHEAT + FCVAR_NEVER_AS_STRING,
		"Allow clients to use thirdperson mode (bThirdPerson)?",
		0, 1
	)
end

/*
net.Start "EphemeralLight"
	net.WriteFloat( 1 ) // Brightness
	net.WriteFloat( 1 ) // Size
	net.WriteFloat( 1 ) // Existence length
	net.WriteFloat( 1 ) // Fade time
	net.WriteVector( vector_origin ) // Position
	net.WriteUInt( 255, 8 ) net.WriteUInt( 255, 8 ) net.WriteUInt( 255, 8 ) // R, G, B
net.Broadcast()
*/

if SERVER then util.AddNetworkString "EphemeralLight" return end

local DynamicLight = DynamicLight
local net_ReadFloat = net.ReadFloat
local net_ReadVector = net.ReadVector
local net_ReadUInt = net.ReadUInt
local math_Round = math.Round
local math_Rand = math.Rand
local CurTime = CurTime
local iEphemeralIndexLast = 0

function EphemeralLight( tData )
	iEphemeralIndexLast = iEphemeralIndexLast + 1
	if iEphemeralIndexLast > 8192 then iEphemeralIndexLast = 0 end
	return DynamicLight( 8192 + iEphemeralIndexLast )
end

net.Receive( "EphemeralLight", function()
	local pLight = EphemeralLight()
	if pLight then
		pLight.brightness = net_ReadFloat()
		pLight.size = net_ReadFloat()
		pLight.dietime = CurTime() + net_ReadFloat()
		pLight.decay = 1000 / net_ReadFloat()
		pLight.pos = net_ReadVector()
		pLight.r = net_ReadUInt( 8 )
		pLight.g = net_ReadUInt( 8 )
		pLight.b = net_ReadUInt( 8 )
	end
end )

hook.Add( "PopulateToolMenu", "CascadeShadowMappingClient", function()
	spawnmenu.AddToolMenuOption( "Utilities", "User", "CascadeShadowMappingClient", "#CascadeShadowMapping", "", "", function( pPanel )
		pPanel:ClearControls()
		pPanel:ControlHelp "#CascadeShadowMappingInformation"
		// 65536 causes shadows to glitch... not sure about the numbers above,
		// but the maximum resolution you'd ever want is probably 65535,
		// because it is both extreme quality and doesn't glitch.
		// 3072 as minimum is because shadows below that resolution are way too ass.
		// EDIT: With clever usage of SetShadowFilter, I lowered
		// the minimum bound to 1024, because the shadows, even at that, now look good!
		// EDIT2: 2400 guarantees that shadows leak so subtly they look like
		// noise or materials, if any. We're not going lower than that!
		local p = pPanel:NumSlider( "#ShadowDepthResolution", "r_flashlightdepthres", 2400, 65535, 0 )
		pPanel:ControlHelp "#ShadowDepthResolutionHelp"
		p.OnValueChanged = function( self, flValue ) RunConsoleCommand( "r_flashlightdepthres", flValue ) end
	end )
end )
hook.Add( "PopulateToolMenu", "CascadeShadowMappingServer", function()
	spawnmenu.AddToolMenuOption( "Utilities", "Admin", "CascadeShadowMappingServer", "#CascadeShadowMapping", "", "", function( pPanel )
		pPanel:ClearControls()
		pPanel:ControlHelp "#CascadeShadowMappingInformation"
		local p = pPanel:CheckBox( "#CascadeShadowMapping", "bCascadeShadowMapping" )
		p:SetValue( false )
		pPanel:ControlHelp "#CascadeShadowMappingHelp"
	end )
end )

local cThirdPerson = CreateClientConVar( "bThirdPerson", "0", true, nil, "Enable thirdperson?", 0, 1 )
local cThirdPersonShoulder = CreateClientConVar( "bThirdPersonShoulder", "0", true, nil, "Should thirdperson use the left shoulder?", 0, 1 )

local util_TraceLine = util.TraceLine
local MASK_VISIBLE_AND_NPCS = MASK_VISIBLE_AND_NPCS
local LocalPlayer = LocalPlayer
local EyePos = EyePos
local EyeVector = EyeVector
local EyeAngles = EyeAngles
local vUpHuge = Vector( 0, 0, 999999 )

// Similar to util.IsSkyboxVisibleFromPoint
function UTIL_IsUnderSkybox()
	return util_TraceLine( {
		start = EyePos(),
		endpos = EyePos() + vUpHuge,
		filter = LocalPlayer(),
		mask = MASK_VISIBLE_AND_NPCS
	} ).HitSky
end

function DrawBlur( flIntensity ) DrawBokehDOF( flIntensity, 0, 0 ) end

local MAX_WATER_BLUR = 3
// [ 0, 1 ], Not [ 0, MAX_WATER_BLUR ]!
local WATER_BLUR_CHANGE_SPEED_TO = .8
local WATER_BLUR_CHANGE_SPEED_FROM = .2

include "postprocess/bloom.lua"
local DrawBloom = DrawBloom
include "postprocess/color_modify.lua"
local DrawColorModify = DrawColorModify

local IsValid = IsValid

local math = math
local math_Clamp = math.Clamp
local math_Remap = math.Remap
local math_Approach = math.Approach
local math_max = math.max
local math_abs = math.abs

local function VectorSum( v ) return math_abs( v[ 1 ] ) + math_abs( v[ 2 ] ) + math_abs( v[ 3 ] ) end

local render = render
local render_ComputeLighting = render.ComputeLighting
local render_ComputeDynamicLighting = render.ComputeDynamicLighting

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local FrameTime = FrameTime

local math_Remap = math.Remap

BREEZE_COLOR = Color( 80, 180, 240 )
BREEZE_VECTOR_COLOR = BREEZE_COLOR:ToVector()

local Lerp = Lerp
local math_min = math.min

local ANALYZATION_STEP = 22.5 / 4

local mDepthOfField = Material "pp/dof"

local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite

local cam_Start3D = cam.Start3D
local render_UpdateRefractTexture = render.UpdateRefractTexture
local cam_End3D = cam.End3D

local tDrawColorModify = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0
}

local RealTime = RealTime

local vColor, flColorSum, flColor = Vector(), 0, 0

local bBleedingBlur
local flBleedingBlur = 0
local flBleedingMotionBlurAdd = 0
local flBleedingMotionBlurDraw = 0

local bWaterBlur
local flWaterBlur = 0
local flWaterBlurDirect = 0
local flWaterBlurRefractAmount = 0

local flBloom = 0

local flFogDensityMul = 0
local flFogDistance = 0
local flFogR, flFogG, flFogB = 0, 0, 0
local flFogMaxDensity = 0

local flBloomDarken, flBloomMultiply, flBloomColorMultiply = 0, 0, 0

local flDepthOfField, flDistance, flSpacing = 0, 0, 0, 0

local flLastTickCall = RealTime()
hook.Add( "Tick", "Graphics", function()
	local flFrameTime = RealTime() - flLastTickCall
	if flFrameTime < .05 then return end // This will be ran 20 FPS MAX
	flLastTickCall = RealTime()
	local self = LocalPlayer()
	if !IsValid( self ) then return end
	vColor = Vector()
	local iPasses = 0
	local vEye, aEye, dEye = EyePos(), EyeAngles(), EyeVector()
	for flPitch = -22.5, 22.5, ANALYZATION_STEP do
		for flYaw = -22.5, 22.5, ANALYZATION_STEP do
			iPasses = iPasses + 1
			aEye[ 1 ] = aEye[ 1 ] + flPitch
			aEye[ 2 ] = aEye[ 2 ] + flYaw
			local tr = util_TraceLine {
				start = vEye,
				endpos = vEye + aEye:Forward() * 999999,
				mask = MASK_VISIBLE_AND_NPCS,
				filter = self
			}
			local vHitPos, dHitNormal = tr.HitPos, tr.HitNormal
			vColor:Add( render_ComputeLighting( vHitPos, dHitNormal ) )
			vColor:Add( render_ComputeDynamicLighting( vHitPos, dHitNormal ) )
			aEye[ 1 ] = aEye[ 1 ] - flPitch
			aEye[ 2 ] = aEye[ 2 ] - flYaw
		end
	end
	vColor:Div( iPasses )
	flColorSum = VectorSum( vColor )
	local flOxygen, flOxygenLimit = self:GetNW2Float( "GAME_flOxygen", -1 ), self:GetNW2Float( "GAME_flOxygenLimit", -1 )
	if flOxygen != -1 && flOxygenLimit != -1 then
		local f = flOxygenLimit * .33
		if flOxygen <= f then
			tDrawColorModify[ "$pp_colour_contrast" ] = tDrawColorModify[ "$pp_colour_contrast" ] * math_Remap( flOxygen, f, 0, 1, 0 )
		else tDrawColorModify[ "$pp_colour_contrast" ] = 1 end
	else tDrawColorModify[ "$pp_colour_contrast" ] = 1 end
	local flDeath = math_Clamp( self:Health() / self:GetMaxHealth(), 0, 1 )
	local f = ( 1 - flDeath ) * 4
	DrawSharpen( f, f )
	tDrawColorModify[ "$pp_colour_colour" ] = math_Remap( flDeath, 1, 0, 1, 0 )
	local f = math_Clamp( math_Remap( self:GetNW2Float( "GAME_flBlood", 0 ), .2, 1, 0, 1 ) - self:GetNW2Float( "GAME_flBleeding", 0 ) * 2, 0, 1 )
	if f < 1 then
		bBleedingBlur = true
		flBleedingBlur = math_Clamp( math_Remap( f, 1, 0, 0, 4 ), 0, 4 ) * f
		flBleedingMotionBlurAdd = math_Clamp( math_Remap( f, 1, 0, .5, .05 ), .05, .5 ) / f
		flBleedingMotionBlurDraw = math_Clamp( 1 - f, 0, 1 ) * f
	else bBleedingBlur = nil end
	if self:WaterLevel() >= 3 then
		flWaterBlur = math_Approach( flWaterBlur || 0, 1, WATER_BLUR_CHANGE_SPEED_TO * flFrameTime )
	else flWaterBlur = math_Approach( flWaterBlur || 0, 0, WATER_BLUR_CHANGE_SPEED_FROM * flFrameTime ) end
	bWaterBlur = flWaterBlur > 0
	flWaterBlurDirect = flWaterBlur * MAX_WATER_BLUR
	flWaterBlurRefractAmount = flWaterBlur * .01
	local vTargetColor = LerpVector( ( flColorSum / 3 ) ^ .5, vColor, BREEZE_VECTOR_COLOR )
	flFogDensityMul = math_Approach( flFogDensityMul || .1, math_Remap( math_Clamp( VectorSum( vTargetColor ), 0, 1 ), 0, 1, .25, .5 ), flFrameTime )
	flColor = math_Clamp( flColorSum, 0, 1 )
	flFogR = math_Approach( flFogR || 255, vTargetColor[ 1 ] * 255, 32 * flFrameTime )
	flFogG = math_Approach( flFogG || 255, vTargetColor[ 2 ] * 255, 32 * flFrameTime )
	flFogB = math_Approach( flFogB || 255, vTargetColor[ 3 ] * 255, 32 * flFrameTime )
	flFogDistance = Lerp( math_min( 1, 10 * flFrameTime ), flFogDistance, UTIL_IsUnderSkybox() && math_Remap( flColor, 0, 1, 512, 12288 ) || math_Remap( flColor, 0, 1, 512, 3072 ) )
	local flBrightness = GetBrightness( flFogR, flFogG, flFogB )
	local flMultiplier = math_Remap( flBrightness, 0, 1, 1, 0 )
	local flFogR, flFogG, flFogB = flFogR * .00392156862, flFogG * .00392156862, flFogB * .00392156862
	tDrawColorModify[ "$pp_colour_addr" ] = flFogR * .33 * flMultiplier
	tDrawColorModify[ "$pp_colour_addg" ] = flFogG * .33 * flMultiplier
	tDrawColorModify[ "$pp_colour_addb" ] = flFogB * .33 * flMultiplier
	tDrawColorModify[ "$pp_colour_mulr" ] = flFogR * flMultiplier
	tDrawColorModify[ "$pp_colour_mulg" ] = flFogG * flMultiplier
	tDrawColorModify[ "$pp_colour_mulb" ] = flFogB * flMultiplier
	flBloom = Lerp( math_min( 1, FrameTime() * .5 ), flBloom || 0, 1 - flColor )
	flBloom = math_Clamp( flBloom + flWaterBlur * .2, 0, 1 )
	flBloomDarken = math_Remap( flBloom, 0, 1, .2, 0 )
	flBloomMultiply = math_Remap( flBloom, 0, 1, 2, 3 )
	flBloomColorMultiply = math_Remap( flBloom, 0, 1, 1.33, 2 )
	local pVehicle = self:GetNW2Entity "GAME_pVehicle"
	flDistance = Lerp(
		math_min( 1, 5 * FrameTime() ),
		flDepthOfField || 0,
		math_Clamp( util_TraceLine( {
			start = vEye,
			endpos = vEye + dEye * 999999,
			mask = MASK_VISIBLE_AND_NPCS,
			filter = IsValid( pVehicle ) && { self, pVehicle } || { self }
		} ).HitPos:Distance( EyePos() ), 0, 6144 )
	)
	flDepthOfField = flDistance * 1.5
	flFogMaxDensity = ( flBrightness < .5 && math_Remap( flBrightness, 0, .5, 0, 1 ) || math_Remap( flBrightness, .5, 1, 1, 0 ) ) * ( flFogDensityMul || 0 )
end )

hook.Add( "RenderScreenspaceEffects", "Graphics", function()
	if bWaterBlur then
		DrawBlur( flWaterBlurDirect )
		DrawMaterialOverlay( "effects/water_warp01", flWaterBlurRefractAmount )
	end
	if bBleedingBlur then
		DrawBlur( flBleedingBlur )
		DrawMotionBlur( flBleedingMotionBlurAdd, flBleedingMotionBlurDraw, 0 )
	end
	DrawMotionBlur( .66, 1, 0 )
	DrawBloom(
		flBloomDarken, flBloomMultiply,
		5, // Size X
		5, // Size Y
		1, // Passes
		flBloomColorMultiply, 1, 1, 1
	)
	DrawColorModify( tDrawColorModify )
	cam_Start3D()
		local vEye, vForward = EyePos(), EyeVector()
		render_UpdateRefractTexture()
		for i = 0, 32 do
			render_SetMaterial( mDepthOfField )
			local flSize = ( flDistance + flDistance * i ) * 8
			render_DrawSprite( vEye + vForward * ( flDistance + flDistance * i ), flSize, flSize, color_white )
		end
	cam_End3D()
end )

local render = render
local render_FogMode = render.FogMode
local render_FogColor = render.FogColor
local render_FogStart = render.FogStart
local render_FogEnd = render.FogEnd
local render_FogMaxDensity = render.FogMaxDensity
local MATERIAL_FOG_LINEAR = MATERIAL_FOG_LINEAR

hook.Add( "SetupWorldFog", "Graphics", function()
	local self = LocalPlayer()
	if !IsValid( self ) then return end
	render_FogMode( MATERIAL_FOG_LINEAR )
	render_FogColor( flFogR, flFogG, flFogB )
	render_FogStart( 0 )
	render_FogEnd( flFogDistance )
	render_FogMaxDensity( flFogMaxDensity )
	return true
end )

local Vector, Angle = Vector, Angle

local vThirdPersonCameraOffset = Vector()

local bAllowThirdPerson = GetConVar "bAllowThirdPerson"

local function fMoreEffects( ply, tView )
	local f = 1 - ply:GetNW2Float( "GAME_flBlood", 1 )
	tView.fov = tView.fov * ( 1 - math.abs( math.sin( RealTime() * .5 ) ) *
	( f + .0016 - ply:GetNW2Float( "GAME_flBleeding", 0 ) ) * FrameTime()
	* .125 )
end

local aThirdPerson = Angle( 0, math.Rand( 0, 360 ), 0 )

function ApplyRecoilToThirdPerson( aAngle ) aThirdPerson:Add( aAngle ) end

local flThirdPersonAttackTime = 0

hook.Add( "CreateMove", "Graphics", function( cmd )
	if bAllowThirdPerson && !bAllowThirdPerson:GetBool() then cThirdPerson:SetBool() return end
	if !cThirdPerson:GetBool() then return end
	local pPlayer = LocalPlayer()
	if !IsValid( pPlayer ) then return end
	local pWeapon = pPlayer:GetActiveWeapon()
	if IsValid( pWeapon ) && pWeapon.__WEAPON__ && pWeapon.bSniper && pWeapon.flAimMultiplier <= ( pWeapon.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then return end
	local aAim = pPlayer:GetAimVector()
	aAim[ 3 ] = 0
	aAim = aAim:Angle()
	local aDirection = Angle( aThirdPerson )
	aDirection[ 1 ] = 0
	aDirection[ 3 ] = 0
	local vDirection = Vector( cmd:GetForwardMove(), -cmd:GetSideMove(), 0 )
	vDirection:Rotate( aDirection )
	vDirection:Normalize()
	aDirection = vDirection:Angle()
	local flActualBiggerMove = math.max( math.abs( cmd:GetForwardMove() ), math.abs( cmd:GetSideMove() ) )
	local f = math.min( pPlayer:GetRunSpeed(), flActualBiggerMove )
	cmd:SetForwardMove( f * aAim:Forward():Dot( vDirection ) )
	cmd:SetSideMove( f * aAim:Right():Dot( vDirection ) )
	if cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) || cmd:KeyDown( IN_ZOOM ) then flThirdPersonAttackTime = RealTime() + .5 end
	local bSpecial = pPlayer:WaterLevel() > 0
	if RealTime() <= flThirdPersonAttackTime then
		cmd:SetViewAngles( LerpAngle( math.min( 1, 22.5 * FrameTime() ), cmd:GetViewAngles(), aThirdPerson ) )
		if math.AngleDifference( cmd:GetViewAngles()[ 1 ], aThirdPerson[ 1 ] ) > 1 || math.AngleDifference( cmd:GetViewAngles()[ 2 ], aThirdPerson[ 2 ] ) > 1 then cmd:RemoveKey( IN_ATTACK ) end
	elseif !bSpecial && flActualBiggerMove > 0 && ( !cmd:KeyDown( IN_ATTACK ) && !cmd:KeyDown( IN_ATTACK2 ) && ( cmd:KeyDown( IN_SPEED ) || pPlayer:GetNW2Bool "CTRL_bSprinting" || pPlayer:GetNW2Bool "CTRL_bSliding" ) ) then
		local a = Angle( aDirection )
		a[ 1 ] = a[ 1 ] + 30
		local r = LerpAngle( math.min( 1, 5 * FrameTime() ), cmd:GetViewAngles(), a )
		r[ 3 ] = 0
		cmd:SetViewAngles( r )
	elseif bSpecial then
		cmd:SetViewAngles( LerpAngle( math.min( 1, FrameTime() ), cmd:GetViewAngles(), aThirdPerson ) )
	elseif flActualBiggerMove > 0 then
		local a = Angle( aDirection )
		a[ 1 ] = a[ 1 ] + 30
		local r = LerpAngle( math.min( 1, FrameTime() ), cmd:GetViewAngles(), a )
		r[ 3 ] = 0
		cmd:SetViewAngles( r )
	else
		local a = Angle( aAim )
		a[ 0 ] = 0
		local r = LerpAngle( math.min( 1, FrameTime() ), cmd:GetViewAngles(), a )
		r[ 3 ] = 0
		cmd:SetViewAngles( r )
	end
end )

hook.Add( "InputMouseApply", "Graphics", function( _, x, y )
	if bAllowThirdPerson && !bAllowThirdPerson:GetBool() then cThirdPerson:SetBool() return end
	local pPlayer = LocalPlayer()
	if !IsValid( pPlayer ) then return end
	local pWeapon = pPlayer:GetActiveWeapon()
	if IsValid( pWeapon ) && pWeapon.__WEAPON__ && pWeapon.bSniper && pWeapon.flAimMultiplier <= ( pWeapon.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then return end
	if !cThirdPerson:GetBool() then return end
	aThirdPerson[ 1 ] = aThirdPerson[ 1 ] + y * FrameTime()
	aThirdPerson[ 2 ] = aThirdPerson[ 2 ] - x * FrameTime()
	return true
end )

hook.Add( "CalcView", "Graphics", function( ply, origin, angles, fov, znear, zfar )
	local view = {
		origin = origin,
		angles = angles,
		fov = fov,
		znear = znear,
		zfar = zfar,
		drawviewer = false
	}
	if drive.CalcView( ply, view ) then
		fMoreEffects( ply, view )
		return view
	end
	local pVehicle = ply:GetNW2Entity "GAME_pVehicle"
	if IsValid( pVehicle ) then
		local vSeat = pVehicle:GetSeatPosition()
		local ang = pVehicle:GetAngles()
		vSeat:Rotate( ang )
		local vView = ply:GetViewOffsetDucked()
		vView:Rotate( ang )
		view.origin = pVehicle:GetPos() + vSeat + vView
		fMoreEffects( ply, view )
		cThirdPerson:SetBool()
		return view
	elseif bAllowThirdPerson && !bAllowThirdPerson:GetBool() then cThirdPerson:SetBool()
	elseif cThirdPerson:GetBool() then
		local pWeapon = ply:GetActiveWeapon()
		if !( IsValid( pWeapon ) && pWeapon.__WEAPON__ && pWeapon.bSniper && pWeapon.flAimMultiplier <= ( pWeapon.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) ) then
			if IsValid( pWeapon ) && pWeapon.__WEAPON__ then pWeapon:CalcView( ply, Vector( 0, 0, 0 ), Angle( 0, 0, 0 ) ) end
			local VARIANTS, PEEK = ply:GetNW2Int "CTRL_Variants", ply:GetNW2Int "CTRL_Peek"
			view.drawviewer = true
			local bAiming = ply:KeyDown( IN_ZOOM )
			local vTarget = Vector( -ply:OBBMaxs()[ 1 ] * ( bAiming && 1 || 4 ), ( cThirdPersonShoulder:GetBool() && ply:OBBMaxs()[ 2 ] || -ply:OBBMaxs()[ 2 ] ) * ( bAiming && 1 || 2 ), ply:OBBMaxs()[ 3 ] * ( ply:Crouching() && .244 || .008 ) )
			local bInCover = ply:GetNW2Bool "CTRL_bInCover" || ply:GetNW2Bool "CTRL_bGunUsesCoverStance"
			if bInCover || PEEK != COVER_PEEK_NONE then
				if VARIANTS == COVER_VARIANTS_LEFT || PEEK == COVER_FIRE_LEFT || PEEK == COVER_BLINDFIRE_LEFT then
					vTarget[ 2 ] = ply:OBBMaxs()[ 2 ] * ( bAiming && 1 || 2 )
				elseif bInCover && VARIANTS == COVER_VARIANTS_RIGHT || PEEK == COVER_FIRE_RIGHT || PEEK == COVER_BLINDFIRE_RIGHT then
					vTarget[ 2 ] = -ply:OBBMaxs()[ 2 ] * ( bAiming && 1 || 2 )
				elseif bInCover && VARIANTS == COVER_VARIANTS_BOTH || PEEK == COVER_BLINDFIRE_UP || PEEK == COVER_FIRE_UP then
					// Nothing
				end
			end
			vThirdPersonCameraOffset = LerpVector( 3 * FrameTime(), vThirdPersonCameraOffset, vTarget )
			local v = Vector( vThirdPersonCameraOffset )
			v:Rotate( aThirdPerson )
			local f = ply:GetFOV() * .33
			local tr = util_TraceLine( {
				start = view.origin,
				endpos = view.origin + v:GetNormalized() * ( v:Length() + f ),
				mask = MASK_VISIBLE_AND_NPCS,
				filter = ply
			} )
			view.origin = tr.HitPos - tr.Normal * f
			view.angles = Angle( aThirdPerson ) + ply:GetViewPunchAngles()
			fMoreEffects( ply, view )
			return view
		end
	end
	player_manager.RunClass( ply, "CalcView", view )
	local pWeapon = ply:GetActiveWeapon()
	if IsValid( pWeapon ) then
		local f = pWeapon.CalcView
		if f then
			local origin, angles, fov = f( pWeapon, ply, Vector( view.origin ), Angle( view.angles ), view.fov )
			view.origin, view.angles, view.fov = origin || view.origin, angles || view.angles, fov || view.fov
		end
	end
	fMoreEffects( ply, view )
	return view
end )

surface.CreateFont( "ReinforcementsBar", {
	font = "Trebuchet24",
	extended = false,
	size = 32,
	weight = 100,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
} )
local flProgress = 0
local MARKER_SIZE = 20
local MARKER_SIZE_OUTLINE = MARKER_SIZE * 1.01
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine
local math_abs = math.abs
local PRECOMPUTED = 360 / ( 2 * math.pi ) * .8
local math_max = math.max
local math_cos = math.cos
local math_sin = math.sin
local math_rad = math.rad
local draw_NoTexture = draw.NoTexture
local surface_DrawRect = surface.DrawRect
local draw_DrawText = draw.DrawText
hook.Add( "HUDPaint", "Graphics", function()
	local ply = LocalPlayer()
	if !IsValid( ply ) then return end
	local flCenterX, flCenterY = ScrW() * .5, ScrH() * .5
	local i = 1
	local flOff, flSize, flThickness = flCenterY * .5, flCenterY * .04, flCenterY * .0002
	while true do
		local sI = tostring( i )
		local v = ply:GetNW2Vector( "GAME_v3DThreat" .. sI )
		if v == vector_origin then break end
		i = i + 1
		//	local ToScreen = v:ToScreen()
		//	local x, y = ToScreen.x, ToScreen.y
		//	local f = math.deg( math.atan2(
		//		flCenterY - y,
		//		x - flCenterX
		//	) )
		local f = ( v - EyePos() ):Angle()[ 2 ] - EyeAngles()[ 2 ] + 90
		surface_SetDrawColor( 0, 0, 0, 255 )
		for i = -1, 1, .5 do
			local flScale = flOff + i
			local flSegmentDistance = PRECOMPUTED / flScale
			for a = f - MARKER_SIZE_OUTLINE, f + MARKER_SIZE_OUTLINE - flSegmentDistance, flSegmentDistance do
				local flDelta = math_abs( a - f ) / MARKER_SIZE_OUTLINE
				local s = MARKER_SIZE_OUTLINE * ( 1 - flDelta ) * .6
				if flDelta <= .166 then s = s + math_abs( flDelta - .166 ) * 66 end
				s = s + 1
				local flCurveInward = flDelta ^ 2 * 5
				local flCurrentRadius = flScale - flCurveInward
				local flCurveInwardNext = ( math_abs( ( a + flSegmentDistance ) - f ) / MARKER_SIZE_OUTLINE ) ^ 2 * 5
				local flNextRadius = flScale - flCurveInwardNext
				surface_DrawLine(
					flCenterX + math_cos( math_rad( a ) ) * ( flCurrentRadius + s ),
					flCenterY - math_sin( math_rad( a ) ) * ( flCurrentRadius + s ),
					flCenterX + math_cos( math_rad( a + flSegmentDistance ) ) * flNextRadius,
					flCenterY - math_sin( math_rad( a + flSegmentDistance ) ) * flNextRadius
				)
			end
		end
		if ply:GetNW2Bool( "GAME_b3DThreat" .. sI ) then
			surface_SetDrawColor( 255, 0, 0, 255 )
		else surface_SetDrawColor( 255, 255, 255, 255 ) end
		for i = 0, 1, .5 do
			local flScale = flOff + i
			local flSegmentDistance = PRECOMPUTED / flScale
			for a = f - MARKER_SIZE, f + MARKER_SIZE - flSegmentDistance, flSegmentDistance do
				local flDelta = math_abs( a - f ) / MARKER_SIZE
				local s = MARKER_SIZE * ( 1 - flDelta ) * .6
				if flDelta <= .166 then s = s + math_abs( flDelta - .166 ) * 66 end
				local flCurveInward = flDelta ^ 2 * 5
				local flCurrentRadius = flScale - flCurveInward
				local flCurveInwardNext = ( math_abs( ( a + flSegmentDistance ) - f ) / MARKER_SIZE ) ^ 2 * 5
				local flNextRadius = flScale - flCurveInwardNext
				surface_DrawLine(
					flCenterX + math_cos( math_rad( a ) ) * ( flCurrentRadius + s ),
					flCenterY - math_sin( math_rad( a ) ) * ( flCurrentRadius + s ),
					flCenterX + math_cos( math_rad( a + flSegmentDistance ) ) * flNextRadius,
					flCenterY - math_sin( math_rad( a + flSegmentDistance ) ) * flNextRadius
				)
			end
		end
	end
	local f = ply:GetNW2Float( "ALARM_flHostileReinforcements", 0 )
	if f <= 0 then flProgress = 0 return end
	flProgress = Lerp( math.min( 1, RealFrameTime() ), flProgress, f )
	draw_NoTexture()
	local flHeight, flWidth = ScrH(), ScrW()
	local flLabelWidth, flLabelHeight = flHeight * .3, flHeight * .05
	surface_SetDrawColor( 0, 0, 0 )
	surface_DrawRect( flWidth * .5 - flLabelWidth * .5, flHeight * .033, flLabelWidth, flLabelHeight )
	draw_DrawText( language.GetPhrase "ReinforcementsBar", "ReinforcementsBar", flWidth * .5, flHeight * .033, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	surface_SetDrawColor( 64, 64, 64 )
	flLabelWidth = flLabelWidth * .9
	surface_DrawRect( flWidth * .5 - flLabelWidth * .5, flHeight * ( .033 + .033 ), flLabelWidth, flHeight * .008 )
	// The flashing is only activated when the true lerped progress is less than a half, not the smoothened one
	surface_SetDrawColor( 255, 255, 255, f <= .33 && math.abs( math.sin( RealTime() * math.Remap( f, 0, .33, .2, .1 ) ) ) * 255 || 255 )
	surface_DrawRect( flWidth * .5 - flLabelWidth * .5, flHeight * ( .033 + .033 ), flProgress * flLabelWidth, flHeight * .008 )
end )
