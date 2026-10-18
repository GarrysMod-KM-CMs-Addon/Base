// TODO: EyesOfDeath (Kordhell reference) behaviour when a bunch of Gekkos turn to you, wait a second, and then all attack

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

	if self:Visible( pEnemy ) && self:GetForward():Dot( ( pEnemy:GetPos() + pEnemy:OBBCenter() - self:GetPos() ):GetNormalized() ) < .7 then
		MyTable.SetSchedule( self, "IntimidationWalkDramaticTurn", MyTable )
	else MyTable.SetSchedule( self, "IntimidationWalkInternal", MyTable ) end
end } )

RegisterSchedule( "IntimidationWalkDramaticTurn", { Execute = function( self, pSchedule, MyTable )
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

	// FUCK YOU!
	if MyTable.HandleDefense( self, MyTable ) != DEF_SAFE then
		MyTable.SetSchedule( self, MyTable.m_sDefaultMeleeSchedule || MyTable.m_sDefaultCombatSchedule, MyTable )
		return
	end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end

	MyTable.ManageFlankPath( self, pEnemyPath, pEnemy, pSchedule, MyTable )

	if !pSchedule.m_bInitialized then
		MyTable.vaAimTargetBody = LerpAngle( .5, self:GetAngles(), ( pEnemy:GetPos() + pEnemy:OBBCenter() - self:GetPos() ):Angle() )

		pSchedule.flBodyDamp = 2.5 + math.random() * 1.5
		pSchedule.flHeadDamp = 1.5 + math.random() * .5

		pSchedule.flLeaveTime = CurTime() + 2 + math.random() * 2

		pSchedule.m_bInitialized = true
	end

	if !pSchedule.bEyesOfDeath then
		if CurTime() > pSchedule.flLeaveTime then
			MyTable.SetSchedule( self, math.random( 2 ) == 1 && "IntimidationWalkInternal" || MyTable.m_sDefaultMeleeSchedule || MyTable.m_sDefaultCombatSchedule, MyTable )
		end
	end

	MyTable.flOverrideBodyDampingThisTick = MyTable.flBodyDamping * pSchedule.flBodyDamp

	MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()

	local pData = MyTable.tActiveBodyTemplates.Head
	if pData then
		pData.SetDamping( self, pData.GetDamping( self ) * pSchedule.flHeadDamp )
	end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )
	if MyTable.UpdatePursuitSenses( self, pEnemy, pTrueEnemy, MyTable ) then
		MyTable.SetSchedule( self, MyTable.m_sDefaultChaseSchedule || MyTable.m_sDefaultMeleeSchedule || MyTable.m_sDefaultCombatSchedule, MyTable )
		return
	end
end } )

RegisterSchedule( "IntimidationWalkInternal", { Execute = function( self, pSchedule, MyTable )
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

	if !pSchedule.m_bInitialized then
		pSchedule.flLeaveTime = CurTime() + math.random() * 12

		pSchedule.m_bInitialized = true
	end

	local f = MyTable.CheckAndDoDumbMelee
	if f then
		local p = f( self, MyTable, pEnemy, pTrueEnemy )
		if p then
			p.fOnComplete = function()
				MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
				return true
			end
			p.fOnInterrupt = p.fOnComplete
			return
		end
	end

	if CurTime() > pSchedule.flLeaveTime then
		MyTable.SetSchedule( self, MyTable.m_sDefaultMeleeSchedule || MyTable.m_sDefaultCombatSchedule, MyTable )
	end

	// FUCK YOU!
	if MyTable.HandleDefense( self, MyTable ) != DEF_SAFE then
		MyTable.SetSchedule( self, MyTable.m_sDefaultMeleeSchedule || MyTable.m_sDefaultCombatSchedule, MyTable )
		return
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
