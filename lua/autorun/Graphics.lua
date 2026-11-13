// Gets the human percieved brightness of a color
function GetBrightness( r, g, b ) return r * .00083372549 + g * .00280470588 + b * .00028313725 end
// Same as above but uses Colors
function GetBrightnessColor( c ) return c.r * .00083372549 + c.g * .00280470588 + c.b * .00028313725 end
// Same as above but uses Vectors
function GetBrightnessVector( v ) return v[ 1 ]  * .2126 + v[ 2 ] * .7152  + v[ 3 ] * .0722 end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local min = math.min
local exp = math.exp

local function FRILerpRate( flRate, flFrameTime ) return min( 1, 1 - exp( -flRate * flFrameTime ) ) end

local cThirdPerson = CreateClientConVar( "bThirdPerson", "0", true, true, "Enable thirdperson?", 0, 1 )

if SERVER then
	util.AddNetworkString "UpdateLuminosity"
	util.AddNetworkString "EphemeralLight"
	util.AddNetworkString "ThirdPersonCameraDirection"

	local net_ReadColor = net.ReadColor
	net.Receive( "UpdateLuminosity", function( _, ply ) CEntity_GetTable( ply ).GAME_cLuminosity = net_ReadColor( false ) end )

	// NOTE: This whole third person here is just here to not be wasted.
	// It should probably have a different GLua supporting API on when to turn on, how to turn on, etc.

	local net_ReadVector = net.ReadVector
	net.Receive( "ThirdPersonCameraDirection", function( _, ply ) CEntity_GetTable( ply ).GAME_dThirdPersonCamera = net_ReadVector() end )

	CreateConVar(
		"bAllowThirdPerson",
		0,
		FCVAR_CHEAT + FCVAR_NEVER_AS_STRING,
		"Allow clients to use thirdperson mode (bThirdPerson)?",
		0, 1
	)

	return
end

local SUPPORTS_HDR = true

if render.GetDXLevel() < 80 then
	ErrorNoHalt( language.GetPhrase "Problem_NoHighDynamicRange_DirectXLevel" .. " " .. language.GetPhrase "Problem_HighDynamicRangeRant" )

	SUPPORTS_HDR = nil
end

local render_GetHDREnabled = render.GetHDREnabled
local mat_hdr_level = GetConVar "mat_hdr_level"

local bHaltCheck = true
hook.Add( "Initialize", "Graphics", function()
	if game.GetMap() != "lobby" then bHaltCheck = nil end
	hook.Remove( "Initialize", "Graphics" )
end )

local function DynamicHighDynamicRangeCheck()
	if bHaltCheck then return end

	if !render_GetHDREnabled() then
		if mat_hdr_level:GetInt() == 2 then // Fuck
			if SUPPORTS_HDR then
				ErrorNoHalt( language.GetPhrase "Problem_NoHighDynamicRange_NotSupported" .. " " .. language.GetPhrase "Problem_HighDynamicRangeRant" )
				SUPPORTS_HDR = nil
			end
		else // Shit
			ErrorNoHalt( language.GetPhrase "Problem_NoHighDynamicRange_Disabled" .. " " .. language.GetPhrase "Problem_HighDynamicRangeRant" )
		end
	end
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

RunConsoleCommand( "mp_show_voice_icons", "0" )

local DynamicLight = DynamicLight
local net_ReadFloat = net.ReadFloat
local net_ReadVector = net.ReadVector
local net_ReadUInt = net.ReadUInt
local math_Round = math.Round
local math_Rand = math.Rand
local CurTime = CurTime
local util_TraceLine = util.TraceLine
local MASK_VISIBLE_AND_NPCS = MASK_VISIBLE_AND_NPCS
local LocalPlayer = LocalPlayer
local EyePos = EyePos
local EyeVector = EyeVector
local IsValid = IsValid
local math_Clamp = math.Clamp
local math_Remap = math.Remap
local math_Approach = math.Approach
local math_max = math.max
local math_abs = math.abs
local render_GetLightColor = render.GetLightColor
local render_ComputeDynamicLighting = render.ComputeDynamicLighting
local FrameTime = FrameTime
local Lerp = Lerp
local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite
local render_UpdateRefractTexture = render.UpdateRefractTexture
local cam_Start3D = cam.Start3D
local cam_End3D = cam.End3D
local RealTime = RealTime
local vUpHuge = Vector( 0, 0, 999999 )
local net_Start = net.Start
local net_WriteColor = net.WriteColor
local net_SendToServer = net.SendToServer
local vector_origin = vector_origin
local render_FogMode = render.FogMode
local render_FogColor = render.FogColor
local render_FogStart = render.FogStart
local render_FogEnd = render.FogEnd
local render_FogMaxDensity = render.FogMaxDensity
local MATERIAL_FOG_LINEAR = MATERIAL_FOG_LINEAR
local Vector, Angle = Vector, Angle
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine
local math_cos = math.cos
local math_sin = math.sin
local math_rad = math.rad
local draw_NoTexture = draw.NoTexture
local surface_DrawRect = surface.DrawRect
local draw_DrawText = draw.DrawText

// Here are some weapon things that are too small to give them another file
VIEWMODEL_CAMERA_ANIMATIONS = VIEWMODEL_CAMERA_ANIMATIONS || {}

WPN_PISTOL = 1
WPN_RIFLE = 2
WPN_RIFLEUP = 3
WPN_SHOTGUN = 4
WPN_SNIPER = 5
WPN_SUBMACHINEGUN = 6

