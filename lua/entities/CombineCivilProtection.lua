AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayer"

scripted_ents.Register( ENT, "CombineCivilProtection" )
scripted_ents.Alias( "npc_combine_s", "CombineCivilProtection" )

ENT.CATEGORIZE = {
	Combine = true,
	CivilProtection = true
}

sound.Add {
	name = "CombineCivilProtectionDeath",
	channel = CHAN_AUTO,
	level = 80,
	sound = {
		"npc/metropolice/die1.wav",
		"npc/metropolice/die2.wav",
		"npc/metropolice/die3.wav",
		"npc/metropolice/die4.wav"
	}
}

list.Set( "NPC", "npc_metropolice", {
	Name = "#CombineCivilProtection",
	Class = "CombineCivilProtection",
	Category = "Combine",
	Weapons = {
		"weapon_pistol,weapon_smg1",
		"weapon_pistol"
	}
} )

if CLIENT then return end

ENT.m_iDefaultClass = CLASS_COMBINE

function ENT:Initialize()
	self:SetModel "models/player/police.mdl"
	self:SetHealth( 150 )
	self:SetMaxHealth( 150 )
	self:SetPlayerColor( Vector() )
	BaseClass.Initialize( self )
end

function ENT:OnCreateRagdoll( pRagdoll ) pRagdoll:EmitSound "CombineCivilProtectionDeath" end
