local util_TraceLine = util.TraceLine

Actor_RegisterSchedule( "TakeCoverMove", function( self, sched, MyTable )
	MyTable.WEAPON_STANCE = MyTable.Moving_WEAPON_STANCE
	local tEnemies = sched.tEnemies || self.tEnemies
	if table.IsEmpty( tEnemies ) then return {} end
	if MyTable.GAME_flSuppression > self:Health() * 4 then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end
	local enemy = sched.Enemy
	if !IsValid( enemy ) then enemy = self.Enemy if !IsValid( enemy ) then return false end end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	local c = self:GetWeaponClipPrimary()
	if c != -1 && c <= 0 then self:WeaponReload() end
	if !self.tCover then return false end
	local vec = self.vCover
	local tAllies = self:GetAlliesByClass()
	if tAllies then
		local f = self:BoundingRadius() * .25
		f = f * f
		for ally in pairs( tAllies ) do
			if self == ally then continue end
			if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= f || ally.vActualTarget && ally.vActualTarget:DistToSqr( vec ) <= f then self.vCover = nil self.pCover = nil self:SetSchedule "TakeCover" return end
		end
		local n = FrameTime()
		for pAlly in pairs( tAllies ) do
			local f = pAlly.flAdvanceTimes
			if f then pAlly.flAdvanceTimes = f + n end
		end
	end
	local vMaxs = self.vHullDuckMaxs || self.vHullMaxs
	local v = vec + Vector( 0, 0, MyTable.vHullDuckMaxs[ 3 ] )
	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end
	MyTable.ComputePath( self, pEnemyPath, enemy:GetPos(), MyTable )
	pEnemyPath:MoveCursorToClosestPosition( vec )
	local d = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() )
	pEnemyPath:MoveCursor( self:BoundingRadius() * MyTable.flPathStabilizer )
	d = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - d
	d[ 3 ] = 0
	d:Normalize()
	if d:IsZero() then d = enemy:GetPos() - vec d[ 3 ] = 0 d:Normalize() end
	if !util_TraceLine( {
		start = v,
		endpos = v + d * MyTable.vHullMaxs[ 1 ] * COVER_BOUND_SIZE,
		mask = MASK_SHOT_HULL,
		filter = self
	} ).Hit then
		MyTable.vCover = nil
		MyTable.tCover = nil
		MyTable.SetSchedule( self, MyTable.CanExpose( self, MyTable ) && "FreeMovementStand" || "TakeCover", MyTable )
		return
	end
	if !sched.Path then sched.Path = Path "Follow" end
	self:ComputePath( sched.Path, self.vCover )
	local v = self:GetPos() + Vector( 0, 0, vMaxs[ 3 ] )
	if util_TraceLine( {
		start = v,
		endpos = v + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
		filter = self
	} ).Hit then
		local f = self.flPathTolerance
		if self:GetPos():DistToSqr( vec ) <= ( f * f ) then return true end
	end
	local tNearestEnemies = {}
	for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
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
					if other == self || self:Disposition( other ) != D_LI || CurTime() <= ( other.flWeaponReloadTime || 0 ) then continue end
					flSoFar = flSoFar + am
					if flSoFar > flThreshold then continue end
				end
				if flSoFar > flThreshold then continue end
			else b = true end
			if b then
				MyTable.CenterTarget( self, ent:GetPos() + ent:OBBCenter(), MyTable )
				pEnemy = ent
				if self:CanAttackHelper( ent ) then self:RangeAttack() end
				break
			end
		end
	end
	if IsValid( pEnemy ) then
		if self.bCoverDuck == true then sched.bCoverStand = nil
		elseif sched.bCoverStand == nil then sched.bCoverStand = math.random( 2 ) == 1 end
		self:MoveAlongPath( sched.Path, self.flRunSpeed, 1 )
	else
		local goal = sched.Path:GetCurrentGoal()
		if goal then
			self.vaAimTargetBody = ( goal.pos - self:GetPos() ):Angle()
			self.vaAimTargetPose = self.vaAimTargetBody
			self:ModifyMoveAimVector( self.vaAimTargetBody, self.flTopSpeed, 1 )
		end
		self:MoveAlongPathToCover( sched.Path )
	end
end )
