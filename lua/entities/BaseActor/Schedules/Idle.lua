ENT.flIdleStandTimeMin = 0
ENT.flIdleStandTimeMax = 4

RegisterSchedule( "Idle", { Execute = function( self, sched )
	if !table.IsEmpty( self.tEnemies ) then return false end
	self.WEAPON_STANCE = WEAPON_STANCE_PASSIVE
	if CurTime() > self.flWeaponReloadTime then
		local t = {}
		for wep in pairs( self.tWeapons ) do if !wep.bNoReloads && wep:Clip1() < wep:GetMaxClip1() then table.insert( t, wep ) end end
		if !table.IsEmpty( t ) then
			self:SetActiveWeapon( table.Random( t ) )
			self:WeaponReload()
		end
	end
	if CurTime() > ( sched.flStandTime || 0 ) then
		if !sched.vGoal then
			local tAllies = self:GetAlliesByClass()
			if !self.bCantUse then
				local flAlarm, vPos, pAlarm = math.huge, self:GetShootPos(), NULL // NULL because ent.pAlarm ( if nil ) == pAlarm ( which is nil )
				local t = __ALARMS__[ self:Classify() ]
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
					local s = self:SetSchedule "PullAlarm"
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
					local s = self:SetSchedule "PullAlarm"
					s.bOff = true
					s.pAlarm = pAlarm
					return
				end
			end
			local area, vec = self:GetLastKnownArea() || navmesh.GetNearestNavArea( self:GetPos() )
			if !area then
				sched.flStandTime = CurTime() + math.Rand( self.flIdleStandTimeMin, self.flIdleStandTimeMax )
				self.vaAimTargetBody = nil
				self.vaAimTargetPose = nil
				sched.Path = nil
				sched.vGoal = nil
				return
			end
			local tQueue, tVisited, flDistSqr = { { area, 0 } }, {}, math.Rand( 0, 1024 )
			flDistSqr = flDistSqr * flDistSqr
			local bDisAllowWater = !self.bCanSwim
			while !table.IsEmpty( tQueue ) do
				local area, dist = unpack( table.remove( tQueue ) )
				for _, t in ipairs( area:GetAdjacentAreaDistances() ) do
					local new = t.area
					if tVisited[ new:GetID() ] then continue end
					if bDisAllowWater && area:IsUnderwater() then continue end
					table.insert( tQueue, { new, dist + t.dist } )
					tVisited[ new:GetID() ] = true
				end
				table.SortByMember( tQueue, 2 )
				local v = area:GetRandomPoint()
				if v:DistToSqr( self:GetPos() ) >= flDistSqr then vec = v break end
			end
			if vec then sched.vGoal = vec else sched.flStandTime = CurTime() + math.Rand( 0, 4 ) return end
		end
		if !sched.Path then sched.Path = Path "Follow" end
		local goal = sched.Path:GetCurrentGoal()
		if goal then self.vaAimTargetBody = ( goal.pos - self:GetPos() ):Angle() self.vaAimTargetPose = self.vaAimTargetBody end
		self:ComputePath( sched.Path, sched.vGoal )
		self:MoveAlongPath( sched.Path, self.flWalkSpeed )
		if math.abs( sched.Path:GetCursorPosition() - sched.Path:GetLength() ) <= self.flPathTolerance then
			sched.flStandTime = CurTime() + math.Rand( self.flIdleStandTimeMin, self.flIdleStandTimeMax )
			self.vaAimTargetBody = nil
			self.vaAimTargetPose = nil
			sched.Path = nil
			sched.vGoal = nil
		end
	else self.vaAimTargetBody = nil self.vaAimTargetPose = nil sched.Path = nil sched.vGoal = nil self:Stand() end
end } )
