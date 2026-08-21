ENT.tPreScheduleResetVariables.vActualCover = false
ENT.tPreScheduleResetVariables.vActualTarget = false

local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull

local insert = table.insert
local DistanceToLine = util.DistanceToLine
local SortByMember = table.SortByMember

RegisterSchedule( "TakeCover", { Execute = function( self, sched, MyTable )
	MyTable.WEAPON_STANCE = MyTable.Moving_WEAPON_STANCE

	local tEnemies = MyTable.tEnemies
	if table.IsEmpty( tEnemies ) then return true end

	local pEnemy = sched.Enemy

	if !IsValid( pEnemy ) then pEnemy = MyTable.Enemy if !IsValid( pEnemy ) then return true end end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )

	MyTable.bWantsCover = true

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end

	local vCover = MyTable.vCover
	local tCover = MyTable.tCover

	if !vCover || !tCover then
		MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy )

		if sched.bBeganSearching then
			MyTable.WEAPON_STANCE = WEAPON_STANCE_AIMING

			local iClip = MyTable.GetWeaponClipPrimary( self, MyTable )
			if iClip!= -1 && iClip <= 0 then MyTable.WeaponReload( self, MyTable ) end

			local vPos = self:GetPos()
	
			local vEnemyCenter = pEnemy:GetPos() + pEnemy:OBBCenter()

			local tFilter = pEnemy == pTrueEnemy && SimpleRelatedFilterDouble( self, pEnemy ) || SimpleRelatedFilterTriple( self, pEnemy, pTrueEnemy )

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
					local nws = math.abs( flHealth - 1 / ( wep.Primary.Automatic && t || t + MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax ) * d * ( wep.Primary_iNum || 1 ) )
					if nws < ws then w, ws = wep, nws end
				end

				if !trStandToCenter.Hit && !trDuckToCenter.Hit then
					if CurTime() > ( sched.flNextDuck || 0 ) then
						sched.bDuck = math.random() <= .5
						sched.flNextDuck = CurTime() + math.Rand( 0, 8 )
					end
					MyTable.Stand( self, sched.bDuck && 0 || 1, MyTable )
				else MyTable.Stand( self, trStandToCenter.Hit && 0 || 1, MyTable ) end

				MyTable.vaAimTargetBody = vEnemyCenter
				MyTable.vaAimTargetPose = MyTable.vaAimTargetBody

				local pWeapon = MyTable.Weapon
				if !IsValid( pWeapon ) then return false end

				local flRecoil = pWeapon.flRecoil
				if flRecoil then
					local flDistance = MyTable.GetShootPos( self, MyTable ):Distance( MyTable.vaAimTargetBody )
					if flRecoil <= 0 || flDistance < 1792 / flRecoil then
						MyTable.flWeaponPrimaryVolleyTimeMin = 0
						MyTable.flWeaponPrimaryVolleyTimeMax = 0
						
						MyTable.flWeaponPrimaryVolleyBreakMin = 0
						MyTable.flWeaponPrimaryVolleyBreakMax = 0
						
						MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMin = 0
						MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax = .2
					end
				end

				if MyTable.CanAttackHelper( self, pEnemy, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
				return
			else
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

					if !trStandToCenter.Hit && !trDuckToCenter.Hit then
						if CurTime() > ( sched.flNextDuck || 0 ) then
							sched.bDuck = math.random() <= .5
							sched.flNextDuck = CurTime() + math.Rand( 0, 8 )
						end
						MyTable.Stand( self, sched.bDuck && 0 || 1, MyTable )
					else MyTable.Stand( self, trStandToCenter.Hit && 0 || 1, MyTable ) end

					MyTable.vaAimTargetBody = vSuppressionPoint
					MyTable.vaAimTargetPose = MyTable.vaAimTargetBody

					local pWeapon = MyTable.Weapon
					if !IsValid( pWeapon ) then return false end

					if MyTable.CanAttackHelper( self, vSuppressionPoint, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
				else
					// Suppression searches are relatively light, especially when we use SHORT angles
					if !LevelOfDetail( sched, "flNextSuppressionSearch", .1 ) then return end
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
							local _, vPoint = DistanceToLine( vPos, tr.HitPos, vTarget )
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
				end
			end
			return
		end

		sched.bBeganSearching = true

		ACTOR_QUEUE( function()
			if !IsValid( self ) || MyTable.Schedule != sched || !IsValid( pEnemy ) then return true end

			MyTable.vCover = nil

			self:Stand( self:GetCrouchTarget() )

			local pIterator = MyTable.SearchAreas( self, nil, nil, MyTable )

			local vEnemy = pEnemy:GetPos()
			local vTarget = vEnemy + pEnemy:OBBCenter()

			local tAllies = MyTable.GetAlliesByClass( self, MyTable )

			local flTakenDistSqr = self:OBBMaxs()[ 1 ]
			flTakenDistSqr = flTakenDistSqr * flTakenDistSqr

			local vMaxs = MyTable.vHullDuckMaxs || MyTable.vHullMaxs

			local vMins = Vector( MyTable.vHullDuckMins || MyTable.vHullMins )
			vMins[ 3 ] = vMins[ 3 ] + vMaxs[ 3 ] * .2

			local tCovers

			while true do
				if !IsValid( self ) || MyTable.Schedule != sched || !IsValid( pEnemy ) then return true end

				local pArea = pIterator()
				if pArea == nil then
					// REPEAT!!! AND TRY HARDER!!!
					pIterator = MyTable.SearchAreas( self, nil, nil, MyTable )
					continue
				end

				tCovers = {}

				for _, tCover in ipairs( __COVERS_STATIC__[ pArea:GetID() ] || {} ) do
					insert( tCovers, { tCover, DistanceToLine( tCover.vStart, tCover.vEnd, self:GetPos() ) } )
				end

				SortByMember( tCovers, 2, true )

				for _, tData in ipairs( tCovers ) do
					local tCover = tData[ 1 ]

					local vStart, vEnd = tCover.vStart, tCover.vEnd

					local vDirection = vEnd - vStart

					local flStep, flStart, flEnd
					if vStart:DistToSqr( self:GetPos() ) <= vEnd:DistToSqr( self:GetPos() ) then
						flStart, flEnd, flStep = 0, vDirection:Length(), vMaxs[ 1 ]
					else
						flStart, flEnd, flStep = vDirection:Length(), 0, -vMaxs[ 1 ]
					end

					vDirection:Normalize()

					local vOff = tCover.bRight && vDirection:Angle():Right() || -vDirection:Angle():Right()
					vOff = vOff * vMaxs[ 1 ] * 1.2

					if !MyTable.IsValidCoverCandidate( self, tCover, pEnemyPath, MyTable ) then continue end

					for flCurrent = flStart, flEnd, flStep do
						local vCover = vStart + vDirection * flCurrent + vOff

						if util_TraceHull( {
							start = vCover,
							endpos = vCover,
							mins = vMins,
							maxs = vMaxs,
							filter = self
						} ).Hit then continue end

						// Supply it with vMaxs because we have, in fact, precomputed them
						if !MyTable.IsValidCoverPoint( self, vCover, tCover, pEnemy, pEnemyPath, MyTable, vMaxs ) then continue end

						if tAllies then
							local b
							for pAlly in pairs( tAllies ) do
								if self == pAlly then continue end
								if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vCover ) <= flTakenDistSqr || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vCover ) <= flTakenDistSqr then b = true break end
							end
							if b then continue end
						end

						MyTable.vCover = vCover
						MyTable.tCover = tCover

						sched.bBeganSearching = nil

						return true
					end
					coroutine.yield()
				end
				coroutine.yield()
			end
		end )
		return
	end

	MyTable.vActualCover = vCover

	local pPath = sched.pPath
	if !pPath then pPath = Path "Follow" sched.pPath = pPath end

	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputePath( self, pPath, vCover ) end

	if LevelOfDetail( sched, "flNextEnemyPath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy ) end

	if LevelOfDetail( sched, "flNextCheck" ) && ( !MyTable.IsValidCoverCandidate( self, tCover, pEnemyPath, MyTable ) || !MyTable.IsValidCoverPoint( self, vCover, tCover, pEnemy, pEnemyPath, MyTable ) ) then
		MyTable.vCover = nil
		MyTable.tCover = nil
		// Purge the schedule instead of trying to search with this one again
		MyTable.SetSchedule( self, MyTable.CanExpose( self, MyTable ) && "FreeMovementStand" || "TakeCover", MyTable )
		return
	end

	local f = MyTable.flPathTolerance
	if self:GetPos():DistToSqr( vCover ) <= ( f * f ) then return true end

	local iClip = MyTable.GetWeaponClipPrimary( self, MyTable )
	if iClip != -1 && iClip <= 0 then MyTable.WeaponReload( self, MyTable ) end

	// TODO: This is a gross oversimplification.
	// Actors should be able to suppress too.
	// Original old suppression code is bullshit.
	// But I am too lazy to rewrite it.
	// So yeah. Shit.
	local bShoot

	local v = pEnemy:GetPos() + pEnemy:OBBCenter()
	local tr = util.TraceLine {
		start = MyTable.GetShootPos( self, MyTable ),
		endpos = v,
		mask = MASK_SHOT_HULL,
		filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
	}

	if !tr.Hit then
		MyTable.MoveAlongPath( self, pPath, MyTable.flJogSpeed, 1 )
		MyTable.CenterTarget( self, v, MyTable )
		if MyTable.CanAttackHelper( self, pEnemy, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
	else
		local pGoal = pPath:GetCurrentGoal()
		if pGoal then
			MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			if bEnemyValid then MyTable.ModifyMoveAimVector( self, MyTable.vaAimTargetBody, MyTable.flTopSpeed, 1 ) end
		end
		MyTable.MoveAlongPath( self, pPath, bEnemyValid && MyTable.flTopSpeed || MyTable.flJogSpeed, 1 )
	end
end } )
