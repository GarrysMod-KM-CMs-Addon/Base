local table_IsEmpty = table.IsEmpty
local IsValid = IsValid
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
Actor_RegisterSchedule( "FreeMovementStand", function( self, sched, MyTable )
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
	local tFilter = pEnemy == pTrueEnemy && SimpleRelatedFilterDouble( self, pEnemy ) || SimpleRelatedFilterTriple( self, pEnemy, pTrueEnemy )
	MyTable.WEAPON_STANCE = WEAPON_STANCE_AIMING
	local vPos = self:GetPos()
	MyTable.vActualTarget = vPos
	local vEnemyCenter = pEnemy:GetPos() + pEnemy:OBBCenter()
	local trStandToCenter, trDuckToCenter = util_TraceLine {
		start = vPos + Vector( 0, 0, MyTable.vHullMaxs[ 3 ] ),
		endpos = vEnemyCenter,
		mask = MASK_SHOT_HULL,
		filter = tFilter
	}, util_TraceLine {
		start = vPos + Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] ),
		endpos = vEnemyCenter,
		mask = MASK_SHOT_HULL,
		filter = tFilter
	}
	if !trStandToCenter.Hit || !trDuckToCenter.Hit then
		local flHealth = pEnemy:Health()
		local ws, w = 0 // Weapon Strength
		for wep in pairs( MyTable.tWeapons ) do
			if wep.bSpecial then continue end
			local t = wep.Primary_flDelay || 0
			if t <= 0 then continue end
			local d = wep.Primary_flDamage || 0
			if d <= 0 then continue end
			local nws = math.abs( flHealth - 1 / ( wep.Primary.Automatic && t || t + MyTable.tWeaponPrimaryVolleyNonAutomaticDelay[ 2 ] ) * d * ( wep.Primary_iNum || 1 ) )
			if nws < ws then w, ws = wep, nws end
		end
		sched.flSuppressTime = CurTime() + math.Rand( MyTable.flShootTimeMin, MyTable.flShootTimeMax )
		sched.bGotALineOfSightBefore = true
		MyTable.Stand( self, trStandToCenter.Hit && 0 || 1, MyTable )
		MyTable.vaAimTargetBody = pEnemy:GetPos() + pEnemy:OBBCenter()
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		local pWeapon = MyTable.Weapon
		if !IsValid( pWeapon ) then return false end
		local flRecoil = pWeapon.flRecoil
		if flRecoil then
			local flDistance = MyTable.GetShootPos( self, MyTable ):Distance( MyTable.vaAimTargetBody )
			if flRecoil <= 0 || flDistance < 1792 / flRecoil then
				MyTable.tWeaponPrimaryVolleyTimes = { 0, 0 }
				MyTable.tWeaponPrimaryVolleyBreaks = { 0, 0 }
				MyTable.tWeaponPrimaryVolleyNonAutomaticDelay = { 0, 0 }
			end
		end
		if MyTable.CanAttackHelper( self, pEnemy, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
		// TODO
		/*if MyTable.m_bHadSmokesLast && MyTable.GAME_flSuppression > 0 && LevelOfDetail( sched, "flNextSmoke" ) then
			local vShoot = self:GetShootPos()
			local vSmokeTarget = ( vEnemyCenter - vShoot ):GetNormalized() * math.min( MyTable.GAME_flThrowForce, math.Rand( 0, self:BoundingRadius() * 10 ) )
			vSmokeTarget[ 3 ] = vShoot[ 3 ]
		end*/
		return
	end
	if sched.bGotALineOfSightBefore then
		MyTable.SetSchedule( self, "FreeMovementSearch", MyTable ).bGotALineOfSightBefore = true
		return
	end
	local pPath = MyTable.pEnemyPath
	if !pPath then
		pPath = Path "Follow"
		MyTable.ComputePath( self, pPath, pEnemy:GetPos(), MyTable )
		MyTable.pEnemyPath = pPath
	end
	local flDistSqr = math.max( 512, math.Remap( vPos:Distance( pEnemy:GetPos() ), 0, 4096, 512, 1024 ) ) / MyTable.flCombatState
	flDistSqr = flDistSqr * flDistSqr
	local vSuppressionPoint = sched.vSuppressionPoint
	// TODO: Validate the point, duh xD
	if vSuppressionPoint then
		local flTime = sched.flSuppressTime
		if !flTime then flTime = CurTime() + math.Rand( MyTable.flShootTimeMin, MyTable.flShootTimeMax ) sched.flSuppressTime = flTime end
		if CurTime() > flTime then MyTable.SetSchedule( self, "FreeMovementSearch", MyTable ).bGotALineOfSightBefore = true return end
		local trStandToCenter, trDuckToCenter = util_TraceLine {
			start = vPos + Vector( 0, 0, MyTable.vHullMaxs[ 3 ] ),
			endpos = vSuppressionPoint,
			mask = MASK_SHOT_HULL,
			filter = tFilter
		}, util_TraceLine {
			start = vPos + Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] ),
			endpos = vSuppressionPoint,
			mask = MASK_SHOT_HULL,
			filter = tFilter
		}
		if trStandToCenter.Hit && trDuckToCenter.Hit then sched.vSuppressionPoint = nil return end
		MyTable.Stand( self, trStandToCenter.Hit && 0 || 1, MyTable )
		MyTable.vaAimTargetBody = vSuppressionPoint
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		local pWeapon = MyTable.Weapon
		if !IsValid( pWeapon ) then return false end
		if MyTable.CanAttackHelper( self, vSuppressionPoint, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
	else
		// Suppression searches are relatively light, especially when we use SHORT angles
		if LevelOfDetail( sched, "flNextSuppressionSearch", .1 ) then return end
		vPos = vPos + Vector( 0, 0, MyTable.vHullMaxs[ 3 ] )
		pPath:MoveCursorToClosestPosition( self:GetPos() )
		local iCursor = pPath:GetCursorPosition()
		local aDirection = pPath:GetPositionOnPath( iCursor )
		pPath:MoveCursor( self:BoundingRadius() * MyTable.flPathStabilizer )
		aDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() ) - aDirection
		aDirection = aDirection:Angle()
		local vTarget = pEnemy:GetPos() + pEnemy:OBBCenter()
		for _, flGlobalAnglePitch in ipairs( self:GetPos()[ 1 ] > pEnemy:GetPos()[ 1 ] && ACTOR_PITCH_ANGLES_SHORT_UP || ACTOR_PITCH_ANGLES_SHORT_DOWN ) do
			for _, flGlobalAngleYaw in ipairs( math.random( 2 ) == 1 && ACTOR_PITCH_ANGLES_SHORT_LEFT || ACTOR_PITCH_ANGLES_SHORT_RIGHT ) do
				local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
				local vAim = aAim:Forward()
				local tr = util_TraceLine {
					start = vPos,
					endpos = vPos + vAim * 999999,
					mask = MASK_SHOT_HULL,
					filter = tFilter
				}
				local _, vPoint = util.DistanceToLine( vPos, tr.HitPos, vTarget )
				if util_TraceLine( {
					start = vPoint,
					endpos = vTarget,
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).Hit || vPoint:DistToSqr( vTarget ) > flDistSqr then continue end
				sched.vSuppressionPoint = vPoint
				return
			end
		end
		MyTable.SetSchedule( self, "FreeMovementSearch", MyTable )
	end
end )

