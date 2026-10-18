RegisterSchedule( "WeaponsPlatformMelee", { Execute = function( self, pSchedule, MyTable )
	MyTable.GekkoChirpControllerCombat( self, MyTable )

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

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end

	MyTable.ManageFlankPath( self, pEnemyPath, pEnemy, pSchedule, MyTable )

	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flTopSpeed * ( CurTime() <= MyTable.flSpeedUpAnimationsTime && .75 || 1 ), _, SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy ) )

	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle() end

	if !pSchedule.m_bInitialized then
		pSchedule.bGunningTurn = math.random( 2 ) == 1

		pSchedule.m_bInitialized = true
	end

	local pHead = MyTable.tActiveBodyTemplates.Head
	if pHead then
		pHead.SetAimTarget( self, pEnemy:GetPos() + pEnemy:OBBCenter() )

		if pSchedule.bGunningTurn then
			local pMachineGun = MyTable.tActiveWeaponTemplates.MachineGun

			local vPos, dDir = pMachineGun.BarrelVector( self ), pMachineGun.BarrelDirection( self )

			MyTable.flWeaponPrimaryVolleyTimeMin = 0
			MyTable.flWeaponPrimaryVolleyTimeMax = 3

			MyTable.flWeaponPrimaryVolleyBreakMin = 0
			MyTable.flWeaponPrimaryVolleyBreakMax = .5

			if MyTable.WeaponPrimaryVolleyContainer( self, "MachineGun", true, MyTable ) && MyTable.CanAttackCustom( self, pEnemy, pTrueEnemy, MyTable, nil, dDir, vPos, .25, .25 ) then
				FireWeapon( self, "MachineGun", pMachineGun )
			end
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
				return true
			end
			p.fOnInterrupt = p.fOnComplete
			return
		end
	end

	if MyTable.LowIfAvailable && math.random() <= .2 * MyTable.m_flFrameTime && MyTable.LowIfAvailable( self, MyTable ) then
		util.ScreenShake( self:GetPos() + self:OBBCenter(), 2, 6, 4, 4096, true )
	end

	if MyTable.sJumpOnTheirHeadSchedule && math.random() <= .3 * MyTable.m_flFrameTime && MyTable.IsInterceptJumpLegal( self, pEnemy ) then
		if MyTable.HandleHeadJump then
			MyTable.HandleHeadJump( self, MyTable, pEnemy, pSchedule, function()
				MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
				return true
			end )
		else
			local vIntercept = MyTable.InterceptJump( self, pEnemy, nil, MyTable.flJumpHeight )
			if vIntercept then
				vIntercept:Sub( self:GetPos() )

				local pSchedule = MyTable.SetSchedule( self, MyTable.sJumpOnTheirHeadSchedule, MyTable )
				pSchedule.aLook = vIntercept:Angle()
				pSchedule.fOnComplete = function()
					MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
					return true
				end
			end
		end

		return
	end

	if !MyTable.sChargeSchedule || !MyTable.Taunt then return end

	local flDistance = pEnemyPath:GetLength() - pEnemyPath:GetCursorPosition()

	local f = MyTable.flChargeSpeed * MyTable.flChargeTimeMin * .4

	if flDistance <= f && math.random() <= .2 * MyTable.m_flFrameTime then
		if math.random( 2 ) == 1 then
			MyTable.Taunt( self, pEnemy, MyTable )
			return
		end

		local pSchedule = MyTable.SetSchedule( self, MyTable.sChargeSchedule, MyTable )
		pSchedule.fOnComplete = function()
			MyTable.SetSchedule( self, "WeaponsPlatformMelee", MyTable )
			return true
		end
		pSchedule.fOnInterrupt = pSchedule.fOnComplete
	end
end } )