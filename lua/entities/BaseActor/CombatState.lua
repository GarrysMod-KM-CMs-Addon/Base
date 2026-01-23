// Whether we wanna advance or retreat, and how fast
ENT.flCombatState = 1
// Same as above, except caused even by small amounts of gunfire
// When You're retreating via this, don't shout "FALL BACK TO COVER!!!"
ENT.flCombatStateSmall = 1

// If an ally this close to us is falling back, we will also do
ENT.flAllyRetreatShareDistance = 4096

// Short-term suppression does not get shared between allies
ENT.flCombatStateSuppressionShort = 0
ENT.flCombatStateSuppressionShortMax = 16
ENT.flCombatStateSuppressionShortRec = 4
ENT.flCombatStateSuppressionShortEffect = 8

ENT.flCombatStateSuppressionLong = 0
ENT.flCombatStateSuppressionLongMax = 768
ENT.flCombatStateSuppressionLongRec = 2
ENT.flCombatStateSuppressionLongEffect = 512

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
	local flSupLong, flSupShort = MyTable.flCombatStateSuppressionLong, MyTable.flCombatStateSuppressionShort
	// If some of us are already retreating, join them
	local t, i = MyTable.GetAlliesByClass( self ), 1
	if t then
		for ally in pairs( t ) do
			if !IsValid( ally ) then continue end
			if CVector_DistToSqr( vMe, CEntity_GetPos( ally ) ) > flDistSqr then continue end
			local tAlly = CEntity_GetTable( ally )
			local n = tAlly.flCombatStateSuppressionLong || 0
			if n > flSupLong then flSupLong = n end
			i = i + ( ally.GAME_flThreat || 1 )
			// local n = tAlly.flCombatStateSuppressionShort || 0
			// if n > flSupShort then flSupShort = n end
		end
	end
	h = h * i
	MyTable.flCombatStateSuppressionLong = flSupLong
	// MyTable.flCombatStateSuppressionShort = flSupShort
	local f = math_Clamp( math_Remap( flSupLong, 0, h * MyTable.flCombatStateSuppressionLongEffect, 1, -1 ), -1, 1 )
	local fs = math_Clamp( math_Remap( flSupShort, 0, h * MyTable.flCombatStateSuppressionShortEffect, 1, -1 ), -1, 1 )
	MyTable.flCombatState = f
	MyTable.flCombatStateSmall = fs
	return f, fs
end