hook.Add( "DrawDeathNotice", "Graphics", function() return true end )
hook.Add( "HUDDrawTargetID", "Graphics", function() return true end )
hook.Add( "HUDWeaponPickedUp", "Graphics", function() return true end )
hook.Add( "HUDItemPickedUp", "Graphics", function() return true end )

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
		pPanel:CheckBox( "#CascadeShadowMapping", "bCascadeShadowMapping" )
		pPanel:ControlHelp "#CascadeShadowMappingHelp"
	end )
end )

local cThirdPersonShoulder = CreateClientConVar( "bThirdPersonShoulder", "0", true, nil, "Should thirdperson use the left shoulder?", 0, 1 )

function DrawBlur( flIntensity ) DrawBokehDOF( flIntensity, 0, 0 ) end

local MAX_WATER_BLUR = 6
local MAX_WATER_BLUR_REFRACT = .02

// [ 0, 1 ], not [ 0, MAX_WATER_BLUR ]!
local WATER_BLUR_CHANGE_SPEED_TO = .8
local WATER_BLUR_CHANGE_SPEED_FROM = .5

local function VectorSum( v ) return math_abs( v[ 1 ] ) + math_abs( v[ 2 ] ) + math_abs( v[ 3 ] ) end

BREEZE_COLOR = Color( 80, 180, 240 )
BREEZE_VECTOR_COLOR = BREEZE_COLOR:ToVector()

local ANALYZATION_STEP = 30

local mDepthOfField = Material "pp/dof"

