local table_IsEmpty = table.IsEmpty
local HasRangeAttack, HasMeleeAttack = HasRangeAttack, HasMeleeAttack
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
local util_DistanceToLine = util.DistanceToLine
local math_random = math.random
local math_Rand = math.Rand
local unpack = unpack
local CurTime = CurTime

function ENT:DLG_MeleeReachable( pEnemy ) end
function ENT:DLG_MeleeUnReachable( pEnemy ) end

ACTOR_PITCH_ANGLES_UP = { 0 }
for a = 5.625, 90, 5.625 do
	table.insert( ACTOR_PITCH_ANGLES_UP, a )
	table.insert( ACTOR_PITCH_ANGLES_UP, -a )
end

ACTOR_PITCH_ANGLES_DOWN = { 0 }
for a = 5.625, 90, 5.625 do
	table.insert( ACTOR_PITCH_ANGLES_DOWN, -a )
	table.insert( ACTOR_PITCH_ANGLES_DOWN, a )
end

ACTOR_PITCH_ANGLES_LEFT = { 0 }
for a = 5.625, 22.5, 5.625 do
	table.insert( ACTOR_PITCH_ANGLES_LEFT, -a )
	table.insert( ACTOR_PITCH_ANGLES_LEFT, a )
end

ACTOR_PITCH_ANGLES_RIGHT = { 0 }
for a = 5.625, 22.5, 5.625 do
	table.insert( ACTOR_PITCH_ANGLES_RIGHT, a )
	table.insert( ACTOR_PITCH_ANGLES_RIGHT, -a )
end

local PLANT_TIME_MINIMUM = 1
local PLANT_TIME_MAXIMUM = 2

function ENT:DLG_MaintainFire()
	// TODO: Find someone else to shoot, not us
	self.flPlantEndTime = nil
	if self.bPlanted then return end
	self:Plant()
end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

// ENT.bMeleeChargeAgainstRange = true // Far Cry 3 Pirate Beheader
// ENT.flMeleeChargeTauntMultiplier = 1

function ENT:DLG_MeleeTaunt() end

ENT.flMaintainFireTime = 0
ENT.flMaintainFireTimeMin = 2
ENT.flMaintainFireTimeMax = 6
ENT.flPathStabilizer = 16

function ENT:DLG_Charge() end

