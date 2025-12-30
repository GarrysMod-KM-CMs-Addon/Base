AddCSLuaFile()

ENT.Base = "base_point"
ENT.Type = "point"
ENT.PrintName = "#env_projectedtexture"

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

function ENT:SetupDataTables()
	// Use 0-1 everywhere EXCEPT `lightcolor`! Internally NOT stored as a 0-255 integer!
	//In `lightcolor`, this is remapped from [0,255] to [0,1]!
	self:NetworkVar( "Float", 0, "Brightness", { KeyName = "raw.brightness" } )
	// Sprite size if `SpriteDisabled` isn't on
	self:NetworkVar( "Float", 1, "SpriteSize", { KeyName = "raw.spritesize" } )
	// Used by `Shadows`, mode 1: the distance to the trace's `HitPos`
	self:NetworkVar( "Float", 2, "TrueDistance", { KeyName = "raw.truedistance" } )
	/*
	0: Use Splinter Cell: Blacklist (modified Unreal Engine 2) inspired shadows (recommended)
	1: Use EXTREMELY EXPENSIVE shadows drawn by Vulcan (doesn't render AT ALL on weak platforms!)
	*/
	self:NetworkVar( "Bool", 1, "Shadows", { KeyName = "raw.shadows" } )
	// The texture of the light
	self:NetworkVar( "String", 0 ,"Texture", { KeyName = "raw.texture" } )
	// The light color
	self:NetworkVar( "Vector", 0 ,"LightColor", { KeyName = "raw.lightcolor" } )
	// Minimum distance. Clamped if less than 10.
	self:NetworkVar( "Float", 3, "MinDistance", { KeyName = "raw.mindistance" } )
	// How far does the light go?
	self:NetworkVar( "Float", 4, "Distance", { KeyName = "raw.distance" } )
	// The amount of degrees to light up vertically
	self:NetworkVar( "Float", 5, "VerFOV", { KeyName = "raw.verfov" } )
	// The amount of degrees to light up horizontally
	self:NetworkVar( "Float", 6, "HorFOV", { KeyName = "raw.horfov" } )
end

if CLIENT then
	function ENT:Initialize() self:Update() end
	function ENT:Think()
		local d = self:GetShadows() && self:GetDistance() || self:GetTrueDistance()
		self:SetRenderBounds( Vector( -d, -d, -d ), Vector( d, d, d ) )
		self:Update()
		self:SetNextClientThink( CurTime() )
		return true
	end

	function ENT:Update()
		if #self:GetTexture() <= 0 then self:SetTexture "effects/flashlight/soft" end
		local pt = self.ProjectedTexture
		if !pt then self.ProjectedTexture = ProjectedTexture() pt = self.ProjectedTexture end
		pt:SetPos( self:GetPos() )
		pt:SetAngles( self:GetAngles() )
		pt:SetTexture( self:GetTexture() )
		pt:SetShadowFilter( 0 )
		pt:SetNearZ( math.max( tonumber( self:GetMinDistance() ), 10 ) )
		pt:SetFarZ( self:GetDistance() )
		pt:SetColor( self:GetLightColor():ToColor() )
		pt:SetBrightness( self:GetBrightness() )
		pt:SetQuadraticAttenuation( self:GetDistance() )
		pt:SetHorizontalFOV( self:GetHorFOV() )
		pt:SetVerticalFOV( self:GetVerFOV() )
		if self:GetShadows() then
			self.flShadowDist = nil
			self.flShadowUpdt = 0
			pt:SetEnableShadows( true )
		else
			pt:SetEnableShadows( false )
			pt:SetFarZ( self:GetTrueDistance() )
		end
		pt:Update()
	end

	function ENT:OnRemove() if IsValid( self.ProjectedTexture ) then self.ProjectedTexture:Remove() end end
else
	function ENT:Initialize() self:Update() end
	function ENT:Think()
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
		if !self:GetShadows() || self:GetComputeTrueDistance() then
			local t = { [ self ] = true }
			local pOwner = self:GetOwner()
			if IsValid( pOwner ) then
				t[ pOwner ] = true
				for _, e in ipairs( pOwner:GetChildren() ) do t[ e ] = true end
			end
			local tr = util_TraceLine {
				start = self:GetPos(),
				endpos = self:GetPos() + self:GetForward() * self:GetDistance(),
				filter = function( ent ) return t[ ent ] == nil end,
				mask = MASK_VISIBLE_AND_NPCS
			}
			local f = tr.HitNormal:Dot( -self:GetForward() )
			f = ( f != 0 && ( tr.HitPos:Distance( self:GetPos() ) / math_cos( math_acos( math_Clamp( f, -1, 1 ) ) ) ) || tr.HitPos:Distance( self:GetPos() ) ) + 128
			self.flShadowDist = f
			self:SetTrueDistance( f )
		end
	end
	function ENT:OnRemove() if IsValid( self.Sprite ) then self.Sprite:Remove() end end
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
		elseif k == "shadows" || k == "shadowquality" then self:SetShadows( v == "1" )
		elseif k == "spritesize" then self:SetSpriteSize( tonumber( v ) || 0 )
		elseif k == "spritedisabled" then self:SetSpriteDisabled( v == "1" ) end
	end
	function ENT:AcceptInput( k, _, _, v )
		k = string.lower( k )
		if k == "settexture" || k == "spotlighttexture" then self:SetTexture( v )
		elseif k == "setbrightness" then self:SetBrightness( v )
		elseif k == "setlightcolor" || k == "setcolor" then
			local t = {}
			for n in string.gmatch( v, "%S+" ) do table.insert( t, ( tonumber( n ) || 255 ) * 0.003921568627451 ) end
			self:SetLightColor( Vector( t[ 1 ], t[ 2 ], t[ 3 ] ) )
			if t[ 4 ] then self:SetBrightness( t[ 4 ] ) end
		elseif k == "setmindistance" || k == "setnearz" then self:SetMinDistance( v )
		elseif k == "setdistance" || k == "setfarz" then self:SetDistance( v )
		elseif k == "sethorfov" then self:SetHorFOV( v )
		elseif k == "setverfov" then self:SetVerFOV( v )
		elseif k == "setfov" || k == "fov" then self:SetHorFOV( v ) self:SetVerFOV( v )
		elseif k == "shadows"  ||  k  ==  "enableshadows" then self:SetShadows( v  ==  "1" )
		elseif k == "setspritesize" then self:SetSpriteSize(tonumber( v ) || 0)
		elseif k == "setspritedisabled" then self:SetSpriteDisabled(tonumber( v )) end
	end
end
