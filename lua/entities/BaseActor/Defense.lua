// Only handles melee dodging for now, and is meant to be used for dodge moves

ENT.Defense = {}

DEF_SAFE = 0

// Seven minutes. Seven minutes is all I can spare to play with you.
// Jokes aside, this basically means we have a fast dodge available,
// ex. 5 seconds, and they have a slow attack, ex. 5.5 seconds.
// Returns: free time available
DEF_TIME_TO_SPARE = 2

DEF_FUCK = 3

DEF_NO_ACTION_NEEDED = DEF_FUCK

DEF_DODGING = 4

// Returns: range to keep from enemy
DEF_DONT_ADVANCE_TO_RANGE = 5

local pairs = pairs
local CurTime = CurTime
local insert = table.insert
local table_IsEmpty = table.IsEmpty
local table_Random = table.Random

local function TraverseRadiusDodgeActions( self, MyTable, pEnemy, Defense, flRadius, vRadius, flHit, tValidActions, flRadiusSqr )
	for sKey, Action in pairs( Defense ) do
		if sKey == "BaseClass" then
			local ESpecial, Param = TraverseRadiusDodgeActions( self, MyTable, pEnemy, Action, flRadius, vRadius, flHit, tValidActions, flRadiusSqr )
			if ESpecial then return ESpecial, Param end
			continue
		end

		if !( Action.HasDodgePart && Action.HasDodgePart( self ) ) then continue end

		local flDuration = Action.Duration( self )
		local flCycle = 1

		local flUntilHit = flHit - CurTime()
		if flUntilHit <= flDuration then
			flCycle = flUntilHit / flDuration
		end

		if flUntilHit > flDuration then
			local vTarget = Action.Point( self, flCycle )
			if vTarget:DistToSqr( vRadius ) > flRadiusSqr then
				return DEF_TIME_TO_SPARE, flUntilHit - flDuration
			else continue end
		end

		insert( tValidActions, Action )
	end
end

local function AttemptRadiusDodge( self, MyTable, pEnemy, Defense, flRadius, vRadius )
	local tValidActions = {}

	local ESpecial, Param = TraverseRadiusDodgeActions( self, MyTable, pEnemy, Defense, flRadius, vRadius, pEnemy.MELEE_flHit, tValidActions, flRadius * flRadius )
	if ESpecial then return ESpecial, Param end

	if table_IsEmpty( tValidActions ) then return DEF_FUCK end

	local Action = table_Random( tValidActions )
	if Action then
		Action.Perform( self, MyTable )
		return DEF_DODGING
	else
		ErrorNoHaltWithStack "What the fuck lmao"
	end
end

function ENT:HandleDefense( MyTable, Defense )
	Defense = Defense || MyTable.Defense

	local pEnemy = MyTable.Enemy

	if !IsValid( pEnemy ) then return DEF_SAFE end

	if CurTime() > ( pEnemy.MELEE_flEnd || 0 ) then return DEF_SAFE end

	local flRadius = pEnemy.MELEE_flRadius

	if !flRadius then return DEF_SAFE end // TODO: Learn to dodge other types of hits too

	local vRadius = pEnemy.MELEE_vRadius || pEnemy:GetPos()
	if self:GetPos():DistToSqr( vRadius ) > flRadius * flRadius then
		return DEF_DONT_ADVANCE_TO_RANGE, flRadius
	end

	return AttemptRadiusDodge( self, MyTable, pEnemy, Defense, flRadius, vRadius )
end
