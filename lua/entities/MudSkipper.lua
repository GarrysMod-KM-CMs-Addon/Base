// There has been a debate going on if it's the Airboat or the Mudskipper.
// Airboat is actually the general term, like "jeep" or "car", and the MudSkipper is the model.
// End of story. There's just nothing else to say.

AddCSLuaFile()
DEFINE_BASECLASS "BaseVehicleAirBoat"

scripted_ents.Register( ENT, "MudSkipper" )
scripted_ents.Alias( "prop_vehicle_airboat", "MudSkipper" )

local CEntity_LookupSequence = FindMetaTable( "Entity" ).LookupSequence
function ENT:HandleAnimation( ply ) return CEntity_LookupSequence( ply, "drive_airboat" ) end

function ENT:GetForwardDirection() return -self:GetRight() end

if !SERVER then return end

function ENT:Initialize()
	BaseClass.Initialize( self )
	self:SetModel "models/airboat.mdl"
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetSeatPosition( Vector( 0, -8, 32 ) )
end
