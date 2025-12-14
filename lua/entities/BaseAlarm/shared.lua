DEFINE_BASECLASS "base_anim"
AddCSLuaFile()

if SERVER then include "Server.lua" end

scripted_ents.Register( ENT, "BaseAlarm" )
