local min = math.min
local exp = math.exp

local function FRILerpRate( flRate, flFrameTime ) return min( 1, 1 - exp( -flRate * flFrameTime ) ) end

local CEntity = FindMetaTable "Entity"
local CEntity_IsOnGround = CEntity.IsOnGround
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local developer = GetConVar "developer"
local CPlayer = FindMetaTable "Player"
local CPlayer_IsSprinting = CPlayer.IsSprinting
local CPlayer_KeyDown = CPlayer.KeyDown
local surface_DrawTexturedRect = surface.DrawTexturedRect
local util_TraceLine = util.TraceLine
local cThirdPerson = GetConVar "bThirdPerson"
local ScrW, ScrH = ScrW, ScrH

SWEP.flCrosshairInAccuracy = 0
SWEP.Primary_flSpreadX = 0
SWEP.Primary_flSpreadY = 0

SWEP.flCrosshairAlpha = 255

function SWEP:GatherCrosshairPosition( MyTable )
	if cThirdPerson:GetBool() then return ScrW() * .5, ScrH() * .5 end
	local v = LocalPlayer():GetNW2Entity "GAME_pVehicle"
	local tr = util_TraceLine {
		start = LocalPlayer():GetShootPos(),
		endpos = LocalPlayer():GetShootPos() + self:GetAimVector() * 999999,
		mask = MASK_SOLID,
		filter = IsValid( v ) && { LocalPlayer(), v } || LocalPlayer()
	}
	local t = tr.HitPos:ToScreen()
	return t.x, t.y
end

local math_max = math.max
function SWEP:GatherCrosshairSpread( MyTable, bForceIdentical )
	local flSpreadX, flSpreadY
	local v = MyTable.Primary_flSpreadX
	if v then flSpreadX = v end
	local v = MyTable.Primary_flSpreadY
	if v then flSpreadY = v end
	local flInaccuracy = MyTable.flCrosshairInAccuracy * ( MyTable.vViewModelAim && MyTable.flAimMultiplier || 1 )
	if MyTable.bCrosshairSizeIdentical || bForceIdentical then
		local v = math_max( flSpreadX || flSpreadY, flSpreadY || flSpreadX ) + flInaccuracy
		return v, v
	end
	return flSpreadX + flInaccuracy, flSpreadY + flInaccuracy
end
function SWEP:GatherCrosshairSpreadIdeal( MyTable, bForceIdentical )
	local flSpreadX, flSpreadY
	local v = MyTable.Primary_flSpreadX
	if v then flSpreadX = v end
	local v = MyTable.Primary_flSpreadY
	if v then flSpreadY = v end
	local flInaccuracy = MyTable.flCrosshairInAccuracyGapPart * ( MyTable.vViewModelAim && MyTable.flAimMultiplier || 1 ) * ( 1 / 3 )
	if MyTable.bCrosshairSizeIdentical || bForceIdentical then
		local v = math_max( flSpreadX || flSpreadY, flSpreadY || flSpreadX ) + flInaccuracy
		return v, v
	end
	return flSpreadX + flInaccuracy, flSpreadY + flInaccuracy
end

local surface = surface
local surface_SetTexture = surface.SetTexture
local surface_GetTextureID = surface.GetTextureID
local surface_SetDrawColor = surface_SetDrawColor
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated

local CROSSHAIR_PART_SIZE = ScrH() * .014
local CROSSHAIR_PART_SIZE_WIDTH = ScrH() * .004
local CROSSHAIR_PART_SIZE_SUB = CROSSHAIR_PART_SIZE * .5

local CROSSHAIR_PART_SIZE_LARGE = ScrH() * .024
local CROSSHAIR_PART_SIZE_LARGE_WIDTH = ScrH() * .004
local CROSSHAIR_PART_SIZE_LARGE_SUB = CROSSHAIR_PART_SIZE_LARGE * .5

local surface_DrawRect = surface.DrawRect
local surface_SetDrawColor = surface.SetDrawColor

SWEP.Crosshair = "Rifle"

local surface_DrawCircle = surface.DrawCircle

