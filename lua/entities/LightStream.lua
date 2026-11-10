AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.PrintName = "#LightStream"

scripted_ents.Register( ENT, "LightStream" )

local TRANSMIT_ALWAYS = TRANSMIT_ALWAYS
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

function ENT:SetupDataTables()
	// Use 0-1 everywhere EXCEPT `lightcolor`! Internally NOT stored as a 0-255 integer!
	// In `lightcolor`, this is remapped from [0,255] to [0,1]!
	self:NetworkVar( "Float", "Brightness" )
	// Used by `Shadows`, mode 1: the distance to the trace's `HitPos`
	self:NetworkVar( "Float", "TrueDistance" )
	// 0: Use Splinter Cell: Blacklist (modified Unreal Engine 2) inspired shadows (recommended)
	// 1: Use EXTREMELY EXPENSIVE shadows drawn by Vulcan (does not render AT ALL on weak platforms!)
	self:NetworkVar( "Bool", "Shadows" )
	// The texture of the light
	self:NetworkVar( "String" ,"Texture" )
	// The light color
	self:NetworkVar( "Vector" ,"LightColor" )
	// Minimum distance. Clamped if less than 10.
	self:NetworkVar( "Float", "MinDistance" )
	// How far does the light go?
	self:NetworkVar( "Float", "Distance" )
	// The amount of degrees to light up vertically
	self:NetworkVar( "Float", "VerFOV" )
	// The amount of degrees to light up horizontally
	self:NetworkVar( "Float", "HorFOV" )
end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

if SERVER then
	function ENT:Initialize()
		self:Update()
		self:DrawShadow( false )
	end

	function ENT:Think()
		self:DrawShadow( false )
		self:Update()
		self:NextThink( CurTime() + .01 )
		return true
	end

	local util_TraceLine = util.TraceLine
	local math = math
	local math_cos = math.cos
	local math_acos = math.acos
	local math_Clamp = math.Clamp

	function ENT:Update()
		local t = { [ self ] = true }

		local pOwner = self:GetOwner()
		if IsValid( pOwner ) then
			t[ pOwner ] = true
			for _, e in ipairs( pOwner:GetChildren() ) do t[ e ] = true end
		end

		local pParent = self:GetParent()
		if IsValid( pParent ) then
			t[ pParent ] = true
			for _, e in ipairs( pParent:GetChildren() ) do t[ e ] = true end
		end

		local tr = util_TraceLine {
			start = self:GetPos(),
			endpos = self:GetPos() + self:GetForward() * 999999,
			filter = function( ent ) return t[ ent ] == nil end,
			mask = MASK_VISIBLE_AND_NPCS
		}

		f = math.Clamp( tr.HitPos:Distance( self:GetPos() ) + 128, 0, self:GetDistance() )
		self.flShadowDistance = f
		self:SetTrueDistance( f )
	end

	function ENT:KeyValue( k, v )
		k = string.lower( k )
		if self:SetNetworkKeyValue( k, v ) then return end
		if k == "brightness" then self:SetBrightness( v )
		elseif k == "color" || k == "lightcolor" then
			local t = {}
			for n in string.gmatch( v, "%S+" ) do table.insert( t, ( tonumber( n ) || 255 ) * .003921568627451 ) end
			self:SetLightColor( Vector( t[ 1 ], t[ 2 ], t[ 3 ] ) )
			if t[ 4 ] then self:SetBrightness( t[ 4 ] ) end
		elseif k == "horfov" then self:SetHorFOV( v )
		elseif k == "verfov" then self:SetVerFOV( v )
		elseif k == "fov" || k == "lightfov" then self:SetHorFOV( v ) self:SetVerFOV( v )
		elseif k == "mindistance" || k == "nearz" then self:SetMinDistance( v )
		elseif k == "distance" || k == "farz" then self:SetDistance( v )
		elseif k == "texture" then self:SetTexture( v )
		elseif k == "shadows" || k == "shadowquality" then self:SetShadows( v == "1" ) end
	end

	function ENT:AcceptInput( k, _, _, v )
		k = string.lower( k )
		if k == "settexture" || k == "spotlighttexture" then self:SetTexture( v )
		elseif k == "setbrightness" then self:SetBrightness( v )
		elseif k == "setlightcolor" || k == "setcolor" then
			local t = {}
			for n in string.gmatch( v, "%S+" ) do table.insert( t, ( tonumber( n ) || 255 ) * .003921568627451 ) end
			self:SetLightColor( Vector( t[ 1 ], t[ 2 ], t[ 3 ] ) )
			if t[ 4 ] then self:SetBrightness( t[ 4 ] ) end
		elseif k == "setmindistance" || k == "setnearz" then self:SetMinDistance( v )
		elseif k == "setdistance" || k == "setfarz" then self:SetDistance( v )
		elseif k == "sethorfov" then self:SetHorFOV( v )
		elseif k == "setverfov" then self:SetVerFOV( v )
		elseif k == "setfov" || k == "fov" then self:SetHorFOV( v ) self:SetVerFOV( v )
		elseif k == "shadows"  ||  k  ==  "enableshadows" then self:SetShadows( v  ==  "1" ) end
	end

	return
