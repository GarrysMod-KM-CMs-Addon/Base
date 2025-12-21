// Use the global SUN_HAS_A_NAME to check if the
// light_environment has a name, so that the CSM
// can turn it off and override it with itself.
// If it's nil, then changing anything that will
// differ with the map's sun data will look ugly.

// Credits to Xenthio and the Real CSM addon
// https://github.com/Xenthio/RealCSM
// I didn't just copy and paste it, however,
// I've rewritten it fully, the only things
// that are identical are materials

AddCSLuaFile()
DEFINE_BASECLASS "base_point"

ENT.AdminOnly = true

scripted_ents.Register( ENT, "CascadeShadowMapping" )

function ENT:SetupDataTables()
	self:NetworkVar( "Vector", 0, "LightColor", { KeyName = "Sun colour", Edit = { type = "VectorColor", order = 2, title = "Sun colour" } } )
	self:NetworkVar( "Float", 0, "Brightness", { KeyName = "Sun brightness", Edit = { type = "Float", order = 3, min = 0, max = 10000, title = "Sun brightness" } } )
	self:NetworkVar( "Float", 1, "SizeNear", { KeyName = "Size 1", Edit = { type = "Float", order = 4, min = 0, max = 32768, title = "Near cascade size" } } )
	self:NetworkVar( "Float", 2, "SizeMid",  { KeyName = "Size 2", Edit = { type = "Float", order = 5, min = 0, max = 32768, title = "Middle cascade size" } } )
	self:NetworkVar( "Float", 3, "SizeFar",  { KeyName = "Size 3", Edit = { type = "Float", order = 6, min = 0, max = 32768, title = "Far cascade size" } } )
	self:NetworkVar( "Float", 4, "SizeFurther",  { KeyName = "Size 4", Edit = { type = "Float", order = 8, min = 0, max = 65536, title = "Further cascade size"  } } )
	self:NetworkVar( "Float", 7, "Height", { KeyName = "Height", Edit = { type = "Float", order = 15, min = 0, max = 50000, title = "Sun Height" } } )
	self:NetworkVar( "Float", 8, "SunNearZ", { KeyName = "NearZ", Edit = { type = "Float", order = 16, min = 0, max = 32768, title = "Sun NearZ" } } )
	self:NetworkVar( "Float", 9, "SunFarZ", { KeyName = "FarZ", Edit = { type = "Float", order = 17, min = 0, max = 50000, title = "Sun FarZ"  } } )
	self:NetworkVar( "Float", 10, "Pitch", { KeyName = "Pitch", Edit = { type = "Float", order = 22, min = -180, max = 180, title = "Pitch" } } )
	self:NetworkVar( "Float", 11, "Yaw", { KeyName = "Yaw", Edit = { type = "Float", order = 23, min = -180, max = 180, title = "Yaw"  } } )
	self:NetworkVar( "Float", 12, "Roll", { KeyName = "Roll", Edit = { type = "Float", order = 24, min = -180, max = 180, title = "Roll" } } )
	if SERVER then
		self:SetLightColor( Vector( 1, 1, 1 ) )
		self:SetBrightness( -1 )
		self:SetSizeNear( 128 )
		self:SetSizeMid( 1024 )
		self:SetSizeFar( 8192 )
		self:SetSizeFurther( 65536 )
		self:SetHeight( 32768 )
		self:SetSunNearZ( 25000 )
		self:SetSunFarZ( 49152 )
		self:SetPitch( 0 )
		self:SetYaw( 0 )
		self:SetRoll( 0 )
	end
end

