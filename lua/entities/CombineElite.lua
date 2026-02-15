AddCSLuaFile()
DEFINE_BASECLASS "CombineSoldier"

scripted_ents.Register( ENT, "CombineElite" )

ENT.CATEGORIZE = {
	Combine = true,
	Soldier = true,
	Elite = true
}

list.Set( "NPC", "CombineElite", {
	Name = "#CombineElite",
	Class = "CombineElite",
	Category = "Combine",
	Weapons = {
		"weapon_ar2",
		"weapon_smg1,weapon_ar2",
		"weapon_shotgun,weapon_ar2",
		"weapon_shotgun,weapon_smg1,weapon_ar2",
		"weapon_pistol,weapon_ar2",
		"weapon_pistol,weapon_smg1,weapon_ar2",
		"weapon_pistol,weapon_shotgun,weapon_ar2",
		"weapon_pistol,weapon_shotgun,weapon_smg1,weapon_ar2"
	}
} )

if !SERVER then return end

function ENT:Initialize()
	BaseClass.Initialize( self )
	self:SetModel "models/player/combine_super_soldier.mdl"
	self:SetHealth( 400 )
	self:SetMaxHealth( 400 )
	self:SetPlayerColor( Vector( 1, 0, 0 ) )
end
