// PULL DAT GAH DAM THING!!!

// The alarm we are trying to pull
ENT.tPreScheduleResetVariables.pAlarm = false

RegisterSchedule( "PullAlarm", { Execute = function( self, sched, MyTable )
	local pEnemy = MyTable.Enemy
	local bEnemyValid = IsValid( pEnemy )

	MyTable.WEAPON_STANCE = bEnemyValid && MyTable.Moving_WEAPON_STANCE || WEAPON_STANCE_PASSIVE

	if Either( sched.bOff, !table.IsEmpty( MyTable.tEnemies ), table.IsEmpty( MyTable.tEnemies ) ) then return false end

	if !MyTable.CanExpose( self, MyTable ) then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end

	local pAlarm = sched.pAlarm
	if !IsValid( pAlarm ) then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end

	if !pAlarm.__ALARM__ || Either( sched.bOff, !pAlarm.bIsOn, pAlarm.bIsOn ) then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end

	local iAlarmClass = pAlarm:Classify()
	if iAlarmClass != CLASS_NONE && iAlarmClass != self:Classify() then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end

	local pPath = sched.pPath
	if !pPath then pPath = Path "Follow" sched.pPath = pPath end

	local vAlarm = pAlarm:GetPos()

	if LevelOfDetail( sched, "flNextPath" ) then
		local _, b = MyTable.ComputePath( self, pPath, vAlarm )
		if b == false then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end // NOT !b
	end

	local v = MyTable.GetShootPos( self )
	local f = MyTable.GAME_flReach
	if v:DistToSqr( pAlarm:NearestPoint( v ) ) <= ( f * f ) then
		if sched.bOff then pAlarm:TurnOff( self )
		else pAlarm:TurnOn( self ) end
		return true
	else
		MyTable.pAlarm = sched.pAlarm

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
			filter = SimpleRelatedFilterDoubleTriple( self, pEnemy, pTrueEnemy )
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
	end
end } )
