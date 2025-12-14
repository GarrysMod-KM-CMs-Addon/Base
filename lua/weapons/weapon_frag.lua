DEFINE_BASECLASS "BaseThrowable"

SWEP.Category = "Throwables"
SWEP.PrintName = "#weapon_frag"

SWEP.Purpose = "An explosive grenade made by the Combine. Used by their soldiers to “extract” enemies out of cover."
SWEP.ViewModel = Model "models/weapons/c_grenade.mdl"
SWEP.WorldModel = Model "models/weapons/w_grenade.mdl"
SWEP.Spawnable = true

SWEP.GRENADE_flMinimumTime = 3
SWEP.GRENADE_flMaximumTime = 3

SWEP.aPullPin = ACT_VM_DRAW

if !SERVER then return end

local util = util
local util_BlastDamage = util.BlastDamage
local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetPos = CEntity.GetPos
local CEntity_OBBCenter = CEntity.OBBCenter
local CEntity_Remove = CEntity.Remove
local CEntity_EmitSound = CEntity.EmitSound
local EffectData = EffectData
local util_Effect = util.Effect

SWEP.__PROJECTILE_EXPLOSION__ = true
SWEP.EXPLOSION_flRadius = 384
SWEP.EXPLOSION_flDamage = 4096

SWEP.flNextTick = 0

function SWEP:Detonate()
	local MyTable = CEntity_GetTable( self )
	local v = CEntity_GetPos( self ) + CEntity_OBBCenter( self )
	util_BlastDamage( self, self, v, MyTable.EXPLOSION_flRadius, MyTable.EXPLOSION_flDamage )
	local ed = EffectData()
	ed:SetOrigin( v )
	ed:SetFlags( 128 )
	util_Effect( "Explosion", ed )
	util_Effect( "HelicopterMegaBomb", ed )
	CEntity_Remove( self )
end

local CurTime = CurTime

sound.Add {
	name = "Combine_Extractor_Tick",
	sound = "weapons/grenade/tick1.wav",
	pitch = { 99, 101 },
	level = 100,
	channel = CHAN_STATIC
}

function SWEP:GAME_Think()
	local MyTable = CEntity_GetTable( self )
	if MyTable.bPinPulled && CurTime() > MyTable.flNextTick then
		CEntity_EmitSound( self, "Combine_Extractor_Tick" )
		MyTable.flNextTick = CurTime() + math.Remap( CurTime(), MyTable.flLastPinPull, MyTable.GRENADE_flTime, .5, .1 )
	end
	BaseClass.GAME_Think( self )
end
