// Whether we wanna advance or retreat, and how fast
ENT.flCombatState = 1

// If an ally this close to us is falling back, we will also do
ENT.flAllyRetreatShareDistance = 4096

ENT.flCombatStateSuppression = 0
ENT.flCombatStateSuppressionEffect = 640

ENT.flSquadHealth = 0

local math = math
local math_Clamp = math.Clamp
local math_Remap = math.Remap

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_Health = CEntity.Health
local CEntity_GetPos = CEntity.GetPos

local CVector_DistToSqr = FindMetaTable( "Vector" ).DistToSqr

local IsValid = IsValid
function ENT:CalcCombatState( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	local h = CEntity_Health( self )
	local flDistSqr = MyTable.flAllyRetreatShareDistance
	flDistSqr = flDistSqr * flDistSqr
	local vMe = CEntity_GetPos( self )
	local flSuppression = MyTable.flCombatStateSuppression
	local t = MyTable.GetAlliesByClass( self ), 1
	if t then
		for pAlly in pairs( t ) do
			if !IsValid( pAlly ) || self == pAlly then continue end
			if CVector_DistToSqr( vMe, CEntity_GetPos( pAlly ) ) > flDistSqr then continue end
			local n = CEntity_GetTable( pAlly ).flCombatStateSuppression || 0
			if n > flSuppression then flSuppression = n end
			h = h + CEntity_Health( pAlly )
		end
	end
	MyTable.flSquadHealth = h
	MyTable.flCombatState = math_Clamp( math_Remap( flSuppression, 0, h * MyTable.flCombatStateSuppressionEffect, 1, -1 ), -1, 1 )
end
