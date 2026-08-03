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

if CLIENT then
	local MATERIAL = Material "sprites/light_glow02_add"
	local COLOR = Color( 255, 0, 0 )
	local SIZE = 12

	local render_SetMaterial = render.SetMaterial
	local render_DrawSprite = render.DrawSprite

	function ENT:Draw()
		self:DrawModel()

		local vGlow, ang = self:GetBonePosition( self:LookupBone "ValveBiped.Bip01_Head1" )
		vGlow:Add( ang:Forward() * 5 + ang:Right() * 4.5 )

		render_SetMaterial( MATERIAL )

		render_DrawSprite( vGlow, SIZE, SIZE, COLOR )
		render_DrawSprite( vGlow, SIZE, SIZE, COLOR )
	end

	return
end

function ENT:Initialize()
	BaseClass.Initialize( self )
	self:SetModel "models/player/combine_super_soldier.mdl"
	self:SetHealth( 300 )
	self:SetMaxHealth( 300 )
	self:SetPlayerColor( Vector( 1, 0, 0 ) )
end
