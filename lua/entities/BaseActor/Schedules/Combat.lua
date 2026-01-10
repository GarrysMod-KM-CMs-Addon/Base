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

include "HoldFireCheckEnemy.lua"

ENT.flMaintainFireTime = 0
ENT.flMaintainFireTimeMin = 2
ENT.flMaintainFireTimeMax = 6
ENT.flPathStabilizer = 8

Actor_RegisterSchedule( "Combat", function( self, sched, MyTable )
	local tEnemies = sched.tEnemies || MyTable.tEnemies
	if table_IsEmpty( tEnemies ) then return {} end
	local enemy = sched.Enemy
	if IsValid( enemy ) then enemy = enemy
	else enemy = MyTable.Enemy if !IsValid( enemy ) then return {} end end
	local enemy, trueenemy = MyTable.SetupEnemy( self, enemy, MyTable )
	if !MyTable.bHoldFire && CurTime() > ( MyTable.flLastEnemy + MyTable.flHoldFireTime ) then MyTable.DLG_HoldFire( self, MyTable ) end
	// Big thing combat
	if self:Health() > enemy:Health() * 100 then
		if MyTable.bPlantAttack then // Lemme guess, we're a Combine Hunter?
			if sched.bMoving then
				local pPath = sched.pEnemyPath
				if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
				MyTable.ComputeFlankPath( self, pPath, enemy, MyTable )
				if util_TraceLine( {
					start = self:GetShootPos(),
					endpos = enemy:GetPos() + enemy:OBBCenter(),
					mask = MASK_SHOT_HULL,
					filter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
				} ).Hit then
					local aDirection
					local tGoal = pPath:NextSegment()
					if tGoal then aDirection = ( tGoal.pos - self:GetShootPos() ):Angle()
					else aDirection = ( enemy:GetPos() - self:GetShootPos() ):Angle() end
					local vTarget = enemy:GetPos() + enemy:OBBCenter()
					local vHeight = Vector( 0, 0, self.vHullDuckMaxs[ 3 ] )
					local tPitchAngles = { 0 }
					if enemy:GetPos().z > self:GetPos().z then
						for a = 5.625, 90, 5.625 do
							table.insert( tPitchAngles, a )
							table.insert( tPitchAngles, -a )
						end
					else
						for a = 5.625, 90, 5.625 do
							table.insert( tPitchAngles, -a )
							table.insert( tPitchAngles, a )
						end
					end
					local bCheckDistance, flDistSqr = MyTable.flCombatState > 0
					if bCheckDistance then
						flDistSqr = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
						flDistSqr = flDistSqr * flDistSqr
					end
					local function fDo( vOrigin, tAngles )
						local vPos = vOrigin + vHeight
						local tWholeFilter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
						for i, flGlobalAnglePitch in ipairs( tPitchAngles ) do
							for i, flGlobalAngleYaw in ipairs( tAngles ) do
								// local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
								local aAim = aDirection + Angle( 0, flGlobalAngleYaw )
								aAim[ 1 ] = flGlobalAnglePitch
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
								} ).Hit || bCheckDistance && vPoint:DistToSqr( vTarget ) > flDistSqr then continue end
								return vPoint
							end
						end
					end
					local tAngles = { 0 }
					for a = 5.625, 22.5, 5.625 do
						table.insert( tAngles, -a )
						table.insert( tAngles, a )
					end
					vTarget = fDo( self:GetShootPos(), tAngles )
					if vTarget then
						MyTable.vaAimTargetBody = vTarget
						MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
						if MyTable.bPlanted then
							local b
							local tAllies = MyTable.GetAlliesByClass( self, MyTable )
							if tAllies then
								for pAlly in pairs( tAllies ) do if self != pAlly && IsValid( pAlly ) && pAlly.bWantsCover then b = true break end end
							else b = true end
							if !MyTable.flPlantEndTime then MyTable.flPlantEndTime = CurTime() + math_Rand( MyTable.flPlantTimeMinimum || PLANT_TIME_MINIMUM, MyTable.flPlantTimeMaximum || PLANT_TIME_MAXIMUM ) end
							if CurTime() <= MyTable.flPlantEndTime || b then MyTable.RangeAttackPlanted( self ) else MyTable.UnPlant( self ) sched.bMoving = true end
							return
						end
						local tAllies = self:GetAlliesByClass()
						if tAllies then
							local bMaintainFire, bAtLeastOneAlly = true
							for pAlly in pairs( tAllies ) do
								if IsValid( pAlly ) && pAlly != self then
									bAtLeastOneAlly = true
									if pAlly.bSuppressing then bMaintainFire = nil break end
								end
							end
							if bAtLeastOneAlly && bMaintainFire then
								if CurTime() > self.flMaintainFireTime then
									MyTable.DLG_MaintainFire( self, MyTable )
									MyTable.flMaintainFireTime = CurTime() + math_Rand( MyTable.flMaintainFireTimeMin, MyTable.flMaintainFireTimeMax )
								end
								return
							else MyTable.flMaintainFireTime = CurTime() + math_Rand( MyTable.flMaintainFireTimeMin, MyTable.flMaintainFireTimeMax ) end
						end
						self:MoveAlongPath( pPath, MyTable.flRunSpeed, 1 )
					else
						MyTable.flMaintainFireTime = CurTime() + math_Rand( MyTable.flMaintainFireTimeMin, MyTable.flMaintainFireTimeMax )
						self:MoveAlongPath( pPath, MyTable.flTopSpeed, 1 )
						local pGoal = sched.pEnemyPath:GetCurrentGoal()
						if pGoal then
							MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
							MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
						end
					end
				else
					MyTable.vaAimTargetBody = enemy:GetPos() + enemy:OBBCenter()
					// TODO!!!
					//	MyTable.vaAimTargetBody = util_TraceLine( {
					//		start = self:GetShootPos(),
					//		endpos = enemy:GetPos() + enemy:OBBCenter(),
					//		mask = MASK_SHOT_HULL,
					//		filter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
					//	} ).Hit && ( enemy:GetPos() + enemy:OBBCenter() ) || x
					MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
					local tAllies = MyTable.GetAlliesByClass( self, MyTable )
					if MyTable.bPlanted then
						local b
						if tAllies then
							for pAlly in pairs( tAllies ) do if self != pAlly && IsValid( pAlly ) && pAlly.bWantsCover then b = true break end end
						else b = true end
						if !MyTable.flPlantEndTime then MyTable.flPlantEndTime = CurTime() + math_Rand( MyTable.flPlantTimeMinimum || PLANT_TIME_MINIMUM, MyTable.flPlantTimeMaximum || PLANT_TIME_MAXIMUM ) end
						if CurTime() <= MyTable.flPlantEndTime || b then self:RangeAttackPlanted() else self:UnPlant() sched.bMoving = true end
						return
					elseif math_Rand( 0, 10000 * FrameTime() ) <= 1 then self.flPlantEndTime = nil self:Plant() return end
					if tAllies then
						local bMaintainFire, bAtLeastOneAlly = true
						for pAlly in pairs( tAllies ) do
							if IsValid( pAlly ) && pAlly != self then
								bAtLeastOneAlly = true
								if pAlly.bSuppressing then bMaintainFire = nil break end
							end
						end
						if bAtLeastOneAlly && bMaintainFire then
							if CurTime() > MyTable.flMaintainFireTime then
								MyTable.DLG_MaintainFire( self, MyTable )
								MyTable.flMaintainFireTime = CurTime() + math_Rand( MyTable.flMaintainFireTimeMin, MyTable.flMaintainFireTimeMax )
							end
							return
						else MyTable.flMaintainFireTime = CurTime() + math_Rand( MyTable.flMaintainFireTimeMin, MyTable.flMaintainFireTimeMax ) end
					else MyTable.flMaintainFireTime = CurTime() + math_Rand( MyTable.flMaintainFireTimeMin, MyTable.flMaintainFireTimeMax ) end
					self:MoveAlongPath( pPath, MyTable.flRunSpeed, 1 )
				end
			else
				MyTable.flMaintainFireTime = CurTime() + math_Rand( MyTable.flMaintainFireTimeMin, MyTable.flMaintainFireTimeMax )
				local pPath = sched.pEnemyPath
				if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
				MyTable.ComputeFlankPath( self, pPath, enemy, MyTable )
				if util_TraceLine( {
					start = self:GetShootPos(),
					endpos = enemy:GetPos() + enemy:OBBCenter(),
					mask = MASK_SHOT_HULL,
					filter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
				} ).Hit then
					local aDirection
					local tGoal = pPath:NextSegment()
					if tGoal then aDirection = ( tGoal.pos - self:GetShootPos() ):Angle()
					else aDirection = ( enemy:GetPos() - self:GetShootPos() ):Angle() end
					local vTarget = enemy:GetPos() + enemy:OBBCenter()
					local vHeight = Vector( 0, 0, self.vHullDuckMaxs[ 3 ] )
					local tPitchAngles = { 0 }
					if enemy:GetPos().z > self:GetPos().z then
						for a = 5.625, 90, 5.625 do
							table.insert( tPitchAngles, a )
							table.insert( tPitchAngles, -a )
						end
					else
						for a = 5.625, 90, 5.625 do
							table.insert( tPitchAngles, -a )
							table.insert( tPitchAngles, a )
						end
					end
					local bCheckDistance, flDistSqr = self.flCombatState > 0
					if bCheckDistance then
						flDistSqr = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
						flDistSqr = flDistSqr * flDistSqr
					end
					local function fDo( vOrigin, tAngles )
						local vPos = vOrigin + vHeight
						local tWholeFilter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
						for i, flGlobalAnglePitch in ipairs( tPitchAngles ) do
							for i, flGlobalAngleYaw in ipairs( tAngles ) do
								// local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
								local aAim = aDirection + Angle( 0, flGlobalAngleYaw )
								aAim[ 1 ] = flGlobalAnglePitch
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
								} ).Hit || bCheckDistance && vPoint:DistToSqr( vTarget ) > flDistSqr then
									continue
								end
								return vPoint
							end
						end
					end
					local tAngles = { 0 }
					for a = 5.625, 22.5, 5.625 do
						table.insert( tAngles, -a )
						table.insert( tAngles, a )
					end
					vTarget = fDo( self:GetShootPos(), tAngles )
					if vTarget then
						if MyTable.bPlanted then
							if self:RangeAttackPlanted() then self:UnPlant() end
						else
							self:Plant()
						end
					else sched.bMoving = true end
				else
					// TODO!!!
					//	self.vaAimTargetBody = SOME_FUNCTION()
					MyTable.vaAimTargetBody = enemy:GetPos() + enemy:OBBCenter()
					MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
					if MyTable.bPlanted then
						local b
						local tAllies = self:GetAlliesByClass()
						if tAllies then
							for pAlly in pairs( tAllies ) do if self != pAlly && IsValid( pAlly ) && pAlly.bWantsCover then b = true break end end
						else b = true end
						if !MyTable.flPlantEndTime then self.flPlantEndTime = CurTime() + math_Rand( MyTable.flPlantTimeMinimum || PLANT_TIME_MINIMUM, MyTable.flPlantTimeMaximum || PLANT_TIME_MAXIMUM ) end
						if CurTime() <= MyTable.flPlantEndTime || b then self:RangeAttackPlanted() else self:UnPlant() sched.bMoving = true end
					else
						MyTable.flPlantEndTime = nil
						self:Plant()
					end
				end
			end
		end
		return
	elseif HasMeleeAttack( self ) && !HasRangeAttack( self ) then
		if !MyTable.bEnemiesHaveRangeAttack || MyTable.bMeleeChargeAgainstRange then
			// TODO: Melee vs melee dance behavior
			local pPath = sched.pEnemyPath
			if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
			MyTable.ComputeFlankPath( self, pPath, enemy, MyTable )
			self:MoveAlongPath( pPath, MyTable.flTopSpeed, 1 )
			if self:Visible( enemy ) then
				if math_random( 10000 * ( MyTable.flMeleeChargeTauntMultiplier || 1 ) * FrameTime() ) == 1 then self:DLG_MeleeTaunt() return end
				local vTarget, vShoot = enemy:GetPos() + enemy:OBBCenter(), self:GetShootPos()
				MyTable.vaAimTargetBody = vTarget
				MyTable.vaAimTargetPose = vTarget
				local d = MyTable.GAME_flReach || 64
				local wep = MyTable.Weapon
				if IsValid( wep ) then d = d + wep.Melee_flRangeAdd || 0 end
				local vMins, vMaxs = self:GatherShootingBounds()
				if vTarget:Distance( vShoot ) <= d then
					if MyTable.bHoldFire then self:ReportPositionAsClear( vTarget )
					elseif self:Disposition( util_TraceLine( {
						start = vShoot,
						endpos = vShoot + self:GetAimVector() * d,
						filter = self,
						mask = MASK_SHOT_HULL,
						mins = vMins, maxs = vMaxs
					} ).Entity ) != D_LI then self:WeaponPrimaryAttack() end
				end
			else
				local goal = pPath:GetCurrentGoal()
				local v = self:GetPos()
				if goal then
					MyTable.vaAimTargetBody = ( goal.pos - v ):Angle()
					MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
				end
			end
		else self:SetSchedule "TakeCover" end
		return
	end
	if math_random(2)==1 then
		sched.bAdvance=true
		sched.bRetreat=nil
	end
	local tCover = MyTable.tCover
	if !tCover then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end
	local bWeAreAlreadyDoingShitGodDammit
	if sched.bAdvance then
		MyTable.flSuppressed = CurTime() + 2 // To not load the CPU
		bWeAreAlreadyDoingShitGodDammit = true
		local tQueue, tVisited, flBestCandidate = sched.tAdvanceSearchQueue, sched.tAdvanceSearchVisited || { [ tCover ] = true }, sched.flAdvanceSearchBestCandidate || math.huge
		local pPath = sched.pEnemyPath
		if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
		local vEnemy = enemy:GetPos()
		local vTarget = vEnemy + enemy:OBBCenter()
		local pIterator = sched.pIterator
		local v = sched.vCoverBounds || self:GatherCoverBounds()
		sched.vCoverBounds = v
		local tAllies = MyTable.GetAlliesByClass( self, MyTable )
		local f = sched.flBoundingRadiusTwo || ( self:BoundingRadius() ^ 2 )
		sched.flBoundingRadiusTwo = f
		local vMaxs = MyTable.vHullDuckMaxs || MyTable.vHullMaxs
		local tCovers = {}
		local tOldCover = MyTable.tCover
		local d = MyTable.vHullMaxs.x * 4
		local flSuppressionTraceFraction = MyTable.flSuppressionTraceFraction
		local RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
		local iLastEnemyPathStackUpCursor = bAdvance && MyTable.iLastEnemyPathStackUpCursor || 0
		local _, vPos = util_DistanceToLine( MyTable.tCover[ 1 ], MyTable.tCover[ 2 ], vEnemy )
		pPath:MoveCursorToClosestPosition( vPos )
		if sched.bAtTheResult then
			local tPath = sched.tAdvanceSearchBest
			if tPath then
				// TODO: Slow as shit!!! Find a better way to do this!!!
				local tOrderedPath = sched.tOrderedAdvancePath
				if !tOrderedPath then
					tOrderedPath = {}
					while tPath do
						table.insert( tOrderedPath, 1, tPath[ 1 ] )
						tPath = tPath[ 3 ]
					end
					table.remove( tOrderedPath, 1 ) // Current cover
					sched.tOrderedAdvancePath = tOrderedPath
				end
				// We don't need to calculate all of this
				// if we're already at the end of the path
				if !table_IsEmpty( tOrderedPath ) then
					local flInitialCursor = pPath:GetCursorPosition()
					local iAdvanceOrderedPathIndex = sched.iAdvanceOrderedPathIndex || 0
					iAdvanceOrderedPathIndex = iAdvanceOrderedPathIndex + 1
					sched.iAdvanceOrderedPathIndex = iAdvanceOrderedPathIndex
					local tCover = tOrderedPath[ iAdvanceOrderedPathIndex ]
					if !tCover then
						sched.bAdvance = nil
						return
					end
					// I'ma be honest, I didn't comment out this line. I wrote it already commented. I'm not so sure
					// if this is truly a good choice, it probably isn't. Since we can path for seconds,
					// this data can already be bad, which doesn't affect pathing that much, but affects this.
					// if tCover[ 4 ] then continue end
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
							s.bTakeCoverAdvance = true
						else
							s.bAdvance = true
						end
						MyTable.vCover = vCover
						MyTable.tCover = tCover
						return
					end
				end
			else sched.bAdvance = nil end
		else
			if !tQueue then
				local vCover = MyTable.vCover
				pPath:MoveCursorToClosestPosition( vCover )
				local flCursor = pPath:GetCursorPosition()
				flBestCandidate = pPath:GetPositionOnPath( flCursor ):Distance( vCover ) + ( pPath:GetLength() - flCursor )
				tQueue = { { tCover, flBestCandidate, nil } }
			end
			sched.tAdvanceSearchQueue = tQueue
			sched.tAdvanceSearchVisited = tVisited
			sched.flAdvanceSearchBestCandidate = flBestCandidate
			local iHandled, bAtTheResult, tMyCover = 1, true, tCover
			while !table_IsEmpty( tQueue ) do
				bAtTheResult = nil
				if iHandled > 12 then break end
				iHandled = iHandled + 1
				table.SortByMember( tQueue, 2 )
				local tSource = table.remove( tQueue )
				local tCover, flCost = unpack( tSource )
				// Moved this here as it feels better - in reality I just
				// felt like moving this here, I think it's better...
				// I have yet to playtest it though. Will I actually do so?
				// Meh, PROBABLY NOT.
				// EDIT: Just kidding, I'm in the mood now, I will.
				// EDIT THREE: It did something. I'm sure of it. I think.
				// Jokes aside, I am leaving this in, because it's nice IMO.
				------------------
				// Lol, how did I make this stupid mistake?
				// if flCost < flBestCandidate then continue end
				// Just now realized I also didn't add the subtraction
				// Even later edit: this system literally wasn't working lmao how did I not notice?
				// if flCost > flBestCandidate then iHandle = iHandled - 1 continue end
				if tCover != tMyCover && flCost > flBestCandidate then iHandle = iHandled - 1 continue end
				// EDIT TWO: Moving this down here too... for the same reason
				// of me simply being stupid as the line above shows
				------------------
				// Later edit: what if we don't set this at all? Allows for more
				// different paths being handled with a still good termination condition
				// flBestCandidate = flCost
				for iAreaID, tIndices in pairs( tCover[ 4 ] || {} ) do
					for iIndex in pairs( tIndices ) do
						local tNewCover = __COVERS_STATIC__[ iAreaID ][ iIndex ]
						if tVisited[ tNewCover ] then continue end // Also checks for nil internally... I love Lua (actually, on second thought, I genuinely do)
						tVisited[ tNewCover ] = true
						local vStart, vEnd = tNewCover[ 1 ], tNewCover[ 2 ]
						local vClosest // Stupid dum dum hacky hack hack
						if vStart:DistToSqr( self:GetPos() ) > vEnd:DistToSqr( self:GetPos() ) then
							vClosest = vEnd
						else vClosest = vStart end
						pPath:MoveCursorToClosestPosition( vClosest )
						local flCursor = pPath:GetCursorPosition()
						local flNewCost = pPath:GetPositionOnPath( flCursor ):Distance( vClosest ) + ( pPath:GetLength() - flCursor )
						// EDIT: Moved it upwards
						//	// This whole thing is for one reason: we can still semi
						//	// path through covers we can't take to check more parts
						//	// of the graph, BUT they're not best candidates
						//	if flNewCost > flBestCandidate then continue end // This is why I said semi
						local flInitialCursor = pPath:GetCursorPosition()
						local bYup
						local vDirection = vEnd - vStart
						local flStep, flStart, flEnd
						if vStart:DistToSqr( self:GetPos() ) <= vEnd:DistToSqr( self:GetPos() ) then
							flStart, flEnd, flStep = 0, vDirection:Length(), vMaxs[ 1 ]
						else
							flStart, flEnd, flStep = vDirection:Length(), 0, -vMaxs[ 1 ]
						end
						vDirection:Normalize()
						local vOff = tNewCover[ 3 ] && vDirection:Angle():Right() || -vDirection:Angle():Right()
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
							local tr = util_TraceLine {
								start = v,
								endpos = vTarget,
								mask = MASK_SHOT_HULL,
								filter = { self, enemy, trueenemy }
							}
							if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:DistToSqr( vTarget ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR then
								local d = vEnemy - vCover
								d[ 3 ] = 0
								d:Normalize()
								if !util_TraceLine( {
									start = v,
									endpos = v + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
									filter = self
								} ).Hit then continue end
							end
							if tAllies then
								local b
								for pAlly in pairs( tAllies ) do
									if self == pAlly then continue end
									if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vCover ) <= f || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vCover ) <= f then b = true break end
								end
								if b then continue end
							end
							bYup = true
							break
						end
						// Don't do this here either
						// if bYup then flBestCandidate = flNewCost end
						local t = { tNewCover, flNewCost, tSource }
						sched.tAdvanceSearchBest = t
						table.insert( tQueue, t )
					end
				end
			end
			sched.bAtTheResult = bAtTheResult
		end
	elseif sched.bRetreat then
		MyTable.flSuppressed = CurTime() + 2 // To not load the CPU
		bWeAreAlreadyDoingShitGodDammit = true
		local tQueue, tVisited, flBestCandidate = sched.tRetreatSearchQueue, sched.tRetreatSearchVisited || { [ tCover ] = true }, sched.flRetreatSearchBestCandidate || math.huge
		local pPath = sched.pEnemyPath
		if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
		local vEnemy = enemy:GetPos()
		local vTarget = vEnemy + enemy:OBBCenter()
		local pIterator = sched.pIterator
		local v = sched.vCoverBounds || self:GatherCoverBounds()
		sched.vCoverBounds = v
		local tAllies = MyTable.GetAlliesByClass( self, MyTable )
		local f = sched.flBoundingRadiusTwo || ( self:BoundingRadius() ^ 2 )
		sched.flBoundingRadiusTwo = f
		local vMaxs = MyTable.vHullDuckMaxs || MyTable.vHullMaxs
		local tCovers = {}
		local tOldCover = MyTable.tCover
		local d = MyTable.vHullMaxs.x * 4
		local flSuppressionTraceFraction = MyTable.flSuppressionTraceFraction
		local RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
		local iLastEnemyPathStackUpCursor = bRetreat && MyTable.iLastEnemyPathStackUpCursor || 0
		local _, vPos = util_DistanceToLine( MyTable.tCover[ 1 ], MyTable.tCover[ 2 ], vEnemy )
		pPath:MoveCursorToClosestPosition( vPos )
		if sched.bAtTheResult then
			local tPath = sched.tRetreatSearchBest
			if tPath then
				// TODO: Slow as shit!!! Find a better way to do this!!!
				local tOrderedPath = sched.tOrderedRetreatPath
				if !tOrderedPath then
					tOrderedPath = {}
					while tPath do
						table.insert( tOrderedPath, 1, tPath[ 1 ] )
						tPath = tPath[ 3 ]
					end
					table.remove( tOrderedPath, 1 )
					sched.tOrderedRetreatPath = tOrderedPath
				end
				if !table_IsEmpty( tOrderedPath ) then
					local flInitialCursor = pPath:GetCursorPosition()
					local iRetreatOrderedPathIndex = sched.iRetreatOrderedPathIndex || 0
					iRetreatOrderedPathIndex = iRetreatOrderedPathIndex + 1
					sched.iRetreatOrderedPathIndex = iRetreatOrderedPathIndex
					local tCover = tOrderedPath[ iRetreatOrderedPathIndex ]
					if !tCover then
						sched.bRetreat = nil
						return
					end
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
			else sched.bRetreat = nil end
		else
			if !tQueue then
				local vCover = MyTable.vCover
				flBestCandidate = vCover:Distance( vEnemy )
				tQueue = { { tCover, flBestCandidate, nil } }
			end
			sched.tRetreatSearchQueue = tQueue
			sched.tRetreatSearchVisited = tVisited
			sched.flRetreatSearchBestCandidate = flBestCandidate
			local iHandled, bAtTheResult, tMyCover = 1, true, tCover
			while !table_IsEmpty( tQueue ) do
				bAtTheResult = nil
				if iHandled > 12 then break end
				iHandled = iHandled + 1
				table.SortByMember( tQueue, 2, true )
				local tSource = table.remove( tQueue )
				local tCover, flCost = unpack( tSource )
				if tCover != tMyCover && flCost <= flBestCandidate then iHandle = iHandled - 1 continue end
				for iAreaID, tIndices in pairs( tCover[ 4 ] || {} ) do
					for iIndex in pairs( tIndices ) do
						local tNewCover = __COVERS_STATIC__[ iAreaID ][ iIndex ]
						if tVisited[ tNewCover ] then continue end // Also checks for nil internally... I love Lua (actually, on second thought, I genuinely do)
						tVisited[ tNewCover ] = true
						local vStart, vEnd = tNewCover[ 1 ], tNewCover[ 2 ]
						local vClosest // Stupid dum dum hacky hack hack
						if vStart:DistToSqr( self:GetPos() ) > vEnd:DistToSqr( self:GetPos() ) then
							vClosest = vEnd
						else vClosest = vStart end
						pPath:MoveCursorToClosestPosition( vClosest )
						local flCursor = pPath:GetCursorPosition()
						local flNewCost = vClosest:Distance( vEnemy )
						local flInitialCursor = pPath:GetCursorPosition()
						local bYup
						local vDirection = vEnd - vStart
						local flStep, flStart, flEnd
						if vStart:DistToSqr( self:GetPos() ) <= vEnd:DistToSqr( self:GetPos() ) then
							flStart, flEnd, flStep = 0, vDirection:Length(), vMaxs[ 1 ]
						else
							flStart, flEnd, flStep = vDirection:Length(), 0, -vMaxs[ 1 ]
						end
						vDirection:Normalize()
						local vOff = tNewCover[ 3 ] && vDirection:Angle():Right() || -vDirection:Angle():Right()
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
							local tr = util_TraceLine {
								start = v,
								endpos = vTarget,
								mask = MASK_SHOT_HULL,
								filter = { self, enemy, trueenemy }
							}
							if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:DistToSqr( vTarget ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR then
								local d = vEnemy - vCover
								d[ 3 ] = 0
								d:Normalize()
								if !util_TraceLine( {
									start = v,
									endpos = v + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
									filter = self
								} ).Hit then continue end
							end
							if tAllies then
								local b
								for pAlly in pairs( tAllies ) do
									if self == pAlly then continue end
									if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vCover ) <= f || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vCover ) <= f then b = true break end
								end
								if b then continue end
							end
							bYup = true
							break
						end
						local t = { tNewCover, flNewCost, tSource }
						sched.tRetreatSearchBest = t
						table.insert( tQueue, t )
					end
				end
			end
			sched.bAtTheResult = bAtTheResult
		end
	else
		sched.tOrderedAdvancePath = nil
		sched.tOrderedRetreatPath = nil
		sched.tAdvanceSearchQueue = nil
		sched.tRetreatSearchQueue = nil
		sched.tAdvanceSearchBest = nil
		sched.tRetreatSearchBest = nil
		sched.tAdvanceSearchVisited = nil
		sched.tRetreatSearchVisited = nil
		sched.iAdvanceOrderedPathIndex = nil
		sched.iRetreatOrderedPathIndex = nil
		sched.bAtTheResult = nil
	end
	local vec = MyTable.vCover
	if !vec then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end
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
	local f = MyTable.flPathTolerance
	if self:GetPos():DistToSqr( vec ) > ( f * f ) then MyTable.vCover = nil MyTable.tCover = nil return end
	local v = vec + Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] )
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
	if !util_TraceLine( {
		start = v,
		endpos = v + d * MyTable.vHullMaxs[ 1 ] * COVER_BOUND_SIZE,
		mask = MASK_SHOT_HULL,
		filter = self
	} ).Hit then
		MyTable.vCover = nil
		MyTable.tCover = nil
		MyTable.SetSchedule( self, "TakeCover", MyTable )
		return
	end
	local vEnemy = enemy:GetPos()
	local vTarget = vEnemy + enemy:OBBCenter()
	local tr = util_TraceLine {
		start = v,
		endpos = vTarget,
		mask = MASK_SHOT_HULL,
		filter = { self, enemy, trueenemy }
	}
	if tr.Fraction > MyTable.flSuppressionTraceFraction && tr.HitPos:DistToSqr( vTarget ) <= ( RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE ) then
		local d = vEnemy - vec
		d[ 3 ] = 0
		d:Normalize()
		if !util_TraceLine( {
			start = v,
			endpos = v + d * MyTable.vHullMaxs[ 1 ] * COVER_BOUND_SIZE,
			filter = self
		} ).Hit then return end
	end
	v = vec + Vector( 0, 0, MyTable.vHullMaxs[ 3 ] )
	sched.bDuck = nil
	self:Stand( util_TraceLine( {
		start = v,
		endpos = v + d * MyTable.vHullMaxs[ 1 ] * COVER_BOUND_SIZE,
		filter = self
	} ).Hit && 0 || 1 )
	MyTable.vaAimTargetBody = d:Angle()
	MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	if !MyTable.CanExpose( self ) then MyTable.flSuppressed = CurTime() + math.Clamp( math.min( 0, ( MyTable.GetExposedWeight( self, MyTable ) / self:Health() ) * .2 ), 0, 2 ) return end
	if bWeAreAlreadyDoingShitGodDammit || CurTime() <= ( MyTable.flSuppressed || 0 ) then return end
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
	if MyTable.flCombatState < 0 && math_random( 2 ) == 1 then sched.bRetreat = true return else
		local tAllies = MyTable.GetAlliesByClass( self, MyTable )
		if tAllies then
			local iShootingAllies, iAllies = 0, table.Count( tAllies )
			if iAllies <= 1 then
				if math_random( 2 ) == 1 then sched[ MyTable.flCombatState > 0 && "bAdvance" || "bRetreat" ] = true end
			else
				for ent in pairs( tAllies ) do if ent.bSuppressing then iShootingAllies = iShootingAllies + 1 end end
				if math_Rand( 0, iAllies / iShootingAllies ) <= 1 then sched[ MyTable.flCombatState > 0 && "bAdvance" || "bRetreat" ] = true end
			end
		elseif math_random( 2 ) == 1 then sched[ MyTable.flCombatState > 0 && "bAdvance" || "bRetreat" ] = true end
	end
	local aDirection
	local tGoal = pPath:NextSegment()
	if tGoal then aDirection = ( tGoal.pos - vec ):Angle()
	else aDirection = ( enemy:GetPos() - vec ):Angle() end
	local vTarget = enemy:GetPos() + enemy:OBBCenter()
	local vHeight = Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] )
	local tPitchAngles = { 0 }
	if enemy:GetPos().z > self:GetPos().z then
		for a = 5.625, 90, 5.625 do
			table.insert( tPitchAngles, a )
			table.insert( tPitchAngles, -a )
		end
	else
		for a = 5.625, 90, 5.625 do
			table.insert( tPitchAngles, -a )
			table.insert( tPitchAngles, a )
		end
	end
	local bCheckDistance, flDistSqr = MyTable.flCombatState > 0
	if bCheckDistance then
		flDistSqr = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
		flDistSqr = flDistSqr * flDistSqr
	end
	local function fDo( vOrigin, tAngles )
		local vPos = vOrigin + vHeight
		local tWholeFilter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
		for i, flGlobalAnglePitch in ipairs( tPitchAngles ) do
			for i, flGlobalAngleYaw in ipairs( tAngles ) do
				// local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
				local aAim = aDirection + Angle( 0, flGlobalAngleYaw )
				aAim[ 1 ] = flGlobalAnglePitch
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
	if self.bHoldFire then
		local tAllies = self:GetAlliesByClass()
		if tAllies then
			local b = true
			for ent in pairs( tAllies ) do
				if !IsValid( ent ) || ent == self || !ent.__ACTOR__ || !IsValid( ent.Enemy ) || !ent:IsCurrentSchedule "HoldFireCheckEnemy" then continue end
				local _, pTrueEnemy = ent:SetupEnemy( ent.Enemy )
				if pTrueEnemy == trueenemy then b = nil break end
			end
			if b then
				MyTable.SetSchedule( self, "HoldFireCheckEnemy", MyTable ).pEnemy = enemy
				return
			end
		else MyTable.SetSchedule( self, "HoldFireCheckEnemy", MyTable ).pEnemy = enemy end
	end
	local aGeneral = Angle( aDirection )
	aGeneral[ 1 ] = 0
	local dRight = aGeneral:Right()
	local dLeft = -dRight
	local flDistance = self:OBBMaxs().x * 2
	local tCover = MyTable.tCover
	local vLeft = tCover[ 1 ] + ( tCover[ 1 ] - tCover[ 2 ] ):GetNormalized() * flDistance
	local flAdd = self:OBBMaxs().x
	local trLeft = util_TraceHull {
		start = vLeft + vHeight,
		endpos = vLeft + dLeft * flAdd + vHeight,
		mins = vMins,
		maxs = vMaxs,
		filter = self
	}
	local tAngles = { 0 }
	for a = 5.625, 22.5, 5.625 do
		table.insert( tAngles, -a )
		table.insert( tAngles, a )
	end
	local vLeftTarget
	if !trLeft.Hit then vLeftTarget = fDo( vLeft, tAngles ) end
	local flDistance = self:OBBMaxs().x * 2
	local vRight = tCover[ 1 ] + ( tCover[ 2 ] - tCover[ 1 ] ):GetNormalized() * flDistance
	local trRight = util_TraceHull {
		start = vRight + vHeight,
		endpos = vRight + dRight * flAdd + vHeight,
		mins = vMins,
		maxs = vMaxs,
		filter = self
	}
	tAngles = { 0 }
	for a = 5.625, 22.5, 5.625 do
		table.insert( tAngles, a )
		table.insert( tAngles, -a )
	end
	local vRightTarget
	if !trRight.Hit then vRightTarget = fDo( vRight, tAngles ) end
	tAngles = { 0 }
	for a = 5.625, 22.5, 5.625 do
		table.insert( tAngles, a )
		table.insert( tAngles, -a )
	end
	local function SetupSchedule( vOrigin, vTarget )
		local sched = MyTable.SetSchedule( self, "RangeAttack", MyTable )
		sched.vFrom = vOrigin
		sched.vTo = vTarget
		sched.Enemy = enemy
		sched.bSuppressing = true
		return sched
	end
	if vLeftTarget && vRightTarget then
		if math_random( 2 ) == 1 then
			SetupSchedule( vLeft, vLeftTarget )
		else
			SetupSchedule( vRight, vRightTarget )
		end
		return
	elseif vLeftTarget then
		SetupSchedule( vLeft, vLeftTarget )
		return
	elseif vRightTarget then
		SetupSchedule( vRight, vRightTarget )
		return
	else
		// If we're advancing, GO AND KEEP PRESSURING THEM, DAMMIT!
		// Do note that this is not a charge, but rather merely
		// trying to find us a firing line, not forcing us a firing line -
		// which would include being able to go the WHOLE way to them.
		if MyTable.flCombatState > 0 then
			local flLength = pPath:GetLength()
			local vForce, vForceTarget, bForceFar
			local f = self:BoundingRadius()
			if flLength < f then
			else
				local flEnd, flStep = f * 4, f * .5
				for i = f, math.min( flEnd, flLength ), flStep do
					vForce = pPath:GetPositionOnPath( i )
					vForceTarget = fDo( vForce, tAngles )
					if vForceTarget then SetupSchedule( vForce, vForceTarget ) return end
				end
			end
			sched.bAdvance = true
		else sched.bRetreat = true /*return -- why did I put this here?*/ end
		return
	end
	if !sched.pEnemyPath then sched.pEnemyPath = Path "Follow" end
	MyTable.ComputeFlankPath( self, sched.pEnemyPath, enemy, MyTable )
	if !sched.bFromCombatFormation && MyTable.flCombatState > 0 then
		local p = sched.pEnemyPath
		local i = self:FindPathStackUpLine( p, tEnemies )
		if i then
			MyTable.iLastEnemyPathStackUpCursor = i
			p:MoveCursorTo( i )
			local g = p:GetCurrentGoal()
			if g then
				local b = MyTable.CreateBehaviour( self, "CombatFormation", MyTable )
				local v = p:GetPositionOnPath( i )
				b.Vector = v
				b.Direction = ( p:GetPositionOnPath( i + 1 ) - v ):GetNormalized()
				b:AddParticipant( self )
				b:GatherParticipants()
				b:Initialize()
				return
			end
		end
	end
end )

include "CombatStuff.lua"
