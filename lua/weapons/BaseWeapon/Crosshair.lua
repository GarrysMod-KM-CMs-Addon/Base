SWEP.flCrosshairInAccuracy = 0
SWEP.Primary_flSpreadX = 0
SWEP.Primary_flSpreadY = 0

local math = math
local math_max = math.max
function SWEP:GatherCrosshairSpread( MyTable, bForceIdentical )
	local flSpreadX, flSpreadY
	local v = MyTable.Primary_flSpreadX
	if v then flSpreadX = v end
	local v = MyTable.Primary_flSpreadY
	if v then flSpreadY = v end
	local flInaccuracy = MyTable.flCrosshairInAccuracy * ( MyTable.vViewModelAim && MyTable.flAimMultiplier || 1 ) + ( MyTable.flCurrentRecoilForGap / MyTable.flRecoil ) * .033
	if MyTable.bCrosshairSizeIdentical || bForceIdentical then
		local v = math_max( flSpreadX || flSpreadY, flSpreadY || flSpreadX ) + flInaccuracy
		return v, v
	end
	return flSpreadX + flInaccuracy, flSpreadY + flInaccuracy
end
function SWEP:GatherCrosshairSpreadIdeal( MyTable )
	local flSpreadX, flSpreadY
	local v = MyTable.Primary_flSpreadX
	if v then flSpreadX = v end
	local v = MyTable.Primary_flSpreadY
	if v then flSpreadY = v end
	if MyTable.bCrosshairSizeIdentical || bForceIdentical then
		local v = math_max( flSpreadX || flSpreadY, flSpreadY || flSpreadX )
		return v, v
	end
	return flSpreadX, flSpreadY
end

local surface = surface
local surface_SetTexture = surface.SetTexture
local surface_GetTextureID = surface.GetTextureID
local surface_SetDrawColor = surface_SetDrawColor
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated

local CROSSHAIR_PART_SIZE = ScrH() * .016
local CROSSHAIR_PART_SIZE_WIDTH = ScrH() * .004
local CROSSHAIR_PART_SIZE_SUB = CROSSHAIR_PART_SIZE * .5
// local CROSSHAIR_PART_SIZE_SUB_SUB = CROSSHAIR_PART_SIZE_SUB * .5

local surface_DrawRect = surface.DrawRect
local surface_SetDrawColor = surface.SetDrawColor

SWEP.Crosshair = "Rifle"

