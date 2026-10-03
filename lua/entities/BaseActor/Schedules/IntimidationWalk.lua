RegisterSchedule( "IntimidationWalk", { Execute = function( self, pSchedule, MyTable )
	local fGekkoChirpControllerCombat = MyTable.GekkoChirpControllerCombat
	if fGekkoChirpControllerCombat then fGekkoChirpControllerCombat( self, MyTable ) end

	if table.IsEmpty( MyTable.tEnemies ) then return true end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )

	local f = self:BoundingRadius()
	f = f * f
	local v = self:GetPos()
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		return
	end

	// Never strut for now
	// TODO: This whole schedule
	if true then
		MyTable.SetSchedule( self, MyTable.m_sDefaultChaseSchedule || MyTable.m_sDefaultMeleeSchedule || MyTable.m_sDefaultCombatSchedule, MyTable )
	end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end

	MyTable.ManageFlankPath( self, pEnemyPath, pEnemy, pSchedule, MyTable )

	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flFastWalkSpeed || MyTable.flWalkSpeed )

	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then
		MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )
	if MyTable.UpdatePursuitSenses( self, pEnemy, pTrueEnemy, MyTable ) then
		MyTable.SetSchedule( self, MyTable.m_sDefaultChaseSchedule || MyTable.m_sDefaultMeleeSchedule || MyTable.m_sDefaultCombatSchedule, MyTable )
		return
	end
end } )
