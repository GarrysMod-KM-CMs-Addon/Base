RegisterSchedule( "WeaponsPlatformSkateMelee", { Execute = function( self, pSchedule, MyTable )
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

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end

	MyTable.ManageFlankPath( self, pEnemyPath, pEnemy, pSchedule, MyTable )

	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flTopSpeed, _, SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy ) )

	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle() end

	if !self:IsOnGround() then return end

	// NOTE: We might want a WeaponsPlatformSkateCircle schedule to
	// drive away while they chase us like idiots to wound them,
	// that triggers when they start meleeing us
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
				MyTable.SetSchedule( self, "WeaponsPlatformSkateMelee", MyTable )
				return true
			end
			p.fOnInterrupt = p.fOnComplete
			return
		end
	end
end } )