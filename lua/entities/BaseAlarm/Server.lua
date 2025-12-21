ENT.__ALARM__ = true

// 0 means audible when visible
ENT.flAudibleDistSqr = 0

local GENERAL_AREA_SIZE_SQR = 4096 * 4096

function ENT:Initialize()
	self:SetUseType( SIMPLE_USE )
	local iClass = self:Classify()
	local t = __ALARMS__[ iClass ]
	if t then t[ self ] = true
	else __ALARMS__[ iClass ] = { [ self ] = true } end
end

local isentity, IsValid = isentity, IsValid
hook.Add( "Think", "Alarm", function()
	local t = {}
	for cls, tbl in pairs( __ALARMS__ ) do
		for ent in pairs( tbl ) do
			if !isentity( ent ) || !IsValid( ent ) then continue end
			local v = t[ cls ]
			if v then v[ ent ] = true else t[ cls ] = { [ ent ] = true } end
		end
	end
	__ALARMS__ = t
	local t = {}
	for pEntity in pairs( __ALARMS_ACTIVE__ ) do
		if !isentity( pEntity ) || !IsValid( pEntity ) || !pEntity.bIsOn then continue end
		t[ pEntity ] = true
	end
	__ALARMS_ACTIVE__ = t
end )

ENT.iDefaultClass = 0
ENT.iClass = 0
function ENT:Classify() return self:GetNPCClass() end
function ENT:GetNPCClass() return self.iLastCallerClass || self.iClass || self.iDefaultClass end
function ENT:SetNPCClass( iClass )
	local iPreviousClass = self:GetNPCClass()
	local t = __ALARMS__[ iPreviousClass ]
	if t then t[ self ] = nil end
	iClass = iClass || CLASS_NONE
	self.iClass = iClass
	local t = __ALARMS__[ iClass ]
	if t then t[ self ] = true
	else __ALARMS__[ iClass ] = { [ self ] = true } end
end

function ENT:CanToggle( ent ) local c = self:Classify() return c == CLASS_NONE || ent.Classify && ent:Classify() == c end

ENT.flTelepathyRangeSqr = 4194304/*2048*/

function ENT:Think()
	local f = self.flReinforcementEndTime
	if f && CurTime() > f then
		local iClass = self:GetNPCClass()
		local f = __ALARM_REINFORCEMENTS__[ iClass ]
		local vPos = self:GetPos() + self:OBBCenter()
		if f then f( self, vPos, 1 ) end
		local t = __ALARMS__[ iClass ]
		if t then
			for ent in pairs( t ) do
				if ent != self && ent:NearestPoint( vPos ):DistToSqr( vPos ) > GENERAL_AREA_SIZE_SQR then continue end
				ent.bIsOn = nil
				ent.pCaller = nil
				ent.iLastCallerClass = nil
				ent.bSpawnedReinforcements = nil
				ent.flReinforcementStartTime = nil
				ent.flReinforcementEndTime = nil
				ent.flCoolDown = CurTime() + math.Rand( 90, 180 )
			end
		end
		if ( self.iClass || self.iDefaultClass ) == CLASS_NONE then
			local t = __ALARMS__[ CLASS_NONE ]
			if t then
				for ent in pairs( t ) do
					if ent != self && ent:NearestPoint( vPos ):DistToSqr( vPos ) > GENERAL_AREA_SIZE_SQR then continue end
					ent.bIsOn = nil
					ent.pCaller = nil
					ent.iLastCallerClass = nil
					ent.bSpawnedReinforcements = nil
					ent.flReinforcementStartTime = nil
					ent.flReinforcementEndTime = nil
					ent.flCoolDown = CurTime() + math.Rand( 90, 180 )
				end
			end
		end
	end
	self:NextThink( CurTime() )
	return true
end

function ENT:TurnOn( ent, pCallerOverride )
	if ent.__ALARM__ || self:CanToggle( ent ) then
		self.bIsOn = true
		local pCaller = IsValid( pCallerOverride ) && pCallerOverride || ent
		self.pCaller = pCaller
		local f = pCaller.GetNPCClass
		if f then self.iLastCallerClass = f( pCaller ) end
		self.bSpawnedReinforcements = nil
		self.flReinforcementStartTime = CurTime()
		self.flReinforcementEndTime = CurTime() + math.Rand( 20, 40 )
		__ALARMS_ACTIVE__[ self ] = true
		if ent.__ALARM__ then return end
		local t = __ALARMS__[ self:Classify() ]
		if t then
			local flDistSqr, vPos = self.flTelepathyRangeSqr, self:GetPos()
			for ent in pairs( t ) do
				if ent == self || vPos:DistToSqr( ent:GetPos() ) > flDistSqr then continue end
				ent:TurnOn( self, pCaller )
			end
		end
	end
end
function ENT:TurnOff( ent )
	if ent.__ALARM__ || self:CanToggle( ent ) then
		self.bIsOn = nil
		self.pCaller = nil
		self.iLastCallerClass = nil
		self.bSpawnedReinforcements = nil
		self.flReinforcementStartTime = nil
		self.flReinforcementEndTime = nil
		if ent.__ALARM__ then return end
		local t = __ALARMS__[ self:Classify() ]
		if t then
			local flDistSqr, vPos = self.flTelepathyRangeSqr, self:GetPos()
			for ent in pairs( t ) do
				if ent == self || vPos:DistToSqr( ent:GetPos() ) > flDistSqr then continue end
				ent:TurnOff( self )
			end
		end
	end
end
function ENT:Toggle( ent )
	if self:CanToggle( ent ) then
		if self.bIsOn then
			self:TurnOff( ent )
		else
			self:TurnOn( ent )
		end
	end
end

function ENT:Use( _, pCaller ) self:Toggle( pCaller ) end