function ENT:Think()
	local flPitch = self:GetPitch()
	local flYaw = self:GetYaw()
	local flRoll = self:GetRoll()
	local vOffset = Vector( 0, 0, 1 )
	vOffset:Rotate( Angle( flPitch, flYaw, flRoll ) )
	local aAngle = Angle()
	aAngle = ( vector_origin - vOffset ):Angle()
	vOffset = vOffset * self:GetHeight()
	if CLIENT then
		RunConsoleCommand( "r_shadowrendertotexture", "1" )
		RunConsoleCommand( "r_shadowdist", "10000" )
		RunConsoleCommand( "r_shadows_gamecontrol", "0" )
		local tProjectedTextures = self.tProjectedTextures
		tProjectedTextures[ 1 ]:SetOrthographic( true, self:GetSizeNear(), self:GetSizeNear(), self:GetSizeNear(), self:GetSizeNear() )
		tProjectedTextures[ 2 ]:SetOrthographic( true, self:GetSizeMid(), self:GetSizeMid(), self:GetSizeMid(), self:GetSizeMid() )
		tProjectedTextures[ 3 ]:SetOrthographic( true, self:GetSizeFar(), self:GetSizeFar(), self:GetSizeFar(), self:GetSizeFar() )
		tProjectedTextures[ 4 ]:SetOrthographic( true, self:GetSizeFurther(), self:GetSizeFurther(), self:GetSizeFurther(), self:GetSizeFurther() )
		for i, pTexture in pairs( self.tProjectedTextures ) do
			pTexture:SetColor( self:GetLightColor():ToColor() )
			pTexture:SetBrightness( self:GetBrightness() )
			pTexture:SetPos( vector_origin + vOffset )
			pTexture:SetAngles( aAngle )
			pTexture:SetShadowDepthBias( 3.5e-05 + 0 * ( i - 1 ) )
			pTexture:SetShadowSlopeScaleDepthBias( 2 )
			pTexture:SetShadowFilter( .08 )
			pTexture:SetNearZ( self:GetSunNearZ() )
			pTexture:SetFarZ( self:GetSunFarZ() )
			pTexture:SetQuadraticAttenuation( 0 )
			pTexture:SetLinearAttenuation( 0 )
			pTexture:SetConstantAttenuation( 1 )
			pTexture:Update()
		end
	end
end

if CLIENT then
	ENT.tProjectedTexture = {}
	function ENT:Initialize()
		local tProjectedTextures = {}
		self.tProjectedTextures = tProjectedTextures
		for i = 1, 4 do
			local pTexture = ProjectedTexture()
			tProjectedTextures[ i ] = pTexture
			pTexture:SetEnableShadows( true )
			pTexture:SetTexture( i == 1 && "CascadeShadowMapping/MaskCenter" || "CascadeShadowMapping/MaskRing" )
		end
	end
	function ENT:OnRemove()
		timer.Simple( .1, function() render.RedownloadAllLightmaps( false, true ) end )
		for _, pTexture in pairs( self.tProjectedTexture ) do pTexture:Remove() end
		table.Empty( self.tProjectedTexture )
	end
	return
end

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

function ENT:Initialize()
	if IsValid( CascadeShadowMapping ) then self:Remove() return end
	CascadeShadowMapping = self
end

function ENT:OnRemove()
	SUN_ANGLES = Angle( self:GetPitch(), self:GetYaw(), self:GetRoll() )
	SUN_PITCH_OVERRIDE = self:GetPitch()
	SUN_BRIGHTNESS = self:GetBrightness()
	SUN_COLOR = self:GetLightColor():ToColor()
	CascadeShadowMapping = nil
end

local cCascadeShadowMapping = CreateConVar( "bCascadeShadowMapping", "0", FCVAR_ARCHIVE + FCVAR_NEVER_AS_STRING, "Forces a CascadeShadowMapping to spawn" )
hook.Add( "Think", "CascadeShadowMapping", function()
	if cCascadeShadowMapping:GetBool() then
		if !IsValid( CascadeShadowMapping ) then ents.Create( "CascadeShadowMapping" ):Spawn() end
	elseif IsValid( CascadeShadowMapping ) then CascadeShadowMapping:Remove() end
end )