Actor_RegisterSchedule( "Combat", function( self, sched, MyTable )
	local tEnemies = sched.tEnemies || MyTable.tEnemies
	if table_IsEmpty( tEnemies ) then return true end
	if !MyTable.bEnemiesHaveRangeAttack && HasRangeAttack( self ) then MyTable.SetSchedule( self, "FreeMovement", MyTable ) return end
	local enemy = sched.Enemy
	if IsValid( enemy ) then enemy = enemy
	else enemy = MyTable.Enemy if !IsValid( enemy ) then return true end end
	local enemy, trueenemy = MyTable.SetupEnemy( self, enemy, MyTable )
	if !MyTable.bHoldFire && CurTime() > ( MyTable.flLastEnemy + MyTable.flHoldFireTime ) then MyTable.DLG_HoldFire( self, MyTable ) end
	local tCover = MyTable.tCover
	if !tCover || !MyTable.vCover then
		MyTable.SetSchedule( self, "TakeCover", MyTable )
		return
	end
	local pEntity = tCover[ 6 ]
	if pEntity != nil && !IsValid( pEntity ) then
		MyTable.SetSchedule( self, "TakeCover", MyTable )
		return
	end
	local vec = MyTable.vCover
	if !vec then
		MyTable.SetSchedule( self, "TakeCover", MyTable )
		return
	end
	MyTable.Stand( self, sched.iStand )
	if sched.bAdvance then
		if LevelOfDetail( sched, "flNextSearch" ) then
			local tCover = MyTable.tCover
			local tQueue, tVisited, flBestCandidate = sched.tRetreatSearchQueue, sched.tRetreatSearchVisited || { [ tCover ] = true }, sched.flRetreatSearchBestCandidate || 0
			local pPath = sched.pEnemyPath
			if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
			local vEnemy = enemy:GetPos()
			local vTarget = vEnemy + enemy:OBBCenter()
			local pIterator = sched.pIterator
			local v = sched.vCoverBounds || self:GatherCoverBounds()
			sched.vCoverBounds = v
			local tAllies = MyTable.GetAlliesByClass( self, MyTable )
			local f = sched.flBoundingRadiusTwo || ( ( self:BoundingRadius() * .25 ) ^ 2 )
			sched.flBoundingRadiusTwo = f
			local vMaxs = MyTable.vHullDuckMaxs || MyTable.vHullMaxs
			local tCovers = {}
			local tOldCover = MyTable.tCover
			local d = MyTable.vHullMaxs.x * 4
			local flSuppressionTraceFraction = MyTable.flSuppressionTraceFraction
			local RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			local _, vPos = util_DistanceToLine( MyTable.tCover[ 1 ], MyTable.tCover[ 2 ], vEnemy )
			pPath:MoveCursorToClosestPosition( vPos )
			if !tQueue then
				local vCover = MyTable.vCover
				local flCostStart, flCostEnd, flCursorStart, flCursorEnd
				local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
				pPath:MoveCursorToClosestPosition( vStart )
				flCursorStart = pPath:GetCursorPosition()
				flCostStart = pPath:GetPositionOnPath( flCursorStart ):Distance( vStart ) + ( pPath:GetLength() - flCursorStart )
				pPath:MoveCursorToClosestPosition( vEnd )
				flCursorEnd = pPath:GetCursorPosition()
				flCostEnd = pPath:GetPositionOnPath( flCursorEnd ):Distance( vStart ) + ( pPath:GetLength() - flCursorEnd )
				if flCostStart < flCostEnd then
					flBestCandidate = flCostEnd
					pPath:MoveCursorTo( flCursorEnd )
				else
					flBestCandidate = flCostStart
					pPath:MoveCursorTo( flCursorStart )
				end
				local f = flBestCandidate - 1
				tQueue = { { tCover, f, f, nil } }
			end
			sched.tRetreatSearchQueue = tQueue
			sched.tRetreatSearchVisited = tVisited
			sched.flRetreatSearchBestCandidate = flBestCandidate
			local iHandled, bAtTheResult, tMyCover = 1, true, tCover
			local tFilter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
			local flBestCandidateLarge = flBestCandidate * 4
			local bInADynamicCoverAndDidntFindOne = tCover[ 5 ] != nil
			while !table_IsEmpty( tQueue ) do
				bAtTheResult = nil
				// if iHandled > 12 then break end
				// Suppression checks are HEAVY!
				if iHandled > 6 then break end
				iHandled = iHandled + 1
				table.SortByMember( tQueue, 2 )
				local tSource = table.remove( tQueue )
				local tCover, flTrueCost, flCost, bMustPass = unpack( tSource )
				if flCost > flBestCandidateLarge then iHandle = iHandled - 1 continue end
				local vCurrentStart, vCurrentEnd = tCover[ 1 ], tCover[ 2 ]
				for iAreaID, tIndices in pairs( tCover[ 4 ] || {} ) do
					for iIndex in pairs( tIndices ) do
						local tNewCover = __COVERS_STATIC__[ iAreaID ][ iIndex ]
						if tVisited[ tNewCover ] then continue end // Also checks for nil internally... I love Lua (actually, on second thought, I genuinely do)
						tVisited[ tNewCover ] = true
						local flCostStart, flCostEnd, flCursorStart, flCursorEnd
						local vStart, vEnd = tNewCover[ 1 ], tNewCover[ 2 ]
						pPath:MoveCursorToClosestPosition( vStart )
						flCursorStart = pPath:GetCursorPosition()
						flCostStart = pPath:GetPositionOnPath( flCursorStart ):Distance( vStart ) + ( pPath:GetLength() - flCursorStart )
						pPath:MoveCursorToClosestPosition( vEnd )
						flCursorEnd = pPath:GetCursorPosition()
						flCostEnd = pPath:GetPositionOnPath( flCursorEnd ):Distance( vStart ) + ( pPath:GetLength() - flCursorEnd )
						local flNewCost
						if flCostStart < flCostEnd then
							flNewCost = flCostEnd
							pPath:MoveCursorTo( flCursorEnd )
						else
							flNewCost = flCostStart
							pPath:MoveCursorTo( flCursorStart )
						end
						if bInADynamicCoverAndDidntFindOne then bInADynamicCoverAndDidntFindOne = nil end
						table.insert( tQueue, { tNewCover, flTrueCost +
						math.min(
							vCurrentStart:Distance( vStart ),
							vCurrentStart:Distance( vEnd ),
							vCurrentEnd:Distance( vStart ),
							vCurrentEnd:Distance( vEnd )
						) + flNewCost, flNewCost } )
					end
				end
				local t = __COVER_DYNAMIC_CONNECTIONS__[ tCover ]
				if t then
					for pEntity, tIdentifiers in pairs( t ) do
						if !IsValid( pEntity ) then continue end
						for sIdentifier, iAreaID in pairs( tIdentifiers ) do
							local tNewCover
							pcall( function() tNewCover = __COVERS_DYNAMIC__[ iAreaID ][ pEntity ][ sIdentifier ] end )
							if !tNewCover then continue end
							if tVisited[ tNewCover ] then continue end // Also checks for nil internally... I love Lua (actually, on second thought, I genuinely do)
							tVisited[ tNewCover ] = true
							local flCostStart, flCostEnd, flCursorStart, flCursorEnd
							local vStart, vEnd = tNewCover[ 1 ], tNewCover[ 2 ]
							pPath:MoveCursorToClosestPosition( vStart )
							flCursorStart = pPath:GetCursorPosition()
							flCostStart = pPath:GetPositionOnPath( flCursorStart ):Distance( vStart ) + ( pPath:GetLength() - flCursorStart )
							pPath:MoveCursorToClosestPosition( vEnd )
							flCursorEnd = pPath:GetCursorPosition()
							flCostEnd = pPath:GetPositionOnPath( flCursorEnd ):Distance( vStart ) + ( pPath:GetLength() - flCursorEnd )
							local flNewCost
							if flCostStart < flCostEnd then
								flNewCost = flCostEnd
								pPath:MoveCursorTo( flCursorEnd )
							else
								flNewCost = flCostStart
								pPath:MoveCursorTo( flCursorStart )
							end
							flBestCandidate = flNewCost
							flBestCandidateLarge = flNewCost * 4
							table.insert( tQueue, { tNewCover, flTrueCost +
							math.min(
								vCurrentStart:Distance( vStart ),
								vCurrentStart:Distance( vEnd ),
								vCurrentEnd:Distance( vStart ),
								vCurrentEnd:Distance( vEnd )
							), flNewCost } )
						end
					end
				end
				if tCover == tMyCover || flCost > flBestCandidate then continue end
				local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
				local vDirection = vEnd - vStart
				local dDirection = vDirection:GetNormalized()
				local flSize = math.abs( MyTable.vHullDuckMins[ 1 ] ) + MyTable.vHullDuckMaxs[ 1 ]
				// This must be here. flSize is too close and flSize * 2 is too far.
				// I love math. And if this keeps going, I'll soon love meth too.
				local flSizeOff = flSize * 1.5
				//	pPath:MoveCursorToClosestPosition( self:GetPos() )
				//	local iCursor = pPath:GetCursorPosition()
				//	local aDirection = pPath:GetPositionOnPath( iCursor )
				//	pPath:MoveCursor( self:BoundingRadius() * MyTable.flPathStabilizer )
				//	aDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() ) - aDirection
				//	aDirection = aDirection:Angle()
				local vTarget = enemy:GetPos() + enemy:OBBCenter()
				//	local vHeight = Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] )
				//	local tPitchAngles = enemy:GetPos().z > self:GetPos().z && ACTOR_PITCH_ANGLES_UP || ACTOR_PITCH_ANGLES_DOWN
				//	local flDistSqr = math.Remap( math.min( vStart:Distance( enemy:GetPos() ), vEnd:Distance( enemy:GetPos() ) ), 0, 4096, 256, 1024 )
				//	flDistSqr = flDistSqr * flDistSqr
				//	local function fDo( vOrigin, tAngles )
				//		local vPos = vOrigin + vHeight
				//		local tWholeFilter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
				//		for i, flGlobalAnglePitch in ipairs( tPitchAngles ) do
				//			for i, flGlobalAngleYaw in ipairs( tAngles ) do
				//				local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
				//				local vAim = aAim:Forward()
				//				local tr = util_TraceLine {
				//					start = vPos,
				//					endpos = vPos + vAim * 999999,
				//					mask = MASK_SHOT_HULL,
				//					filter = self
				//				}
				//				local _, vPoint = util.DistanceToLine( vPos, tr.HitPos, vTarget )
				//				if util_TraceLine( {
				//					start = vPoint,
				//					endpos = vTarget,
				//					mask = MASK_SHOT_HULL,
				//					filter = tWholeFilter
				//				} ).Hit || vPoint:DistToSqr( vTarget ) > flDistSqr then continue end
				//				return true
				//			end
				//		end
				//	end
				local vLeft = vStart - dDirection * flSizeOff + dDirection:Angle():Right() * ( bRight && -flSize || flSize )
				local vLeftCheckDucked = vLeft + Vector( 0, 0, MyTable.vHullDuckMaxs[ 1 ] )
				local vRight = vEnd + dDirection * flSizeOff + dDirection:Angle():Right() * ( bRight && -flSize || flSize )
				local vRightCheckDucked = vRight + Vector( 0, 0, MyTable.vHullDuckMaxs[ 1 ] )
				//	if !( fDo( vLeftCheckDucked, ACTOR_PITCH_ANGLES_RIGHT ) || fDo( vRightCheckDucked, ACTOR_PITCH_ANGLES_RIGHT ) ) then continue end
				if !( !util_TraceLine( {
					start = vStart + Vector( 0, 0, MyTable.vHullDuckMaxs[ 1 ] ) + dDirection:Angle():Right() * ( bRight && -flSize || flSize ),
					endpos = vLeftCheckDucked,
					filter = tFilter,
					mask = MASK_SHOT_HULL
				} ).Hit && util_TraceLine( {
					start = vLeftCheckDucked,
					endpos = vTarget,
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).Fraction >= .66 || !util_TraceLine( {
					start = vEnd + Vector( 0, 0, MyTable.vHullDuckMaxs[ 1 ] ) + dDirection:Angle():Right() * ( bRight && -flSize || flSize ),
					endpos = vRightCheckDucked,
					filter = tFilter,
					mask = MASK_SHOT_HULL
				} ).Hit && util_TraceLine( {
					start = vRightCheckDucked,
					endpos = vTarget,
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).Fraction >= .66 ) then continue end
				flBestCandidate = flCost
				flBestCandidateLarge = flCost * 4
				local flStep, flStart, flEnd
				if vStart:DistToSqr( self:GetPos() ) <= vEnd:DistToSqr( self:GetPos() ) then
					flStart, flEnd, flStep = 0, vDirection:Length(), vMaxs[ 1 ]
				else
					flStart, flEnd, flStep = vDirection:Length(), 0, -vMaxs[ 1 ]
				end
				vDirection:Normalize()
				local vOff = tCover[ 3 ] && vDirection:Angle():Right() || -vDirection:Angle():Right()
				vOff = vOff * vMaxs[ 1 ] * math.max( 1.25, COVER_BOUND_SIZE * .5 )
				for iCurrent = flStart, flEnd, flStep do
					local vCover = vStart + vDirection * iCurrent + vOff
					pPath:MoveCursorToClosestPosition( vCover )
					local iCursor = pPath:GetCursorPosition()
					local dDirection = pPath:GetPositionOnPath( iCursor )
					pPath:MoveCursor( self:BoundingRadius() * MyTable.flPathStabilizer )
					dDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() ) - dDirection
					dDirection[ 3 ] = 0
					dDirection:Normalize()
					if dDirection:IsZero() then
						dDirection = vEnemy - vCover
						dDirection[ 3 ] = 0
						dDirection:Normalize()
					end
					if util_TraceHull( {
						start = vCover,
						endpos = vCover,
						mins = vMins,
						maxs = vMaxs,
						filter = self
					} ).Hit then continue end
					local v = vCover + Vector( 0, 0, vMaxs[ 3 ] )
					if !util_TraceLine( {
						start = v,
						endpos = v + dDirection * vMaxs[ 1 ] * COVER_BOUND_SIZE,
						filter = self
					} ).Hit then continue end
					local d = vEnemy - vCover
					d[ 3 ] = 0
					d:Normalize()
					if !util_TraceLine( {
						start = v,
						endpos = v + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
						filter = self
					} ).Hit then continue end
					if tAllies then
						local b
						for pAlly in pairs( tAllies ) do
							if self == pAlly then continue end
							if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vCover ) <= f || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vCover ) <= f then b = true break end
						end
						if b then continue end
					end
					local s = self:SetSchedule "TakeCoverMove"
					if math.abs( MyTable.flCombatState ) < .2 then
						s.bTakeCoverRetreat = true
					else
						s.bRetreat = true
					end
					MyTable.vCover = vCover
					MyTable.tCover = tCover
					return
				end
			end
			if table_IsEmpty( tQueue ) then
				MyTable.SetSchedule( self, "FreeMovement", MyTable )
				return
			end
		end
		return
	elseif sched.bRetreat then
		if LevelOfDetail( sched, "flNextSearch" ) then
			local tCover = MyTable.tCover
			local tQueue, tVisited, flBestCandidate = sched.tRetreatSearchQueue, sched.tRetreatSearchVisited || { [ tCover ] = true }, sched.flRetreatSearchBestCandidate || 0
			local pPath = sched.pEnemyPath
			if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
			local vEnemy = enemy:GetPos()
			local vTarget = vEnemy + enemy:OBBCenter()
			local pIterator = sched.pIterator
			local v = sched.vCoverBounds || self:GatherCoverBounds()
			sched.vCoverBounds = v
			local tAllies = MyTable.GetAlliesByClass( self, MyTable )
			local f = sched.flBoundingRadiusTwo || ( ( self:BoundingRadius() * .25 ) ^ 2 )
			sched.flBoundingRadiusTwo = f
			local vMaxs = MyTable.vHullDuckMaxs || MyTable.vHullMaxs
			local tCovers = {}
			local tOldCover = MyTable.tCover
			local d = MyTable.vHullMaxs.x * 4
			local flSuppressionTraceFraction = MyTable.flSuppressionTraceFraction
			local RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			local _, vPos = util_DistanceToLine( MyTable.tCover[ 1 ], MyTable.tCover[ 2 ], vEnemy )
			pPath:MoveCursorToClosestPosition( vPos )
			if !tQueue then
				local vCover = MyTable.vCover
				local flCostStart, flCostEnd, flCursorStart, flCursorEnd
				local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
				pPath:MoveCursorToClosestPosition( vStart )
				flCursorStart = pPath:GetCursorPosition()
				flCostStart = pPath:GetPositionOnPath( flCursorStart ):Distance( vStart ) + ( pPath:GetLength() - flCursorStart )
				pPath:MoveCursorToClosestPosition( vEnd )
				flCursorEnd = pPath:GetCursorPosition()
				flCostEnd = pPath:GetPositionOnPath( flCursorEnd ):Distance( vStart ) + ( pPath:GetLength() - flCursorEnd )
				if flCostStart < flCostEnd then
					flBestCandidate = flCostEnd
					pPath:MoveCursorTo( flCursorEnd )
				else
					flBestCandidate = flCostStart
					pPath:MoveCursorTo( flCursorStart )
				end
				local f = flBestCandidate + 1
				tQueue = { { tCover, f, f, nil } }
			end
			sched.tRetreatSearchQueue = tQueue
			sched.tRetreatSearchVisited = tVisited
			sched.flRetreatSearchBestCandidate = flBestCandidate
			local iHandled, bAtTheResult, tMyCover = 1, true, tCover
			while !table_IsEmpty( tQueue ) do
				bAtTheResult = nil
				if iHandled > 12 then break end
				iHandled = iHandled + 1
				table.SortByMember( tQueue, 2 )
				local tSource = table.remove( tQueue )
				local tCover, flTrueCost, flCost = unpack( tSource )
				if flCost <= flBestCandidate then iHandle = iHandled - 1 continue end
				local vCurrentStart, vCurrentEnd = tCover[ 1 ], tCover[ 2 ]
				for iAreaID, tIndices in pairs( tCover[ 4 ] || {} ) do
					for iIndex in pairs( tIndices ) do
						local tNewCover = __COVERS_STATIC__[ iAreaID ][ iIndex ]
						if tVisited[ tNewCover ] then continue end // Also checks for nil internally... I love Lua (actually, on second thought, I genuinely do)
						tVisited[ tNewCover ] = true
						local flCostStart, flCostEnd, flCursorStart, flCursorEnd
						local vStart, vEnd = tNewCover[ 1 ], tNewCover[ 2 ]
						pPath:MoveCursorToClosestPosition( vStart )
						flCursorStart = pPath:GetCursorPosition()
						flCostStart = pPath:GetPositionOnPath( flCursorStart ):Distance( vStart ) + ( pPath:GetLength() - flCursorStart )
						pPath:MoveCursorToClosestPosition( vEnd )
						flCursorEnd = pPath:GetCursorPosition()
						flCostEnd = pPath:GetPositionOnPath( flCursorEnd ):Distance( vStart ) + ( pPath:GetLength() - flCursorEnd )
						local flNewCost
						if flCostStart < flCostEnd then
							flNewCost = flCostEnd
							pPath:MoveCursorTo( flCursorEnd )
						else
							flNewCost = flCostStart
							pPath:MoveCursorTo( flCursorStart )
						end
						table.insert( tQueue, { tNewCover, flTrueCost +
						// Rough approximation
						math.min(
							vCurrentStart:Distance( vStart ),
							vCurrentStart:Distance( vEnd ),
							vCurrentEnd:Distance( vStart ),
							vCurrentEnd:Distance( vEnd )
						), flNewCost, tSource } )
					end
				end
				if tCover == tMyCover || flCost <= flBestCandidate then continue end
				flBestCandidate = flCost
				local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
				local vDirection = vEnd - vStart
				local flStep, flStart, flEnd
				if vStart:DistToSqr( self:GetPos() ) <= vEnd:DistToSqr( self:GetPos() ) then
					flStart, flEnd, flStep = 0, vDirection:Length(), vMaxs[ 1 ]
				else
					flStart, flEnd, flStep = vDirection:Length(), 0, -vMaxs[ 1 ]
				end
				vDirection:Normalize()
				local vOff = tCover[ 3 ] && vDirection:Angle():Right() || -vDirection:Angle():Right()
				vOff = vOff * vMaxs[ 1 ] * math.max( 1.25, COVER_BOUND_SIZE * .5 )
				for iCurrent = flStart, flEnd, flStep do
					local vCover = vStart + vDirection * iCurrent + vOff
					pPath:MoveCursorToClosestPosition( vCover )
					local iCursor = pPath:GetCursorPosition()
					local dDirection = pPath:GetPositionOnPath( iCursor )
					pPath:MoveCursor( self:BoundingRadius() * MyTable.flPathStabilizer )
					dDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() ) - dDirection
					dDirection[ 3 ] = 0
					dDirection:Normalize()
					if dDirection:IsZero() then
						dDirection = vEnemy - vCover
						dDirection[ 3 ] = 0
						dDirection:Normalize()
					end
					if util_TraceHull( {
						start = vCover,
						endpos = vCover,
						mins = vMins,
						maxs = vMaxs,
						filter = self
					} ).Hit then continue end
					local v = vCover + Vector( 0, 0, vMaxs[ 3 ] )
					if !util_TraceLine( {
						start = v,
						endpos = v + dDirection * vMaxs[ 1 ] * COVER_BOUND_SIZE,
						filter = self
					} ).Hit then continue end
					local d = vEnemy - vCover
					d[ 3 ] = 0
					d:Normalize()
					if !util_TraceLine( {
						start = v,
						endpos = v + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
						filter = self
					} ).Hit then continue end
					if tAllies then
						local b
						for pAlly in pairs( tAllies ) do
							if self == pAlly then continue end
							if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vCover ) <= f || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vCover ) <= f then b = true break end
						end
						if b then continue end
					end
					local s = self:SetSchedule "TakeCoverMove"
					if math.abs( MyTable.flCombatState ) < .2 then
						s.bTakeCoverRetreat = true
					else
						s.bRetreat = true
					end
					MyTable.vCover = vCover
					MyTable.tCover = tCover
					return
				end
			end
			if table_IsEmpty( tQueue ) then sched.bRetreat = nil return end
		end
		return
	end
	if !LevelOfDetail( sched, "flNextCheck" ) then return end
	MyTable.vActualCover = vec
	if !sched.Path then sched.Path = Path "Follow" end
	MyTable.ComputePath( self, sched.Path, MyTable.vCover, MyTable )
	local tAllies = self:GetAlliesByClass()
	if tAllies then
		local f = self:BoundingRadius()
		f = f * f
		for ally in pairs( tAllies ) do
			if self == ally then continue end
			if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= f || ally.vActualTarget && ally.vActualTarget:DistToSqr( vec ) <= f then self.vCover = nil self:SetSchedule "TakeCover" return end
		end
	end
	local f = MyTable.flPathTolerance * 1.5
	if self:GetPos():DistToSqr( vec ) > ( f * f ) then MyTable.vCover = nil MyTable.tCover = nil return end
	local v = vec + Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] )
	// We don't repath often, so have to check this
	if !util_TraceLine( {
		start = v,
		endpos = enemy:GetPos(),
		mask = MASK_SHOT_HULL,
		filter = { self, enemy }
	} ).Hit then
		if MyTable.CanExpose( self, MyTable ) then MyTable.SetSchedule( self, "FreeMovement", MyTable ) else MyTable.SetSchedule( self, "TakeCover", MyTable ) end
		return
	end
	// Don't even try to repath often!
	local pEnemyPath = MyTable.pLastEnemyPath || sched.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.ComputePath( self, pEnemyPath, enemy:GetPos(), MyTable )
		MyTable.pLastEnemyPath = pEnemyPath
		sched.pEnemyPath = pEnemyPath
	end
	pEnemyPath:MoveCursorToClosestPosition( vec )
	local d = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() )
	pEnemyPath:MoveCursor( self:BoundingRadius() * MyTable.flPathStabilizer )
	d = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - d
	d[ 3 ] = 0
	d:Normalize()
	if d:IsZero() then d = enemy:GetPos() - vec d[ 3 ] = 0 d:Normalize() end
	if !util_TraceLine( {
		start = v,
		endpos = v + d * MyTable.vHullMaxs[ 1 ] * COVER_BOUND_SIZE,
		mask = MASK_SHOT_HULL,
		filter = self
	} ).Hit then
		MyTable.vCover = nil
		MyTable.tCover = nil
		if MyTable.CanExpose( self, MyTable ) then MyTable.SetSchedule( self, "FreeMovement", MyTable ) else MyTable.SetSchedule( self, "TakeCover", MyTable ) end
		return
	end
	v = vec + Vector( 0, 0, MyTable.vHullMaxs[ 3 ] )
	sched.bDuck = nil
	sched.iStand = util_TraceLine( {
		start = v,
		endpos = v + d * MyTable.vHullMaxs[ 1 ] * COVER_BOUND_SIZE,
		filter = self
	} ).Hit && 1 || 0
	local b = CurTime() > ( sched.flSweep || 0 )
	if b && math.Rand( 0, 500 * FrameTime() ) <= 1 then sched.flSweep = CurTime() + math.Rand( .75, 2 ) end
	MyTable.vaAimTargetBody = ( b && d || -d ):Angle()
	MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	if !MyTable.CanExpose( self ) then
		sched.bRetaliateAgainstSuppression = true
		sched.bAdvance = nil
		sched.bRetreat = nil
		local f = MyTable.GAME_flSuppression
		sched.flSuppressedShort = CurTime() + math.Clamp( f / self:Health(), 0, 6 )
		sched.flSuppressed = CurTime() + math.Clamp( f / self:Health() * .5, 0, 1 )
		if !sched.bPinned && f > self:Health() * 6 then
			MyTable.DLG_Pinned( self, MyTable )
			sched.bPinned = true
		end
		return
	end
	if CurTime() <= ( sched.flSuppressedShort || 0 ) then return end
	sched.bPinned = nil
	if CurTime() <= ( sched.flSuppressed || 0 ) then return end
	// TODO: Check if we can't hit 'em from cover, and if so, move, instead of staying there because of this
	if CurTime() <= ( sched.flWaitCheck || 0 ) then return end
	if !sched.bDoneWaitCheck then
		for pAlly in pairs( MyTable.GetAlliesByClass( self, MyTable ) || {} ) do
			if !IsValid( pAlly ) then continue end
			if pAlly.bAttacking then continue end
			sched.flWaitCheck = CurTime() + 2
			sched.bDoneWaitCheck = true
			return
		end
	end
	local flAlarm, vPos, pAlarm = math.huge, self:GetShootPos(), NULL // NULL because ent.pAlarm ( if nil ) == pAlarm ( which is nil )
	local t = __ALARMS__[ self:Classify() ]
	if t then
		for ent in pairs( t ) do
			if !IsValid( ent ) || ent.bIsOn then continue end
			local d = ent:NearestPoint( vPos ):DistToSqr( vPos )
			// Don't go out of audible range, even if an ally alarm. Why?
			// Because it's not funny to run kilometers away from the battlefield to it like an idiot
			if d >= flAlarm || Either( ent.flAudibleDistSqr == 0, self:Visible( ent ), d >= ent.flAudibleDistSqr ) then continue end
			local f = ent.flCoolDown
			if CurTime() <= f then continue end
			local b
			if tAllies then for ent in pairs( tAllies ) do if ent != self && IsValid( ent ) && ent.pAlarm == pAlarm then b = true break end end end
			if b then continue end
			pAlarm, flAlarm = ent, d
		end
	end
	if IsValid( pAlarm ) then
		local s = MyTable.SetSchedule( self, "PullAlarm", MyTable )
		s.pAlarm = pAlarm
		MyTable.pAlarm = pAlarm
		return
	end
	t = __ALARMS__[ CLASS_NONE ]
	if t then
		for ent in pairs( t ) do
			if !IsValid( ent ) || ent.bIsOn then continue end
			local d = ent:NearestPoint( vPos ):DistToSqr( vPos )
			if d >= flAlarm || Either( ent.flAudibleDistSqr == 0, self:Visible( ent ), d >= ent.flAudibleDistSqr ) then continue end
			local f = ent.flCoolDown
			if f && CurTime() <= f then continue end
			local b
			if tAllies then for ent in pairs( tAllies ) do if ent != self && IsValid( ent ) && ent.pAlarm == pAlarm then b = true break end end end
			if b then continue end
			pAlarm, flAlarm = ent, d
		end
	end
	if IsValid( pAlarm ) then
		local s = MyTable.SetSchedule( self, "PullAlarm", MyTable )
		s.pAlarm = pAlarm
		MyTable.pAlarm = pAlarm
		return
	end
	local pPath = sched.pEnemyPath
	if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
	MyTable.ComputeFlankPath( self, pPath, enemy, MyTable )
	if !sched.bRetaliateAgainstSuppression then
		local iCount, iShooting = 0, 0
		for pAlly in pairs( MyTable.GetAlliesByClass( self, MyTable ) || {} ) do
			if !IsValid( pAlly ) then continue end
			if pAlly.bAttacking then
				iShooting = iShooting + 1
			else iCount = iCount + 1 end
		end
		if math.Rand( 0, iCount ) <= 1 then
			if MyTable.flCombatState > 0 then sched.bAdvance = true else sched.bRetreat = true end
			return
		end
	end
	local vStart, vEnd, bRight = tCover[ 1 ], tCover[ 2 ], tCover[ 3 ]
	local dDirection = vEnd - vStart
	dDirection:Normalize()
	local flSize = math.abs( MyTable.vHullDuckMins[ 1 ] ) + MyTable.vHullDuckMaxs[ 1 ]
	// This must be here. flSize is too close and flSize * 2 is too far.
	// I love math. And if this keeps going, I'll soon love meth too.
	local flSizeOff = flSize * 1.5
	pPath:MoveCursorToClosestPosition( self:GetPos() )
	local iCursor = pPath:GetCursorPosition()
	local aDirection = pPath:GetPositionOnPath( iCursor )
	pPath:MoveCursor( self:BoundingRadius() * MyTable.flPathStabilizer )
	aDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() ) - aDirection
	aDirection = aDirection:Angle()
	local vTarget = enemy:GetPos() + enemy:OBBCenter()
	local tPitchAngles = enemy:GetPos().z > self:GetPos().z && ACTOR_PITCH_ANGLES_UP || ACTOR_PITCH_ANGLES_DOWN
	local bCheckDistance, flDistSqr = MyTable.flCombatState > 0
	if bCheckDistance then
		// Note: MyTable.flCombatState will never be <=0 here... look two lines above, this is only ran if it's > 0
		flDistSqr = math.max( 512, math.Remap( vec:Distance( enemy:GetPos() ), 0, 4096, 512, 2048 ) ) / MyTable.flCombatState
		flDistSqr = flDistSqr * flDistSqr
		//	flDistSqr = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
		//	flDistSqr = flDistSqr * flDistSqr
	end
	local function fDo( vPos, tAngles )
		local tWholeFilter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
		for i, flGlobalAnglePitch in ipairs( tPitchAngles ) do
			for i, flGlobalAngleYaw in ipairs( tAngles ) do
				local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
				local vAim = aAim:Forward()
				local tr = util_TraceLine {
					start = vPos,
					endpos = vPos + vAim * 999999,
					mask = MASK_SHOT_HULL,
					filter = self
				}
				local _, vPoint = util.DistanceToLine( vPos, tr.HitPos, vTarget )
				if util_TraceLine( {
					start = vPoint,
					endpos = vTarget,
					mask = MASK_SHOT_HULL,
					filter = tWholeFilter
				} ).Hit ||
				bCheckDistance // We're shitting ourselves. Badly.
				&& vPoint:DistToSqr( vTarget ) > flDistSqr then continue end
				return vPoint
			end
		end
	end
	// TODO: Don't repeat myself and make this more adequate... if that's even possible
	if vStart:DistToSqr( self:GetPos() ) < vEnd:DistToSqr( self:GetPos() ) then
		local tAllies = self:GetAlliesByClass()
		local vLeft = vStart - dDirection * flSizeOff + dDirection:Angle():Right() * ( bRight && flSize || -flSize )
		local vLeftCheckDucked = vLeft + Vector( 0, 0, MyTable.vHullDuckMaxs[ 1 ] )
		local bLeft = !util_TraceLine( {
			start = vStart,
			endpos = vLeftCheckDucked,
			filter = self,
			mask = MASK_SHOT_HULL
		} ).Hit
		if bLeft && tAllies then
			local f = self:BoundingRadius()
			f = f * f
			for pAlly in pairs( tAllies ) do
				if self == pAlly then continue end
				if pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vLeft ) <= f then bLeft = nil break end
			end
		end
		if bLeft then
			if !util_TraceLine( {
				start = vLeftCheckDucked,
				endpos = enemy:GetPos() + enemy:OBBCenter(),
				filter = { self, enemy, trueenemy },
				mask = MASK_SHOT_HULL
			} ).Hit then
				local s = MyTable.SetSchedule( self, "RangeAttack", MyTable )
				s.vFrom = vLeft
				s.Enemy = enemy
				return
			end
		end
		local vRight = vEnd + dDirection * flSizeOff + dDirection:Angle():Right() * ( bRight && flSize || -flSize )
		local vRightCheckDucked = vRight + Vector( 0, 0, MyTable.vHullDuckMaxs[ 1 ] )
		local bRight = !util_TraceLine( {
			start = vEnd,
			endpos = vRightCheckDucked,
			filter = self,
			mask = MASK_SHOT_HULL
		} ).Hit
		if tAllies then
			local f = self:BoundingRadius()
			f = f * f
			for pAlly in pairs( tAllies ) do
				if self == pAlly then continue end
				if pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vRight ) <= f then bRight = nil break end
			end
		end
		if bRight then
			if !util_TraceLine( {
				start = vRightCheckDucked,
				endpos = enemy:GetPos() + enemy:OBBCenter(),
				filter = { self, enemy, trueenemy },
				mask = MASK_SHOT_HULL
			} ).Hit then
				local s = MyTable.SetSchedule( self, "RangeAttack", MyTable )
				s.vFrom = vRight
				s.Enemy = enemy
				return
			end
		end
		if bLeft then
			local v = fDo( vLeftCheckDucked, ACTOR_PITCH_ANGLES_LEFT )
			if v then
				local sched = MyTable.SetSchedule( self, "RangeAttack", MyTable )
				sched.vFrom = vRight
				sched.vTo = v
				sched.Enemy = enemy
				sched.bSuppressing = true
				return
			end
		end
		if bRight then
			local v = fDo( vRightCheckDucked, ACTOR_PITCH_ANGLES_RIGHT )
			if v then
				local sched = MyTable.SetSchedule( self, "RangeAttack", MyTable )
				sched.vFrom = vRight
				sched.vTo = v
				sched.Enemy = enemy
				sched.bSuppressing = true
				return
			end
		end
		if MyTable.flCombatState > 0 then sched.bAdvance = true else sched.bRetreat = true end
		return
	else
		local tAllies = self:GetAlliesByClass()
		local vRight = vEnd + dDirection * flSizeOff + dDirection:Angle():Right() * ( bRight && flSize || -flSize )
		local vRightCheckDucked = vRight + Vector( 0, 0, MyTable.vHullDuckMaxs[ 1 ] )
		local bRight = !util_TraceLine( {
			start = vEnd,
			endpos = vRightCheckDucked,
			filter = self,
			mask = MASK_SHOT_HULL
		} ).Hit
		if tAllies then
			local f = self:BoundingRadius()
			f = f * f
			for pAlly in pairs( tAllies ) do
				if self == pAlly then continue end
				if pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vRight ) <= f then bRight = nil break end
			end
		end
		if bRight then
			if !util_TraceLine( {
				start = vRightCheckDucked,
				endpos = enemy:GetPos() + enemy:OBBCenter(),
				filter = { self, enemy, trueenemy },
				mask = MASK_SHOT_HULL
			} ).Hit then
				local s = MyTable.SetSchedule( self, "RangeAttack", MyTable )
				s.vFrom = vRight
				s.Enemy = enemy
				return
			end
		end
		local vLeft = vStart - dDirection * flSizeOff + dDirection:Angle():Right() * ( bRight && flSize || -flSize )
		local vLeftCheckDucked = vLeft + Vector( 0, 0, MyTable.vHullDuckMaxs[ 1 ] )
		local bLeft = !util_TraceLine( {
			start = vStart,
			endpos = vLeftCheckDucked,
			filter = self,
			mask = MASK_SHOT_HULL
		} ).Hit
		if tAllies then
			local f = self:BoundingRadius()
			f = f * f
			for pAlly in pairs( tAllies ) do
				if self == pAlly then continue end
				if pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vLeft ) <= f then bLeft = nil break end
			end
		end
		if bLeft then
			if !util_TraceLine( {
				start = vLeftCheckDucked,
				endpos = enemy:GetPos() + enemy:OBBCenter(),
				filter = { self, enemy, trueenemy },
				mask = MASK_SHOT_HULL
			} ).Hit then
				local s = MyTable.SetSchedule( self, "RangeAttack", MyTable )
				s.vFrom = vLeft
				s.Enemy = enemy
				return
			end
		end
		if bRight then
			local v = fDo( vRightCheckDucked, ACTOR_PITCH_ANGLES_RIGHT )
			if v then
				local sched = MyTable.SetSchedule( self, "RangeAttack", MyTable )
				sched.vFrom = vRight
				sched.vTo = v
				sched.Enemy = enemy
				sched.bSuppressing = true
				return
			end
		end
		if bLeft then
			local v = fDo( vLeftCheckDucked, ACTOR_PITCH_ANGLES_LEFT )
			if v then
				local sched = MyTable.SetSchedule( self, "RangeAttack", MyTable )
				sched.vFrom = vRight
				sched.vTo = v
				sched.Enemy = enemy
				sched.bSuppressing = true
				return
			end
		end
		if MyTable.flCombatState > 0 then sched.bAdvance = true else sched.bRetreat = true end
		return
	end
end )

include "CombatStuff.lua"