Actor_RegisterSchedule( "FreeMovementMove", function( self, sched, MyTable )
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
	local tFilter = pEnemy == pTrueEnemy && SimpleRelatedFilterDouble( self, pEnemy ) || SimpleRelatedFilterTriple( self, pEnemy, pTrueEnemy )
	local vPoint = sched.vPoint
	if !vPoint then return true end
	MyTable.WEAPON_STANCE = MyTable.Moving_WEAPON_STANCE
	MyTable.vActualTarget = vPoint
	local pPath = sched.pPath
	if !pPath then pPath = Path "Follow" sched.pPath = pPath end
	MyTable.ComputePath( self, pPath, vPoint, MyTable )
	local f = MyTable.flPathTolerance
	if self:GetPos():DistToSqr( vPoint ) <= ( f * f ) then sched.vPoint = nil MyTable.SetSchedule( self, "FreeMovementStand", MyTable ).bGotALineOfSightBefore = sched.bGotALineOfSightBefore return end
	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )
	local tFilter = pEnemy == pTrueEnemy && SimpleRelatedFilterDouble( self, pEnemy ) || SimpleRelatedFilterTriple( self, pEnemy, pTrueEnemy )
	MyTable.WEAPON_STANCE = WEAPON_STANCE_AIMING
	local vPos = self:GetPos()
	local vEnemyCenter = pEnemy:GetPos() + pEnemy:OBBCenter()
	local trStandToCenter, trDuckToCenter = util_TraceLine {
		start = vPos + Vector( 0, 0, MyTable.vHullMaxs[ 3 ] ),
		endpos = vEnemyCenter,
		mask = MASK_SHOT_HULL,
		filter = tFilter
	}, util_TraceLine {
		start = vPos + Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] ),
		endpos = vEnemyCenter,
		mask = MASK_SHOT_HULL,
		filter = tFilter
	}
	if !trStandToCenter.Hit || !trDuckToCenter.Hit then
		if !sched.bGotALineOfSightBefore then
			MyTable.SetSchedule( self, "FreeMovementStand", MyTable ).bGotALineOfSightBefore = true
			return
		end
		MyTable.MoveAlongPath( self, pPath, MyTable.flRunSpeed, trStandToCenter.Hit && 0 || 1 )
		MyTable.vaAimTargetBody = pEnemy:GetPos() + pEnemy:OBBCenter()
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		local pWeapon = MyTable.Weapon
		if !IsValid( pWeapon ) then return false end
		local flRecoil = pWeapon.flRecoil
		if flRecoil then
			local flDistance = MyTable.GetShootPos( self, MyTable ):Distance( MyTable.vaAimTargetBody )
			if flRecoil <= 0 || flDistance < 1792 / flRecoil then
				MyTable.tWeaponPrimaryVolleyTimes = { 0, 0 }
				MyTable.tWeaponPrimaryVolleyBreaks = { 0, 0 }
				MyTable.tWeaponPrimaryVolleyNonAutomaticDelay = { 0, 0 }
			end
		end
		if MyTable.CanAttackHelper( self, pEnemy, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
		return
	end
	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.ComputePath( self, pEnemyPath, pEnemy:GetPos(), MyTable )
		MyTable.pEnemyPath = pEnemyPath
	end
	local flDistSqr = math.max( 512, math.Remap( vPos:Distance( pEnemy:GetPos() ), 0, 4096, 512, 1024 ) ) / MyTable.flCombatState
	flDistSqr = flDistSqr * flDistSqr
	local vSuppressionPoint = sched.vSuppressionPoint
	// TODO: Validate the point, duh xD
	if vSuppressionPoint then
		local trStandToCenter, trDuckToCenter = util_TraceLine {
			start = vPos + Vector( 0, 0, MyTable.vHullMaxs[ 3 ] ),
			endpos = vSuppressionPoint,
			mask = MASK_SHOT_HULL,
			filter = tFilter
		}, util_TraceLine {
			start = vPos + Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] ),
			endpos = vSuppressionPoint,
			mask = MASK_SHOT_HULL,
			filter = tFilter
		}
		if trStandToCenter.Hit && trDuckToCenter.Hit then sched.vSuppressionPoint = nil return end
		MyTable.MoveAlongPath( self, pPath, MyTable.flRunSpeed, trStandToCenter.Hit && 0 || 1 )
		MyTable.vaAimTargetBody = vSuppressionPoint
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		local pWeapon = MyTable.Weapon
		if !IsValid( pWeapon ) then return false end
		if MyTable.CanAttackHelper( self, vSuppressionPoint, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
	else
		MyTable.MoveAlongPath( self, pPath, MyTable.flTopSpeed )
		local tGoal = pPath:GetCurrentGoal()
		if tGoal then
			MyTable.vaAimTargetBody = ( tGoal.pos - self:GetPos() ):Angle()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			MyTable.ModifyMoveAimVector( self, MyTable.vaAimTargetBody, MyTable.flTopSpeed, 1, MyTable )
		end
		if LevelOfDetail( sched, "flNextSuppressionSearch", .1 ) then return end
		vPos = vPos + Vector( 0, 0, MyTable.vHullMaxs[ 3 ] )
		pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )
		local iCursor = pEnemyPath:GetCursorPosition()
		local aDirection = pEnemyPath:GetPositionOnPath( iCursor )
		pEnemyPath:MoveCursor( self:BoundingRadius() * MyTable.flPathStabilizer )
		aDirection = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - aDirection
		aDirection = aDirection:Angle()
		local vTarget = pEnemy:GetPos() + pEnemy:OBBCenter()
		for _, flGlobalAnglePitch in ipairs( self:GetPos()[ 1 ] > pEnemy:GetPos()[ 1 ] && ACTOR_PITCH_ANGLES_SHORT_UP || ACTOR_PITCH_ANGLES_SHORT_DOWN ) do
			for _, flGlobalAngleYaw in ipairs( math.random( 2 ) == 1 && ACTOR_PITCH_ANGLES_SHORT_LEFT || ACTOR_PITCH_ANGLES_SHORT_RIGHT ) do
				local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
				local vAim = aAim:Forward()
				local tr = util_TraceLine {
					start = vPos,
					endpos = vPos + vAim * 999999,
					mask = MASK_SHOT_HULL,
					filter = tFilter
				}
				local _, vPoint = util.DistanceToLine( vPos, tr.HitPos, vTarget )
				if util_TraceLine( {
					start = vPoint,
					endpos = vTarget,
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).Hit || vPoint:DistToSqr( vTarget ) > flDistSqr then continue end
				sched.vSuppressionPoint = vPoint
			end
		end
	end
end )

