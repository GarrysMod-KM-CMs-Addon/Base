AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayer"

scripted_ents.Register( ENT, "CombineSoldier" )
scripted_ents.Alias( "npc_combine_s", "CombineSoldier" )

local VOICE_PITCH_MIN, VOICE_PITCH_MAX = 90, 110

ENT.CATEGORIZE = {
	Combine = true,
	Soldier = true
}

sound.Add {
	name = "Combine_Soldier_FiringAtAnExposedTarget",
	channel = CHAN_VOICE,
	level = 150,
	pitch = { VOICE_PITCH_MIN, VOICE_PITCH_MAX },
	sound = {
		"npc/combine_soldier/vo/contact.wav",
		"npc/combine_soldier/vo/contactconfim.wav",
		"npc/combine_soldier/vo/contactconfirmprosecuting.wav",
		"npc/combine_soldier/vo/fullactive.wav"
	}
}

sound.Add {
	name = "Combine_Soldier_Advancing",
	channel = CHAN_VOICE,
	level = 150,
	pitch = { VOICE_PITCH_MIN, VOICE_PITCH_MAX },
	sound = {
		"npc/combine_soldier/vo/closing.wav",
		"npc/combine_soldier/vo/closing2.wav",
		"npc/combine_soldier/vo/unitisclosing.wav",
		"npc/combine_soldier/vo/unitismovingin.wav",
		"npc/combine_soldier/vo/bearing.wav"
	}
}

sound.Add {
	name = "Combine_Soldier_TakeCover",
	channel = CHAN_VOICE,
	level = 150,
	pitch = { VOICE_PITCH_MIN, VOICE_PITCH_MAX },
	sound = {
		"npc/combine_soldier/vo/bodypackholding.wav",
		"npc/combine_soldier/vo/cover.wav",
		"npc/combine_soldier/vo/coverhurt.wav",
		"npc/combine_soldier/vo/stabilizationteamholding.wav",
		"npc/combine_soldier/vo/sharpzone.wav",
		"npc/combine_soldier/vo/heavyresistance.wav"
	}
}

sound.Add {
	name = "Combine_Soldier_Retreating",
	channel = CHAN_VOICE,
	level = 150,
	pitch = { VOICE_PITCH_MIN, VOICE_PITCH_MAX },
	sound = {
		"npc/combine_soldier/vo/displace.wav",
		"npc/combine_soldier/vo/displace2.wav",
		"npc/combine_soldier/vo/sharpzone.wav",
		"npc/combine_soldier/vo/heavyresistance.wav",
	}
}

sound.Add {
	name = "Combine_Soldier_Death",
	channel = CHAN_AUTO,
	level = 150,
	pitch = { VOICE_PITCH_MIN, VOICE_PITCH_MAX },
	sound = {
		"npc/combine_soldier/die1.wav",
		"npc/combine_soldier/die2.wav",
		"npc/combine_soldier/die3.wav"
	}
}

sound.Add {
	name = "Combine_Soldier_HoldFire",
	channel = CHAN_AUTO,
	level = 150,
	pitch = { VOICE_PITCH_MIN, VOICE_PITCH_MAX },
	sound = "npc/combine_soldier/vo/hasnegativemovement.wav"
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

local CEntity_EmitSound = FindMetaTable( "Entity" ).EmitSound

function ENT:DLG_FiringAtAnExposedTarget() CEntity_EmitSound( self, "Combine_Soldier_FiringAtAnExposedTarget" ) end
function ENT:DLG_Advancing() CEntity_EmitSound( self, "Combine_Soldier_Advancing" ) end
function ENT:DLG_Retreating() CEntity_EmitSound( self, "Combine_Soldier_Retreating" ) end
function ENT:DLG_TakeCoverGeneral() CEntity_EmitSound( self, "Combine_Soldier_TakeCover" ) end
function ENT:DLG_HoldFire() CEntity_EmitSound( self, "Combine_Soldier_HoldFire" ) BaseClass.DLG_HoldFire( self ) end

ENT.iDefaultClass = CLASS_COMBINE

function ENT:Initialize()
	self:SetModel "models/player/combine_soldier.mdl"
	self:SetHealth( 200 )
	self:SetMaxHealth( 200 )
	self:SetPlayerColor( Vector( 0, 1, 1 ) )
	BaseClass.Initialize( self )
end

function ENT:OnKilled( ... )
	CEntity_EmitSound( self, "Combine_Soldier_Death" )
	return BaseClass.OnKilled( self, ... )
end
