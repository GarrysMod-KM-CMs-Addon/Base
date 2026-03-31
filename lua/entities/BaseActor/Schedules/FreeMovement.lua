// I am currently cooking up a full rework of this. The current code below is shit, dunno if it was
// the last update that broke it, but just wait, the new code's lit, I promise :)

local table_IsEmpty = table.IsEmpty
local IsValid = IsValid
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
Actor_RegisterSchedule( "FreeMovement", function( self, sched, MyTable )
	MyTable.vCover = nil
	MyTable.tCover = nil
	local tEnemies = sched.tEnemies || MyTable.tEnemies
	if table_IsEmpty( tEnemies ) then return true end
	if MyTable.flCombatState < 0 || MyTable.GAME_flSuppression > self:Health() * 2 then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end
	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end
	if LevelOfDetail( sched, "flNextHoldFireCheckTime" ) then if !MyTable.bHoldFire && CurTime() > ( MyTable.flLastEnemy + MyTable.flHoldFireTime ) then MyTable.DLG_HoldFire( self, MyTable ) end end
	local c = MyTable.GetWeaponClipPrimary( self, MyTable )
	if c != -1 && c <= 0 then MyTable.WeaponReload( self, MyTable ) end
	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then pEnemyPath = Path "Follow" sched.pEnemyPath = pEnemyPath end
	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputePath( self, pEnemyPath, pEnemy:GetPos(), MyTable ) end
	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )
	local v = pEnemy:GetPos() + pEnemy:OBBCenter()
	local bCanShoot, bCanShootDirectly
	// Start the schedule by charging headfirst into them
	if !sched.m_bInitialized then
		sched.bSearching = true
		sched.m_bInitialized = true
	end
	local tFilter = IsValid( pTrueEnemy ) && { self, pEnemy, pTrueEnemy } || { self, pEnemy }
	local vDuckOffset = Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] )
	local vStandOffset = Vector( 0, 0, MyTable.vHullMaxs[ 3 ] )
	local bDuck, bStand = util_TraceLine( {
		start = self:GetPos() + vDuckOffset,
		endpos = v,
		mask = MASK_SHOT_HULL,
		filter = tFilter
	} ).Hit, util_TraceLine( {
		start = self:GetPos() + vStandOffset,
		endpos = v,
		mask = MASK_SHOT_HULL,
		filter = tFilter
	} ).Hit
	if bDuck && bStand then
		if LevelOfDetail( sched, "flNextSuppressionSearch" ) then
			local aDirection
			local tGoal = pEnemyPath:NextSegment()
			if tGoal then aDirection = ( tGoal.pos - self:GetShootPos() ):Angle()
			else aDirection = ( pEnemy:GetPos() - self:GetShootPos() ):Angle() end
			local vTarget = pEnemy:GetPos() + pEnemy:OBBCenter()
			local vHeight = Vector( 0, 0, self.vHullDuckMaxs[ 3 ] )
			local tPitchAngles = pEnemy:GetPos()[ 3 ] > self:GetPos()[ 3 ] && ACTOR_PITCH_ANGLES_UP || ACTOR_PITCH_ANGLES_DOWN
			local bCheckDistance, flDistSqr = MyTable.flCombatState > 0
			if bCheckDistance then
				flDistSqr = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
				flDistSqr = flDistSqr * flDistSqr
			end
			local function fDo( vOrigin, tAngles )
				local vPos = vOrigin + vHeight
				local tWholeFilter = IsValid( trueenemy ) && { self, pEnemy, trueenemy } || { self, pEnemy }
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
			sched.vTarget = fDo( self:GetShootPos(), tAngles )
		end
		local vTarget = sched.vTarget
		if vTarget then
			bCanShoot = true
			MyTable.vaAimTargetBody = vTarget
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			if MyTable.CanAttackHelper( self, vTarget, MyTable ) || MyTable.CanAttackHelper( self, pEnemy, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
		else
			local pPath = sched.pPath
			if pPath then
				local pGoal = pPath:GetCurrentGoal()
				if pGoal then
					MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
					MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
				end
			end
		end
	else
		bCanShoot, bCanShootDirectly = true, true
		MyTable.vaAimTargetBody = v
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		if MyTable.CanAttackHelper( self, pEnemy, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
	end
	MyTable.bSuppressing = bCanShoot
	local vPoint = sched.vPoint
	if vPoint then
		MyTable.WEAPON_STANCE = MyTable.Moving_WEAPON_STANCE
		if sched.bStanding && !sched.bHolyMotherOfJesusJustShutUpAlready then
			if math.random( 2 ) == 1 then MyTable.DLG_FiringAtAnExposedTarget( self ) else MyTable.DLG_Advancing( self ) end
		end
		sched.bStanding = nil
		sched.flNextMoveTime = CurTime() + math.Rand( 4, 6 )
		MyTable.vActualTarget = vPoint
		sched.pIterator = nil
		sched.bSearching = nil
		local pPath = sched.pPath
		if !pPath then pPath = Path "Follow" sched.pPath = pPath end
		MyTable.ComputePath( self, pPath, vPoint, MyTable )
		MyTable.MoveAlongPath( self, pPath, MyTable.flRunSpeed )
		local f = MyTable.flPathTolerance
		if self:GetPos():DistToSqr( vPoint ) <= ( f * f ) then sched.vPoint = nil return end
		return
	end
	if sched.bSearching then
		local pIterator = sched.pIterator
		if !pIterator then
			local vEnemy = pEnemy:GetPos()
			pIterator = MyTable.SearchNodes( self, nil, function( vNew, flCurrentDistance, flAdditionalDistance )
				return flCurrentDistance + flAdditionalDistance + vNew:Distance( vEnemy )
			end )
			sched.pIterator = pIterator
		end
		local flDesiredCursor = sched.flDesiredCursor
		if !flDesiredCursor then
			pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )
			local flBoundingRadius = self:BoundingRadius()
			flDesiredCursor = math.Clamp( pEnemyPath:GetCursorPosition() + flBoundingRadius * math.Remap( pEnemyPath:GetLength() - pEnemyPath:GetCursorPosition(), 0, flBoundingRadius * 128, 8, 32 ) * MyTable.flCombatState, 0, pEnemyPath:GetLength() - flBoundingRadius * 12 )
			sched.flDesiredCursor = flDesiredCursor
		end
		if LevelOfDetail( sched, "flNextSearch", .1 ) then
			local vSimpleOffset = Vector( 0, 0, 12 )
			local tFilter = IsValid( pTrueEnemy ) && { self, pEnemy, pTrueEnemy } || { self, pEnemy }
			local vDuckOffset = Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] )
			local vStandOffset = Vector( 0, 0, MyTable.vHullMaxs[ 3 ] )
			local pPath = MyTable.pEnemyPath
			if !pPath then pPath = Path "Follow" MyTable.ComputePath( self, pPath, pEnemy:GetPos(), MyTable ) MyTable.pEnemyPath = pPath end
			MyTable.vCover = nil
			self:Stand( self:GetCrouchTarget() )
			local vEnemy = pEnemy:GetPos()
			local vTarget = vEnemy + pEnemy:OBBCenter()
			local v = sched.vCoverBounds || MyTable.GatherCoverBounds( self, MyTable )
			sched.vCoverBounds = v
			local tAllies = MyTable.GetAlliesByClass( self, MyTable )
			local f = sched.flBoundingRadiusTwo || ( self:BoundingRadius() ^ 2 )
			sched.flBoundingRadiusTwo = f
			local vMins, vMaxs = sched.vMins || ( MyTable.vHullDuckMins || MyTable.vHullMins ) + Vector( 0, 0, MyTable.loco:GetStepHeight() ), MyTable.vHullDuckMaxs || MyTable.vHullMaxs
			sched.vMins = vMins
			local tCovers = {}
			local tVisited = {}
			local d = MyTable.vHullMaxs.x * 4
			local flSuppressionTraceFraction = MyTable.flSuppressionTraceFraction
			local RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			for _ = 0, 8 do
				local vPoint, pArea = pIterator()
				if vPoint == nil then sched.pIterator = nil return end
				if pArea != nil && !tVisited[ pArea:GetID() ] then
					tVisited[ pArea:GetID() ] = true
					tCovers = {}
					for _, t in ipairs( __COVERS_STATIC__[ pArea:GetID() ] || {} ) do table.insert( tCovers, { t, util.DistanceToLine( t[ 1 ], t[ 2 ], self:GetPos() ) } ) end
					for pEntity, tTable in pairs( __COVERS_DYNAMIC__[ pArea:GetID() ] || {} ) do
						if !IsValid( pEntity ) then continue end
						for _, t in pairs( tTable ) do table.insert( tCovers, { t, util.DistanceToLine( t[ 1 ], t[ 2 ], self:GetPos() ) } ) end
					end
					table.SortByMember( tCovers, 2, true )
					for _, t in ipairs( tCovers ) do
						local tCover = t[ 1 ]
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
						local flCursorStart, flCursorEnd
						pPath:MoveCursorToClosestPosition( vStart )
						flCursorStart = pPath:GetCursorPosition() + pPath:GetPositionOnPath( pPath:GetCursorPosition() ):Distance( vStart )
						pPath:MoveCursorToClosestPosition( vEnd )
						flCursorEnd = pPath:GetCursorPosition() + pPath:GetPositionOnPath( pPath:GetCursorPosition() ):Distance( vEnd )
						if math.max( flCursorStart, flCursorEnd ) <= flDesiredCursor then continue end
						for iCurrent = flStart, flEnd, flStep do
							local vCover = vStart + vDirection * iCurrent + vOff
							pPath:MoveCursorToClosestPosition( vCover )
							if pPath:GetCursorPosition() + pPath:GetPositionOnPath( pPath:GetCursorPosition() ):Distance( vCover ) <= flDesiredCursor then continue end
							local dDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() )
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
							MyTable.vCover = vCover
							MyTable.tCover = tCover
							// bActed to shut up "I'M MOVING!"
							MyTable.SetSchedule( self, "TakeCoverMove", MyTable ).bActed = true
							return
						end
					end
				end
				pEnemyPath:MoveCursorToClosestPosition( vPoint )
				if pEnemyPath:GetCursorPosition() <= flDesiredCursor ||
				util_TraceLine( {
					start = vPoint + vSimpleOffset,
					endpos = vPoint + vDuckOffset,
					mask = MASK_SOLID,
					filter = tFilter
				} ).Hit then continue end
				if !util_TraceLine( {
					start = vPoint + vDuckOffset,
					endpos = v,
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).Hit && !util_TraceLine( {
					start = vPoint + vStandOffset,
					endpos = v,
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).Hit then
					local tAllies, b = MyTable.GetAlliesByClass( self, MyTable ) || {}, true
					local f = self:BoundingRadius()
					f = f * f
					for pAlly in pairs( tAllies ) do
						if self == pAlly then continue end
						if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vPoint ) <= f || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vPoint ) <= f then b = nil break end
					end
					if b then
						sched.flDesiredCursor = nil
						sched.vPoint = vPoint
						sched.bHolyMotherOfJesusJustShutUpAlready = nil
						sched.bDontSearchForCoverTheFirstTime = nil
						return
					end
				end
			end
		end
	else
		sched.pIterator = nil
		if bCanShootDirectly then
			// FIXME: Move randomly for now
			if CurTime() > ( sched.flNextMoveTime || 0 ) then
				sched.bSearching = true
			end
		else
			sched.bSearching = true
		end
		/*
		local tAllies, bMaintainFire, bAtLeastOneAlly = MyTable.GetAlliesByClass( self, MyTable ), true
		if tAllies then
			for pAlly in pairs( tAllies ) do
				if IsValid( pAlly ) && pAlly != self then
					bAtLeastOneAlly = true
					if pAlly.bSuppressing then bMaintainFire = nil break end
				end
			end
		end
		if bAtLeastOneAlly then
		else
		end
		*/
	end
	MyTable.WEAPON_STANCE = WEAPON_STANCE_AIMING
	if !bDuck && !bStand then
		if CurTime() > ( sched.flNextCrouchTime || 0 ) then
			sched.flNextCrouchTime = CurTime() + math.Rand( 1, 8 )
			sched.flCrouch = math.Rand( 0, 1 )
		end
	elseif bStand then
		sched.flCrouch = 0
	else sched.flCrouch = 1 end
	if !sched.bStanding then sched.bStanding = true end
	MyTable.Stand( self, sched.flCrouch )
end )
