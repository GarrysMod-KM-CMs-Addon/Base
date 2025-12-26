AddCSLuaFile()
DEFINE_BASECLASS "BaseProjectile"

scripted_ents.Register( ENT, "rpg_missile" )

if !SERVER then return end

local SOLID_VPHYSICS = SOLID_VPHYSICS
local ParticleEffectAttach = ParticleEffectAttach
local PATTACH_ABSORIGIN_FOLLOW = PATTACH_ABSORIGIN_FOLLOW
local util_SpriteTrail = util.SpriteTrail

local CEntity = FindMetaTable "Entity"
local CEntity_SetModel = CEntity.SetModel
local CEntity_PhysicsInit = CEntity.PhysicsInit
local CEntity_SetHealth = CEntity.SetHealth
local CEntity_SetMaxHealth = CEntity.SetMaxHealth

function ENT:Initialize()
	CEntity_SetModel( self, "models/weapons/w_missile_launch.mdl" )
	CEntity_PhysicsInit( self, SOLID_VPHYSICS )
	CEntity_SetHealth( self, 128 )
	CEntity_SetMaxHealth( self, 128 )
end

ENT.__PROJECTILE_EXPLOSION__ = true
ENT.EXPLOSION_flDamage = 2048
ENT.EXPLOSION_flRadius = 512

ENT.__PROJECTILE_ROCKET__ = true
ENT.ROCKET_flSpeed = 4096

local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local CEntity_GetForward = CEntity.GetForward
local CEntity_GetTable = CEntity.GetTable
local CEntity_NextThink = CEntity.NextThink
local CurTime = CurTime

function ENT:Think()
	local pPhys = CEntity_GetPhysicsObject( self )
	if !IsValid( pPhys ) then return end
	pPhys:SetVelocity( CEntity_GetForward( self ) * CEntity_GetTable( self ).ROCKET_flSpeed )
	CEntity_NextThink( self, CurTime() )
	return true
end

local util_BlastDamage = util.BlastDamage
local CEntity_GetOwner = CEntity.GetOwner
local IsValid = IsValid
local ParticleEffect = ParticleEffect

local CEntity_GetPos = CEntity.GetPos
local CEntity_OBBCenter = CEntity.OBBCenter
local CEntity_EmitSound = CEntity.EmitSound
local CEntity_GetAngles = CEntity.GetAngles
local CEntity_EmitSound = CEntity.EmitSound
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_Remove = CEntity.Remove
local util_Effect = util.Effect

function ENT:Detonate( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	if MyTable.bDetonated then return end
	local vPos = CEntity_GetPos( self )
	local v = vPos + CEntity_OBBCenter( self )
	local pOwner = CEntity_GetOwner( self )
	self:EmitSound( self:WaterLevel() > 0 && "BaseExplosionEffect.Water" || "BaseExplosionEffect.Sound" )
	local flMagnitude = self.flMagnitude
	local flDistance = MyTable.EXPLOSION_flRadius
	util_BlastDamage( self, GetOwner( self ), self:GetPos(), flDistance, MyTable.EXPLOSION_flDamage )
	flDistance = flDistance - 96
	for _ = 1, math.max( 5, flDistance * .2 ) do
		local dir = VectorRand()
		local tr = util.TraceLine {
			start = self:GetPos() + dir * 50,
			endpos = self:GetPos() + dir * 50 + VectorRand() * math.Rand( 0, flDistance ),
			mask = MASK_SOLID
		}
		local ed = EffectData()
		ed:SetOrigin( tr.HitPos - Vector( 0, 0, 24 ) )
		ed:SetNormal( VectorRand() )
		ed:SetFlags( 4 ) // A brighter kaboom
		util_Effect( "Explosion", ed )
	end
	local flSpeed = flDistance * 8
	for _ = 1, math.max( 5, flDistance * math.Rand( .03, .06 ) ) do
		local dir = VectorRand()
		local tr = util.TraceLine {
			start = self:GetPos() + dir * 50,
			endpos = self:GetPos() + dir * 50 + VectorRand() * math.Rand( 0, flDistance ),
			mask = MASK_SOLID
		}
		local p = ents.Create "prop_physics"
		p:SetPos( tr.HitPos )
		p:SetModel "models/combine_helicopter/helicopter_bomb01.mdl"
		p:SetNoDraw( true )
		p:Spawn()
		p.GAME_bFireBall = true
		local f = ents.Create "env_fire_trail"
		f:SetPos( p:GetPos() )
		f:SetParent( p )
		f:Spawn()
		p:GetPhysicsObject():AddVelocity( VectorRand() * math.Rand( 0, flSpeed ) )
		AddThinkToEntity( p, function( self ) self:Ignite( 999999 ) if math.random( GetFlameStopChance( self ) * FrameTime() ) == 1 || self:WaterLevel() != 0 then self:Remove() return true end end )
	end
	for i = 1, math.max( 5, flDistance * .1 ) do
		local dir = VectorRand()
		util.Decal( "Scorch", self:GetPos() + dir * 50, self:GetPos() + dir * 50 + VectorRand() * flDistance )
	end
	MyTable.bDetonated = true
	CEntity_Remove( self )
end

function ENT:PhysicsCollide()
	local MyTable = CEntity_GetTable( self )
	MyTable.Detonate( self, MyTable )
end

local CEntity_Health = CEntity.Health

function ENT:OnTakeDamage( dDamage )
	local MyTable = CEntity_GetTable( self )
	if MyTable.bDead then return 0 end
	local f = CEntity_Health( self ) - dDamage:GetDamage()
	CEntity_SetHealth( self, f )
	if f <= 0 then MyTable.bDead = true MyTable.Detonate( self, MyTable ) return 0 end
end
