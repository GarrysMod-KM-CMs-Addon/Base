AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

if SERVER then
	include "Server.lua"
	include "Player.lua"
	include "Miscellaneous.lua"
end

scripted_ents.Register( ENT, "BaseActorPlayer" )