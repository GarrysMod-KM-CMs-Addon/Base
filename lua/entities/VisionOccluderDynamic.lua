AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "brush"

local CEntity = FindMetaTable "Entity"

local COLLISION_GROUP_WORLD = COLLISION_GROUP_WORLD
local EFL_DONTBLOCKLOS = EFL_DONTBLOCKLOS

local CEntity_SetNoDraw = CEntity.SetNoDraw
local CEntity_SetCollisionGroup = CEntity.SetCollisionGroup
local CEntity_RemoveEFlags = CEntity.RemoveEFlags
local CEntity_PhysicsInit = CEntity.PhysicsInit
local CEntity_SetMoveType = CEntity.SetMoveType

function ENT:Initialize()
	CEntity_PhysicsInit( self, SOLID_VPHYSICS )
	CEntity_SetMoveType( self, MOVETYPE_FLY )
	CEntity_SetNoDraw( self, true )
	CEntity_SetCollisionGroup( self, COLLISION_GROUP_WORLD )
	CEntity_RemoveEFlags( self, EFL_DONTBLOCKLOS )
end

local CEntity_AddEFlags = CEntity.AddEFlags

local string_lower = string.lower
function ENT:AcceptInput( s )
	s = string_lower( s )
	if s == "enable" then
		CEntity_RemoveEFlags( self, EFL_DONTBLOCKLOS )
	elseif s == "disable" then
		CEntity_AddEFlags( self, EFL_DONTBLOCKLOS )
	end
end
