AddCSLuaFile()
DEFINE_BASECLASS "base_anim"

function ENT:SetupDataTables()
	self:NetworkVar( "Vector", "SeatPosition" )
	self:NetworkVar( "Angle", "SeatAngle" )
end

ENT.__VEHICLE__ = true

if SERVER then include "Server.lua" end

scripted_ents.Register( ENT, "BaseVehicle" )
