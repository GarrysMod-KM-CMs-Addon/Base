// Only handles melee dodging for now, and is meant to be used for dodge moves

ENT.Defense = {}

DEF_SAFE = 0

// Seven minutes. Seven minutes is all I can spare to play with you.
// Jokes aside, this basically means we have a fast dodge available,
// ex. 5 seconds, and they have a slow attack, ex. 5.5 seconds.
// Returns: free time available
DEF_TIME_TO_SPARE = 2

// Returns: range to keep from enemy
DEF_DONT_ADVANCE_TO_RANGE = 3

DEF_FUCK = 4

DEF_NO_ACTION_NEEDED = DEF_FUCK

DEF_DODGING = 5

local pairs = pairs
local CurTime = CurTime
local insert = table.insert
local table_IsEmpty = table.IsEmpty
local table_Random = table.Random

function IsActiveDefenseAction( EAction )
	return EAction == DEF_DODGING
end

local function TraverseRadiusDodgeActions( self, MyTable, pEnemy, Dodge, flRadius, vRadius, flHit, tValidActions, flRadiusSqr )
	for sKey, Action in pairs( Dodge ) do
		if sKey == "BaseClass" then
			local ESpecial, Param = TraverseRadiusDodgeActions( self, MyTable, pEnemy, Action, flRadius, vRadius, flHit, tValidActions, flRadiusSqr )
			if ESpecial then return ESpecial, Param end
			continue
		end

		if !( Action.HasDodgePart && Action.HasDodgePart( self ) ) then continue end

		// TODO: If we can dodge at a slower speed, randomly do it faster/slower,
		// as long as it's still available and won't get us fucked
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

		insert( tValidActions, { Action, 1 } )
	end
end

local function AttemptRadiusDodge( self, MyTable, pEnemy, Dodge, flRadius, vRadius )
	local tValidActions = {}

	local ESpecial, Param = TraverseRadiusDodgeActions( self, MyTable, pEnemy, Dodge, flRadius, vRadius, pEnemy.MELEE_flHit, tValidActions, flRadius * flRadius )
	if ESpecial then return ESpecial, Param end

	if table_IsEmpty( tValidActions ) then return DEF_FUCK end

	local tAction = table_Random( tValidActions )
	if tAction then
		tAction[ 1 ].Perform( self, MyTable, tAction[ 2 ] )
		return DEF_DODGING
	else
		ErrorNoHaltWithStack "What the fuck lmao"
	end
end

function ENT:HandleDefense( MyTable, Defense )
	local pEnemy = MyTable.Enemy

	if !IsValid( pEnemy ) then return DEF_SAFE end

	if CurTime() > ( pEnemy.MELEE_flEnd || 0 ) then return DEF_SAFE end

	local flHit = pEnemy.MELEE_flHitEnd || pEnemy.MELEE_flHit
	if flHit && CurTime() > flHit then return DEF_SAFE end

	local flRadius = pEnemy.MELEE_flRadius

	if !flRadius then
		if pEnemy.MELEE_fvStart then
			// Hacky hack hack
			flRadius = pEnemy:MELEE_fvStart():Distance( pEnemy:MELEE_fvEnd() )
		else return DEF_SAFE end
	end

	local vRadius = pEnemy.MELEE_vRadius || pEnemy:GetPos()
	if self:GetPos():DistToSqr( vRadius ) > flRadius * flRadius then
		return DEF_DONT_ADVANCE_TO_RANGE, flRadius
	end

	return AttemptRadiusDodge( self, MyTable, pEnemy, Defense || MyTable.Dodge, flRadius, vRadius )
end
