AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

ENT.__ANIMAL__ = true

if SERVER then include "Server.lua" end

scripted_ents.Register( ENT, "BaseActorAnimal" )
