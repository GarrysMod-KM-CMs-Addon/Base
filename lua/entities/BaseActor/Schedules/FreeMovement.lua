local table_IsEmpty = table.IsEmpty
local IsValid = IsValid
local util_TraceLine = util.TraceLine
Actor_RegisterSchedule( "FreeMovement", function( self, sched, MyTable )
	local tEnemies = sched.tEnemies || MyTable.tEnemies
	if table_IsEmpty( tEnemies ) then return true end
	if MyTable.flCombatState < 0 || !MyTable.CanExpose( self, MyTable ) then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end
	local pEnemy = sched.Enemy
	if IsValid( pEnemy ) then pEnemy = pEnemy
	else pEnemy = MyTable.Enemy if !IsValid( pEnemy ) then return true end end
	if LevelOfDetail( sched, "flNextHoldFireCheckTime" ) then
		if !MyTable.bHoldFire && CurTime() > ( MyTable.flLastEnemy + MyTable.flHoldFireTime ) then MyTable.DLG_HoldFire( self, MyTable ) end
		if MyTable.bHoldFire then
			local tAllies = MyTable.GetAlliesByClass( self, MyTable )
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
	end
	local c = MyTable.GetWeaponClipPrimary( self, MyTable )
	if c != -1 && c <= 0 then MyTable.WeaponReload( self, MyTable ) end
	local pPath = MyTable.pEnemyPath
	if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputeFlankPath( self, pPath, pEnemy, MyTable ) end
	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )
	local v = pEnemy:GetPos() + pEnemy:OBBCenter()
	local bCanShoot, bCanShootDirectly
	// Start the schedule by charging headfirst into them
	if !sched.m_bInitialized then
		sched.bSearching = true
		sched.m_bInitialized = true
	end
	if util_TraceLine( {
		start = self:GetShootPos(),
		endpos = v,
		mask = MASK_SHOT_HULL,
		filter = IsValid( pTrueEnemy ) && { self, pEnemy, pTrueEnemy } || { self, pEnemy }
	} ).Hit then
		if LevelOfDetail( sched, "flNextSuppressionSearch" ) then
			local aDirection
			local tGoal = pPath:NextSegment()
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
			local pGoal = sched.pEnemyPath:GetCurrentGoal()
			if pGoal then
				MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
				MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
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
			pPath:MoveCursorToClosestPosition( self:GetPos() )
			flDesiredCursor = math.Clamp( pPath:GetCursorPosition() + self:BoundingRadius() * 14 * MyTable.flCombatState, 0, pPath:GetLength() * .5 )
			sched.flDesiredCursor = flDesiredCursor
		end
		if LevelOfDetail( sched, "flNextSearch" ) then
			for _ = 0, 4 do
				local vPoint = pIterator()
				if vPoint == nil then sched.pIterator = nil return end
				pPath:MoveCursorToClosestPosition( vPoint )
				if pPath:GetCursorPosition() >= flDesiredCursor &&
				!util_TraceLine( {
					start = vPoint + Vector( 0, 0, 12 ),
					endpos = vPoint + Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] ),
					mask = MASK_SOLID,
					filter = IsValid( pTrueEnemy ) && { self, pEnemy, pTrueEnemy } || { self, pEnemy }
				} ).Hit then
					if !util_TraceLine( {
						start = vPoint,
						endpos = v,
						mask = MASK_SHOT_HULL,
						filter = IsValid( pTrueEnemy ) && { self, pEnemy, pTrueEnemy } || { self, pEnemy }
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
							return
						end
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
	if CurTime() > ( sched.flNextCrouchTime || 0 ) then
		sched.flNextCrouchTime = CurTime() + math.Rand( 1, 8 )
		sched.flCrouch = math.Rand( 0, 1 )
	end
	MyTable.Stand( self, sched.flCrouch )
end )