__WEAPON_CROSSHAIR_TABLE__ = {
	[ "" ] = function( MyTable, self ) return true end,
	Shotgun = function( MyTable, self, R, G, B )
		local flSpread = MyTable.GatherCrosshairSpreadIdeal( self, MyTable, true )
		local flHeight, flWidth = ScrH(), ScrW()
		local flRadius = flSpread * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local f = .004 * flHeight
		local flCrosshairAlpha = MyTable.flCrosshairAlpha
		surface_DrawCircle( flX, flY, flRadius - 1, R, G, B, flCrosshairAlpha )
		surface_DrawCircle( flX, flY, flRadius, R, G, B, flCrosshairAlpha )
		surface_DrawCircle( flX, flY, flRadius + 1, R, G, B, flCrosshairAlpha )
		return true
	end,
	// I should technically call this one "Generic" from now on, but the name "Rifle" just stuck,
	// and I don't want to change it, even though it would be easy
	Rifle = function( MyTable, self, R, G, B )
		local flSpreadX, flSpreadY = MyTable.GatherCrosshairSpread( self, MyTable )
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSpreadHorizontal = flSpreadX * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flSpreadVertical = flSpreadY * flHeight * ( 90 / MyTable.flFoV ) * .5 * ( flWidth / flHeight )
		surface_SetTexture( surface_GetTextureID "Crosshair" )
		surface_SetDrawColor( R, G, B, MyTable.flCrosshairAlpha )
		// Top
		surface_DrawTexturedRectRotated( flX, flY - flSpreadVertical - CROSSHAIR_PART_SIZE_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 180 )
		// Bottom
		surface_DrawTexturedRectRotated( flX, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 0 )
		// Left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 270 )
		// Right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 90 )
		return true
	end,
	Sniper = function( MyTable, self, R, G, B )
		local flSpreadX, flSpreadY = MyTable.GatherCrosshairSpread( self, MyTable )
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSpreadHorizontal = flSpreadX * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flSpreadVertical = flSpreadY * flHeight * ( 90 / MyTable.flFoV ) * .5 * ( flWidth / flHeight )
		surface_SetTexture( surface_GetTextureID "Crosshair" )
		surface_SetDrawColor( R, G, B, MyTable.flCrosshairAlpha )
		// Top
		surface_DrawTexturedRectRotated( flX, flY - flSpreadVertical - CROSSHAIR_PART_SIZE_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 180 )
		// Bottom
		surface_DrawTexturedRectRotated( flX, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 0 )
		// Left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 270 )
		// Right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 90 )
		return true
	end,
	SubMachineGun = function( MyTable, self, R, G, B )
		local flSpreadX, flSpreadY = MyTable.GatherCrosshairSpread( self, MyTable )
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSpreadHorizontal = flSpreadX * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flSpreadVertical = flSpreadY * flHeight * ( 90 / MyTable.flFoV ) * .5 * ( flWidth / flHeight )
		surface_SetTexture( surface_GetTextureID "Crosshair" )
		surface_SetDrawColor( R, G, B, MyTable.flCrosshairAlpha )
		// Top
		surface_DrawTexturedRectRotated( flX, flY - flSpreadVertical - CROSSHAIR_PART_SIZE_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 180 )
		// Bottom
		surface_DrawTexturedRectRotated( flX, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 0 )
		// Left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 270 )
		// Right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 90 )
		return true
	end,
	Pistol = function( MyTable, self, R, G, B )
		local flSpreadX, flSpreadY = MyTable.GatherCrosshairSpread( self, MyTable )
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSpreadHorizontal = flSpreadX * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flSpreadVertical = flSpreadY * flHeight * ( 90 / MyTable.flFoV ) * .5 * ( flWidth / flHeight )
		surface_SetTexture( surface_GetTextureID "Crosshair" )
		surface_SetDrawColor( R, G, B, MyTable.flCrosshairAlpha )
		// Bottom
		surface_DrawTexturedRectRotated( flX, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 0 )
		// Left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 270 )
		// Right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 90 )
		return true
	end,
	Revolver = function( MyTable, self, R, G, B )
		local flSpreadX, flSpreadY = MyTable.GatherCrosshairSpread( self, MyTable )
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSpreadHorizontal = flSpreadX * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flSpreadVertical = flSpreadY * flHeight * ( 90 / MyTable.flFoV ) * .5 * ( flWidth / flHeight )
		surface_SetTexture( surface_GetTextureID "Crosshair" )
		surface_SetDrawColor( R, G, B, MyTable.flCrosshairAlpha )
		// Bottom
		surface_DrawTexturedRectRotated( flX, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 0 )
		// Left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 270 )
		// Right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 90 )
		return true
	end,
	// HACK: This is actually the RPG crosshair, which is four parts at square edges, like this:
	//               /         \
	//
	//
	//               \         /
	// But since I have zero idea how to possibly draw that, we use the Requiem's crosshair as a placeholder
	Open = function( MyTable, self, R, G, B )
		local flSpreadX, flSpreadY = MyTable.GatherCrosshairSpread( self, MyTable )
		flSpreadX = flSpreadX * .5
		flSpreadY = flSpreadY * .5
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSpreadHorizontal = flSpreadX * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flSpreadVertical = flSpreadY * flHeight * ( 90 / MyTable.flFoV ) * .5 * ( flWidth / flHeight )
		surface_SetTexture( surface_GetTextureID "Crosshair" )
		surface_SetDrawColor( R, G, B, MyTable.flCrosshairAlpha )
		// Top left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_LARGE_SUB, flY - flSpreadVertical - CROSSHAIR_PART_SIZE_LARGE_SUB, CROSSHAIR_PART_SIZE_LARGE_WIDTH, CROSSHAIR_PART_SIZE_LARGE, 225 )
		// Top right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_LARGE_SUB, flY - flSpreadVertical - CROSSHAIR_PART_SIZE_LARGE_SUB, CROSSHAIR_PART_SIZE_LARGE_WIDTH, CROSSHAIR_PART_SIZE_LARGE, 135 )
		// Bottom left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_LARGE_SUB, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_LARGE_SUB, CROSSHAIR_PART_SIZE_LARGE_WIDTH, CROSSHAIR_PART_SIZE_LARGE, 315 )
		// Bottom right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_LARGE_SUB, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_LARGE_SUB, CROSSHAIR_PART_SIZE_LARGE_WIDTH, CROSSHAIR_PART_SIZE_LARGE, 45 )
		return true
	end,
	Requiem = function( MyTable, self, R, G, B )
		local flSpreadX, flSpreadY = MyTable.GatherCrosshairSpread( self, MyTable )
		flSpreadX = flSpreadX * .5
		flSpreadY = flSpreadY * .5
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSpreadHorizontal = flSpreadX * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flSpreadVertical = flSpreadY * flHeight * ( 90 / MyTable.flFoV ) * .5 * ( flWidth / flHeight )
		surface_SetTexture( surface_GetTextureID "Crosshair" )
		surface_SetDrawColor( R, G, B, MyTable.flCrosshairAlpha )
		// Top left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_LARGE_SUB, flY - flSpreadVertical - CROSSHAIR_PART_SIZE_LARGE_SUB, CROSSHAIR_PART_SIZE_LARGE_WIDTH, CROSSHAIR_PART_SIZE_LARGE, 225 )
		// Top right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_LARGE_SUB, flY - flSpreadVertical - CROSSHAIR_PART_SIZE_LARGE_SUB, CROSSHAIR_PART_SIZE_LARGE_WIDTH, CROSSHAIR_PART_SIZE_LARGE, 135 )
		// Bottom left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_LARGE_SUB, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_LARGE_SUB, CROSSHAIR_PART_SIZE_LARGE_WIDTH, CROSSHAIR_PART_SIZE_LARGE, 315 )
		// Bottom right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_LARGE_SUB, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_LARGE_SUB, CROSSHAIR_PART_SIZE_LARGE_WIDTH, CROSSHAIR_PART_SIZE_LARGE, 45 )
		return true
	end,
}
local __WEAPON_CROSSHAIR_TABLE__ = __WEAPON_CROSSHAIR_TABLE__

