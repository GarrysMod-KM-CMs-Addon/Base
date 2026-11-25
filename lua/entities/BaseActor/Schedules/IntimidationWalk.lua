// TODO: EyesOfDeath (Kordhell reference) behaviour when a bunch of Gekkos turn to you, wait a second, and then all attack

ENT.flDontDoIntimidationWalkTime = 0

RegisterSchedule( "IntimidationWalk", { Execute = function( self, pSchedule, MyTable )
	if CurTime() <= MyTable.flDontDoIntimidationWalkTime then
		MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
		return
	end

	local fGekkoChirpControllerCombat = MyTable.GekkoChirpControllerCombat
	if fGekkoChirpControllerCombat then fGekkoChirpControllerCombat( self, MyTable ) end

	if table.IsEmpty( MyTable.tEnemies ) then return true end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )

	local f
	local fGetStompDamageRadius = MyTable.GetStompDamageRadius
	if fGetStompDamageRadius then
		f = fGetStompDamageRadius( self, MyTable ) * 1.25
	end
	f = f || self:BoundingRadius()
	f = f * f
	local v = self:GetPos()
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		return
	end

	if !self:Visible( pEnemy ) then
		// TODO: Stacking up on hostiles
		MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
	end

	if self:GetForward():Dot( ( pEnemy:GetPos() + pEnemy:OBBCenter() - self:GetPos() ):GetNormalized() ) < .8 then
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

	local f
	local fGetStompDamageRadius = MyTable.GetStompDamageRadius
	if fGetStompDamageRadius then
		f = fGetStompDamageRadius( self, MyTable ) * 1.25
	end
	f = f || self:BoundingRadius()
	f = f * f
	local v = self:GetPos()

	local bQuiteClose = v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f

	if pEnemy.__ACTOR_BULLSEYE__ && bQuiteClose && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		return
	end

	// FUCK YOU!
	if MyTable.HandleDefense( self, MyTable ) != DEF_SAFE then
		MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
		return
	end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end

	MyTable.ManageFlankPath( self, pEnemyPath, pEnemy, pSchedule, MyTable )

	MyTable.Stand( self, MyTable )

	if !pSchedule.m_bInitialized then
		MyTable.vaAimTargetBody = LerpAngle( .5, self:GetAngles(), ( pEnemy:GetPos() + pEnemy:OBBCenter() - self:GetPos() ):Angle() )

		pSchedule.flBodyDamp = 4 + math.random()

		pSchedule.flHeadDamp = 2 + math.random()
		pSchedule.flHeadStiff = 1.2 + math.random() * .3

		pSchedule.flLeaveTime = 1 + math.random() * math.random() * 1.5

		pSchedule.m_bInitialized = true
	end

	if bQuiteClose then MyTable.vaAimTargetBody = pEnemy:GetPos() end

	pSchedule.flLeaveTime = pSchedule.flLeaveTime - MyTable.m_flFrameTime

	if !pSchedule.bEyesOfDeath then
		if pSchedule.flLeaveTime <= 0 then
			local i = math.random( 3 )
			if i == 1 then
				MyTable.SetSchedule( self, "IntimidationWalkInternal", MyTable )
			elseif i == 2 then
				MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
			elseif i == 3 then
				MyTable.SetSchedule( self, "WeaponsPlatformStrut", MyTable )
			end
			return
		end
	end

	MyTable.flOverrideBodyDampingThisTick = MyTable.flBodyDamping * pSchedule.flBodyDamp

	MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()

	local pData = MyTable.pActiveBodyTemplates.Head
	if pData then
		pData.SetStiffness( self, pData.GetNormalStiffness( self ) * pSchedule.flHeadStiff )
		pData.SetDamping( self, pData.GetNormalDamping( self ) * pSchedule.flHeadDamp )
	end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )
	if MyTable.UpdatePursuitSenses( self, pEnemy, pTrueEnemy, MyTable ) then
		pSchedule.flLeaveTime = pSchedule.flLeaveTime - MyTable.m_flFrameTime
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

	local f
	local fGetStompDamageRadius = MyTable.GetStompDamageRadius
	if fGetStompDamageRadius then
		f = fGetStompDamageRadius( self, MyTable ) * 1.25
	end
	f = f || self:BoundingRadius()
	f = f * f
	local v = self:GetPos()
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		return
	end

	if !pSchedule.m_bInitialized then
		pSchedule.flLeaveTime = math.random() * math.random() * 12

		pSchedule.m_bInitialized = true
	end

	pSchedule.flLeaveTime = pSchedule.flLeaveTime - MyTable.m_flFrameTime

	if !self:IsOnGround() || CurTime() <= ( pSchedule.flPerformingJump || 0 ) then return end

	local f = MyTable.CheckAndDoDumbMelee
	if f then
		local p = f( self, MyTable, pEnemy, pTrueEnemy )
		if p then
			p.fOnComplete = function()
				if math.random( 2 ) == 1 then
					MyTable.SetSchedule( self, "WeaponsPlatformStrut", MyTable )
				else
					MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
				end
				MyTable.flDontDoIntimidationWalkTime = CurTime() + 1
				return true
			end
			p.fOnInterrupt = p.fOnComplete
			return
		end
	end

	if pSchedule.flLeaveTime <= 0 then
		if math.random( 2 ) == 1 then
			MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
		else
			MyTable.SetSchedule( self, "WeaponsPlatformStrut", MyTable )
		end

		return
	end

	// FUCK YOU!
	if MyTable.HandleDefense( self, MyTable ) != DEF_SAFE then
		MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
		return
	end

	if MyTable.sJumpOnTheirHeadSchedule && math.random() <= .15 * MyTable.m_flFrameTime && MyTable.IsInterceptJumpLegal( self, pEnemy ) then
		if MyTable.HandleHeadJump then
			MyTable.HandleHeadJump( self, MyTable, pEnemy, pSchedule, function()
				if math.random( 2 ) == 1 then
					MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
				else
					MyTable.SetSchedule( self, "WeaponsPlatformStrut", MyTable )
				end
				MyTable.flDontDoIntimidationWalkTime = CurTime() + 1
				return true
			end )
		else
			local vIntercept = MyTable.InterceptJump( self, pEnemy, nil, MyTable.flJumpHeight )
			if vIntercept then
				vIntercept:Sub( self:GetPos() )

				local pSchedule = MyTable.SetSchedule( self, MyTable.sJumpOnTheirHeadSchedule, MyTable )
				pSchedule.aLook = vIntercept:Angle()
				pSchedule.fOnComplete = function()
					if math.random( 2 ) == 1 then
						MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
					else
						MyTable.SetSchedule( self, "WeaponsPlatformStrut", MyTable )
					end
					MyTable.flDontDoIntimidationWalkTime = CurTime() + 1
					return true
				end
			end
		end

		return
	end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end

	MyTable.ManageFlankPath( self, pEnemyPath, pEnemy, pSchedule, MyTable )

	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flWalkSpeed, _, SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy ), nil, nil, nil, function()
		if pEnemyPath:IsValid() && MyTable.IsInterceptJumpLegalMedium( self, pEnemy, nil, true ) then
			//	pEnemyPath:Invalidate()

			MyTable.HandleHeadJumpStill( self, MyTable, pEnemy, pSchedule, function()
				MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
				return true
			end )

			return true
		end
	end, function()
		if pEnemyPath:IsValid() && MyTable.IsInterceptJumpLegalMedium( self, pEnemy, nil, true ) then
			pEnemyPath:Invalidate()

			MyTable.HandleHeadJumpStill( self, MyTable, pEnemy, pSchedule, function()
				MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
				return true
			end )

			return true
		end
	end )

	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then
		MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
		MyTable.vaAimTargetPose = self:Visible( pEnemy ) && ( pEnemy:GetPos() + pEnemy:OBBCenter() ) || MyTable.vaAimTargetBody
	else
		MyTable.vaAimTargetBody = pEnemy:GetPos()
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )
	if MyTable.UpdatePursuitSenses( self, pEnemy, pTrueEnemy, MyTable ) then
		pSchedule.flLeaveTime = pSchedule.flLeaveTime - MyTable.m_flFrameTime
	end
end } )
