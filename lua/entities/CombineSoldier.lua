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

if CLIENT then
	local MATERIAL = Material "sprites/light_glow02_add"
	local COLOR_STANDARD = Color( 123, 182, 255 )
	local COLOR_SHOTGUNNER = Color( 255, 123, 57 )
	local SIZE = 8

	local render_SetMaterial = render.SetMaterial
	local render_DrawSprite = render.DrawSprite

	function ENT:Draw()
		self:DrawModel()

		local v, ang = self:GetBonePosition( self:LookupBone "ValveBiped.Bip01_Head1" )
		local vGlow = v + ang:Forward() * 4.5 + ang:Right() * 5 + ang:Up() * 1.75

		render_SetMaterial( MATERIAL )

		local cColor = self:GetSkin() == 0 && COLOR_STANDARD || COLOR_SHOTGUNNER

		render_DrawSprite( vGlow, SIZE, SIZE, cColor )
		render_DrawSprite( vGlow, SIZE, SIZE, cColor )

		vGlow = v + ang:Forward() * 4.5 + ang:Right() * 5 + ang:Up() * -1.75
		render_DrawSprite( vGlow, SIZE, SIZE, cColor )
		render_DrawSprite( vGlow, SIZE, SIZE, cColor )
	end

	return
end

ENT.bNightVision = true

ENT.iDefaultClass = CLASS_COMBINE

function ENT:Initialize()
	self:SetModel "models/player/combine_soldier.mdl"
	self:SetHealth( 250 )
	self:SetMaxHealth( 250 )
	self:SetPlayerColor( Vector( 0, 1, 1 ) )
	BaseClass.Initialize( self )
end

function ENT:OnKilled( ... )
	self:EmitSentence { sSentence = "CombineSoldierDeath" }
	self:HandleSentences()
	return BaseClass.OnKilled( self, ... )
end
