// PULL DAT GAH DAM THING!!!

// The alarm we are trying to pull
ENT.tPreScheduleResetVariables.pAlarm = false

Actor_RegisterSchedule( "PullAlarm", function( self, sched )
	if Either( sched.bOff, !table.IsEmpty( self.tEnemies ), table.IsEmpty( self.tEnemies ) ) then return {} end
	if !self:CanExpose() then self:SetSchedule "TakeCover" return end
	local pAlarm = sched.pAlarm
	if !IsValid( pAlarm ) then self:SetSchedule "TakeCover" return end
	if !pAlarm.__ALARM__ || Either( sched.bOff, !pAlarm.bIsOn, pAlarm.bIsOn ) then self:SetSchedule "TakeCover" return end
	local iAlarmClass = pAlarm:Classify()
	if iAlarmClass != CLASS_NONE && iAlarmClass != self:Classify() then self:SetSchedule "TakeCover" return end
	if !sched.Path then sched.Path = Path "Follow" end
	local vAlarm = pAlarm:GetPos()
	local _, b = self:ComputePath( sched.Path, vAlarm )
	if b == false then self:SetSchedule "TakeCover" return end // NOT !b
	local v = self:GetShootPos()
	local f = self.GAME_flReach
	if v:DistToSqr( pAlarm:NearestPoint( v ) ) <= ( f * f ) then
		if sched.bOff then pAlarm:TurnOff( self )
		else pAlarm:TurnOn( self ) end
		return {}
	else
		self.pAlarm = sched.pAlarm
		local tNearestEnemies = {}
		for ent in pairs( self.tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
		table.SortByMember( tNearestEnemies, 2, true )
		local tAllies, pEnemy = self:GetAlliesByClass()
		for _, d in ipairs( tNearestEnemies ) do
			local ent = d[ 1 ]
			local v = ent:GetPos() + ent:OBBCenter()
			local tr = util.TraceLine {
				start = self:GetShootPos(),
				endpos = v,
				mask = MASK_SHOT_HULL,
				filter = { self, ent }
			}
			if !tr.Hit || tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( v ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
				local b = true
				if ent.GAME_tSuppressionAmount then
					local flThreshold, flSoFar = ent:Health() * .1, 0
					for other, am in pairs( ent.GAME_tSuppressionAmount ) do
						if other == self || self:Disposition( other ) != D_LI then continue end
						flSoFar = flSoFar + am
						if flSoFar > flThreshold then continue end
					end
					if flSoFar > flThreshold then continue end
				end
				if b then
					self.vaAimTargetBody = ent:GetPos() + ent:OBBCenter()
					self.vaAimTargetPose = self.vaAimTargetBody
					pEnemy = ent
					if self:CanAttackHelper( ent ) then self:RangeAttack() end
					break
				end
			end
		end
		if IsValid( pEnemy ) then self:MoveAlongPath( sched.Path, self.flRunSpeed, 1 ) else
			local goal = sched.Path:GetCurrentGoal()
			if goal then
				self.vaAimTargetBody = ( goal.pos - self:GetPos() ):Angle()
				self.vaAimTargetPose = self.vaAimTargetBody
				self:ModifyMoveAimVector( self.vaAimTargetBody, self.flTopSpeed, 1 )
			end
			self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
		end
	end
end )