Actor_RegisterSchedule( "FreeMovementSearch", function( self, sched, MyTable )
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
	local tFilter = pEnemy == pTrueEnemy && SimpleRelatedFilterDouble( self, pEnemy ) || SimpleRelatedFilterTriple( self, pEnemy, pTrueEnemy )
	local pIterator = sched.pIterator
	if !pIterator then
		local vEnemy = pEnemy:GetPos()
		pIterator = MyTable.SearchNodes( self, nil, function( vNew, flCurrentDistance, flAdditionalDistance )
			pEnemyPath:MoveCursorToClosestPosition( vNew )
			return flCurrentDistance + flAdditionalDistance - pEnemyPath:GetCursorPosition() + pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ):Distance( vNew )
		end )
		sched.pIterator = pIterator
	end
	// SHIT. I lost motivation halfway :(
	local flDesiredCursor = sched.flDesiredCursor
	if !flDesiredCursor then
		pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )
		local flBoundingRadius = self:BoundingRadius()
		flDesiredCursor = math.Clamp( pEnemyPath:GetCursorPosition() + flBoundingRadius * math.Remap( pEnemyPath:GetLength() - pEnemyPath:GetCursorPosition(), 0, flBoundingRadius * 128, 8, 32 ) * MyTable.flCombatState, 0, pEnemyPath:GetLength() - flBoundingRadius * 12 )
		sched.flDesiredCursor = flDesiredCursor
	end
	if LevelOfDetail( sched, "flNextSearch", .1 ) then
		local vMyStart, vMyEnd = sched.vMyStart, sched.vMyEnd
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
		local tAllies = MyTable.GetAlliesByClass( self, MyTable )
		local f = sched.flBoundingRadiusTwo || ( self:BoundingRadius() ^ 2 )
		sched.flBoundingRadiusTwo = f
		local vMins, vMaxs = sched.vMins || ( MyTable.vHullDuckMins || MyTable.vHullMins ) + Vector( 0, 0, MyTable.loco:GetStepHeight() ), MyTable.vHullDuckMaxs || MyTable.vHullMaxs
		sched.vMins = vMins
		local tCovers = {}
		local tVisited = {}
		local d = MyTable.vHullMaxs[ 1 ] * 4
		local flSuppressionTraceFraction = MyTable.flSuppressionTraceFraction
		local RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
		for _ = 0, 4 do
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
					if vStart == vMyStart || vEnd == vMyEnd then continue end
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
					flCursorStart = pPath:GetCursorPosition() - pPath:GetPositionOnPath( pPath:GetCursorPosition() ):Distance( vStart )
					pPath:MoveCursorToClosestPosition( vEnd )
					flCursorEnd = pPath:GetCursorPosition() - pPath:GetPositionOnPath( pPath:GetCursorPosition() ):Distance( vEnd )
					if math.max( flCursorStart, flCursorEnd ) <= flDesiredCursor then continue end
					for iCurrent = flStart, flEnd, flStep do
						local vCover = vStart + vDirection * iCurrent + vOff
						pPath:MoveCursorToClosestPosition( vCover )
						if pPath:GetCursorPosition() - pPath:GetPositionOnPath( pPath:GetCursorPosition() ):Distance( vCover ) <= flDesiredCursor then continue end
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
						local vCheck = vCover + Vector( 0, 0, vMaxs[ 3 ] )
						if !util_TraceLine( {
							start = vCheck,
							endpos = vCheck + dDirection * vMaxs[ 1 ] * COVER_BOUND_SIZE,
							filter = self
						} ).Hit then continue end
						if !util_TraceLine( {
							start = vCheck,
							endpos = vCheck + dDirection * vMaxs[ 1 ] * COVER_BOUND_SIZE,
							filter = self
						} ).Hit then continue end
						local tr = util_TraceLine {
							start = vCheck,
							endpos = vTarget,
							mask = MASK_SHOT_HULL,
							filter = { self, enemy, trueenemy }
						}
						local d = vEnemy - vCover
						d[ 3 ] = 0
						d:Normalize()
						if !util_TraceLine( {
							start = vCheck,
							endpos = vCheck + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
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
						MyTable.SetSchedule( self, "TakeCoverMove", MyTable )
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
			debugoverlay.Line(vPoint,vPoint+vStandOffset,5,Color(255,0,0),true)
			if !util_TraceLine( {
				start = vPoint + vDuckOffset,
				endpos = vEnemy,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit && !util_TraceLine( {
				start = vPoint + vStandOffset,
				endpos = vEnemy,
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
					local pNew = MyTable.SetSchedule( self, "FreeMovementMove", MyTable )
					pNew.vPoint = vPoint
					pNew.bGotALineOfSightBefore = sched.bGotALineOfSightBefore
					MyTable.vActualTarget = vPoint
					return
				end
			end
		end
	end
	//if LevelOfDetail( sched, "flNextSearch", .5 ) then
	//	local flLimit = self:BoundingRadius() * 16
	//	local vSimpleOffset = Vector( 0, 0, 12 )
	//	local tFilter = IsValid( pTrueEnemy ) && { self, pEnemy, pTrueEnemy } || { self, pEnemy }
	//	local vDuckOffset = Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] )
	//	local vStandOffset = Vector( 0, 0, MyTable.vHullMaxs[ 3 ] )
	//	local pPath = MyTable.pEnemyPath
	//	if !pPath then pPath = Path "Follow" MyTable.ComputePath( self, pPath, pEnemy:GetPos(), MyTable ) MyTable.pEnemyPath = pPath end
	//	MyTable.vCover = nil
	//	self:Stand( self:GetCrouchTarget() )
	//	local vEnemy = pEnemy:GetPos()
	//	local vTarget = vEnemy + pEnemy:OBBCenter()
	//	local tAllies = MyTable.GetAlliesByClass( self, MyTable )
	//	local f = sched.flBoundingRadiusTwo || ( self:BoundingRadius() ^ 2 )
	//	sched.flBoundingRadiusTwo = f
	//	local vMins, vMaxs = sched.vMins || ( MyTable.vHullDuckMins || MyTable.vHullMins ) + Vector( 0, 0, MyTable.loco:GetStepHeight() ), MyTable.vHullDuckMaxs || MyTable.vHullMaxs
	//	sched.vMins = vMins
	//	local tCovers = {}
	//	local tVisited = {}
	//	local d = MyTable.vHullMaxs[ 1 ] * 4
	//	local flSuppressionTraceFraction = MyTable.flSuppressionTraceFraction
	//	local RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
	//	for _ = 0, 4 do
	//		local vPoint, pArea, flDistance = pIterator()
	//		if vPoint == nil then sched.pIterator = nil return end
	//		if pArea != nil && !tVisited[ pArea:GetID() ] then
	//			tVisited[ pArea:GetID() ] = true
	//			tCovers = {}
	//			for _, t in ipairs( __COVERS_STATIC__[ pArea:GetID() ] || {} ) do table.insert( tCovers, { t, util.DistanceToLine( t[ 1 ], t[ 2 ], self:GetPos() ) } ) end
	//			for pEntity, tTable in pairs( __COVERS_DYNAMIC__[ pArea:GetID() ] || {} ) do
	//				if !IsValid( pEntity ) then continue end
	//				for _, t in pairs( tTable ) do table.insert( tCovers, { t, util.DistanceToLine( t[ 1 ], t[ 2 ], self:GetPos() ) } ) end
	//			end
	//			table.SortByMember( tCovers, 2, true )
	//			// TODO: Validate the covers for a line of sight
	//			//for _, t in ipairs( tCovers ) do
	//			//	local tCover = t[ 1 ]
	//			//	local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
	//			//	local vDirection = vEnd - vStart
	//			//	local flStep, flStart, flEnd
	//			//	if vStart:DistToSqr( self:GetPos() ) <= vEnd:DistToSqr( self:GetPos() ) then
	//			//		flStart, flEnd, flStep = 0, vDirection:Length(), vMaxs[ 1 ]
	//			//	else
	//			//		flStart, flEnd, flStep = vDirection:Length(), 0, -vMaxs[ 1 ]
	//			//	end
	//			//	vDirection:Normalize()
	//			//	local vOff = tCover[ 3 ] && vDirection:Angle():Right() || -vDirection:Angle():Right()
	//			//	vOff = vOff * vMaxs[ 1 ] * math.max( 1.25, COVER_BOUND_SIZE * .5 )
	//			//	local flCursorStart, flCursorEnd
	//			//	pPath:MoveCursorToClosestPosition( vStart )
	//			//	flCursorStart = pPath:GetCursorPosition() + pPath:GetPositionOnPath( pPath:GetCursorPosition() ):Distance( vStart )
	//			//	pPath:MoveCursorToClosestPosition( vEnd )
	//			//	flCursorEnd = pPath:GetCursorPosition() + pPath:GetPositionOnPath( pPath:GetCursorPosition() ):Distance( vEnd )
	//			//	for iCurrent = flStart, flEnd, flStep do
	//			//		local vCover = vStart + vDirection * iCurrent + vOff
	//			//		pPath:MoveCursorToClosestPosition( vCover )
	//			//		local dDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() )
	//			//		pPath:MoveCursor( self:BoundingRadius() * MyTable.flPathStabilizer )
	//			//		dDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() ) - dDirection
	//			//		dDirection[ 3 ] = 0
	//			//		dDirection:Normalize()
	//			//		if dDirection:IsZero() then
	//			//			dDirection = vEnemy - vCover
	//			//			dDirection[ 3 ] = 0
	//			//			dDirection:Normalize()
	//			//		end
	//			//		if util_TraceHull( {
	//			//			start = vCover,
	//			//			endpos = vCover,
	//			//			mins = vMins,
	//			//			maxs = vMaxs,
	//			//			filter = self
	//			//		} ).Hit then continue end
	//			//		local v = vCover + Vector( 0, 0, vMaxs[ 3 ] )
	//			//		if !util_TraceLine( {
	//			//			start = v,
	//			//			endpos = v + dDirection * vMaxs[ 1 ] * COVER_BOUND_SIZE,
	//			//			filter = self
	//			//		} ).Hit then continue end
	//			//		if !util_TraceLine( {
	//			//			start = v,
	//			//			endpos = v + dDirection * vMaxs[ 1 ] * COVER_BOUND_SIZE,
	//			//			filter = self
	//			//		} ).Hit then continue end
	//			//		local tr = util_TraceLine {
	//			//			start = v,
	//			//			endpos = vTarget,
	//			//			mask = MASK_SHOT_HULL,
	//			//			filter = { self, enemy, trueenemy }
	//			//		}
	//			//		local d = vEnemy - vCover
	//			//		d[ 3 ] = 0
	//			//		d:Normalize()
	//			//		if !util_TraceLine( {
	//			//			start = v,
	//			//			endpos = v + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
	//			//			filter = self
	//			//		} ).Hit then continue end
	//			//		if tAllies then
	//			//			local b
	//			//			for pAlly in pairs( tAllies ) do
	//			//				if self == pAlly then continue end
	//			//				if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vCover ) <= f || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vCover ) <= f then b = true break end
	//			//			end
	//			//			if b then continue end
	//			//		end
	//			//		MyTable.vCover = vCover
	//			//		MyTable.tCover = tCover
	//			//		MyTable.SetSchedule( self, "TakeCoverMove", MyTable )
	//			//		return
	//			//	end
	//			//end
	//		end
	//		if flDistance && flDistance > flLimit then MyTable.SetSchedule( self, "FreeMovementSearch2", MyTable ) return end
	//		if util_TraceLine( {
	//			start = vPoint + vSimpleOffset,
	//			endpos = vPoint + vDuckOffset,
	//			mask = MASK_SOLID,
	//			filter = tFilter
	//		} ).Hit then continue end
	//		if !util_TraceLine( {
	//			start = vPoint + vDuckOffset,
	//			endpos = vTarget,
	//			mask = MASK_SHOT_HULL,
	//			filter = tFilter
	//		} ).Hit && !util_TraceLine( {
	//			start = vPoint + vStandOffset,
	//			endpos = vTarget,
	//			mask = MASK_SHOT_HULL,
	//			filter = tFilter
	//		} ).Hit then
	//			local tAllies, b = MyTable.GetAlliesByClass( self, MyTable ) || {}, true
	//			local f = self:BoundingRadius()
	//			f = f * f
	//			for pAlly in pairs( tAllies ) do
	//				if self == pAlly then continue end
	//				if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vPoint ) <= f || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vPoint ) <= f then b = nil break end
	//			end
	//			if b then
	//				local pNew = MyTable.SetSchedule( self, "FreeMovementMove", MyTable )
	//				pNew.vPoint = vPoint
	//				pNew.bGotALineOfSightBefore = sched.bGotALineOfSightBefore
	//				MyTable.vActualTarget = vPoint
	//				return
	//			end
	//		end
	//	end
	//end
end )
