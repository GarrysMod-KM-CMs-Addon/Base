ENT.flIdleStandTimeMin = 0
ENT.flIdleStandTimeMax = 4

// TODO: Excretion stations, and not voiding on ally territory

local function fGetIdleContinuousRate( MyTable )
	local flAmount = MyTable.LAT_flAmount
	local flFloor = MyTable.LAT_flManifoldFloor
	local flCrit = MyTable:LAT_GetCritical()

	if flAmount < flFloor then return 0 end
	if flAmount >= flCrit then return 999 end

	local flRatio = ( flAmount - flFloor ) / ( flCrit - flFloor )
	return .004 + .196 * ( flRatio ^ 1.25 )
end

// Voids nearly everything since nothing is interrupting it
local function fCalcIdleVoid( MyTable )
	local flAmount = MyTable.LAT_flAmount

	if flAmount >= MyTable.LAT_flSize * .68 && math.random() < .85 then return flAmount end

	local flResidual = flAmount < 18 && math.Rand( .5, 1.1 ) || ( MyTable.LAT_flResidualMin * math.Rand( .65, 1.0 ) )
	local flVoidable = math.max( 0, flAmount - flResidual )
	local flVoidFraction = math.Rand( .88, .98 )

	return math.min( flVoidable * flVoidFraction, flAmount )
end

local function fIdleExcrete( self, MyTable )
	local flVoidAmount = fCalcIdleVoid( MyTable )

	if MyTable.Moo then MyTable.Moo( self, MyTable ) end

	MyTable.NormalExcrete( self, flVoidAmount, MyTable, function()
		MyTable.vaAimTargetPose = nil
	end )
end

local function fIdleExcrete( self, MyTable )
	local flVoidAmount = fCalcIdleVoid( MyTable )

	MyTable.TauntExcrete( self, flVoidAmount, MyTable, function()
		MyTable.vaAimTargetPose = nil
	end )
end

RegisterSchedule( "Idle", { Execute = function( self, pSchedule, MyTable )
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

	if MyTable.LAT_flAmount && math.random() <= fGetIdleContinuousRate( MyTable ) * MyTable.m_flFrameTime then
		fIdleExcrete( self, MyTable )
		return
	end

	if CurTime() <= ( pSchedule.flStandTime || 0 ) then
		MyTable.vaAimTargetBody = nil
		MyTable.vaAimTargetPose = nil
		pSchedule.pPath = nil
		pSchedule.vGoal = nil
		MyTable.Stand( self )
		return
	end

	if !pSchedule.vGoal then
		local tAllies = MyTable:GetAlliesByClass()

		if !MyTable.bCantUse then
			local flAlarm, vPos, pAlarm = math.huge, MyTable.GetShootPos( self ), NULL // NULL because ent.pAlarm ( if nil ) == pAlarm ( which is nil )
			local t = __ALARMS__[ MyTable.Classify( self, MyTable ) ]
			if t then
				for ent in pairs( t ) do
					if !IsValid( ent ) || !ent.bIsOn then continue end
					local d = ent:NearestPoint( vPos ):DistToSqr( vPos )
					if d >= flAlarm then continue end
					local b
					if tAllies then
						for pAlly in pairs( tAllies ) do
							if !IsValid( pAlly ) || pAlly == self then continue end
							local pSchedule = pAlly.Schedule
							if pSchedule && pSchedule.pAlarm == pAlarm then b = true break end
						end
					end
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
					if tAllies then
						for pAlly in pairs( tAllies ) do
							if !IsValid( pAlly ) || pAlly == self then continue end
							local pSchedule = pAlly.Schedule
							if pSchedule && pSchedule.pAlarm == pAlarm then b = true break end
						end
					end
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
			pSchedule.flStandTime = CurTime() + math.Rand( MyTable.flIdleStandTimeMin, MyTable.flIdleStandTimeMax )

			MyTable.vaAimTargetBody = nil
			MyTable.vaAimTargetPose = nil

			pSchedule.Path = nil
			pSchedule.vGoal = nil

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

		if vec then pSchedule.vGoal = vec
		else pSchedule.flStandTime = CurTime() + math.Rand( MyTable.flIdleStandTimeMin, MyTable.flIdleStandTimeMax ) return end
	end

	local pPath = pSchedule.pPath
	if !pPath then
		pPath = Path "Follow"
		pSchedule.pPath = pPath
	end

	local pGoal = pPath:GetCurrentGoal()
	if pGoal then
		MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	end

	if LevelOfDetail( pSchedule, "flNextPath" ) then MyTable.ComputePath( self, pPath, pSchedule.vGoal ) end

	MyTable.MoveAlongPath( self, pPath, MyTable.flWalkSpeed )

	if math.abs( pPath:GetCursorPosition() - pPath:GetLength() ) <= MyTable.flPathTolerance then
		pSchedule.flStandTime = CurTime() + math.Rand( MyTable.flIdleStandTimeMin, MyTable.flIdleStandTimeMax )

		MyTable.vaAimTargetBody = nil
		MyTable.vaAimTargetPose = nil

		pSchedule.pPath = nil
		pSchedule.vGoal = nil
	end
end } )