function SWEP.pCrosshairTable() return __WEAPON_CROSSHAIR_TABLE__ end

SWEP.Primary_flDelay = 1
SWEP.Secondary_flDelay = 1

local AMMO_BAR_WIDTH, AMMO_BAR_HEIGHT = 5, 28
local AMMO_BAR_LARGE_WIDTH, AMMO_BAR_LARGE_HEIGHT = AMMO_BAR_WIDTH * ( 1 + 1 / 3 ), AMMO_BAR_HEIGHT * ( 1 + 1 / 3 )
local AMMO_FONT = "Impact"

surface.CreateFont( "BaseWeapon_AmmoBarText", {
	font = AMMO_FONT,
	extended = false,
	size = AMMO_BAR_HEIGHT,
	weight = 0,
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
surface.CreateFont( "BaseWeapon_AmmoBarLargeText", {
	font = AMMO_FONT,
	extended = false,
	size = AMMO_BAR_LARGE_HEIGHT,
	weight = 0,
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

sound.Add {
	name = "BaseWeapon_Aim_Pistol",
	channel = CHAN_STATIC,
	sound = {
		"Aim/Pistol/1.wav",
		"Aim/Pistol/2.wav",
		"Aim/Pistol/3.wav",
		"Aim/Pistol/4.wav",
		"Aim/Pistol/5.wav",
	}
}
sound.Add {
	name = "BaseWeapon_Aim_SubMachineGun",
	channel = CHAN_STATIC,
	sound = {
		"Aim/SubMachineGun/1.wav",
		"Aim/SubMachineGun/2.wav",
		"Aim/SubMachineGun/3.wav",
		"Aim/SubMachineGun/4.wav",
		"Aim/SubMachineGun/5.wav",
	}
}
sound.Add {
	name = "BaseWeapon_Aim_Rifle",
	channel = CHAN_STATIC,
	sound = {
		"Aim/Rifle/1.wav",
		"Aim/Rifle/2.wav",
		"Aim/Rifle/3.wav",
		"Aim/Rifle/4.wav",
		"Aim/Rifle/5.wav",
	}
}

SWEP.sAimSound = ""

local flLastDoDrawCrosshairCall = 0

function SWEP:DrawSniperScope( MyTable )
	surface_SetDrawColor( 0, 0, 0, 255 )
	surface_SetTexture( surface_GetTextureID( MyTable.sSniperTexture || "CrosshairScope1" ) )

	local flHeight, flWidth = ScrH(), ScrW()
	local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )

	//	local flSize = flWidth * ( .6 + ( MyTable.flBarrelBack || 0 ) * .25 ) * .9
	local flSize = flWidth * .85

	surface_SetDrawColor( 255, 255, 255, 255 )
	surface_DrawTexturedRect( flX - flSize * .5, flY - flSize * .5, flSize, flSize )

	surface_SetDrawColor( 10, 10, 10, 255 )
	surface_DrawRect( 0, 0, flX - flSize * .5 + 1, flHeight )
	surface_DrawRect( flX + flSize * .5 - 1, 0, flWidth - flX, flHeight )
	surface_DrawRect( flX - flSize * .5, 0, flSize, flY - flSize * .5 )
	surface_DrawRect( flX - flSize * .5, flY + flSize * .5 - 1, flSize, flHeight - flY )

	return true
end

SWEP.bDontDrawCrosshairDuringZoom = true
SWEP.flCrosshairInAccuracyGapPart = 0
SWEP.flCrosshairInAccuracyRecoilPart = 0

// Allowing this to be toggled on by the client for testing
// how good guns feel without the smooth crosshair disappearance,
// and because this is a straight up nerf, not a buff.
local cNoWeaponHuD = CreateConVar(
	"bNoWeaponHuD",
	0,
	FCVAR_NEVER_AS_STRING,
	"",
	0, 1
)

function SWEP:DoDrawCrosshair()
	local f = SysTime()
	local flFrameTime = f - flLastDoDrawCrosshairCall
	flLastDoDrawCrosshairCall = f

	if cNoWeaponHuD:GetBool() then return true end
	if developer:GetBool() then return end

	local MyTable = CEntity_GetTable( self )

	local ply = LocalPlayer()

	local flDelay, f = min( MyTable.Primary_flDelay, .2 )
	if MyTable.Primary.Automatic then
		f = ( 2 / 3 ) / flDelay
		MyTable.flCurrentRecoilForGap = math_max( 0, MyTable.flCurrentRecoilForGap - f * flFrameTime )
	else
		f = ( 2 / 3 ) / ( flDelay + 1 / 30 )
		MyTable.flCurrentRecoilForGap = math_max( 0, MyTable.flCurrentRecoilForGap - f * flFrameTime )
	end

	if CurTime() > MyTable.flLastShot + flDelay * 2 then
		local f = 2 / flDelay
		MyTable.flCurrentRecoilForCrosshair = math_max( 0, MyTable.flCurrentRecoilForCrosshair - f * flFrameTime )
	else MyTable.flCurrentRecoilForCrosshair = MyTable.flCurrentRecoilForCrosshair + 1 * ply:GetNW2Float( "GAME_flRecoil", 1 ) / flDelay * flFrameTime end

	local flAimMultiplier = MyTable.flAimMultiplier
	local flGapPart = Lerp( FRILerpRate( 20, flFrameTime ), MyTable.flCrosshairInAccuracyGapPart, math.Clamp( ply:GetVelocity():Length() / ply:GetWalkSpeed() * .033, 0, .033 ) )
	MyTable.flCrosshairInAccuracyGapPart = flGapPart

	local flRecoilPart = Lerp(
		FRILerpRate( flDelay * 2000, flFrameTime ),
		MyTable.flCrosshairInAccuracyRecoilPart,
		MyTable.flCurrentRecoilForGap * .05 / ( MyTable.Primary_flDelay + ( MyTable.Primary.Automatic && 0 || .1 ) ) / min( 20, self:GetMaxClip1() * ( 2 / 3 ) ) * ( MyTable.Primary.Automatic && 1 || .05 )
	)

	MyTable.flCrosshairInAccuracyRecoilPart = flRecoilPart
	MyTable.flCrosshairInAccuracy = flGapPart + flRecoilPart + ( MyTable.Crosshair == "Sniper" && .15 || ( 1 / 30 ) )

	if MyTable.sAimSound && MyTable.vViewModelAim then
		if MyTable.bAiming then
			if flAimMultiplier > .9 then
				MyTable.bAiming = nil
				MyTable.bDidAimingSound = nil
			elseif flAimMultiplier > .1 then
				if !MyTable.bDidAimingSound then
					EmitSound( MyTable.sAimSound, vector_origin, -2 )
					MyTable.bDidAimingSound = true
				end
			end
		else
			if flAimMultiplier < .1 then
				MyTable.bAiming = true
				MyTable.bDidAimingSound = nil
			elseif flAimMultiplier < .9 then
				if !MyTable.bDidAimingSound then
					EmitSound( MyTable.sAimSound, vector_origin, -2 )
					MyTable.bDidAimingSound = true
				end
			end
		end
	end

	if CurTime() <= MyTable.flReloadTime then
		MyTable.flCrosshairAlpha = 0
	else
		if cThirdPerson:GetBool() && flAimMultiplier <= .5 && MyTable.bDontDrawCrosshairDuringZoom && MyTable.vViewModelAim then
			MyTable.flCrosshairAlpha = Lerp( FRILerpRate( 5, flFrameTime ), MyTable.flCrosshairAlpha, 255 )
		else
			local flAlpha = math_max( 0, 255 - ( 255 * 4 ) * MyTable.flCurrentRecoilForCrosshair * ( MyTable.Primary.Automatic && 1 || .1 ) / min( 20, self:GetMaxClip1() * ( 2 / 3 ) ) )
			MyTable.flCrosshairAlpha = flAlpha
		end
	end

	if MyTable.bSniper && flAimMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then
		MyTable.DrawSniperScope( self, MyTable )
		return true
	end

	if !MyTable.bDontDrawAmmo then
		local flClip = math_max( self:Clip1(), self:GetMaxClip1() )

		local flW, flH = ScrW() * .9, ScrH() * .9
		surface_SetDrawColor( 0, 0, 0, 255 )
		local flWidth, flHeight, sFont
		local b = MyTable.bDontDrawAmmoBars
		if b || self:GetMaxClip1() <= 15 then
			flWidth, flHeight, sFont = AMMO_BAR_LARGE_WIDTH, AMMO_BAR_LARGE_HEIGHT, "BaseWeapon_AmmoBarLargeText"
		else
			flWidth, flHeight, sFont = AMMO_BAR_WIDTH, AMMO_BAR_HEIGHT, "BaseWeapon_AmmoBarText"
		end
		local flX, flY = flW - flWidth, flH - flHeight
		local a = self.Primary.Ammo
		if a && a != "" && string.lower( a ) != "none" then
			a = ply:GetAmmoCount( a )
			if a > 0 then
				draw.SimpleTextOutlined( a, sFont, flX, flY, Color( 255, 255, 255, 255 ), nil, nil, 1, Color( 0, 0, 0, 255 ) )
			end
		end
		if !b then
			local flTotal = flWidth * flClip
			flX = flX - flTotal
			surface_DrawRect( flX, flY, flTotal, flHeight )

			if CurTime() <= MyTable.flReloadTime then
				surface_SetDrawColor( 255, 255, 255, 255 * ( 1 - math.abs( math.sin( RealTime() * 5 ) ) * .9 ) )
				local flX, flY = flW - flWidth, flH - flHeight
				for _ = 1, flClip do
					flX = flX - flWidth
					surface_DrawRect( flX + 1, flY + 1, flWidth - 2, flHeight - 2 )
				end
			else
				surface_SetDrawColor( 255, 255, 255, 255 )
				local flX, flY = flW - flWidth, flH - flHeight
				for _ = 1, self:Clip1() do
					flX = flX - flWidth
					surface_DrawRect( flX + 1, flY + 1, flWidth - 1, flHeight - 2 )
				end

				surface_SetDrawColor( 32, 32, 32, 255 )
				for _ = self:Clip1() + 1, flClip do
					flX = flX - flWidth
					surface_DrawRect( flX + 1, flY + 1, flWidth - 1, flHeight - 2 )
				end
			end
		end
	end

	if !cThirdPerson:GetBool() then
		if CEntity_GetNW2Bool( ply, "CTRL_bSprinting" )|| CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) || CEntity_GetNW2Bool( ply, "CTRL_bInCover" ) && !CEntity_GetNW2Bool( ply, "CTRL_bGunUsesCoverStance" ) then return true end
		if flAimMultiplier <= .5 && MyTable.bDontDrawCrosshairDuringZoom && MyTable.vViewModelAim then return true end
	end

	local v = __WEAPON_CROSSHAIR_TABLE__[ MyTable.Crosshair ]
	if v != nil then
		local EAimingAt = ply:GetNW2Int "DR_EAimingAt"
		if EAimingAt == 1 then
			if v( MyTable, self, 255, 0, 0, MyTable.flCrosshairAlpha ) then return true end
		elseif EAimingAt == 2 then
			if v( MyTable, self, 0, 255, 0, MyTable.flCrosshairAlpha ) then return true end
		elseif v( MyTable, self, 255, 255, 255, MyTable.flCrosshairAlpha ) then return true end
	end

	local flHeight, flWidth = ScrH(), ScrW()
	local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
	local flEnd = .002 * flHeight
	local flCrosshairAlpha = MyTable.flCrosshairAlpha
	for I = 0, flEnd do surface.DrawCircle( flX, flY, I, 255, 255, 255, flCrosshairAlpha ) end
	local flTarget = flEnd + .0001 * flHeight
	for I = flEnd, flTarget do surface.DrawCircle( flX, flY, I, 0, 0, 0, flCrosshairAlpha ) end

	return true
end

function SWEP:CustomAmmoDisplay() return {} end
