AddCSLuaFile()
DEFINE_BASECLASS "base_anim"

if SERVER then include "Server.lua" end

ENT.__PROJECTILE__ = true

scripted_ents.Register( ENT, "BaseProjectile" )