SWEP.CrosshairColorBase = Color( 255, 255, 255 )
SWEP.CrosshairColorOutLine = Color( 0, 0, 0 )
__WEAPON_CROSSHAIR_TABLE__ = {
	[ "" ] = function( MyTable, self ) return true end,
	Shotgun = function( MyTable, self )
		local flSpread = MyTable.GatherCrosshairSpreadIdeal( self, MyTable, true )
		local flHeight, flWidth = ScrH(), ScrW()
		local flRadius = flSpread * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local co = MyTable.CrosshairColorOutLine
		local f = .0008 * flHeight
		local flStart, flEnd = flRadius, flRadius + f
		local flCrosshairAlpha = MyTable.flCrosshairAlpha
		for I = flStart, flEnd do surface.DrawCircle( flX, flY, I, co.r, co.g, co.b, flCrosshairAlpha ) end
		local c = MyTable.CrosshairColorBase
		local flStart = flEnd
		local flEnd = flEnd + .0012 * flHeight
		for I = flStart, flEnd do surface.DrawCircle( flX, flY, I, c.r, c.g, c.b, flCrosshairAlpha ) end
		local flStart = flEnd
		local flEnd = flEnd + f
		for I = flStart, flEnd do surface.DrawCircle( flX, flY, I, co.r, co.g, co.b, flCrosshairAlpha ) end
		return true
	end,
	// I should technically call this one "Generic" from now on, but the name "Rifle" just stuck,
	// and I don't want to change it, even thought it would be easy
	Rifle = function( MyTable, self )
		local flSpreadX, flSpreadY = MyTable.GatherCrosshairSpread( self, MyTable )
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSpreadHorizontal = flSpreadX * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flSpreadVertical = flSpreadY * flHeight * ( 90 / MyTable.flFoV ) * .5 * ( flWidth / flHeight )
		surface_SetTexture( surface_GetTextureID "Crosshair" )
		surface_SetDrawColor( 255, 255, 255, MyTable.flCrosshairAlpha )
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
	SubMachineGun = function( MyTable, self )
		local flSpreadX, flSpreadY = MyTable.GatherCrosshairSpread( self, MyTable )
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSpreadHorizontal = flSpreadX * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flSpreadVertical = flSpreadY * flHeight * ( 90 / MyTable.flFoV ) * .5 * ( flWidth / flHeight )
		surface_SetTexture( surface_GetTextureID "Crosshair" )
		surface_SetDrawColor( 255, 255, 255, MyTable.flCrosshairAlpha )
		// Bottom
		surface_DrawTexturedRectRotated( flX, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 0 )
		// Left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 270 )
		// Right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 90 )
		//	// Left top
		//	surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_SUB_SUB, flY - flSpreadVertical - CROSSHAIR_PART_SIZE_SUB_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 225 )
		//	// Left bottom
		//	surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_SUB_SUB, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_SUB_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 315 )
		//	// Right top
		//	surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_SUB_SUB, flY - flSpreadVertical - CROSSHAIR_PART_SIZE_SUB_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 135 )
		//	// Right bottom
		//	surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_SUB_SUB, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_SUB_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 45 )
		return true
	end,
	Pistol = function( MyTable, self )
		local flSpreadX, flSpreadY = MyTable.GatherCrosshairSpread( self, MyTable )
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSpreadHorizontal = flSpreadX * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flSpreadVertical = flSpreadY * flHeight * ( 90 / MyTable.flFoV ) * .5 * ( flWidth / flHeight )
		surface_SetTexture( surface_GetTextureID "Crosshair" )
		surface_SetDrawColor( 255, 255, 255, MyTable.flCrosshairAlpha )
		// Bottom
		surface_DrawTexturedRectRotated( flX, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 0 )
		// Left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 270 )
		// Right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 90 )
		return true
	end,
	Revolver = function( MyTable, self )
		local flSpreadX, flSpreadY = MyTable.GatherCrosshairSpread( self, MyTable )
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSpreadHorizontal = flSpreadX * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flSpreadVertical = flSpreadY * flHeight * ( 90 / MyTable.flFoV ) * .5 * ( flWidth / flHeight )
		surface_SetTexture( surface_GetTextureID "Crosshair" )
		surface_SetDrawColor( 255, 255, 255, MyTable.flCrosshairAlpha )
		// Bottom
		surface_DrawTexturedRectRotated( flX, flY + flSpreadVertical + CROSSHAIR_PART_SIZE_SUB, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 0 )
		// Left
		surface_DrawTexturedRectRotated( flX - flSpreadHorizontal - CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 270 )
		// Right
		surface_DrawTexturedRectRotated( flX + flSpreadHorizontal + CROSSHAIR_PART_SIZE_SUB, flY, CROSSHAIR_PART_SIZE_WIDTH, CROSSHAIR_PART_SIZE, 90 )
		return true
	end
}
local __WEAPON_CROSSHAIR_TABLE__ = __WEAPON_CROSSHAIR_TABLE__

function SWEP.pCrosshairTable() return __WEAPON_CROSSHAIR_TABLE__ end

SWEP.Primary_flDelay = 1
SWEP.Secondary_flDelay = 1

local AMMO_BAR_WIDTH, AMMO_BAR_HEIGHT = 6, 32
local AMMO_BAR_LARGE_WIDTH, AMMO_BAR_LARGE_HEIGHT = AMMO_BAR_WIDTH * 1.33, AMMO_BAR_HEIGHT * 1.33
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

