local insert = table.insert
local SortByMember = table.SortByMember
local DistanceToLine = util.DistanceToLine
local table_IsEmpty = table.IsEmpty
local IsValid = IsValid
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull

local math_max = math.max

function ENT:FreeMovementCoverHealth( MyTable ) return self:Health() * ( math_max( MyTable.flCombatState, 0 ) * 2 + 2 ) end

// This is intentionally short.
// You are almost never going to FreeMovement to suppress!
ENT.flFreeMovementSuppressTimeMin = 0
ENT.flFreeMovementSuppressTimeMax = 4

// Poor mercs are so ADHD feat. Filian that they can't stand still for like five minutes
// Better than being autistic
ENT.flFreeMovementStandTimeMin = 0
ENT.flFreeMovementStandTimeMax = 4

// TODO: If the enemy left, do the following.
// If we can see them in hold fire, look around confused and tell everyone to search.
// If we can see them in combat, instantly transition to hold fire.
RegisterSchedule( "FreeMovementStand", { Execute = function( self, sched, MyTable )
	MyTable.vCover = nil
	MyTable.tCover = nil

	local tEnemies = MyTable.tEnemies
	if table_IsEmpty( tEnemies ) then return true end

	if MyTable.flCombatState < 0 || MyTable.GAME_flSuppression > MyTable.FreeMovementCoverHealth( self, MyTable ) then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	if LevelOfDetail( sched, "flNextHoldFireCheckTime" ) then if !MyTable.bHoldFire && CurTime() > ( MyTable.flLastEnemy + MyTable.flHoldFireTime ) then MyTable.DLG_HoldFire( self, MyTable ) end end

	local c = MyTable.GetWeaponClipPrimary( self, MyTable )
	if c != -1 && c <= 0 then MyTable.WeaponReload( self, MyTable ) end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		sched.pEnemyPath = pEnemyPath
	end

	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )
	if MyTable.UpdatePursuitSenses( self, pEnemy, pTrueEnemy, MyTable ) then
		MyTable.SetSchedule( self, "FreeMovementPursuit", MyTable )
		return
	end

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
		// TODO: Ignore this if we are the last guy suppressing and our allies need cover
		local flTime = sched.flShootTime
		if !flTime then
			flTime = CurTime() + math.Rand( MyTable.flFreeMovementSuppressTimeMin, MyTable.flFreeMovementSuppressTimeMax )
			sched.flShootTime = flTime
		end

		if CurTime() > flTime then
			local pSchedule = MyTable.SetSchedule( self, "FreeMovementPressure", MyTable )
			pSchedule.vMyStart = sched.vMyStart
			pSchedule.vMyEnd = sched.vMyEnd
			pSchedule.bGotALineOfSightBefore = true
			return
		end

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

		sched.flSuppressTime = CurTime() + math.Rand( MyTable.flShootTimeMin, MyTable.flShootTimeMax ) * .5

		sched.bGotALineOfSightBefore = true

		if !trStandToCenter.Hit && !trDuckToCenter.Hit then
			if CurTime() > ( sched.flNextDuck || 0 ) then
				sched.bDuck = math.random() <= .5
				sched.flNextDuck = CurTime() + math.Rand( 0, 8 )
			end
			MyTable.Stand( self, sched.bDuck && 0 || 1, MyTable )
		else MyTable.Stand( self, trStandToCenter.Hit && 0 || 1, MyTable ) end

		MyTable.vaAimTargetBody = pEnemy:GetPos() + pEnemy:OBBCenter()
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

		// TODO
		/*if MyTable.m_bHadSmokesLast && MyTable.GAME_flSuppression > 0 && LevelOfDetail( sched, "flNextSmoke" ) then
			local vShoot = self:GetShootPos()
			local vSmokeTarget = ( vEnemyCenter - vShoot ):GetNormalized() * math.min( MyTable.GAME_flThrowForce, math.Rand( 0, self:BoundingRadius() * 10 ) )
			vSmokeTarget[ 3 ] = vShoot[ 3 ]
		end*/
		return
	end

	if sched.bGotALineOfSightBefore then
		local pSchedule = MyTable.SetSchedule( self, "FreeMovementSearch", MyTable )
		pSchedule.vMyStart = sched.vMyStart
		pSchedule.vMyEnd = sched.vMyEnd
		pSchedule.bGotALineOfSightBefore = true
		return
	end

	local pPath = MyTable.pEnemyPath
	if !pPath then
		pPath = Path "Follow"
		MyTable.ComputeFlankPath( self, pPath, pEnemy, MyTable )
		MyTable.pEnemyPath = pPath
	end

	local flDistSqr = math.max( 512, math.Remap( vPos:Distance( pEnemy:GetPos() ), 0, 4096, 512, 1024 ) ) / MyTable.flCombatState
	flDistSqr = flDistSqr * flDistSqr
	local vSuppressionPoint = sched.vSuppressionPoint
	// TODO: Validate the point, duh xD
	if vSuppressionPoint then
		// TODO: Ignore this if we are the last guy suppressing and our allies need cover
		local flTime = sched.flSuppressTime
		if !flTime then
			flTime = CurTime() + math.Rand( MyTable.flFreeMovementSuppressTimeMin, MyTable.flFreeMovementSuppressTimeMax )
			sched.flSuppressTime = flTime
		end

		if CurTime() > flTime then
			local pSchedule = MyTable.SetSchedule( self, "FreeMovementSearch", MyTable )
			pSchedule.vMyStart = sched.vMyStart
			pSchedule.vMyEnd = sched.vMyEnd
			pSchedule.bGotALineOfSightBefore = true
			return
		end
	
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

		local pSchedule = MyTable.SetSchedule( self, "FreeMovementSearch", MyTable )
		pSchedule.vMyStart = sched.vMyStart
		pSchedule.vMyEnd = sched.vMyEnd
	end
end } )

