ENT.TRAVERSES = TRAVERSES_NONE
ENT.flMass = 1
ENT.flBuoyancy = 0
ENT.flExitTime = 0

function ENT:Move( vDirection, flSpeed ) end
function ENT:Stay() end
function ENT:Turn( vDirection ) end
function ENT:TurnLeft() end
function ENT:TurnRight() end
function ENT:AimWeapon( vAim ) end // Global Vector, NOT Direction
function ENT:CanWeapon() end // Can We have a Weapon?
function ENT:HasWeapon() end // Do We have a Weapon?
function ENT:DoesWeaponHit( v ) end
function ENT:FireWeapon() end
function ENT:GetShootPos() end
function ENT:GetForwardDirection() return self:GetForward() end

local __VEHICLE_TABLE_LOCAL__ = __VEHICLE_TABLE__
local bit_band = bit.band
function ENT:Initialize()
	local f = self.TRAVERSES
	if bit_band( f, TRAVERSES_WATER ) != 0 then __VEHICLE_TABLE_LOCAL__[ TRAVERSES_WATER ][ self ] = true end
	if bit_band( f, TRAVERSES_GROUND ) != 0 then __VEHICLE_TABLE_LOCAL__[ TRAVERSES_GROUND ][ self ] = true end
	if bit_band( f, TRAVERSES_AIR ) != 0 then __VEHICLE_TABLE_LOCAL__[ TRAVERSES_AIR ][ self ] = true end
end
hook.Add( "Think", "BaseVehicle", function()
	local t = {}
	for cat, tbl in pairs( __VEHICLE_TABLE_LOCAL__ ) do
		t[ cat ] = {}
		for ent in pairs( tbl ) do
			if IsValid( ent ) && bit_band( ent.TRAVERSES, cat ) != 0 then
				t[ cat ][ ent ] = true
			end
		end
	end
	__VEHICLE_TABLE__ = t
	__VEHICLE_TABLE_LOCAL__ = __VEHICLE_TABLE__
end )

function ENT:Use( ply )
	if CurTime() <= self.flExitTime || IsValid( self.pDriver ) || !ply:IsPlayer() then return end
	self:EnterVehicle( ply )
	self.bDriverHoldingUse = true
end

function ENT:EnterVehicle( pDriver )
	self.pDriver = pDriver
	pDriver.GAME_pVehicle = self
	if pDriver:IsPlayer() then pDriver:SetNW2Entity( "GAME_pVehicle", self ) end
end

ENT.flExitDistance = 64

local util_TraceHull = util.TraceHull
function ENT:ExitVehicle( pDriver )
	local v = self:GetPos() + self:OBBCenter() - self:GetForward() * self.flExitDistance * self:GetModelScale()
	if util_TraceHull( {
		start = self:GetPos() + self:OBBCenter(),
		endpos = v,
		mask = MASK_SOLID,
		filter = { self, pDriver },
		mins = pDriver:OBBMins(),
		maxs = pDriver:OBBMaxs()
	} ).Hit then return end
	if pDriver:IsPlayer() then pDriver:SetNW2Entity "GAME_pVehicle" end
	pDriver.GAME_pVehicle = nil
	pDriver:SetParent( NULL )
	pDriver:SetPos( v )
	local a = pDriver:GetAngles()
	a.p = 0
	a.r = 0
	pDriver:SetAngles( a )
	self.pDriver = nil
	self.flExitTime = CurTime() + 1
	return true
end

ENT.AutomaticFrameAdvance = true

function ENT:Tick() end
function ENT:PlayerControls( ply, cmd ) end

local IsValid = IsValid
function ENT:Think()
	local p = self:GetPhysicsObject()
	if IsValid( p ) then
		p:SetMass( self.flMass )
		p:SetBuoyancyRatio( self.flBuoyancy )
	end
	local pDriver = self.pDriver
	if IsValid( pDriver ) then
		pDriver:SetLocalPos( self:GetSeatPosition() )
		pDriver:SetLocalAngles( self:GetSeatAngle() )
		if pDriver:GetParent() != self then pDriver:SetParent( self ) end
	end
	self:NextThink( CurTime() )
	return true
end
