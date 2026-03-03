function ENT:GetStartleSoundTime( sName, flLevel )
	local t = self.tSoundHarmless[ sName ]
	return flLevel * 16 / self:GetStartleSoundLevel( sName ) / self.flBoldness / math.max( 1, t && t[ 1 ] || 1 )
end

function ENT:DLG_Startled() end

Actor_RegisterSchedule( "StartleNoise", function( self, sched )
	if !table.IsEmpty( self.tEnemies ) then return {} end
	if !sched.bDidNoise then
		self:DLG_Startled()
		sched.bDidNoise = true
	end
	// THIS NEEDS MORE VALIDATION!
	if !sched.flTime then
		local f = self:GetStartleSoundTime( sched.tData.SoundName, sched.tData.SoundLevel )
		sched.flTime = CurTime() + math.Rand( f * .9, f * 1.1 )
	end
	if !sched.bSoundWasNotHarmless then
		local t = self.tSoundHarmless[ sched.tData.SoundName ]
		if sched.tData.Volume <= .33 || sched.tData.SoundLevel <= self:GetStartleSoundLevel( sched.tData.SoundName, sched.tData.SoundLevel ) then
			local t = self.tSoundHarmless[ sched.tData.SoundName ]
			self.tSoundHarmless[ sched.tData.SoundName ] = { ( t && t[ 1 ] || 0 ) + 1 * sched.flConsecutiveSounds, {} /* TODO: Safe emitters */ }
			return true
		end
	end
	if CurTime() > sched.flTime then
		if !sched.bSoundWasNotHarmless then
			local t = self.tSoundHarmless[ sched.tData.SoundName ]
			self.tSoundHarmless[ sched.tData.SoundName ] = { ( t && t[ 1 ] || 0 ) + 1 * sched.flConsecutiveSounds, {} /* TODO: Safe emitters */ }
		end
		return true
	end
	if !sched.vGoal then
		local tAllies = self:GetAlliesByClass()
		local area, vec = self:GetLastKnownArea() || navmesh.GetNearestNavArea( self:GetPos() )
		if !area then
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
		if vec then sched.vGoal = vec else
			sched.Path = nil
			sched.vGoal = nil
			return
		end
	end
	if !sched.vGoal then return end
	if !sched.Path then sched.Path = Path "Follow" end
	local goal = sched.Path:GetCurrentGoal()
	if goal then self.vaAimTargetBody = ( goal.pos - self:GetPos() ):Angle() self.vaAimTargetPose = self.vaAimTargetBody end
	self:ComputePath( sched.Path, sched.vGoal )
	self:MoveAlongPath( sched.Path, self.flTopSpeed )
	if math.abs( sched.Path:GetCursorPosition() - sched.Path:GetLength() ) <= self.flPathTolerance then
		self.vaAimTargetBody = nil
		self.vaAimTargetPose = nil
		sched.Path = nil
		sched.vGoal = nil
	end
end )
