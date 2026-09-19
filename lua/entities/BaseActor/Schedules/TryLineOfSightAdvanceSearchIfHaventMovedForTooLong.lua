function ENT:TryLineOfSightAdvanceSearchIfHaventMovedForTooLong( pSchedule, MyTable, pEnemy, pTrueEnemy, vFrom )
	// Ah yes, the supermega formula
	if math.random( 2 ) == 1 then return end

	// Vertical
	if vFrom == true then
		vFrom = Vector( MyTable.vCover )
		vFrom[ 3 ] = vFrom[ 3 ] + MyTable.vViewOffsetDucked[ 3 ]
	end

	pSchedule.bBusy = true

	ACTOR_QUEUE( function()
		if !IsValid( self ) || MyTable.Schedule != pSchedule || !IsValid( pEnemy ) then return true end

		local pEnemyPath = MyTable.pEnemyPath
		if !pEnemyPath then
			pEnemyPath = Path "Follow"
			MyTable.pEnemyPath = pEnemyPath
		end

		if MyTable.ManageFlankPathLockThisCoroutine( self, pEnemyPath, pEnemy, pSchedule, MyTable ) then
			pSchedule.bBusy = nil
			return true
		end

		// They could've hid while we were searching, you know!
		if util.TraceLine( {
			start = vFrom,
			endpos = pEnemy:GetPos() + pEnemy:OBBCenter(),
			mask = MASK_SHOT_HULL,
			filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
		} ).Hit then
			// TODO: This should actually change to normal advance search
			pSchedule.bBusy = nil
			return true
		end

		local tAllies = MyTable:GetAlliesByClass()

		local flTakenDistSqr = self:OBBMaxs()[ 1 ]
		flTakenDistSqr = flTakenDistSqr * flTakenDistSqr

		local vMaxs = MyTable.vHullDuckMaxs || MyTable.vHullMaxs

		local vHitMaxs = MyTable.vHullDuckHitCheckMaxs || MyTable.vHullDuckMaxs || MyTable.vHullMaxs

		local vMins = Vector( MyTable.vHullDuckMins || MyTable.vHullMins )
		vMins[ 3 ] = vMins[ 3 ] + vMaxs[ 3 ] * .2

		local pInitialCover = MyTable.tCover
		local tQueue = { { pInitialCover, 0, 0 } }
		local tVisited = { [ pInitialCover ] = true }

		local flTakenDistSqr = self:OBBMaxs()[ 1 ] * 1.25
		flTakenDistSqr = flTakenDistSqr * flTakenDistSqr

		while !table.IsEmpty( tQueue ) do
			if !IsValid( self ) || MyTable.Schedule != pSchedule || !IsValid( pEnemy ) then return true end

			if util.TraceLine( {
				start = vFrom,
				endpos = pEnemy:GetPos() + pEnemy:OBBCenter(),
				mask = MASK_SHOT_HULL,
				filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
			} ).Hit then
				// TODO: This should actually change to normal advance search
				pSchedule.bBusy = nil
				return true
			end

			local pCover, flRealDistance = unpack( table.remove( tQueue ) )

			for iAreaID, tIndices in pairs( pCover.tLinks || {} ) do
				for iTarget in pairs( tIndices ) do
					local pTarget = __COVERS_STATIC__[ iAreaID ]
					if pTarget then
						pTarget = pTarget[ iTarget ]

						if tVisited[ pTarget ] then continue end
						tVisited[ pTarget ] = true

						bNew = true

						local flNewDistance = flRealDistance + math.min(
							pTarget.vStart:Distance( pCover.vStart ),
							pTarget.vStart:Distance( pCover.vEnd ),
							pTarget.vEnd:Distance( pCover.vStart ),
							pTarget.vEnd:Distance( pCover.vEnd )
						)

						table.insert( tQueue, {
							pTarget,
							flNewDistance,
							flNewDistance // TODO: Prefer covers along pEnemyPath
						} )
					end
				end
			end

			if bNew then table.SortByMember( tQueue, 3 ) end

			if pCover == pInitialCover || !MyTable.IsValidCoverCandidate( self, pCover, pEnemyPath, MyTable ) then continue end

			local vStart, vEnd = pCover.vStart, pCover.vEnd

			local vDirection = vEnd - vStart

			local flStep, flStart, flEnd
			if vStart:DistToSqr( self:GetPos() ) <= vEnd:DistToSqr( self:GetPos() ) then
				flStart, flEnd, flStep = 0, vDirection:Length(), vMaxs[ 1 ]
			else
				flStart, flEnd, flStep = vDirection:Length(), 0, -vMaxs[ 1 ]
			end

			vDirection:Normalize()

			local vOff = pCover.bRight && vDirection:Angle():Right() || -vDirection:Angle():Right()
			vOff = vOff * vMaxs[ 1 ] * 1.2

			for flCurrent = flStart, flEnd, flStep do
				local vCover = vStart + vDirection * flCurrent + vOff

				if util.TraceHull( {
					start = vCover,
					endpos = vCover,
					mins = vMins,
					maxs = vMaxs,
					filter = self
				} ).Hit then continue end

				if !MyTable.IsValidCoverPoint( self, vCover, pCover, pEnemy, pEnemyPath, MyTable, vHitMaxs ) then continue end

				if tAllies then
					local b
					for pAlly in pairs( tAllies ) do
						if !IsValid( pAlly ) || self == pAlly then continue end
						if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vCover ) <= flTakenDistSqr || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vCover ) <= flTakenDistSqr then b = true break end
					end
					if b then continue end
				end

				local pSchedule = MyTable.SetSchedule( self, "TakeCoverMove", MyTable )
				pSchedule.vCoverFrom = MyTable.vCover
				pSchedule.pCoverFrom = MyTable.tCover

				MyTable.vCover = vCover
				MyTable.pCover = pCover

				return true
			end

			coroutine.yield()
		end
	end )

	return true
end
