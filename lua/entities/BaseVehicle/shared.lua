// NOTE: This is a very, VERY old base. It is barely functional, and even then, it sucks.
// DO NOT USE IT until it has been recoded, which will probably happen in a few... years.

AddCSLuaFile()
DEFINE_BASECLASS "base_anim"

function ENT:SetupDataTables()
	self:NetworkVar( "Vector", "SeatPosition" )
	self:NetworkVar( "Angle", "SeatAngle" )
end

ENT.__VEHICLE__ = true

if SERVER then include "Server.lua" end

scripted_ents.Register( ENT, "BaseVehicle" )