RegisterSchedule( "FreeMovementMove", { Execute = function( self, sched, MyTable )
	MyTable.vCover = nil
	MyTable.tCover = nil

	local tEnemies = MyTable.tEnemies
	if table_IsEmpty( tEnemies ) then return true end

	if MyTable.flCombatState < 0 || MyTable.GAME_flSuppression > MyTable.FreeMovementCoverHealth( self, MyTable ) then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	if LevelOfDetail( sched, "flNextHoldFireCheckTime" ) then if !MyTable.bHoldFire && CurTime() > ( MyTable.flLastEnemy + MyTable.flHoldFireTime ) then MyTable.DLG_HoldFire( self, MyTable ) end end

	local c = MyTable.GetWeaponClipPrimary( self, MyTable )
	if c != -1 && c <= 0 then MyTable.WeaponReload( self, MyTable ) end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then pEnemyPath = Path "Follow" sched.pEnemyPath = pEnemyPath end

	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end

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
	if self:GetPos():DistToSqr( vPoint ) <= ( f * f ) then
		sched.vPoint = nil
		local pSchedule = MyTable.SetSchedule( self, "FreeMovementStand", MyTable )
		pSchedule.vMyStart = sched.vMyStart
		pSchedule.vMyEnd = sched.vMyEnd
		pSchedule.bGotALineOfSightBefore = sched.bGotALineOfSightBefore
		return
	end

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
			local pSchedule = MyTable.SetSchedule( self, "FreeMovementStand", MyTable )
			pSchedule.bGotALineOfSightBefore = true
			pSchedule.vMyStart = sched.vMyStart
			pSchedule.vMyEnd = sched.vMyEnd
			return
		end

		MyTable.MoveAlongPath( self, pPath, MyTable.flJogSpeed, trStandToCenter.Hit && 0 || 1 )

		local vTarget = pEnemy:GetPos() + pEnemy:OBBCenter()
		MyTable.CenterTarget( self, vTarget, MyTable )

		local pWeapon = MyTable.Weapon
		if !IsValid( pWeapon ) then return false end

		local flRecoil = pWeapon.flRecoil
		if flRecoil then
			local flDistance = MyTable.GetShootPos( self, MyTable ):Distance( vTarget )
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
	end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable )
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

		MyTable.MoveAlongPath( self, pPath, MyTable.flJogSpeed, trStandToCenter.Hit && 0 || 1 )
		MyTable.CenterTarget( self, vSuppressionPoint, MyTable )

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
			end
		end
	end
end } )

