AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

if SERVER then include "Server.lua" end

scripted_ents.Register( ENT, "BaseActorPlayer" )