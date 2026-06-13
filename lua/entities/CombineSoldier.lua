AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayer"

scripted_ents.Register( ENT, "CombineSoldier" )
scripted_ents.Alias( "npc_combine_s", "CombineSoldier" )

ENT.CATEGORIZE = {
	Combine = true,
	Soldier = true
}

sound.Add {
	name = "CombineSoldierDeath",
	channel = CHAN_AUTO,
	level = 90,
	sound = {
		"npc/combine_soldier/die1.wav",
		"npc/combine_soldier/die2.wav",
		"npc/combine_soldier/die3.wav"
	}
}

list.Set( "NPC", "npc_combine_s", {
	Name = "#CombineSoldier",
	Class = "CombineSoldier",
	Category = "Combine",
	Weapons = {
		"weapon_smg1", "weapon_ar2", "weapon_shotgun",
		"weapon_smg1,weapon_ar2",
		"weapon_shotgun,weapon_smg1",
		"weapon_shotgun,weapon_ar2",
		"weapon_shotgun,weapon_smg1,weapon_ar2",
	}
} )

if !SERVER then return end

ENT.iDefaultClass = CLASS_COMBINE

function ENT:Initialize()
	self:SetModel "models/player/combine_soldier.mdl"
	self:SetHealth( 250 )
	self:SetMaxHealth( 250 )
	self:SetPlayerColor( Vector( 0, 1, 1 ) )
	BaseClass.Initialize( self )
end

function ENT:OnKilled( ... )
	self:EmitSentence { SOUND = "CombineSoldierDeath" }
	self:HandleSentences()
	return BaseClass.OnKilled( self, ... )
end
