AddCSLuaFile()
DEFINE_BASECLASS "base_point"

ENT.__ACTOR_BULLSEYE__ = true
// ENT.Enemy = NULL
// ENT.Owner = NULL
ENT.flTime = 0

function ENT:Initialize() self.flTime = CurTime() end

scripted_ents.Register( ENT, "BaseActorBullseye" )