end

function ENT:Initialize()
	local MyTable = CEntity_GetTable( self )
	MyTable.Update( self, MyTable )

	self.pixelvis_handle_t = util.GetPixelVisibleHandle()

	self:DrawShadow( false )
end

local vTemp1, vTemp2 = Vector(), Vector()
function ENT:Think()
	self:DrawShadow( false )

	local flDistance = self:GetTrueDistance()

	vTemp1[ 1 ] = flDistance
	vTemp1[ 2 ] = flDistance
	vTemp1[ 3 ] = flDistance

	vTemp2[ 1 ] = flDistance
	vTemp2[ 2 ] = flDistance
	vTemp2[ 3 ] = flDistance

	self:SetRenderBounds( vTemp1, vTemp2 )

	local MyTable = CEntity_GetTable( self )
	MyTable.Update( self, MyTable )

	self:SetNextClientThink( CurTime() )
	return true
end

local math_max = math.max
local tonumber = tonumber
function ENT:Update( MyTable )
	if #self:GetTexture() <= 0 then self:SetTexture "effects/flashlight/soft" end

	local pTexture = MyTable.m_pProjectedTexture
	if !pTexture then
		pTexture = ProjectedTexture()
		MyTable.m_pProjectedTexture = pTexture
	end

	pTexture:SetPos( self:GetPos() )
	pTexture:SetAngles( self:GetAngles() )
	pTexture:SetTexture( self:GetTexture() )
	pTexture:SetShadowFilter( 0 )
	pTexture:SetNearZ( math_max( tonumber( self:GetMinDistance() ), 10 ) )
	pTexture:SetFarZ( self:GetDistance() )
	pTexture:SetColor( self:GetLightColor():ToColor() )
	pTexture:SetBrightness( self:GetBrightness() )
	pTexture:SetHorizontalFOV( self:GetHorFOV() )
	pTexture:SetVerticalFOV( self:GetVerFOV() )

	if self:GetShadows() then
		pTexture:SetEnableShadows( true )
	else
		pTexture:SetEnableShadows( false )
	end

	pTexture:SetFarZ( self:GetTrueDistance() )

	pTexture:Update()
end

function ENT:OnRemove()
	local pTexture = CEntity_GetTable( self ).m_pProjectedTexture
	if IsValid( pTexture ) then pTexture:Remove() end
end

ENT.RenderGroup = RENDERGROUP_BOTH
ENT.WantsTranslucency = true

local mLight = Material "sprites/light_ignorez"
local mBeam = Material "effects/lamp_beam"

function ENT:Draw()
	local pixelvis_handle_t = self.pixelvis_handle_t

	// TODO: This is a really bad check. We need to optionally store the player that owns it in each LightStream.
	if !pixelvis_handle_t || GetViewEntity() == LocalPlayer() then return end

	local vViewNormal = self:GetPos() - EyePos()
	local flDistance = vViewNormal:Length()
	vViewNormal:Normalize()
	local vForward = self:GetForward()
	local flViewDot = vViewNormal:Dot( vForward * -1 )
	local c = self:GetLightColor():ToColor()
	local r, g, b = c.r, c.g, c.b
	local v = self:GetPos()
	render.SetMaterial( mBeam )
	local flTrueDistance = self:GetTrueDistance() * .5
	local flWidth = flTrueDistance * math.abs( math.sin( ( self:GetVerFOV() + self:GetHorFOV() ) * .5 ) ) * .125
	local flAlpha = math.Remap( flViewDot ^ 5, 1, .5, 0, 1 )
	local flActualAlpha = flAlpha * self:GetBrightness() * .02
	render.StartBeam( 3 )
		render.AddBeam( v + vForward * 1, flWidth, 0, Color( r, g, b, 32 * flActualAlpha ) )
		render.AddBeam( v + vForward * flTrueDistance * .5, flWidth, .5, Color( r, g, b, 96 * flActualAlpha ) )
		render.AddBeam( v + vForward * flTrueDistance, flWidth, 1, Color( r, g, b, 0 ) )
	render.EndBeam()
	render.SetMaterial( mLight )
	local flVisible = util.PixelVisible( v, 16, pixelvis_handle_t )
	if !flVisible then return end
	// Beam flare
	flDistance = math.Clamp( flTrueDistance, 32, self:GetDistance() )
	local flSize = self:GetBrightness() * self:GetDistance() * .002 * flVisible
	c.a = flAlpha * 255 * self:GetBrightness() * .05
	render.DrawSprite( v + vForward, flSize, flSize, c )
	// Directly exposed flare
	flDistance = math.Clamp( flTrueDistance, 32, self:GetDistance() )
	local flSize = self:GetBrightness() * self:GetDistance() * .005 * flVisible
	c.a = flViewDot ^ 25 * 255
	render.DrawSprite( v + vForward, flSize, flSize, c )
end

ENT.DrawTranslucent = ENT.Draw
