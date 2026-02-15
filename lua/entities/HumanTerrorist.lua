AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayerHuman"

scripted_ents.Register( ENT, "HumanTerrorist" )

ENT.CATEGORIZE = { Terrorist = true }

list.Set( "NPC", "HumanTerrorist", {
	Name = "#HumanTerrorist",
	Class = "HumanTerrorist",
	Category = "Humans",
	Weapons = { // My humble terrorist WeaponSet (yes that term is a C&C Generals: ZH reference)!
		"weapon_smg1",
		"weapon_shotgun",
		"weapon_357",
		"weapon_pistol",
		"DesertEagle",
		"BenelliM4Super90",
		"MAC10",
		"MP5",
		"UMP45",
		"AK47",
		"AWM"
	}
} )

if !SERVER then return end

if !CLASS_HUMAN_TERRORIST then Add_NPC_Class "CLASS_HUMAN_TERRORIST" end
ENT.iDefaultClass = CLASS_HUMAN_TERRORIST

function ENT:Initialize()
	self:SetModel( math.random( 2 ) == 1 && "models/player/phoenix.mdl" || "models/player/arctic.mdl" )
	self:SetHealth( 100 )
	self:SetMaxHealth( 100 )
	BaseClass.Initialize( self )
end
