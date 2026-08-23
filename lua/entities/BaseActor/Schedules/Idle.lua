ENT.flIdleStandTimeMin = 0
ENT.flIdleStandTimeMax = 4

RegisterSchedule( "Idle", { Execute = function( self, sched, MyTable )
	if !table.IsEmpty( MyTable.tEnemies ) then return false end

	MyTable.WEAPON_STANCE = WEAPON_STANCE_PASSIVE

	if CurTime() > MyTable.flWeaponReloadTime then
		local t, i = {}, 0

		for wep in pairs( MyTable.tWeapons ) do
			if !wep.bNoReloads && wep:Clip1() < wep:GetMaxClip1() then
				table.insert( t, wep )
				i = i + 1
			end
		end

		if !table.IsEmpty( t ) then
			MyTable.SetActiveWeapon( self, t[ math.random( i ) ], MyTable )
			MyTable.WeaponReload( self, MyTable )
		end
	end

	if CurTime() <= ( sched.flStandTime || 0 ) then
		MyTable.vaAimTargetBody = nil
		MyTable.vaAimTargetPose = nil
		sched.pPath = nil
		sched.vGoal = nil
		MyTable.Stand( self )
		return
	end

	if !sched.vGoal then
		local tAllies = MyTable.GetAlliesByClass( self, MyTable )

		if !MyTable.bCantUse then
			local flAlarm, vPos, pAlarm = math.huge, MyTable.GetShootPos( self ), NULL // NULL because ent.pAlarm ( if nil ) == pAlarm ( which is nil )
			local t = __ALARMS__[ MyTable.Classify( self, MyTable ) ]
			if t then
				for ent in pairs( t ) do
					if !IsValid( ent ) || !ent.bIsOn then continue end
					local d = ent:NearestPoint( vPos ):DistToSqr( vPos )
					if d >= flAlarm then continue end
					local b
					if tAllies then for ent in pairs( tAllies ) do if ent != self && ent.pAlarm == pAlarm then b = true break end end end
					if b then continue end
					pAlarm, flAlarm = ent, d
				end
			end

			if IsValid( pAlarm ) then
				local s = MyTable.SetSchedule( self, "PullAlarm", MyTable )
				s.bOff = true
				s.pAlarm = pAlarm
				return
			end

			t = __ALARMS__[ CLASS_NONE ]
			if t then
				for ent in pairs( t ) do
					if !IsValid( ent ) || !ent.bIsOn then continue end
					local d = ent:NearestPoint( vPos ):DistToSqr( vPos )
					if d >= flAlarm || Either( ent.flAudibleDistSqr == 0, self:Visible( ent ), d >= ent.flAudibleDistSqr ) then continue end
					local b
					if tAllies then for ent in pairs( tAllies ) do if ent != self && ent.pAlarm == pAlarm then b = true break end end end
					if b then continue end
					pAlarm, flAlarm = ent, d
				end
			end

			if IsValid( pAlarm ) then
				local s = MyTable.SetSchedule( self, "PullAlarm", MyTable )
				s.bOff = true
				s.pAlarm = pAlarm
				return
			end
		end

		local pArea, vec = self:GetLastKnownArea() || navmesh.GetNearestNavArea( self:GetPos() )
		if !pArea then
			sched.flStandTime = CurTime() + math.Rand( MyTable.flIdleStandTimeMin, MyTable.flIdleStandTimeMax )

			MyTable.vaAimTargetBody = nil
			MyTable.vaAimTargetPose = nil

			sched.Path = nil
			sched.vGoal = nil

			return
		end

		local tQueue, tVisited, flDistSqr = { { pArea, 0 } }, {}, math.Rand( 0, 1024 )
		flDistSqr = flDistSqr * flDistSqr
		local bDisAllowWater = MyTable.bHasOxygen
		while !table.IsEmpty( tQueue ) do
			local pArea, flDistance = unpack( table.remove( tQueue ) )
			for _, t in ipairs( pArea:GetAdjacentAreaDistances() ) do
				local pNew = t.area
				if tVisited[ pNew:GetID() ] then continue end
				if bDisAllowWater && pArea:IsUnderwater() then continue end
				table.insert( tQueue, { pNew, flDistance + t.dist } )
				tVisited[ pNew:GetID() ] = true
			end
			table.SortByMember( tQueue, 2 )
			vec = pArea:GetRandomPoint()
			if vec:DistToSqr( self:GetPos() ) >= flDistSqr then break end
		end

		if vec then sched.vGoal = vec
		else sched.flStandTime = CurTime() + math.Rand( MyTable.flIdleStandTimeMin, MyTable.flIdleStandTimeMax ) return end
	end

	local pPath = sched.pPath
	if !pPath then
		pPath = Path "Follow"
		sched.pPath = pPath
	end

	local pGoal = pPath:GetCurrentGoal()
	if pGoal then
		MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	end

	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputePath( self, pPath, sched.vGoal ) end

	MyTable.MoveAlongPath( self, pPath, MyTable.flWalkSpeed )

	if math.abs( pPath:GetCursorPosition() - pPath:GetLength() ) <= MyTable.flPathTolerance then
		sched.flStandTime = CurTime() + math.Rand( MyTable.flIdleStandTimeMin, MyTable.flIdleStandTimeMax )

		MyTable.vaAimTargetBody = nil
		MyTable.vaAimTargetPose = nil

		sched.pPath = nil
		sched.vGoal = nil
	end
end } )