// TODO: This should ideally find a point in front of the hostile and go there
// when not chasing anymore, not just go straight at them, but whatever
RegisterSchedule( "FreeMovementPursuit", { Execute = function( self, sched, MyTable )
	MyTable.vCover = nil
	MyTable.tCover = nil

	local tEnemies = MyTable.tEnemies
	if table_IsEmpty( tEnemies ) then return true end

	if MyTable.flCombatState < 0 || MyTable.GAME_flSuppression > MyTable.FreeMovementCoverHealth( self, MyTable ) then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	if LevelOfDetail( sched, "flNextHoldFireCheckTime" ) then if !MyTable.bHoldFire && CurTime() > ( MyTable.flLastEnemy + MyTable.flHoldFireTime ) then MyTable.DLG_HoldFire( self, MyTable ) end end

	local iClip = MyTable.GetWeaponClipPrimary( self, MyTable )
	if iClip != -1 && iClip <= 0 then MyTable.WeaponReload( self, MyTable ) end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable )
		MyTable.pEnemyPath = pEnemyPath
	end

	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )

	if !MyTable.UpdatePursuitSenses( self, pEnemy, pTrueEnemy, MyTable ) then
		MyTable.SetSchedule( self, "FreeMovementSearch", MyTable ).bGotALineOfSightBefore = true
		return
	end

	local tFilter = pEnemy == pTrueEnemy && SimpleRelatedFilterDouble( self, pEnemy ) || SimpleRelatedFilterTriple( self, pEnemy, pTrueEnemy )

	MyTable.WEAPON_STANCE = MyTable.Moving_WEAPON_STANCE

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )

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
		MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flJogSpeed, trStandToCenter.Hit && 0 || 1 )

		local vTarget = pEnemy:GetPos() + pEnemy:OBBCenter()
		MyTable.CenterTarget( self, vTarget, MyTable )

		local pWeapon = MyTable.Weapon
		if !IsValid( pWeapon ) then return false end

		local flRecoil = pWeapon.flRecoil
		if flRecoil then
			local flDistance = MyTable.GetShootPos( self, MyTable ):Distance( vTarget )
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
		MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flJogSpeed, trStandToCenter.Hit && 0 || 1 )
		MyTable.CenterTarget( self, vSuppressionPoint, MyTable )
		local pWeapon = MyTable.Weapon
		if !IsValid( pWeapon ) then return false end
		if MyTable.CanAttackHelper( self, vSuppressionPoint, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
	else
		MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flTopSpeed )
		local tGoal = pEnemyPath:GetCurrentGoal()
		if tGoal then
			MyTable.vaAimTargetBody = ( tGoal.pos - self:GetPos() ):Angle()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			MyTable.ModifyMoveAimVector( self, MyTable.vaAimTargetBody, MyTable.flTopSpeed, 1, MyTable )
		end
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
			end
		end
	end
end } )

