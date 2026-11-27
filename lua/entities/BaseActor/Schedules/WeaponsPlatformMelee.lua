RegisterSchedule( "WeaponsPlatformMelee", { Execute = function( self, pSchedule, MyTable )
	MyTable.flDontDoIntimidationWalkTime = CurTime() + 1

	if MyTable.bSkater then
		MyTable.SetSchedule( self, "WeaponsPlatformSkateMelee", MyTable )
		return
	end

	local fGekkoChirpControllerCombat = MyTable.GekkoChirpControllerCombat
	if fGekkoChirpControllerCombat then fGekkoChirpControllerCombat( self, MyTable ) end

	if table.IsEmpty( MyTable.tEnemies ) then return true end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

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

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end

	MyTable.ManageFlankPath( self, pEnemyPath, pEnemy, pSchedule, MyTable )

	MyTable.MoveAlongPath( self, pEnemyPath, ( CurTime() <= ( pSchedule.flSpeedUpAnimationsTime || 0 ) ) && ( MyTable.flTopSpeed * .5 ) || MyTable.flTopSpeed, _, SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy ), nil, nil, nil, function()
		if pEnemyPath:IsValid() && MyTable.IsInterceptJumpLegalMedium( self, pEnemy, nil, true ) then
			//	pEnemyPath:Invalidate()
	
			MyTable.HandleHeadJumpStill( self, MyTable, pEnemy, pSchedule, function()
				if math.random( 3 ) == 1 then
					MyTable.SetSchedule( self, "WeaponsPlatformStrut", MyTable )
					return true
				end

				MyTable.SetSchedule( self, pSchedule, MyTable )
				return true
			end )
	
			return true
		end
	end, function()
		if pEnemyPath:IsValid() && MyTable.IsInterceptJumpLegalMedium( self, pEnemy, nil, true ) then
			pEnemyPath:Invalidate()
	
			MyTable.HandleHeadJumpStill( self, MyTable, pEnemy, pSchedule, function()
				if math.random( 3 ) == 1 then
					MyTable.SetSchedule( self, "WeaponsPlatformStrut", MyTable )
					return true
				end

				MyTable.SetSchedule( self, pSchedule, MyTable )
				return true
			end )
	
			return true
		end
	end )

	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then
		if MyTable.aNavigation then
			MyTable.vaAimTargetBody = MyTable.aNavigation
		else
			MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
		end
	else
		MyTable.vaAimTargetBody = pEnemy:GetPos()
	end

	if !pSchedule.m_bInitialized then
		pSchedule.bGunningTurn = math.random( 2 ) == 1

		pSchedule.m_bInitialized = true
	end

	local pHead = MyTable.pActiveBodyTemplates.Head
	if pHead then
		if self:Visible( pEnemy ) then
			pHead.SetAimTarget( self, pEnemy:GetPos() + pEnemy:OBBCenter() )
		else
			pHead.SetAimTarget( self, MyTable.vaAimTargetBody )
		end

		if pSchedule.bGunningTurn then
			local pMachineGun = MyTable.pActiveWeaponTemplates.MachineGun

			local vPos, dDir = pMachineGun.BarrelVector( self ), pMachineGun.BarrelDirection( self )

			MyTable.flWeaponPrimaryVolleyTimeMin = 0
			MyTable.flWeaponPrimaryVolleyTimeMax = 3

			MyTable.flWeaponPrimaryVolleyBreakMin = 0
			MyTable.flWeaponPrimaryVolleyBreakMax = .5

			if MyTable.WeaponPrimaryVolleyContainer( self, "MachineGun", true, MyTable ) && MyTable.CanAttackCustom( self, pEnemy, pTrueEnemy, MyTable, nil, dDir, vPos, .25, .25 ) then
				FireWeapon( self, "MachineGun", pMachineGun )
			end
		end
	else
		if self:Visible( pEnemy ) then
			MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
		else
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		end
	end

	if !self:IsOnGround() || CurTime() <= ( pSchedule.flPerformingJump || 0 ) then return end

	local EDefense, flOptional = MyTable.HandleDefense( self, MyTable )
	if EDefense >= DEF_NO_ACTION_NEEDED then
		if EDefense == DEF_DONT_ADVANCE_TO_RANGE then
			// TODO: Handle this, duh xD
		else return end
	end

	local f = MyTable.CheckAndDoDumbMelee
	if f then
		local p = f( self, MyTable, pEnemy, pTrueEnemy )
		if p then
			p.fOnComplete = function()
				MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
				MyTable.flDontDoIntimidationWalkTime = CurTime() + 1
				return true
			end
			p.fOnInterrupt = p.fOnComplete
			return
		end
	end

	if MyTable.LowIfAvailable && math.random() <= .1 * MyTable.m_flFrameTime then
		MyTable.LowIfAvailable( self, MyTable )
	end

	if MyTable.sJumpOnTheirHeadSchedule && math.random() <= .18 * MyTable.m_flFrameTime && MyTable.IsInterceptJumpLegal( self, pEnemy ) then
		if MyTable.HandleHeadJump then
			MyTable.HandleHeadJump( self, MyTable, pEnemy, pSchedule, function()
				if math.random( 3 ) == 1 then
					MyTable.SetSchedule( self, "WeaponsPlatformStrut", MyTable )
					return true
				end

				MyTable.SetSchedule( self, pSchedule, MyTable )
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
					if math.random( 3 ) == 1 then
						MyTable.SetSchedule( self, "WeaponsPlatformStrut", MyTable )
						return true
					end

					MyTable.SetSchedule( self, pSchedule, MyTable )
					MyTable.flDontDoIntimidationWalkTime = CurTime() + 1
					return true
				end
			end
		end

		return
	end

	if !self:Visible( pEnemy ) then return end

	if MyTable.Taunt && math.random() <= .05 * MyTable.m_flFrameTime then
		MyTable.Taunt( self, pEnemy, MyTable )
		pSchedule.flMeleeTimer = 4 + math.random() * 4
		return
	end

	if !MyTable.sChargeSchedule then return end

	local flDistance = pEnemyPath:GetLength() - pEnemyPath:GetCursorPosition()

	local f = MyTable.flChargeSpeed * MyTable.flChargeTimeMin * .4

	if flDistance <= f && math.random() <= MyTable.m_flFrameTime * .065 then
		local pCharge = MyTable.SetSchedule( self, MyTable.sChargeSchedule, MyTable )
		pCharge.fOnComplete = function()
			if math.random( 3 ) == 1 then
				MyTable.SetSchedule( self, "WeaponsPlatformStrut", MyTable )
				return true
			end

			MyTable.SetSchedule( self, pSchedule, MyTable )
			MyTable.flDontDoIntimidationWalkTime = CurTime() + 1
			return true
		end
		pCharge.fOnInterrupt = pCharge.fOnComplete
	end
end } )