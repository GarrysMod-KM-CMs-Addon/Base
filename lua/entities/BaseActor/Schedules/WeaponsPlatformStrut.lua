// TODO: Dramatic gunning turn? Not sure how that'd work with DRY lol

RegisterSchedule( "WeaponsPlatformStrut", { Execute = function( self, pSchedule, MyTable )
	MyTable.flDontDoIntimidationWalkTime = CurTime() + 1

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

	if MyTable.bSkater then
		MyTable.SetSchedule( self, "WeaponsPlatformSkateMelee", MyTable )
		return
	end

	if !pSchedule.m_bInitialized then
		if self:Visible( pEnemy ) then pSchedule.bStopFirstTaunt = true end

		pSchedule.m_bInitialized = true
	end

	local f = MyTable.CheckAndDoDumbMelee
	if f then
		local p = f( self, MyTable, pEnemy, pTrueEnemy )
		if p then
			p.fOnComplete = function()
				if math.random( 3 ) == 1 then
					MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
					return true
				end

				MyTable.SetSchedule( self, pSchedule, MyTable )
				return true
			end
			p.fOnInterrupt = p.fOnComplete
			return
		end
	end

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

	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flWalkSpeed, _, SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy ), nil, nil, nil, function()
		if pEnemyPath:IsValid() && MyTable.IsInterceptJumpLegalMedium( self, pEnemy, nil, true ) then
			//	pEnemyPath:Invalidate()

			MyTable.HandleHeadJumpStill( self, MyTable, pEnemy, pSchedule, function()
				if math.random( 3 ) == 1 then
					MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
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
					MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
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
		MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
	else
		MyTable.vaAimTargetBody = pEnemy:GetPos()
	end

	if !self:IsOnGround() || CurTime() <= ( pSchedule.flPerformingJump || 0 ) then return end

	if MyTable.sJumpOnTheirHeadSchedule && math.random() <= .15 * MyTable.m_flFrameTime && MyTable.IsInterceptJumpLegal( self, pEnemy ) then
		if MyTable.HandleHeadJump then
			MyTable.HandleHeadJump( self, MyTable, pEnemy, pSchedule, function()
				if math.random( 2 ) == 1 then
					MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
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
					if math.random( 2 ) == 1 then
						MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
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

	if !pSchedule.flMeleeTimer then
		if !self:Visible( pEnemy ) then
			MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
			return
		end

		pSchedule.flMeleeTimer = 4 + math.random() * 4
	end

	pSchedule.flMeleeTimer = pSchedule.flMeleeTimer - MyTable.m_flFrameTime

	if pSchedule.flMeleeTimer <= 0 then
		MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
		return
	end

	local flEnemyHealth = pEnemy:Health()

	local pHead = MyTable.pActiveBodyTemplates.Head
	if pHead then
		pHead.SetAimTarget( self, pEnemy:GetPos() + pEnemy:OBBCenter() )
	
		pHead.SetStiffness( self, pHead.GetNormalStiffness( self ) * 100 )
		pHead.SetDamping( self, pHead.GetNormalDamping( self ) * 20 )
	
		local pMachineGun = MyTable.pActiveWeaponTemplates.MachineGun
	
		local flDelay = math.Clamp( pMachineGun.Damage() / flEnemyHealth, 0, 1 )

		local vPos, dDir = pMachineGun.BarrelVector( self ), pMachineGun.BarrelDirection( self )

		if !pSchedule.bWallFire then pSchedule.bWallFire = math.random( 2 ) == 1 end

		if pSchedule.bWallFire && flDelay > 60 / 550 then
			MyTable.flWeaponPrimaryVolleyTimeMin = 0
			MyTable.flWeaponPrimaryVolleyTimeMax = 6

			MyTable.flWeaponPrimaryVolleyBreakMin = 0
			MyTable.flWeaponPrimaryVolleyBreakMax = 1

			MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMin = 60 / 550
			MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax = 60 / 550
		else
			MyTable.flWeaponPrimaryVolleyTimeMin = 0
			MyTable.flWeaponPrimaryVolleyTimeMax = 3

			MyTable.flWeaponPrimaryVolleyBreakMin = 0
			MyTable.flWeaponPrimaryVolleyBreakMax = .5

			MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMin = 0
			MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax = flDelay * ( 1 - math.random() * math.random() )
		end

		local bAttack = MyTable.CanAttackCustomSpacePart( self, pEnemy, pTrueEnemy, MyTable, nil, dDir, vPos, pMachineGun.SpreadX(), pMachineGun.SpreadY() )

		if bAttack && MyTable.CanAttackCustomAimPart( self, pEnemy, pTrueEnemy, MyTable, nil, dDir, vPos, pMachineGun.SpreadX(), pMachineGun.SpreadY() ) && MyTable.WeaponPrimaryVolleyContainer( self, "MachineGun", nil, MyTable ) then
			FireWeapon( self, "MachineGun", pMachineGun )
		end
	
		if !pSchedule.flAttackMooDelay then pSchedule.flAttackMooDelay = math.random() * math.random() * 2 end
	
		if bAttack then
			if MyTable.sChargeSchedule then
				local flDistance = pEnemyPath:GetLength() - pEnemyPath:GetCursorPosition()

				local f = MyTable.flChargeSpeed * MyTable.flChargeTimeMin * .4

				if flDistance <= f && math.random() <= MyTable.m_flFrameTime * .1 then
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
			end

			if math.random() <= .06 * MyTable.m_flFrameTime then
				MyTable.Taunt( self, pEnemy, MyTable )
				pSchedule.flMeleeTimer = 4 + math.random() * 4
				return
			end

			pSchedule.flMeleeTimer = 4 + math.random() * 4
	
			if CurTime() <= ( pSchedule.flJustMooed || 0 ) then
				pSchedule.bAttackMooed = true
				pSchedule.flJustMooed = CurTime() + 4
	
			elseif !pSchedule.bAttackMooed && CurTime() > pSchedule.flAttackMooDelay then
				pSchedule.bAttackMooed = true
				pSchedule.flJustMooed = CurTime() + 4
	
				if !pSchedule.bStopFirstTaunt && math.random() <= .4 then
					MyTable.Taunt( self, pEnemy, MyTable )
					pSchedule.flMeleeTimer = 4 + math.random() * 4
					return
				end
	
				pSchedule.bStopFirstTaunt = nil
	
				MyTable.LowIfAvailable( self, MyTable )
			end
		else
			pSchedule.bWallFire = nil
			pSchedule.bAttackMooed = nil
			pSchedule.flAttackMooDelay = CurTime() + math.random() * math.random() * 2
		end
	else
		MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
	end
end } )