AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayer"

local VOICE_PITCH = { 90, 110 }

sound.Add {
	name = "Human_TakeCover",
	channel = CHAN_VOICE,
	level = 150,
	pitch = VOICE_PITCH,
	sound = {
		"vo/npc/male01/takecover02.wav"
	}
}

sound.Add {
	name = "Human_Retreat",
	channel = CHAN_VOICE,
	level = 150,
	pitch = VOICE_PITCH,
	sound = {
		"vo/npc/male01/gethellout.wav",
		"vo/npc/male01/runforyourlife01.wav",
		"vo/npc/male01/runforyourlife02.wav",
		"vo/npc/male01/runforyourlife03.wav"
	}
}

if SERVER then
	local CEntity_EmitSound = FindMetaTable( "Entity" ).EmitSound

	function ENT:DLG_State_TakeCover() CEntity_EmitSound( self, "Human_TakeCover" ) end
	function ENT:DLG_State_Retreat() CEntity_EmitSound( self, "Human_Retreat" ) end
end

scripted_ents.Register( ENT, "BaseActorPlayerHuman" )
