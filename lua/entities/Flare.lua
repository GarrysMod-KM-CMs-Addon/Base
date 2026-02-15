AddCSLuaFile()
DEFINE_BASECLASS "base_anim"

ENT.PrintName = "#Flare"

ENT.__FLARE__ = true // Don't confuse with __FLARE_ACTIVE__!

sound.Add {
	name = "FlareBurn",
	channel = CHAN_STATIC,
	level = 150,
	sound = "weapons/flaregun/burn.wav"
}

if !SERVER then return end

function ENT:GetNPCClass() return self.iClass || -1 end
ENT.Classify = ENT.GetNPCClass
function ENT:SetNPCClass() end // Will automatically use GetOwner()'s Classify() instead

function ENT:Initialize()
	self:SetModel "models/weapons/w_grenade.mdl"
	self:PhysicsInit( SOLID_VPHYSICS )
end

function ENT:OnRemove() if self.Sound then self.Sound:Stop() end end

ENT.AutomaticFrameAdvance = true

function ENT:Think()
	if self:IsOnFire() then self:Extinguish() end
	self:NextThink( CurTime() )
	self.__FLARE_ACTIVE__ = nil
	if !self.flEndTime then if IsValid( self.pSprite ) then self.pSprite:Remove() end if self.Sound then self.Sound:Stop() end return true end
	if CurTime() > self.flEndTime then self:Remove() return true end
	self.__FLARE_ACTIVE__ = true
	local p = self:GetOwner()
	if IsValid( p ) then
		local t = p.FLARE_Table
		if t then t[ self ] = true
		else t = { [ self ] = true } end
		if p.Classify then self.iClass = p:Classify() end
	end
	if IsValid( self.pSprite ) then
		local spr = self.pSprite
		// spr:SetKeyValue( "scale", math.Remap( CurTime(), self.flStartTime, self.flEndTime, 1, 0 ) )
		spr:SetKeyValue( "renderamt", math.Remap( CurTime(), self.flStartTime, self.flEndTime, 1530, 0 ) )
		spr:Fire( "ColorRedValue", 255 )
		spr:Fire( "ColorGreenValue", 0 )
		spr:Fire( "ColorBlueValue", 0 )
	else
		local spr = ents.Create "env_sprite"
		spr:SetPos( self:GetPos() + self:OBBCenter() )
		spr:SetParent( self )
		spr:SetOwner( self )
		spr:SetKeyValue( "model", "sprites/glow1.spr" )
		spr:SetKeyValue( "scale", 1 )
		spr:SetKeyValue( "rendermode", 9 )
		spr:SetKeyValue( "renderamt", 1530 )
		spr:Fire( "ColorRedValue", 255 )
		spr:Fire( "ColorGreenValue", 0 )
		spr:Fire( "ColorBlueValue", 0 )
		spr:Spawn()
		self.pSprite = spr
	end
	if self.Sound then
		self.Sound:ChangeVolume( math.Remap( CurTime(), self.flStartTime, self.flEndTime, .5, .05 ) )
		self.Sound:ChangePitch( math.Remap( CurTime(), self.flStartTime, self.flEndTime, 100, 0 ) )
	else
		self.Sound = CreateSound( self, "FlareBurn" )
		self.Sound:Play()
	end
	return true
end

function ENT:PhysicsCollide( d )
	local p = d.HitEntity
	if IsValid( p ) then p:Ignite( 10 ) end
end

local AcceptInput = {
	start = function( self, Value ) self.flStartTime = CurTime() self.flEndTime = CurTime() + ( tonumber( Value ) || math.Rand( 30, 60 ) ) end,
	die = function( self, Value ) self.flStartTime = CurTime() self.flEndTime = CurTime() + ( tonumber( Value ) || math.Rand( 30, 60 ) ) end,
	launch = function( self, Value )
		local p = self:GetPhysicsObject()
		if IsValid( p ) then p:AddVelocity( self:GetForward() * ( tonumber( Value ) || math.Rand( 3072, 4096 ) ) )
		else ErrorNoHaltWithStack "Flare with No Physics Object! What The Hell?!" end
	end
}
function ENT:AcceptInput( Key, _, _, Value )
	local v = AcceptInput[ string.lower( Key ) ]
	if v then v( self, Value ) end
end

scripted_ents.Register( ENT, "Flare" )
scripted_ents.Alias( "env_flare", "Flare" )