local CEntity = FindMetaTable "Entity"
local CEntity_IsOnGround = CEntity.IsOnGround
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local developer = GetConVar "developer"
local CPlayer = FindMetaTable "Player"
local CPlayer_IsSprinting = CPlayer.IsSprinting
local CPlayer_KeyDown = CPlayer.KeyDown
SWEP.bDontDrawCrosshairDuringZoom = true
local surface_DrawTexturedRect = surface.DrawTexturedRect
local math_min = math.min
local cThirdPerson = GetConVar "bThirdPerson"
local flLastDoDrawCrosshairCall = 0
function SWEP:DoDrawCrosshair()
	if developer:GetBool() then return end
	local f = SysTime()
	local flFrameTime = f - flLastDoDrawCrosshairCall
	flLastDoDrawCrosshairCall = f
	local MyTable = CEntity_GetTable( self )
	local ply = LocalPlayer()
	local flAimMultiplier = MyTable.flAimMultiplier
	MyTable.flCrosshairInAccuracy = Lerp( math_min( 15 * flFrameTime ), MyTable.flCrosshairInAccuracy, math.Clamp( ply:GetVelocity():Length() / ply:GetWalkSpeed() * .066 + .033, 0, .1 ) )
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
		f = math_max( 0, 255 - 255 * ( ( MyTable.flCurrentRecoilForCrosshair * ( ( MyTable.Primary_flDelay / .5 ) * 1000 / math_max( 50, self:GetMaxClip1() ) ) ) - 1.2 ) * .25 )
		if MyTable.vViewModelAim then
			f = f * MyTable.flAimMultiplier
		else f = Lerp( 1 - MyTable.flAimMultiplier, f, 255 ) end
		MyTable.flCrosshairAlpha = f
	end
	if !MyTable.bDontDrawAmmo then
		// TODO: Machine gun ammo cubes
		if false then//self:GetMaxClip1() > 60 then
			
		else
			local flW, flH = ScrW() * .9, ScrH() * .9
			surface_SetDrawColor( 32, 32, 32, 255 )
			local flWidth, flHeight, sFont
			if self:GetMaxClip1() <= 15 then
				flWidth, flHeight, sFont = AMMO_BAR_LARGE_WIDTH, AMMO_BAR_LARGE_HEIGHT, "BaseWeapon_AmmoBarLargeText"
			else
				flWidth, flHeight, sFont = AMMO_BAR_WIDTH, AMMO_BAR_HEIGHT, "BaseWeapon_AmmoBarText"
			end
			local flX, flY = flW - flWidth, flH - flHeight
			local a = self.Primary.Ammo
			if a && a != "" && string.lower( a ) != "none" then
				a = ply:GetAmmoCount( a )
				if a > 0 then
					draw.SimpleTextOutlined( a, sFont, flX, flY, nil, nil, nil, 1, Color( 0, 0, 0 ) )
				end
			end
			for _ = 1, self:GetMaxClip1() do
				flX = flX - flWidth - 1
				surface_DrawRect( flX, flY, flWidth, flHeight )
			end
			// TODO: Reloading animation
			//	surface_SetDrawColor( 255, 255, 255, 255 * ( 1 - math.abs( math.sin( RealTime() * 4 ) ) ) )
			//	local flX, flY = flW - flWidth, flH - flHeight
			//	for _ = 1, self:GetMaxClip1() do
			//		flX = flX - flWidth - 1
			//		surface_DrawRect( flX + 1, flY + 1, flWidth - 2, flHeight - 2 )
			//	end
			surface_SetDrawColor( 255, 255, 255, 255 )
			local flX, flY = flW - flWidth, flH - flHeight
			for _ = 1, self:Clip1() do
				flX = flX - flWidth - 1
				surface_DrawRect( flX + 1, flY + 1, flWidth - 2, flHeight - 2 )
			end
			surface_SetDrawColor( 64, 64, 64, 255 )
			for _ = self:Clip1() + 1, self:GetMaxClip1() do
				flX = flX - flWidth - 1
				surface_DrawRect( flX + 1, flY + 1, flWidth - 2, flHeight - 2 )
			end
		end
	end
	if MyTable.bSniper && flAimMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then
		surface_SetDrawColor( 0, 0, 0, 255 )
		surface_SetTexture( surface_GetTextureID( MyTable.sSniperTexture || "CrosshairScope1" ) )
		local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
		local flSize = flWidth * .5
		surface_SetDrawColor( 255, 255, 255, 255 )
		surface_DrawTexturedRect( flX - flSize * .5, flY - flSize * .5, flSize, flSize )
		surface_SetDrawColor( 0, 0, 0, 255 )
		surface_DrawRect( 0, 0, flX - flSize * .5, flHeight )
		surface_DrawRect( flX + flSize * .5, 0, flWidth - flX, flHeight )
		surface_DrawRect( flX - flSize * .5, 0, flSize, flY - flSize * .5 )
		surface_DrawRect( flX - flSize * .5, flY + flSize * .5, flSize, flHeight - flY )
		return true
	end
	if CEntity_GetNW2Bool( ply, "CTRL_bSprinting" )|| CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) || CEntity_GetNW2Bool( ply, "CTRL_bInCover" ) && !CEntity_GetNW2Bool( ply, "CTRL_bGunUsesCoverStance" ) then return true end
	if flAimMultiplier <= .5 && !cThirdPerson:GetBool() && MyTable.bDontDrawCrosshairDuringZoom && MyTable.vViewModelAim && CPlayer_KeyDown( ply, IN_ZOOM ) then return true end
	local v = __WEAPON_CROSSHAIR_TABLE__[ MyTable.Crosshair ]
	if v != nil && v( MyTable, self ) then return true end
	local flHeight, flWidth = ScrH(), ScrW()
		local flX, flY = MyTable.GatherCrosshairPosition( self, MyTable )
	local c = MyTable.CrosshairColorBase
	local flEnd = .002 * flHeight
	local flCrosshairAlpha = MyTable.flCrosshairAlpha
	for I = 0, flEnd do surface.DrawCircle( flX, flY, I, c.r, c.g, c.b, flCrosshairAlpha ) end
	c = MyTable.CrosshairColorOutLine
	local flTarget = flEnd + .0001 * flHeight
	for I = flEnd, flTarget do surface.DrawCircle( flX, flY, I, c.r, c.g, c.b, flCrosshairAlpha ) end
	return true
end

function SWEP:CustomAmmoDisplay() return {} end