// TODO: If we didn't have a LoS before, don't go for one! Suppress instead!
RegisterSchedule( "FreeMovementSearch", { Execute = function( self, sched, MyTable )
	MyTable.vCover = nil
	MyTable.tCover = nil

	local tEnemies = MyTable.tEnemies
	if table_IsEmpty( tEnemies ) then return true end

	if MyTable.flCombatState < 0 || MyTable.GAME_flSuppression > MyTable.FreeMovementCoverHealth( self, MyTable ) then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	if LevelOfDetail( sched, "flNextHoldFireCheckTime" ) then if !MyTable.bHoldFire && CurTime() > ( MyTable.flLastEnemy + MyTable.flHoldFireTime ) then MyTable.DLG_HoldFire( self, MyTable ) end end

	local iClip = MyTable.GetWeaponClipPrimary( self, MyTable )
	if iClip != -1 && iClip <= 0 then MyTable.WeaponReload( self, MyTable ) end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then pEnemyPath = Path "Follow" sched.pEnemyPath = pEnemyPath end
	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )
	local tFilter = pEnemy == pTrueEnemy && SimpleRelatedFilterDouble( self, pEnemy ) || SimpleRelatedFilterTriple( self, pEnemy, pTrueEnemy )

	if sched.bBeganSearching then return end
	sched.bBeganSearching = true

	local vEnemy = pEnemy:GetPos()
	local vTarget = vEnemy + pEnemy:OBBCenter()

	ACTOR_QUEUE( function()
		if !IsValid( self ) || !IsValid( pEnemy ) || MyTable.Schedule != sched then return true end

		local pIterator = MyTable.SearchNodes( self, nil, function( vNew, flCurrentDistance, flAdditionalDistance )
			pEnemyPath:MoveCursorToClosestPosition( vNew )
			return flCurrentDistance + flAdditionalDistance - pEnemyPath:GetCursorPosition() + pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ):Distance( vNew )
		end )

		pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )

		local tVisited = {}

		local vSimpleOffset = Vector( 0, 0, 12 )
		local vDuckOffset = Vector( 0, 0, MyTable.GetViewOffsetDucked( self, MyTable ) )
		local vStandOffset = Vector( 0, 0, MyTable.GetViewOffset( self, MyTable ) )

		local tAllies = MyTable.GetAlliesByClass( self, MyTable )

		local vMaxs = MyTable.vHullDuckMaxs || MyTable.vHullMaxs

		local vMins = Vector( MyTable.vHullDuckMins || MyTable.vHullMins )
		vMins[ 3 ] = vMins[ 3 ] + vMaxs[ 3 ] * .2

		local flTakenDistSqr = self:BoundingRadius()
		flTakenDistSqr = flTakenDistSqr * flTakenDistSqr

		local tCovers

		while true do
			if !IsValid( self ) || !IsValid( pEnemy ) || MyTable.Schedule != sched then return true end
			local vEnemy = pEnemy:GetPos()
			local vTarget = vEnemy + pEnemy:OBBCenter()
			local vPoint, pArea = pIterator()
			if vPoint == nil then sched.bBeganSearching = nil return true end

			local pPath = MyTable.pEnemyPath
			if !pPath then
				pPath = Path "Follow"
				MyTable.ComputeFlankPath( self, pPath, pEnemy, MyTable )
				MyTable.pEnemyPath = pPath
			end

			if !IsValid( self ) || !IsValid( pEnemy ) || MyTable.Schedule != sched then return true end

			if util_TraceLine( {
				start = vPoint + vSimpleOffset,
				endpos = vPoint + vDuckOffset,
				mask = MASK_SOLID,
				filter = tFilter
			} ).Hit then continue end
			local vPointDuck = vPoint + vDuckOffset
			local vPointStand = vPoint + vStandOffset
			if !( util_TraceLine( {
				start = vPointDuck,
				endpos = vTarget,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit || util_TraceLine( {
				start = vPointDuck,
				endpos = util_TraceLine( {
					start = vTarget,
					endpos = vTarget + ( vTarget - vPointDuck ):Angle():Right() * self:BoundingRadius(),
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).HitPos,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit || util_TraceLine( {
				start = vPointDuck,
				endpos = util_TraceLine( {
					start = vTarget,
					endpos = vTarget - ( vTarget - vPointDuck ):Angle():Right() * self:BoundingRadius(),
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).HitPos,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit ) || !( util_TraceLine( {
				start = vPointStand,
				endpos = vTarget,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit || util_TraceLine( {
				start = vPointStand,
				endpos = util_TraceLine( {
					start = vTarget,
					endpos = vTarget + ( vTarget - vPointStand ):Angle():Right() * self:BoundingRadius(),
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).HitPos,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit || util_TraceLine( {
				start = vPointStand,
				endpos = util_TraceLine( {
					start = vTarget,
					endpos = vTarget - ( vTarget - vPointStand ):Angle():Right() * self:BoundingRadius(),
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).HitPos,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit ) then
			//	if !util_TraceLine( {
			//		start = vPointDuck,
			//		endpos = vTarget,
			//		mask = MASK_SHOT_HULL,
			//		filter = tFilter
			//	} ).Hit || !util_TraceLine( {
			//		start = vPointStand,
			//		endpos = vTarget,
			//		mask = MASK_SHOT_HULL,
			//		filter = tFilter
			//	} ).Hit then
				local tAllies, b = MyTable.GetAlliesByClass( self, MyTable ) || {}, true
				for pAlly in pairs( tAllies ) do
					if self == pAlly then continue end
					if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vPoint ) <= flTakenDistSqr || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vPoint ) <= flTakenDistSqr then b = nil break end
				end
				if b then
					local pNew = MyTable.SetSchedule( self, "FreeMovementMove", MyTable )
					pNew.vPoint = vPoint
					pNew.vMyStart = vMyStart
					pNew.vMyEnd = vMyEnd
					pNew.bGotALineOfSightBefore = sched.bGotALineOfSightBefore
					MyTable.vActualTarget = vPoint
					return true
				end
			end
			coroutine.yield()
		end
	end )
end } )

RegisterSchedule( "FreeMovementPressure", { Execute = function( self, sched, MyTable )
	MyTable.vCover = nil
	MyTable.tCover = nil

	local tEnemies = MyTable.tEnemies
	if table_IsEmpty( tEnemies ) then return true end

	if MyTable.flCombatState < 0 || MyTable.GAME_flSuppression > MyTable.FreeMovementCoverHealth( self, MyTable ) then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	if LevelOfDetail( sched, "flNextHoldFireCheckTime" ) then if !MyTable.bHoldFire && CurTime() > ( MyTable.flLastEnemy + MyTable.flHoldFireTime ) then MyTable.DLG_HoldFire( self, MyTable ) end end

	local c = MyTable.GetWeaponClipPrimary( self, MyTable )
	if c != -1 && c <= 0 then MyTable.WeaponReload( self, MyTable ) end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then pEnemyPath = Path "Follow" sched.pEnemyPath = pEnemyPath end

	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )
	local tFilter = pEnemy == pTrueEnemy && SimpleRelatedFilterDouble( self, pEnemy ) || SimpleRelatedFilterTriple( self, pEnemy, pTrueEnemy )

	if sched.bBeganSearching then return end
	sched.bBeganSearching = true

	local vEnemy = pEnemy:GetPos()
	local vTarget = vEnemy + pEnemy:OBBCenter()
	ACTOR_QUEUE( function()
		if !IsValid( self ) || !IsValid( pEnemy ) || MyTable.Schedule != sched then return true end

		pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )

		local flCursor = pEnemyPath:GetCursorPosition()
		local flLength = pEnemyPath:GetLength()

		local pIterator = MyTable.SearchNodes( self,

			pEnemyPath:GetPositionOnPath( math.Clamp( Lerp( math.random(), flCursor, flLength ), flCursor, math.max( flCursor, flLength - self:BoundingRadius() * 5 ) ) ),

			function( vNew, flCurrentDistance, flAdditionalDistance )
			pEnemyPath:MoveCursorToClosestPosition( vNew )
			return flCurrentDistance + flAdditionalDistance - pEnemyPath:GetCursorPosition() + pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ):Distance( vNew )
		end )

		local tVisited = {}

		local vSimpleOffset = Vector( 0, 0, 12 )
		local vDuckOffset = Vector( 0, 0, MyTable.GetViewOffsetDucked( self, MyTable ) )
		local vStandOffset = Vector( 0, 0, MyTable.GetViewOffset( self, MyTable ) )

		local tAllies = MyTable.GetAlliesByClass( self, MyTable )

		local vMaxs = MyTable.vHullDuckMaxs || MyTable.vHullMaxs

		local vMins = Vector( MyTable.vHullDuckMins || MyTable.vHullMins )
		vMins[ 3 ] = vMins[ 3 ] + vMaxs[ 3 ] * .2

		local flTakenDistSqr = self:BoundingRadius()
		flTakenDistSqr = flTakenDistSqr * flTakenDistSqr

		local tCovers

		while true do
			if !IsValid( self ) || !IsValid( pEnemy ) || MyTable.Schedule != sched then return true end
			local vEnemy = pEnemy:GetPos()
			local vTarget = vEnemy + pEnemy:OBBCenter()
			local vPoint, pArea = pIterator()
			if vPoint == nil then sched.bBeganSearching = nil return true end

			local pPath = MyTable.pEnemyPath
			if !pPath then
				pPath = Path "Follow"
				MyTable.ComputeFlankPath( self, pPath, pEnemy, MyTable )
				MyTable.pEnemyPath = pPath
			end

			if util_TraceLine( {
				start = vPoint + vSimpleOffset,
				endpos = vPoint + vDuckOffset,
				mask = MASK_SOLID,
				filter = tFilter
			} ).Hit then continue end
			local vPointDuck = vPoint + vDuckOffset
			local vPointStand = vPoint + vStandOffset
			if !( util_TraceLine( {
				start = vPointDuck,
				endpos = vTarget,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit || util_TraceLine( {
				start = vPointDuck,
				endpos = util_TraceLine( {
					start = vTarget,
					endpos = vTarget + ( vTarget - vPointDuck ):Angle():Right() * self:BoundingRadius(),
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).HitPos,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit || util_TraceLine( {
				start = vPointDuck,
				endpos = util_TraceLine( {
					start = vTarget,
					endpos = vTarget - ( vTarget - vPointDuck ):Angle():Right() * self:BoundingRadius(),
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).HitPos,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit ) || !( util_TraceLine( {
				start = vPointStand,
				endpos = vTarget,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit || util_TraceLine( {
				start = vPointStand,
				endpos = util_TraceLine( {
					start = vTarget,
					endpos = vTarget + ( vTarget - vPointStand ):Angle():Right() * self:BoundingRadius(),
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).HitPos,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit || util_TraceLine( {
				start = vPointStand,
				endpos = util_TraceLine( {
					start = vTarget,
					endpos = vTarget - ( vTarget - vPointStand ):Angle():Right() * self:BoundingRadius(),
					mask = MASK_SHOT_HULL,
					filter = tFilter
				} ).HitPos,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			} ).Hit ) then
			//	if !util_TraceLine( {
			//		start = vPointDuck,
			//		endpos = vTarget,
			//		mask = MASK_SHOT_HULL,
			//		filter = tFilter
			//	} ).Hit || !util_TraceLine( {
			//		start = vPointStand,
			//		endpos = vTarget,
			//		mask = MASK_SHOT_HULL,
			//		filter = tFilter
			//	} ).Hit then
				local tAllies, b = MyTable.GetAlliesByClass( self, MyTable ) || {}, true
				for pAlly in pairs( tAllies ) do
					if self == pAlly then continue end
					if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vPoint ) <= flTakenDistSqr || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vPoint ) <= flTakenDistSqr then b = nil break end
				end
				if b then
					local pNew = MyTable.SetSchedule( self, "FreeMovementMove", MyTable )
					pNew.vPoint = vPoint
					pNew.vMyStart = vMyStart
					pNew.vMyEnd = vMyEnd
					pNew.bGotALineOfSightBefore = true
					MyTable.vActualTarget = vPoint
					return true
				end
			end
			coroutine.yield()
		end
	end )
end } )
