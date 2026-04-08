// Whether we wanna advance or retreat, and how fast
ENT.flCombatState = 1
// Same as above, except caused even by small amounts of gunfire
// When You're retreating via this, don't shout "FALL BACK TO COVER!!!"
ENT.flCombatStateSmall = 1

// If an ally this close to us is falling back, we will also do
ENT.flAllyRetreatShareDistance = 4096

ENT.flCombatStateSuppression = 0
ENT.flCombatStateSuppressionMax = 512
ENT.flCombatStateSuppressionRec = 2
ENT.flCombatStateSuppressionEffect = 256

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
	local flSupLong = MyTable.flCombatStateSuppression
	// If some of us are already retreating, join them
	local t, i = MyTable.GetAlliesByClass( self ), 1
	if t then
		for ally in pairs( t ) do
			if !IsValid( ally ) then continue end
			if CVector_DistToSqr( vMe, CEntity_GetPos( ally ) ) > flDistSqr then continue end
			local tAlly = CEntity_GetTable( ally )
			local n = tAlly.flCombatStateSuppression || 0
			if n > flSupLong then flSupLong = n end
			i = i + ( ally.GAME_flThreat || 1 )
		end
	end
	h = h * i
	MyTable.flCombatStateSuppression = flSupLong
	MyTable.flCombatState = math_Clamp( math_Remap( flSupLong, 0, h * MyTable.flCombatStateSuppressionEffect, 1, -1 ), -1, 1 )
	return f, fs
end
