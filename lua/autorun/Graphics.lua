// This is shared for a reason, and includes more than just client graphics

// Gets the human percieved brightness of a color
function GetBrightness( c ) return c[ 1 ] * .00083372549 + c[ 2 ] * .00280470588 + c[ 3 ] * .00028313725 end
// Same as above except uses vector colors
function GetBrightnessVC( v ) return v[ 1 ]  * .2126 + v[ 2 ] * .7152  + v[ 3 ] * .0722 end
// Also same as above except uses red/green/blue floats
function GetBrightnessRGB( r, g, b ) return r * .00083372549 + g * .00280470588 + b * .00028313725 end

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
net.Start "DynamicLight"
	net.WriteFloat( 1 ) // Brightness
	net.WriteFloat( 1 ) // Size
	net.WriteFloat( 1 ) // Existence length
	net.WriteVector( vector_origin ) // Position
	net.WriteUInt( 255, 8 ) net.WriteUInt( 255, 8 ) net.WriteUInt( 255, 8 ) // R, G, B
net.Broadcast()
*/

if SERVER then util.AddNetworkString "DynamicLight" return end

local DynamicLight = DynamicLight
local net_ReadFloat = net.ReadFloat
local net_ReadVector = net.ReadVector
local net_ReadUInt = net.ReadUInt
local math_Round = math.Round
local math_Rand = math.Rand
local CurTime = CurTime
local iLightsThisTick, iLightsTickIndexLast, iLightsLastStoredTick = 0, 0
local engine_TickCount = engine.TickCount
net.Receive( "DynamicLight", function()
	local iTick = engine_TickCount()
	if iTick == iLightsLastStoredTick then
		iLightsThisTick = iLightsThisTick + 1
	else
		iLightsLastStoredTick = iTick
		iLightsTickIndexLast = iLightsTickIndexLast + iLightsThisTick
		iLightsThisTick = 0
	end
	local pLight = DynamicLight( 8192 + iLightsTickIndexLast )
	if pLight then
		pLight.brightness = net_ReadFloat()
		pLight.size = net_ReadFloat()
		local f = net_ReadFloat()
		pLight.decay = 1000 / f
		pLight.dietime = CurTime() + f
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
		local p = pPanel:NumSlider( "#ShadowDepthResolution", "r_flashlightdepthres", 0, 16384, 0 )
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

local BLEED_LOWER_THRESHOLD = .25

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

BREEZE_COLOR = Color( 40, 120, 200 )
BREEZE_VECTOR_COLOR = BREEZE_COLOR:ToVector()

local Lerp = Lerp
local math_min = math.min

local ANALYZATION_STEP = 22.5 / 4

hook.Add( "RenderScreenspaceEffects", "Graphics", function()
	local self = LocalPlayer()
	if !IsValid( self ) then return end
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
	local flDeath = math_Clamp( self:Health() / self:GetMaxHealth(), 0, 1 )
	tDrawColorModify[ "$pp_colour_colour" ] = tDrawColorModify[ "$pp_colour_colour" ] * math_Remap( flDeath, 1, BLEED_LOWER_THRESHOLD, 1, 0 )
	if flDeath != 0 then
		DrawBlur( math_Clamp( math_Remap( flDeath, 1, BLEED_LOWER_THRESHOLD, 0, 8 ), 0, 8 ) )
		DrawMotionBlur( math_Clamp( math_Remap( flDeath, 1, BLEED_LOWER_THRESHOLD, .1, .05 ), .1, .05 ), math_Clamp( math_Remap( flDeath, 1, BLEED_LOWER_THRESHOLD, 0, 1 ), 0, 1 ), 0 )
	end
	local flOxygen, flOxygenLimit = self:GetNW2Float( "GAME_flOxygen", -1 ), self:GetNW2Float( "GAME_flOxygenLimit", -1 )
	if flOxygen != -1 && flOxygenLimit != -1 then
		local f = flOxygenLimit * .33
		if flOxygen <= f then
			tDrawColorModify[ "$pp_colour_contrast" ] = tDrawColorModify[ "$pp_colour_contrast" ] * math_Remap( flOxygen, f, 0, 1, 0 )
		end
	end
	local vEye, aEye = EyePos(), EyeVector():Angle()
	local iPasses = 1
	local vColor = Vector( 0, 0, 0 )
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
			vColor = vColor + ( render_ComputeLighting( tr.HitPos, tr.HitNormal ) + render_ComputeDynamicLighting( tr.HitPos, tr.HitNormal ) )
			aEye[ 1 ] = aEye[ 1 ] - flPitch
			aEye[ 2 ] = aEye[ 2 ] - flYaw
		end
	end
	vColor = vColor / iPasses
	local flColor = math_Clamp( VectorSum( vColor ), 0, 1 )
	local MyTable = CEntity_GetTable( self )
	local flBloom = Lerp( math.min( 1, FrameTime() * .5 ), MyTable.GP_flBloom || 0, 1 - flColor )
	MyTable.GP_flBloom = flBloom
	if self:WaterLevel() >= 3 then
		MyTable.GP_flWaterBlur = math_Approach( MyTable.GP_flWaterBlur || 0, 1, WATER_BLUR_CHANGE_SPEED_TO * FrameTime() )
	else MyTable.GP_flWaterBlur = math_Approach( MyTable.GP_flWaterBlur || 0, 0, WATER_BLUR_CHANGE_SPEED_FROM * FrameTime() ) end
	if MyTable.GP_flWaterBlur > 0 then
		DrawBlur( MyTable.GP_flWaterBlur * MAX_WATER_BLUR )
		DrawMaterialOverlay( "effects/water_warp01", MyTable.GP_flWaterBlur * .01 )
		flBloom = math_Clamp( flBloom + MyTable.GP_flWaterBlur * .2, 0, 1 )
	end
	local f = self:GetNW2Float( "GAME_flSuppressionEffects", 0 )
	if f > 0 then
		DrawBlur( math_Clamp( math_Remap( f, 0, 1, 0, 1 ), 0, 1 ) )
		DrawMotionBlur( math_Clamp( math_Remap( f, 0, 1, .5, .25 ), .25, .5 ), math_Clamp( f, 0, 1 ), 0 )
	end
	local f = math_Clamp( math_Remap( self:GetNW2Float( "GAME_flBlood", 0 ), .2, 1, 0, 1 ) - self:GetNW2Float( "GAME_flBleeding", 0 ) * 2, 0, 1 )
	if f < 1 then
		DrawBlur( math_Clamp( math_Remap( f, 1, 0, 0, 4 ), 0, 4 ) )
		DrawMotionBlur( math_Clamp( math_Remap( f, 1, 0, .5, .05 ), .05, .5 ), math_Clamp( 1 - f, 0, 1 ), 0 )
	end
	MyTable.GP_FogDensityMul = math_Approach( MyTable.GP_FogDensityMul || .1, math.Remap( flColor, 0, 1, .33, .66 ), 1 * FrameTime() )
	local vTargetColor = LerpVector( ( ( vColor[ 1 ] + vColor[ 2 ] + vColor[ 3 ] ) / 3 ) ^ 4, vColor, BREEZE_VECTOR_COLOR )
	MyTable.GP_FogR = math_Approach( MyTable.GP_FogR || 255, vTargetColor[ 1 ] * 255, 32 * FrameTime() )
	MyTable.GP_FogG = math_Approach( MyTable.GP_FogG || 255, vTargetColor[ 2 ] * 255, 32 * FrameTime() )
	MyTable.GP_FogB = math_Approach( MyTable.GP_FogB || 255, vTargetColor[ 3 ] * 255, 32 * FrameTime() )
	local flFogR, flFogG, flFogB = MyTable.GP_FogR, MyTable.GP_FogG, MyTable.GP_FogB
	local flBrightness = GetBrightnessRGB( flFogR, flFogG, flFogB )
	local flMultiplier = math_Remap( flBrightness, 0, 1, 1, 0 )
	flFogR, flFogG, flFogB = flFogR * .00392156862, flFogG * .00392156862, flFogB * .00392156862
	tDrawColorModify[ "$pp_colour_addr" ] = tDrawColorModify[ "$pp_colour_addr" ] + flFogR * .2 * flMultiplier
	tDrawColorModify[ "$pp_colour_addg" ] = tDrawColorModify[ "$pp_colour_addg" ] + flFogG * .2 * flMultiplier
	tDrawColorModify[ "$pp_colour_addb" ] = tDrawColorModify[ "$pp_colour_addb" ] + flFogB * .2 * flMultiplier
	tDrawColorModify[ "$pp_colour_mulr" ] = tDrawColorModify[ "$pp_colour_mulr" ] + flFogR * flMultiplier
	tDrawColorModify[ "$pp_colour_mulg" ] = tDrawColorModify[ "$pp_colour_mulg" ] + flFogG * flMultiplier
	tDrawColorModify[ "$pp_colour_mulb" ] = tDrawColorModify[ "$pp_colour_mulb" ] + flFogB * flMultiplier
	MyTable.GP_FogDistance = Lerp( math_min( 1, .1 * FrameTime() ), MyTable.GP_FogDistance || 0, UTIL_IsUnderSkybox() && math_Remap( flColor, 0, 1, 512, 16384 ) || math_Remap( flColor, 0, 1, 512, 3072 ) )
	DrawBloom(
		math_Remap( flBloom, 0, 1, .2, 0 ), math_Remap( flBloom, 0, 1, 1.33, 2 ),
		// Setting all three to 1 and then tweaking the other settings
		// is the way to make the scene actually beautiful, and why
		// the new versions (since commit 266) are so freakin' beautiful!
		1, // Size X
		1, // Size Y
		1, // Passes
		math_Remap( flBloom, 0, 1, 1.33, 2 ), 1, 1, 1
	)
	DrawColorModify( tDrawColorModify )
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
	local MyTable = CEntity_GetTable( self )
	render_FogColor( MyTable.GP_FogR || 255, MyTable.GP_FogG || 255, MyTable.GP_FogB || 255 )
	render_FogStart( 0 )
	render_FogEnd( MyTable.GP_FogDistance || 0 )
	local flBrightness = GetBrightnessRGB( MyTable.GP_FogR || 255, MyTable.GP_FogG || 255, MyTable.GP_FogB || 255 )
	render_FogMaxDensity( ( flBrightness < .5 && math_Remap( flBrightness, 0, .5, 0, 1 ) || math_Remap( flBrightness, .5, 1, 1, 0 ) ) * ( MyTable.GP_FogDensityMul || 0 ) )
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

local flThirdPersonAttackTime = 0

hook.Add( "CreateMove", "Graphics", function( cmd )
	if bAllowThirdPerson && !bAllowThirdPerson:GetBool() then cThirdPerson:SetBool() return end
	if !cThirdPerson:GetBool() then return end
	local pPlayer = LocalPlayer()
	if !IsValid( pPlayer ) then return end
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
	if cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) || cmd:KeyDown( IN_ZOOM ) then flThirdPersonAttackTime = RealTime() + .2 end
	local bSpecial = pPlayer:WaterLevel() > 0
	if !bSpecial && flActualBiggerMove > 0 && ( cmd:KeyDown( IN_SPEED ) || pPlayer:GetNW2Bool "CTRL_bSprinting" || pPlayer:GetNW2Bool "CTRL_bSliding" ) then
		local a = Angle( aDirection )
		a[ 1 ] = a[ 1 ] + 30
		cmd:SetViewAngles( LerpAngle( math.min( 1, 5 * FrameTime() ), cmd:GetViewAngles(), a ) )
	elseif RealTime() <= flThirdPersonAttackTime then
		cmd:SetViewAngles( LerpAngle( math.min( 1, 5 * FrameTime() ), cmd:GetViewAngles(), aThirdPerson ) )
		if math.AngleDifference( cmd:GetViewAngles()[ 1 ], aThirdPerson[ 1 ] ) > 1 || math.AngleDifference( cmd:GetViewAngles()[ 2 ], aThirdPerson[ 2 ] ) > 1 then cmd:RemoveKey( IN_ATTACK ) end
	elseif bSpecial then
		cmd:SetViewAngles( LerpAngle( math.min( 1, FrameTime() ), cmd:GetViewAngles(), aThirdPerson ) )
	elseif flActualBiggerMove > 0 then
		local a = Angle( aDirection )
		a[ 1 ] = a[ 1 ] + 30
		cmd:SetViewAngles( LerpAngle( math.min( 1, FrameTime() ), cmd:GetViewAngles(), a ) )
	else
		local a = Angle( aAim )
		a[ 0 ] = 0
		cmd:SetViewAngles( LerpAngle( math.min( 1, FrameTime() ), cmd:GetViewAngles(), a ) )
	end
end )

hook.Add( "InputMouseApply", "Graphics", function( _, x, y )
	if bAllowThirdPerson && !bAllowThirdPerson:GetBool() then cThirdPerson:SetBool() return end
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
		local VARIANTS, PEEK = ply:GetNW2Int "CTRL_Variants", ply:GetNW2Int "CTRL_Peek"
		view.drawviewer = true
		local vTarget = Vector( -64, cThirdPersonShoulder:GetBool() && 24 || -24, ply:Crouching() && 24 || 8 )
		local bInCover = ply:GetNW2Bool "CTRL_bInCover" || ply:GetNW2Bool "CTRL_bGunUsesCoverStance"
		if bInCover || PEEK != COVER_PEEK_NONE then
			if VARIANTS == COVER_VARIANTS_LEFT || PEEK == COVER_FIRE_LEFT || PEEK == COVER_BLINDFIRE_LEFT then
				vTarget = Vector( -64, 32, ply:Crouching() && 24 || 8 )
			elseif bInCover && VARIANTS == COVER_VARIANTS_RIGHT || PEEK == COVER_FIRE_RIGHT || PEEK == COVER_BLINDFIRE_RIGHT then
				vTarget = Vector( -64, -32, ply:Crouching() && 24 || 8 )
			elseif bInCover && VARIANTS == COVER_VARIANTS_BOTH || PEEK == COVER_BLINDFIRE_UP || PEEK == COVER_FIRE_UP then
				vTarget = Vector( -64, 0, 32 )
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

__HUD_SHOULD_NOT_DRAW__ = {
	CHudHistoryResource = true,
	CHudGeiger = true,
	CHudDamageIndicator = true,
	CHudHealth = true,
	CHudHistoryResource = true
}
hook.Add( "HUDShouldDraw", "Graphics", function( sName ) return __HUD_SHOULD_NOT_DRAW__[ sName ] == nil end )

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
hook.Add( "HUDPaint", "Graphics", function()
	local ply = LocalPlayer()
	if !IsValid( ply ) then return end
	local f = ply:GetNW2Float( "ALARM_flHostileReinforcements", 0 )
	if f <= 0 then flProgress = 0 return end
	flProgress = Lerp( math.min( 1, RealFrameTime() ), flProgress, f )
	draw.NoTexture()
	local flHeight, flWidth = ScrH(), ScrW()
	local flLabelWidth, flLabelHeight = flHeight * .3, flHeight * .05
	surface.SetDrawColor( 0, 0, 0 )
	surface.DrawRect( flWidth * .5 - flLabelWidth * .5, flHeight * .033, flLabelWidth, flLabelHeight )
	draw.DrawText( language.GetPhrase "ReinforcementsBar", "ReinforcementsBar", flWidth * .5, flHeight * .033, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	surface.SetDrawColor( 64, 64, 64 )
	flLabelWidth = flLabelWidth * .9
	surface.DrawRect( flWidth * .5 - flLabelWidth * .5, flHeight * ( .033 + .033 ), flLabelWidth, flHeight * .008 )
	// The flashing is only activated when the true lerped progress is less than a half, not the smoothened one
	surface.SetDrawColor( 255, 255, 255, f <= .33 && math.abs( math.sin( RealTime() * math.Remap( f, 0, .33, .2, .1 ) ) ) * 255 || 255 )
	surface.DrawRect( flWidth * .5 - flLabelWidth * .5, flHeight * ( .033 + .033 ), flProgress * flLabelWidth, flHeight * .008 )
end )
