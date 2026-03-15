DEFINE_BASECLASS "BaseThrowable"

SWEP.Category = "Throwables"
SWEP.PrintName = "#FlashBang"
SWEP.Purpose = "Flashbang grenade. Unknown manufacturer."
SWEP.ViewModel = Model "models/weapons/cstrike/c_eq_flashbang.mdl"
SWEP.WorldModel = Model "models/weapons/w_eq_flashbang.mdl"
SWEP.Spawnable = true

if !SERVER then return end

local util = util
local util_BlastDamage = util.BlastDamage
local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetPos = CEntity.GetPos
local CEntity_OBBCenter = CEntity.OBBCenter
local CEntity_Remove = CEntity.Remove
local EffectData = EffectData
local util_Effect = util.Effect

SWEP.__PROJECTILE_EXPLOSION__ = true
SWEP.EXPLOSION_flRadius = 256
SWEP.EXPLOSION_flDamage = 32

SWEP.__FLASHBANG__ = true
SWEP.FLASHBANG_flBlindTime = 5
SWEP.FLASHBANG_flBlindFadeTime = 5

SWEP.GRENADE_flMinimumTime = 2.2
SWEP.GRENADE_flMaximumTime = 2.4

function SWEP:Detonate()
	local MyTable = CEntity_GetTable( self )
	local v = CEntity_GetPos( self ) + CEntity_OBBCenter( self )
	util_BlastDamage( self, self, v, MyTable.EXPLOSION_flRadius, MyTable.EXPLOSION_flDamage )
	local ed = EffectData()
	ed:SetOrigin( v )
	ed:SetFlags( 128 )
	util_Effect( "Explosion", ed )
	CEntity_Remove( self )
end

local math = math
local math_Clamp = math.Clamp
local math_Remap = math.Remap

function SWEP:GAME_OnHurtSomething( ent, dmg )
	local f = ent.ScreenFade
	if f then
		local MyTable = CEntity_GetTable( self )
		f( ent, SCREENFADE.IN, color_white,
			math_Clamp( math_Remap( dmg:GetDamage(), 0, MyTable.GRENADE_flDamage, 0, MyTable.FLASHBANG_flBlindTime ), 0, MyTable.FLASHBANG_flBlindTime ),
			math_Clamp( math_Remap( dmg:GetDamage(), 0, MyTable.GRENADE_flDamage, 0, MyTable.FLASHBANG_flBlindFadeTime ), 0, MyTable.FLASHBANG_flBlindFadeTime ) )
	end
end
