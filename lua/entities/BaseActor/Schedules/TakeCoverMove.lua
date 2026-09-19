local util_TraceLine = util.TraceLine

local function fAttemptReturn( self, pSchedule, MyTable )
	local pPath = pSchedule.pPath
	if !pPath then
		MyTable.vCover = pSchedule.vCoverFrom
		MyTable.tCover = pSchedule.pCoverFrom
		MyTable.SetSchedule( self, "TakeCover", MyTable )
		return true
	end

	// If we haven't ran THAT far yet, try to return back to the cover we came from.
	// Note this is NOT .5, as we still need to do a 180,
	// which can be very bad for someone getting, you know, shot at

	pPath:MoveCursorToClosestPosition( self:GetPos() )

	if pPath:GetCursorPosition() <= pPath:GetLength() * 1 / 3 then
		MyTable.vCover = pSchedule.vCoverFrom
		MyTable.tCover = pSchedule.pCoverFrom
		MyTable.SetSchedule( self, "TakeCover", MyTable )
		return true
	end
end

RegisterSchedule( "TakeCoverMove", {
	SomeoneIsPeekingMe = function( self, pSchedule, MyTable ) fAttemptReturn( self, pSchedule, MyTable ) end,

	Execute = function( self, pSchedule, MyTable )
		MyTable.WEAPON_STANCE = MyTable.Moving_WEAPON_STANCE

		local tEnemies = pSchedule.tEnemies || MyTable.tEnemies
		if table.IsEmpty( tEnemies ) then return true end

		if MyTable.GAME_flSuppression > self:Health() * 4 then MyTable.SetSchedule( self, "TakeCover", MyTable ) return end

		local pEnemy = MyTable.Enemy
		if !IsValid( pEnemy ) then return true end

		local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy )

		local iClip = MyTable.GetWeaponClipPrimary( self, MyTable )
		if iClip != -1 && iClip <= 0 then MyTable.WeaponReload( self, MyTable ) end

		local vCover = MyTable.vCover
		local tCover = MyTable.tCover

		if !tCover || !vCover then
			MyTable.SetSchedule( self, "TakeCover", MyTable )
			return
		end

		local pPath = pSchedule.pPath
		if !pPath then
			pPath = Path "Follow"
			pSchedule.pPath = pPath
		end

		MyTable.ComputePath( self, pPath, MyTable.vCover )

		if !MyTable.CanExpose( self, MyTable ) && fAttemptReturn( self, pSchedule, MyTable ) then return end

		local pEnemyPath = MyTable.pEnemyPath
		if !pEnemyPath then
			pEnemyPath = Path "Follow"
			MyTable.pEnemyPath = pEnemyPath
		end

		if LevelOfDetail( pSchedule, "flNextEnemyPath" ) then
			MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy )
		end

		local flTolerance = self:OBBMaxs()[ 1 ] * ( 1 / 3 )
		if self:GetPos():DistToSqr( vCover ) <= flTolerance * flTolerance then return true end

		if LevelOfDetail( pSchedule, "flNextCheck" ) then
			if !MyTable.IsValidCoverCandidate( self, tCover, pEnemyPath, MyTable ) || !MyTable.IsValidCoverPoint( self, vCover, tCover, pEnemy, pEnemyPath, MyTable ) then
				// Pray to God that it's closer and we aren't dying for no reason lmao
				MyTable.vCover = pSchedule.vCoverFrom
				MyTable.tCover = pSchedule.pCoverFrom
				MyTable.SetSchedule( self, "TakeCover", MyTable )
				return
			end
		end

		local vSuppress = MyTable.ManageOnTheMoveSuppressionTarget( self, pSchedule, pEnemy, pTrueEnemy, pEnemyPath )
		if vSuppress then
			MyTable.MoveAlongPath( self, pPath, MyTable.flJogSpeed, 1 )
			MyTable.CenterTarget( self, v, MyTable )
			if MyTable.CanAttackHelper( self, pEnemy, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
		else
			local pGoal = pPath:GetCurrentGoal()
			if pGoal then
				MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
				MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			end

			MyTable.MoveAlongPathToCover( self, pPath, nil, self:OBBMaxs()[ 1 ] / 3 )
		end
	end
} )
