AddCSLuaFile()
DEFINE_BASECLASS "BaseAlarm"

sound.Add {
	name = "SimpleSiren",
	sound = "AirRaidSirenOscillatorLoop.wav",
	level = 100,
	channel = CHAN_STATIC
}

scripted_ents.Register( ENT, "SimpleSiren" )

list.Set( "SpawnableEntities", "SimpleSiren", {
	PrintName = "#SimpleSiren",
	ClassName = "SimpleSiren"
} )

ENT.Editable = true
function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "AlarmClass", { KeyName = "iClass", Edit = { type = "String", order = 0, title = "Class" } } )
	if SERVER then
		self:NetworkVarNotify( "AlarmClass", function( self, _, _, c )
			if !c:lower():sub( 1, 6 ) != "class_" then return end
			c = _G[ c ]
			if c then self:SetNPCClass( c ) end
		end )
	end
end

ENT.PrintName = "#SimpleSiren"

if !SERVER then return end

ENT.CATEGORIZE = { Siren = true }

ENT.flAudibleDistSqr = 3981071.705535

ENT.flRoundsPerMinuteLimit = 3400
ENT.flRoundsPerMinute = 0
ENT.flWailSpeedLimitMin = 128
ENT.flWailSpeedLimitMax = 512
ENT.flWailTime = 0
ENT.flWailTimeMin = 0
ENT.flWailTimeMax = ENT.flRoundsPerMinuteLimit / ENT.flWailSpeedLimitMin
ENT.flWailLowerBound = .33
ENT.flWailSpeed = -1

function ENT:Initialize()
	BaseClass.Initialize( self )
	self:SetModel "models/props_combine/combine_interface001.mdl"
	self:PhysicsInit( SOLID_VPHYSICS )
	self:PhysWake()
end

function ENT:Think()
	local pSound = self.pSound
	if !pSound then
		pSound = CreateSound( self, "SimpleSiren" )
		pSound:PlayEx( 0, 0 )
		self.pSound = pSound
	end
	pSound:SetDSP( 4 )
	if self.bIsOn then
		local f = self.flWailSpeed
		if CurTime() > self.flWailTime then
			f = self.flWailSpeed < 0 && math.Rand( self.flWailSpeedLimitMin, self.flWailSpeedLimitMax ) || math.Rand( -self.flWailSpeedLimitMax, -self.flWailSpeedLimitMin )
			self.flWailTime = CurTime() + math.Rand( self.flWailTimeMin, self.flWailTimeMax )
		end
		self.flWailSpeed = f
		f = self.flRoundsPerMinute + f * FrameTime()
		self.flRoundsPerMinute = math.Clamp( f, 0, self.flRoundsPerMinuteLimit )
		if f <= ( self.flRoundsPerMinuteLimit * self.flWailLowerBound ) then
			self.flWailSpeed = math.Rand( self.flWailSpeedLimitMin, self.flWailSpeedLimitMax )
			self.flWailTime = CurTime() + math.Rand( self.flWailTimeMin, self.flWailTimeMax )
		elseif f > self.flRoundsPerMinuteLimit then
			self.flWailSpeed = math.Rand( -self.flWailSpeedLimitMax, -self.flWailSpeedLimitMin )
			self.flWailTime = CurTime() + math.Rand( self.flWailTimeMin, self.flWailTimeMax )
		end
	else
		self.flRoundsPerMinute = math.Approach( self.flRoundsPerMinute, 0, self.flWailSpeedLimitMax * FrameTime() )
	end
	local f = self.flRoundsPerMinute / self.flRoundsPerMinuteLimit
	pSound:ChangeVolume( f * .5 )
	pSound:ChangePitch( f * 100 )
	BaseClass.Think( self )
	self:NextThink( CurTime() )
	return true
end

function ENT:OnRemove()
	local pSound = self.pSound
	pSound:Stop() // SHUT UP YOU'RE DEAD
end
