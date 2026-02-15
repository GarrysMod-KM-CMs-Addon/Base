AddCSLuaFile()
DEFINE_BASECLASS "base_nextbot"

ENT.__ACTOR__ = true

if SERVER then
	include "Server.lua"

	local CEntity_SetNWVector = FindMetaTable( "Entity" ).SetNWVector
	function ENT:SetPlayerColor( v ) CEntity_SetNWVector( self, "m_vcPlayerColor", v ) end
end

local CEntity_GetNWVector = FindMetaTable( "Entity" ).GetNWVector
// Such a bright fallback because that means unset.
// In simpler words, we're trying to scream "ERROR!!!"
local v = Vector( 1, 1, 1 )
function ENT:GetPlayerColor() return CEntity_GetNWVector( self, "m_vcPlayerColor", v ) end

scripted_ents.Register( ENT, "BaseActor" )