g_pDrawColorModify = g_pDrawColorModify || {
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

local g_pDrawColorModify = g_pDrawColorModify

local vColor, flColorSum, flColor = Vector(), 0, 0

local bBleedingBlur
local flBleedingBlur = 0
local flBleedingMotionBlurAdd = 0
local flBleedingMotionBlurDraw = 0

WATER_BLUR = 0

local bWaterBlur
local flWaterBlurDirect = 0
local flWaterBlurRefractAmount = 0

local flBloom = 0

local flFogDensityMul = 0
local flFogDistance = 0
local flFogR, flFogG, flFogB = 0, 0, 0
local flFogMaxDensity = 0

local flBloomDarken, flBloomMultiply, flBloomColorMultiply = 0, 0, 0

local flDepthOfField, flSpacing = 0, 0

local DOFModeHack = DOFModeHack

local flActualDoFBegin = 0

local flNextSendLuminosity = 0

function RecalculateWaterBlurAmounts()
	if WATER_BLUR > 1 then WATER_BLUR = 1 end

	flWaterBlurDirect = WATER_BLUR * MAX_WATER_BLUR
	flWaterBlurRefractAmount = WATER_BLUR * MAX_WATER_BLUR_REFRACT
end

local RecalculateWaterBlurAmounts = RecalculateWaterBlurAmounts

local vTemp = Vector()

local CVector = FindMetaTable "Vector"

local CVector_Set = CVector.Set

local CVector_Mul = CVector.Mul
local CVector_Add = CVector.Add
local CVector_Div = CVector.Div

local CAngle_Forward = FindMetaTable( "Angle" ).Forward

local pLocalPlayer

local trRequestAnalyze = {
	endpos = vTemp,
	mask = MASK_VISIBLE_AND_NPCS,
	filter = function( pEntity )
		if pEntity == pLocalPlayer || pEntity.__PROJECTILE__ then return false end
		return true
	end
}

local pairs = pairs

g_pCurrentScreenspaceEffectsModifyColor = g_pCurrentScreenspaceEffectsModifyColor || {}
local g_pCurrentScreenspaceEffectsModifyColor = g_pCurrentScreenspaceEffectsModifyColor

local flLastTickCall = RealTime()
hook.Add( "Tick", "Graphics", function()
	pLocalPlayer = LocalPlayer()
	if !IsValid( pLocalPlayer ) then return end

	if RealTime() > flNextSendLuminosity then
		DynamicHighDynamicRangeCheck() // Do this here for optimization reasons
	
		flNextSendLuminosity = RealTime() + math_Rand( .1, .5 )
	
		net_Start( "UpdateLuminosity", true )

		local iPasses = 0

		CVector_Set( vColor, vector_origin )

		local vPos, aEye = pLocalPlayer:GetPos(), pLocalPlayer:EyeAngles()

		vPos:Add( pLocalPlayer:OBBCenter() )

		trRequestAnalyze.start = vPos

		local flLen = pLocalPlayer:BoundingRadius() * 1.5
		for flPitch = 0, 360, 33.75 do
			for flYaw = 0, 360, 33.75 do
				iPasses = iPasses + 1

				aEye[ 1 ] = aEye[ 1 ] + flPitch
				aEye[ 2 ] = aEye[ 2 ] + flYaw

				local vForward = CAngle_Forward( aEye )
				CVector_Mul( vForward, flLen )
				CVector_Set( vTemp, vPos )
				CVector_Add( vTemp, vForward )

				local tr = util_TraceLine( trRequestAnalyze )

				local vHitPos = tr.HitPos
				local vLight = render_GetLightColor( vHitPos )
				CVector_Add( vLight, render_ComputeDynamicLighting( vHitPos, tr.HitNormal ) )
				CVector_Mul( vLight, 1.5 )
				CVector_Add( vColor, vLight )

				aEye[ 1 ] = aEye[ 1 ] - flPitch
				aEye[ 2 ] = aEye[ 2 ] - flYaw
			end
		end

		CVector_Div( vColor, iPasses )

		net_WriteColor( vColor:ToColor(), false )
		net_SendToServer()
	end
	
	local flFrameTime = RealTime() - flLastTickCall
	if flFrameTime < .05 then return end // This will be ran 20 FPS MAX

	flLastTickCall = RealTime()

	g_pDrawColorModify[ "$pp_colour_addr" ] = 0
	g_pDrawColorModify[ "$pp_colour_addg" ] = 0
	g_pDrawColorModify[ "$pp_colour_addb" ] = 0

	g_pDrawColorModify[ "$pp_colour_mulr" ] = 0
	g_pDrawColorModify[ "$pp_colour_mulg" ] = 0
	g_pDrawColorModify[ "$pp_colour_mulb" ] = 0

	g_pDrawColorModify[ "$pp_colour_brightness" ] = 0
	g_pDrawColorModify[ "$pp_colour_contrast" ] = 1
	g_pDrawColorModify[ "$pp_colour_colour" ] = 1

	DOFModeHack( true )

	CVector_Set( vColor, vector_origin )

	local flPasses = 0
	local vEye, aEye = EyePos(), pLocalPlayer:EyeAngles()

	trRequestAnalyze.start = vEye

	for flPitch = -90, 90, ANALYZATION_STEP do
		for flYaw = -90, 90, ANALYZATION_STEP do
			aEye[ 1 ] = aEye[ 1 ] + flPitch
			aEye[ 2 ] = aEye[ 2 ] + flYaw

			local vForward = CAngle_Forward( aEye )
			CVector_Mul( vForward, 999999 )
			CVector_Set( vTemp, vEye )
			CVector_Add( vTemp, vForward )

			local tr = util_TraceLine( trRequestAnalyze )

			local vHitPos = tr.HitPos
			local vLight = render_GetLightColor( vHitPos )
			CVector_Add( vLight, render_ComputeDynamicLighting( vHitPos, tr.HitNormal ) )

			// Leaving this here in case anyone needs it
			// Do not uncomment this unless testing, as it produces a comical load lol
			//	debugoverlay.Cross( tr.HitPos, 14, 1, ( vLight * 3 ):ToColor(), true )

			flPasses = flPasses + .5 + VectorSum( vLight ) * .5

			CVector_Add( vColor, vLight )

			aEye[ 1 ] = aEye[ 1 ] - flPitch
			aEye[ 2 ] = aEye[ 2 ] - flYaw
		end
	end

	CVector_Div( vColor, flPasses )

	local vTargetColor = LerpVector( ( VectorSum( vColor ) / 3 ) ^ 2, vColor, BREEZE_VECTOR_COLOR )
	flFogR = math_Approach( flFogR, vTargetColor[ 1 ] * 255, 32 * flFrameTime )
	flFogG = math_Approach( flFogG, vTargetColor[ 2 ] * 255, 32 * flFrameTime )
	flFogB = math_Approach( flFogB, vTargetColor[ 3 ] * 255, 32 * flFrameTime )

	vColor[ 1 ] = vColor[ 1 ] ^ .5
	vColor[ 2 ] = vColor[ 2 ] ^ .5
	vColor[ 3 ] = vColor[ 3 ] ^ .5

	flColorSum = VectorSum( vColor )

	local flDeath = math_Clamp( pLocalPlayer:Health() / pLocalPlayer:GetMaxHealth(), 0, 1 ) ^ 1.5
	g_pDrawColorModify[ "$pp_colour_colour" ] = g_pDrawColorModify[ "$pp_colour_colour" ] * flDeath

	local flOxygen, flOxygenLimit = pLocalPlayer:GetNW2Float( "GAME_flOxygen", -1 ), pLocalPlayer:GetNW2Float( "GAME_flOxygenLimit", -1 )
	if flOxygen != -1 && flOxygenLimit != -1 then
		local f = flOxygenLimit * .5
		if flOxygen <= f then
			g_pDrawColorModify[ "$pp_colour_contrast" ] = g_pDrawColorModify[ "$pp_colour_contrast" ] * math_Remap( flOxygen, f, 0, 1, 0 )
		end
	end

	local f = math_Clamp( math_Remap( pLocalPlayer:GetNW2Float( "GAME_flBlood", 0 ), .2, 1, 0, 1 ) - pLocalPlayer:GetNW2Float( "GAME_flBleeding", 0 ) * 2, 0, 1 )
	if f < 1 then
		bBleedingBlur = true
		flBleedingBlur = math_Clamp( math_Remap( f, 1, 0, 0, 4 ), 0, 4 ) * f
		flBleedingMotionBlurAdd = math_Clamp( math_Remap( f, 1, 0, .5, .05 ), .05, .5 ) / f
		flBleedingMotionBlurDraw = math_Clamp( 1 - f, 0, 1 ) * f
	else bBleedingBlur = nil end
	if pLocalPlayer:WaterLevel() >= 3 then
		WATER_BLUR = math_Approach( WATER_BLUR || 0, 1, WATER_BLUR_CHANGE_SPEED_TO * flFrameTime )
	else WATER_BLUR = math_Approach( WATER_BLUR || 0, 0, WATER_BLUR_CHANGE_SPEED_FROM * flFrameTime ) end
	bWaterBlur = WATER_BLUR > 0
	RecalculateWaterBlurAmounts()

	local flBrightness = GetBrightness( flFogR, flFogG, flFogB )

	flBloom = Lerp( FRILerpRate( .5, flFrameTime ), flBloom || 0, math_max( 0, 1 - flColorSum ) )

	flBloomDarken = math_Remap( flBloom, 0, 1, .2, 0 )
	flBloomMultiply = math_Remap( flBloom, 0, 1, .5, 6 )
	flBloomColorMultiply = math_Remap( flBloom, 0, 1, 1, 1.25 )

	flFogDensityMul = math_Approach( flFogDensityMul, math_Remap( math_Clamp( VectorSum( vTargetColor ), 0, 1 ), 0, 1, .2, 1 ), flFrameTime )
	flFogDistance = Lerp( FRILerpRate( 2, flFrameTime ), flFogDistance, math_Remap( flColorSum, 0, 1, 512, 12288 ) )
	flFogMaxDensity = ( flBrightness < .5 && math_Remap( flBrightness, 0, .5, 0, 1 ) || math_Remap( flBrightness, .5, 1, 1, 0 ) ) * ( flFogDensityMul || 0 )

	local pVehicle = pLocalPlayer:GetNW2Entity "GAME_pVehicle"

	local vForward = EyeVector()
	CVector_Mul( vForward, 999999 )
	CVector_Add( vForward, vEye )

	local tr = util_TraceLine {
		start = vEye,
		endpos = vEye + EyeVector() * 999999,
		mask = MASK_OPAQUE_AND_NPCS,
		filter = function( pEntity )
			if pEntity == pLocalPlayer || pEntity == pVehicle || pEntity.__PROJECTILE__ then return false end
			return true
		end
	}

	local flDistance = tr.HitPos:Distance( EyePos() ) * 1.2

	flDepthOfField = Lerp(
		FRILerpRate( 10, flFrameTime ),
		flDepthOfField,	
		flDistance
	)

	flSpacing = Lerp(
		FRILerpRate( 10, flFrameTime ),
		flSpacing,
		math_Clamp( flDistance, 0, 1024 )
	)

	if tr.HitSky then
		flActualDoFBegin = Lerp( FRILerpRate( 1.5, flFrameTime ), flActualDoFBegin, math_Clamp( ( flDepthOfField / flDistance ) ^ 10 * 5, 0, 5 ) )
	else
		flActualDoFBegin = Lerp( FRILerpRate( 1.5, flFrameTime ), flActualDoFBegin, 0 )
	end

	for _, pEffect in pairs( g_pCurrentScreenspaceEffectsModifyColor ) do pEffect() end
end )

g_pCurrentScreenspaceEffectsPreBuiltIn = g_pCurrentScreenspaceEffectsPreBuiltIn || {}
local g_pCurrentScreenspaceEffectsPreBuiltIn = g_pCurrentScreenspaceEffectsPreBuiltIn

local cvBuildingCubemaps = GetConVar "building_cubemaps"
hook.Add( "RenderScreenspaceEffects", "Graphics", function()
	if cvBuildingCubemaps:GetBool() then return end

	for _, pEffect in pairs( g_pCurrentScreenspaceEffectsPreBuiltIn ) do pEffect() end

	if bWaterBlur then
		DrawBlur( flWaterBlurDirect )
		DrawMaterialOverlay( "effects/water_warp01", flWaterBlurRefractAmount )
	end

	if bBleedingBlur then
		DrawBlur( flBleedingBlur )
		DrawMotionBlur( flBleedingMotionBlurAdd, flBleedingMotionBlurDraw, 0 )
	end

	DrawBloom(
		flBloomDarken, flBloomMultiply,
		4, // Size X
		4, // Size Y
		4, // Passes
		flBloomColorMultiply, 1, 1, 1
	)

	DrawColorModify( g_pDrawColorModify )

	cam_Start3D()
		local vEye, vForward = EyePos(), EyeVector()
		for i = flActualDoFBegin, 4 do
			render_UpdateRefractTexture()
			render_SetMaterial( mDepthOfField )
			local flSize = ( flDepthOfField + flSpacing * i ) * 8
			render_DrawSprite( vEye + vForward * ( flDepthOfField + flSpacing * i ), flSize, flSize, color_white )
		end
	cam_End3D()
end )

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

hook.Add( "SetupSkyboxFog", "Graphics", function( flScale )
	local self = LocalPlayer()
	if !IsValid( self ) then return end
	render_FogMode( MATERIAL_FOG_LINEAR )
	render_FogColor( flFogR, flFogG, flFogB )
	render_FogStart( 0 )
	render_FogEnd( flFogDistance * flScale )
	render_FogMaxDensity( flFogMaxDensity )
	return true
end )

hook.Add( "HUDDrawPickupHistory", "Graphics", function() return true end )

local vThirdPersonCameraOffset = Vector()

local bAllowThirdPerson = GetConVar "bAllowThirdPerson"

local function fMoreEffects( ply, tView )
	local f = 1 - ply:GetNW2Float( "GAME_flBlood", 1 )
	tView.fov = tView.fov * ( 1 - math.abs( math.sin( RealTime() * .5 ) ) * f * .125 )
end

local aThirdPerson = Angle( 0, math.Rand( 0, 360 ), 0 )

function AddAngleToThirdPersonFacing( aAngle ) aThirdPerson:Add( aAngle ) end
//	function ApplyRecoilToThirdPerson( aAngle ) aThirdPerson:Add( aAngle ) end

local flThirdPersonAttackTime = 0

local aLastThirdPersonAngle = Angle()
local flThirdPersonToAttackLerp = 0

local net_WriteVector = net.WriteVector

local flWheelTime = 0
local flSelectCooldown = 0
local bLastWheelUp

g_flLastSelectWeaponIndex = g_flLastSelectWeaponIndex || 0

hook.Add( "CreateMove", "Graphics", function( cmd )
	local pPlayer = LocalPlayer()
	if !IsValid( pPlayer ) then return end

	if !cmd:KeyDown( IN_SPEED ) then
		local flWheel = cmd:GetMouseWheel()

		if bLastWheelUp == nil || CurTime() <= flWheelTime then
			if CurTime() > flSelectCooldown && flWheel != 0 then
				g_flLastSelectWeaponIndex = g_flLastSelectWeaponIndex + flWheel

				bLastWheelUp = flWheel > 0

				local pWeapons = pPlayer:GetWeapons()
				local pSelect = pWeapons[ math.floor( g_flLastSelectWeaponIndex ) ]
				if !IsValid( pSelect ) then g_flLastSelectWeaponIndex = bLastWheelUp && 1 || #pWeapons end

				flWheelTime = CurTime() + .1
			end
		else
			flSelectCooldown = CurTime() + .1

			local pWeapons = pPlayer:GetWeapons()

			local pSelect = pWeapons[ math.floor( g_flLastSelectWeaponIndex ) ]

			// For SOME REASON, cmd:SelectWeapon just DOES NOT WORK lol
			if IsValid( pSelect ) then
				input.SelectWeapon( pSelect )
			else
				g_flLastSelectWeaponIndex = bLastWheelUp && 1 || #pWeapons

				local pSelect = pWeapons[ g_flLastSelectWeaponIndex ]

				if IsValid( pSelect ) then input.SelectWeapon( pSelect ) end
			end

			bLastWheelUp = nil
		end
	end

	local pWeapon = pPlayer:GetActiveWeapon()
	if IsValid( pWeapon ) then
		// I love Modern Wokefare and patched this for it!! :)
		// Though sadly it has no flag so we check this instead
		if pWeapon.Camera && pWeapon.m_AimModeDeltaLerp then
			local bZoom, bAttack2 = cmd:KeyDown( IN_ZOOM ), cmd:KeyDown( IN_ATTACK2 )
			if bZoom == bAttack2 then
			elseif bZoom then
				cmd:RemoveKey( IN_ZOOM )
				cmd:AddKey( IN_ATTACK2 )
			else
				cmd:RemoveKey( IN_ATTACK2 )
				cmd:AddKey( IN_ZOOM )
			end
		end
	end

	if bAllowThirdPerson && !bAllowThirdPerson:GetBool() then return end
	if !cThirdPerson:GetBool() then return end
	if IsValid( pWeapon ) && pWeapon.__WEAPON__ && pWeapon.bSniper && pWeapon.flAimMultiplier <= ( pWeapon.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then return end

	net_Start "ThirdPersonCameraDirection"
		net_WriteVector( aThirdPerson:Forward() )
	net_SendToServer()

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
	local f = min( pPlayer:GetRunSpeed(), flActualBiggerMove )
	cmd:SetForwardMove( f * aAim:Forward():Dot( vDirection ) )
	cmd:SetSideMove( f * aAim:Right():Dot( vDirection ) )

	if cmd:KeyDown( IN_SPEED ) || pPlayer:GetNW2Bool "CTRL_bSliding" then
		flThirdPersonToAttackLerp = Lerp( FRILerpRate( 5, FrameTime() ), flThirdPersonToAttackLerp, 0 )
	
		local r = LerpAngle( FRILerpRate( 1, FrameTime() ), cmd:GetViewAngles(), aDirection )
		r[ 3 ] = 0
		cmd:SetViewAngles( r )
		aLastThirdPersonAngle = Angle( r )
	
		return
	end

	if cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) || cmd:KeyDown( IN_ZOOM ) then flThirdPersonAttackTime = RealTime() + .5 end

	local bSpecial = !pPlayer:IsOnGround() && pPlayer:WaterLevel() > 0
	if RealTime() <= flThirdPersonAttackTime then
		flThirdPersonToAttackLerp = Lerp( FRILerpRate( 5, FrameTime() ), flThirdPersonToAttackLerp, 1 )

		cmd:SetViewAngles( LerpAngle( flThirdPersonToAttackLerp, aLastThirdPersonAngle, aThirdPerson ) )
		if math.AngleDifference( cmd:GetViewAngles()[ 1 ], aThirdPerson[ 1 ] ) > 1 || math.AngleDifference( cmd:GetViewAngles()[ 2 ], aThirdPerson[ 2 ] ) > 1 then cmd:RemoveKey( IN_ATTACK ) end

	elseif !bSpecial && flActualBiggerMove > 0 then
		flThirdPersonToAttackLerp = Lerp( FRILerpRate( 5, FrameTime() ), flThirdPersonToAttackLerp, 0 )

		local r = LerpAngle( FRILerpRate( 5, FrameTime() ), cmd:GetViewAngles(), aDirection )
		cmd:SetViewAngles( r )
		aLastThirdPersonAngle = Angle( r )

	elseif bSpecial then
		flThirdPersonToAttackLerp = Lerp( FRILerpRate( 5, FrameTime() ), flThirdPersonToAttackLerp, 0 )

		cmd:SetViewAngles( LerpAngle( FRILerpRate( 1, FrameTime() ), cmd:GetViewAngles(), aThirdPerson ) )
		aLastThirdPersonAngle = LerpAngle( FRILerpRate( 1, FrameTime() ), cmd:GetViewAngles(), aThirdPerson )

	elseif flActualBiggerMove > 0 then
		flThirdPersonToAttackLerp = Lerp( FRILerpRate( 5, FrameTime() ), flThirdPersonToAttackLerp, 0 )

		local r = LerpAngle( FRILerpRate( 1, FrameTime() ), cmd:GetViewAngles(), aDirection )
		r[ 3 ] = 0
		cmd:SetViewAngles( r )
		aLastThirdPersonAngle = Angle( r )

	else
		flThirdPersonToAttackLerp = Lerp( FRILerpRate( 5, FrameTime() ), flThirdPersonToAttackLerp, 0 )

		local a = Angle( aAim )
		a[ 0 ] = 0
		local r = LerpAngle( FRILerpRate( 1, FrameTime() ), cmd:GetViewAngles(), a )
		r[ 3 ] = 0
		cmd:SetViewAngles( r )
		aLastThirdPersonAngle = Angle( r )
	end
end )

hook.Add( "InputMouseApply", "Graphics", function( _, x, y )
	local pPlayer = LocalPlayer()
	if !IsValid( pPlayer ) then return end

	local pWeapon = pPlayer:GetActiveWeapon()
	if IsValid( pWeapon ) then
		local fFreezeMovement = pWeapon.FreezeMovement
		if fFreezeMovement && fFreezeMovement( pWeapon ) then return end
	end

	x = x * FrameTime()
	y = y * FrameTime()

	local flPitch = pPlayer:EyeAngles()[ 1 ]
	local flRealY = ( flPitch <= -89 || flPitch >= 89 ) && 0 || y

	if WEAPON_SWAY then
		WEAPON_SWAY[ 1 ] = WEAPON_SWAY[ 1 ] - flRealY
		WEAPON_SWAY[ 2 ] = WEAPON_SWAY[ 2 ] + x
	end

	if bAllowThirdPerson && !bAllowThirdPerson:GetBool() then return end

	local pWeapon = pPlayer:GetActiveWeapon()
	if IsValid( pWeapon ) && pWeapon.__WEAPON__ && pWeapon.bSniper && pWeapon.flAimMultiplier <= ( pWeapon.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then return end
	if !cThirdPerson:GetBool() then return end
	aThirdPerson[ 1 ] = aThirdPerson[ 1 ] + y
	aThirdPerson[ 2 ] = aThirdPerson[ 2 ] - x
	return true
end )

hook.Add( "CalcView", "Graphics", function( ply, origin, angles, fov, znear, zfar )
	local tView = {
		origin = origin,
		angles = angles,
		fov = fov == ply:GetInfoNum( "fov_desired", 75 ) && UNIVERSAL_FOV || fov,
		znear = znear,
		zfar = zfar,
		drawviewer = false
	}

	if drive.CalcView( ply, tView ) then
		fMoreEffects( ply, tView )
		return tView
	end

	local pVehicle = ply:GetNW2Entity "GAME_pVehicle"
	if IsValid( pVehicle ) then
		local vSeat = pVehicle:GetSeatPosition()
		local ang = pVehicle:GetAngles()
		vSeat:Rotate( ang )
		local vView = ply:GetViewOffsetDucked()
		vView:Rotate( ang )
		tView.origin = pVehicle:GetPos() + vSeat + vView
		fMoreEffects( ply, tView )
		return tView
	elseif bAllowThirdPerson && !bAllowThirdPerson:GetBool() then
	elseif cThirdPerson:GetBool() then
		local pWeapon = ply:GetActiveWeapon()
		if !( IsValid( pWeapon ) && pWeapon.__WEAPON__ && pWeapon.bSniper && pWeapon.flAimMultiplier <= ( pWeapon.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) ) then
			if IsValid( pWeapon ) && pWeapon.__WEAPON__ then pWeapon:CalcView( ply, Vector( 0, 0, 0 ), Angle( 0, 0, 0 ) ) end
			local VARIANTS, PEEK = ply:GetNW2Int "CTRL_Variants", ply:GetNW2Int "CTRL_Peek"
			tView.drawviewer = true
			local bAiming = !ply:GetNW2Bool "CTRL_bSprinting" && ply:KeyDown( IN_ZOOM )
			local bWalking = ply:GetVelocity():Length() > ply:GetSlowWalkSpeed() * .9
			local vTarget = Vector(
				( ply:OBBMaxs()[ 1 ] / HULL_HUMAN_MAXS[ 1 ] ) * -8 * ( bAiming && 2.5 || 5 ),
				( cThirdPersonShoulder:GetBool() && ply:OBBMaxs()[ 2 ] || -ply:OBBMaxs()[ 2 ] ) / HULL_HUMAN_MAXS[ 2 ] * 8 * ( bAiming && 2 || 3 ) * ( ( bAiming && bWalking ) && 1.3 || 1 ),
				ply:OBBMaxs()[ 3 ] / HULL_HUMAN_MAXS[ 3 ] * 66 * ( ply:Crouching() && ( bWalking && .2 || -.1 ) || ( bAiming && -.02 || -.004 ) ) )
			local bInCover = ply:GetNW2Bool "CTRL_bInCover" || ply:GetNW2Bool "CTRL_bGunUsesCoverStance"
			if bInCover || PEEK != COVER_PEEK_NONE then
				if VARIANTS == COVER_VARIANTS_LEFT || PEEK == COVER_FIRE_LEFT || PEEK == COVER_BLINDFIRE_LEFT then
					vTarget[ 2 ] = ply:OBBMaxs()[ 2 ] / HULL_HUMAN_MAXS[ 2 ] * 8 * ( bAiming && 2 || 4 )
					vTarget[ 3 ] = ply:OBBMaxs()[ 3 ] / HULL_HUMAN_MAXS[ 3 ] * 66 * .04
				elseif bInCover && VARIANTS == COVER_VARIANTS_RIGHT || PEEK == COVER_FIRE_RIGHT || PEEK == COVER_BLINDFIRE_RIGHT then
					vTarget[ 2 ] = -ply:OBBMaxs()[ 2 ] / HULL_HUMAN_MAXS[ 2 ] * 8 * ( bAiming && 2 || 4 )
					vTarget[ 3 ] = ply:OBBMaxs()[ 3 ] / HULL_HUMAN_MAXS[ 3 ] * 66 * .04
				elseif bInCover && VARIANTS == COVER_VARIANTS_BOTH || PEEK == COVER_BLINDFIRE_UP || PEEK == COVER_FIRE_UP then
					if !bAiming && RealTime() > flThirdPersonAttackTime then vTarget[ 2 ] = 0 end
				end
			end
			vThirdPersonCameraOffset = LerpVector( FRILerpRate( 4, FrameTime() ), vThirdPersonCameraOffset, vTarget )
			local v = Vector( vThirdPersonCameraOffset )
			v:Rotate( aThirdPerson )
			local f = UNIVERSAL_FOV / 3
			local tr = util_TraceLine( {
				start = tView.origin,
				endpos = tView.origin + v:GetNormalized() * ( v:Length() + f ),
				mask = MASK_VISIBLE_AND_NPCS,
				filter = function( pEntity )
					if pEntity == ply || pEntity.__PROJECTILE__ then return false end
					return true
				end
			} )
			tView.origin = tr.HitPos - tr.Normal * f
			tView.angles = Angle( aThirdPerson ) + ply:GetViewPunchAngles()
			fMoreEffects( ply, tView )
			return tView
		end
	end
	player_manager.RunClass( ply, "CalcView", tView )
	local pWeapon = ply:GetActiveWeapon()
	if IsValid( pWeapon ) then
		local f = pWeapon.CalcView
		if f then
			local origin, angles, fov = f( pWeapon, ply, Vector( tView.origin ), Angle( tView.angles ), tView.fov )
			tView.origin, tView.angles, tView.fov = origin || tView.origin, angles || tView.angles, fov || tView.fov
		end
	end
	fMoreEffects( ply, tView )
	return tView
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
local PRECOMPUTED = 360 / ( 2 * math.pi ) * .8

hook.Add( "HUDPaint", "Graphics", function()
	local ply = LocalPlayer()
	if !IsValid( ply ) then return end

	// No. Just no. The game's better without this.
	// It's a vibe, sure, but keeping it on makes it feel somewhat convoluted, too.
	// Plus ruins many genres like Serious Sam.
	// And I don't want to make different "HUD genres", that's stupid and not lore accurate.
	// So just... get the steel balls required to say no to this feature.
	//	local flCenterX, flCenterY = ScrW() * .5, ScrH() * .5
	//	local i = 1
	//	local flOff, flSize, flThickness = flCenterY * .5, flCenterY * .04, flCenterY * .0002
	//	while i <= 5 do
	//		local sI = tostring( i )
	//		local v = ply:GetNW2Vector( "GAME_v3DThreat" .. sI )
	//		if v == vector_origin then break end
	//	
	//		i = i + 1
	//	
	//		//	local ToScreen = v:ToScreen()
	//		//	local x, y = ToScreen.x, ToScreen.y
	//		//	local f = math.deg( math.atan2(
	//		//		flCenterY - y,
	//		//		x - flCenterX
	//		//	) )
	//	
	//		local f = ( v - EyePos() ):Angle()[ 2 ] - EyeAngles()[ 2 ] + 90
	//		surface_SetDrawColor( 0, 0, 0, 255 )
	//		for i = -1, 1, .5 do
	//			local flScale = flOff + i
	//			local flSegmentDistance = PRECOMPUTED / flScale
	//			for a = f - MARKER_SIZE_OUTLINE, f + MARKER_SIZE_OUTLINE - flSegmentDistance, flSegmentDistance do
	//				local flDelta = math_abs( a - f ) / MARKER_SIZE_OUTLINE
	//				local s = MARKER_SIZE_OUTLINE * ( 1 - flDelta ) * .6
	//				if flDelta <= .18 then s = s + math_abs( flDelta - .18 ) * 58 end
	//				s = s + 1
	//				local flCurveInward = flDelta ^ 2 * 3 /* CURL */
	//				local flCurrentRadius = flScale - flCurveInward
	//				local flCurveInwardNext = ( math_abs( ( a + flSegmentDistance ) - f ) / MARKER_SIZE_OUTLINE ) ^ 2 * 3 /* CURL */
	//				local flNextRadius = flScale - flCurveInwardNext
	//				surface_DrawLine(
	//					flCenterX + math_cos( math_rad( a ) ) * ( flCurrentRadius + s ),
	//					flCenterY - math_sin( math_rad( a ) ) * ( flCurrentRadius + s ),
	//					flCenterX + math_cos( math_rad( a + flSegmentDistance ) ) * flNextRadius,
	//					flCenterY - math_sin( math_rad( a + flSegmentDistance ) ) * flNextRadius
	//				)
	//			end
	//		end
	//	
	//		local bThreat = ply:GetNW2Bool( "GAME_b3DThreat" .. sI )
	//		for i = 0, 1, .5 do
	//			local flScale = flOff + i
	//			local flSegmentDistance = PRECOMPUTED / flScale
	//			for a = f - MARKER_SIZE, f + MARKER_SIZE - flSegmentDistance, flSegmentDistance do
	//				local flDelta = math_abs( a - f ) / MARKER_SIZE
	//				local s = MARKER_SIZE * ( 1 - flDelta ) * .6
	//				if flDelta <= .18 then s = s + math_abs( flDelta - .18 ) * 58 end
	//				local flCurveInward = flDelta ^ 2 * 3 /* CURL */
	//				local flCurrentRadius = flScale - flCurveInward
	//				local flCurveInwardNext = ( math_abs( ( a + flSegmentDistance ) - f ) / MARKER_SIZE ) ^ 2 * 3 /* CURL */
	//				local flNextRadius = flScale - flCurveInwardNext
	//				local flValue = 1 - flDelta ^ 3 * .5
	//				if bThreat then surface_SetDrawColor( flValue * 255, 0, 0, 255 )
	//				else surface_SetDrawColor( flValue * 255, flValue * 255, flValue * 255, 255 ) end
	//				surface_DrawLine(
	//					flCenterX + math_cos( math_rad( a ) ) * ( flCurrentRadius + s ),
	//					flCenterY - math_sin( math_rad( a ) ) * ( flCurrentRadius + s ),
	//					flCenterX + math_cos( math_rad( a + flSegmentDistance ) ) * flNextRadius,
	//					flCenterY - math_sin( math_rad( a + flSegmentDistance ) ) * flNextRadius
	//				)
	//			end
	//		end
	//	end

	local f = ply:GetNW2Float( "ALARM_flHostileReinforcements", 0 )
	if f <= 0 then
		flProgress = 0
	else
		flProgress = Lerp( FRILerpRate( 1, RealFrameTime() ), flProgress, f )
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
	end
end )

HUD_SHOULD_NOT_DRAW = {
	CHudHistoryResource = true,
	CHudGeiger = true,
	CHudDamageIndicator = true,
	CHudHealth = true,
	CHudHistoryResource = true,
	CHUDQuickInfo = true,
	CHudWeaponSelection = true
}

local HUD_SHOULD_NOT_DRAW = HUD_SHOULD_NOT_DRAW

HUD_SHOULD_NOT_DRAW_IMMERSIVE = {
	CHudHistoryResource = true,
	CHudGeiger = true,
	CHudDamageIndicator = true,
	CHudHealth = true,
	CHudHistoryResource = true,
	CHUDQuickInfo = true,
	CHudWeaponSelection = true,

	CHudAmmo = true,
	CHudSecondaryAmmo = true,
	CHudCrosshair = true
}

local HUD_SHOULD_NOT_DRAW_IMMERSIVE = HUD_SHOULD_NOT_DRAW_IMMERSIVE

hook.Add( "HUDShouldDraw", "Graphics", function( sName )
	if GetGlobal2Bool "g_bImmersiveMode" then
		return !HUD_SHOULD_NOT_DRAW_IMMERSIVE[ sName ]
	else
		return !HUD_SHOULD_NOT_DRAW[ sName ]
	end
end )

hook.Add( "OnCloseCaptionEmit", "Graphics", function( sName ) return sName != "customLuaToken" end )

local l_flHorizontalBlur = 0
local l_flVerticalBlur = 0
local l_flRadialBlur = 0

local MAX_RADIAL_BLUR = 5
local MAX_HORIZONTAL_BLUR = 5
local MAX_VERTICAL_BLUR = 5
local MAX_ROTATIONAL_BLUR = 5

// Maybe let people change the formulas or tweak the intensity?
// But that's for later regardless, lol.

hook.Add( "GetMotionBlurValues", "Graphics", function()
	// flHorizontal and flVertical DO matter, since they offset to the target,
	// e.g. 10 is to the right, -10 is to the left.
	// flRadial seems to not be any different.
	// flRotational is to the right.

	local flHorizontal, flVertical, flRadial, flRotational = 0, 0, 0, 0

	local pPlayer = LocalPlayer()

	local aEye = EyeAngles()

	local vVelocity = GetVelocity( pPlayer )

	local flVelocity = vVelocity:Length()

	local pVehicle = pPlayer:GetNW2Entity "GAME_pVehicle"
	if IsValid( pVehicle ) then
		// For now
		return 0, 0, 0, 0
	end

	local bGround = pPlayer:IsOnGround() || pPlayer:WaterLevel() > 0

	local flRightDot = vVelocity:GetNormalized():Dot( aEye:Right() )
	if math.abs( flRightDot ) >= .7071067 then flRightDot = flRightDot > 0 && 1 || -1 end

	if bGround && pPlayer:GetNW2Bool "CTRL_bSliding" then
		l_flRadialBlur = Lerp( FRILerpRate( 50, FrameTime() ), l_flRadialBlur, math_Clamp( math.abs( flVelocity * vVelocity:GetNormalized():Dot( aEye:Forward() ) ) / pPlayer:GetRunSpeed() * .5, 0, MAX_RADIAL_BLUR ) )
	elseif bGround && pPlayer:GetNW2Bool "CTRL_bSprinting" then
		l_flRadialBlur = Lerp( FRILerpRate( 50, FrameTime() ), l_flRadialBlur, math_Clamp( math.abs( flVelocity * vVelocity:GetNormalized():Dot( aEye:Forward() ) ) / pPlayer:GetRunSpeed() * .25, 0, MAX_RADIAL_BLUR ) )
	else
		l_flRadialBlur = Lerp( FRILerpRate( 50, FrameTime() ), l_flRadialBlur, math_Clamp( ( math.abs( flVelocity * vVelocity:GetNormalized():Dot( aEye:Forward() ) ) / pPlayer:GetRunSpeed() ) ^ 5 * .25, 0, MAX_RADIAL_BLUR ) )
	end

	l_flHorizontalBlur = Lerp( FRILerpRate( 50, FrameTime() ), l_flHorizontalBlur, math_Clamp( ( flVelocity * flRightDot / pPlayer:GetRunSpeed() ) ^ 2 * .03, -MAX_HORIZONTAL_BLUR, MAX_HORIZONTAL_BLUR ) )

	l_flVerticalBlur = Lerp( FRILerpRate( 50, FrameTime() ), l_flVerticalBlur, math_Clamp( ( flVelocity * vVelocity:GetNormalized():Dot( aEye:Up() ) / pPlayer:GetRunSpeed() ) * .05, -MAX_VERTICAL_BLUR, MAX_VERTICAL_BLUR ) )

	flRadial = flRadial + l_flRadialBlur
	flHorizontal = flHorizontal + l_flHorizontalBlur
	flVertical = flVertical + l_flVerticalBlur

	return flHorizontal, flVertical, flRadial, flRotational
end )
