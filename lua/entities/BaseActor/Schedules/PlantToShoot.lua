// PlantToShoot is just a fancy name I made when making Strogg Blaster Marine
// Actually refers to anything that likes to combat people in the open
// Do not confuse with FreeMovement, which is also in the open, but that's
// because a soldier went "GOING AFTER HIM!!"
// Technically, an enemy that can't plant (e.g. Strogg Shotgun Marine) can still use PlantToShoot

RegisterSchedule( "PlantToShoot", {
	Execute = function( self, pSchedule, MyTable )
		local pEnemy = MyTable.Enemy
		if !IsValid( pEnemy ) then return true end

		local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy )

		if MyTable.bPlantToShoot then
			local vEnemy = pEnemy:GetPos() + pEnemy:OBBCenter()
			if !util.TraceLine( {
				start = MyTable.GetShootPos( self ),
				endpos = vEnemy,
				mask = MASK_SHOT_HULL,
				filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
			} ).Hit then
				MyTable.vaAimTargetBody = vEnemy
				MyTable.vaAimTargetPose = vEnemy
				if MyTable.IsInPlantDelta( self, vEnemy, MyTable ) then
					MyTable.SetSchedule( self, "PlantToShootPlant", MyTable )
				end
			end
		end

		local EDefense, flOptional = MyTable.HandleDefense( self, MyTable )
		if EDefense >= DEF_NO_ACTION_NEEDED then
			if EDefense == DEF_DONT_ADVANCE_TO_RANGE then
				// TODO: Handle this, duh xD
			else return end
		end

		local pPath = MyTable.pEnemyPath
		if !pPath then
			pPath = Path "Follow"
			MyTable.pEnemyPath = pPath
		end

		MyTable.ManageFlankPath( self, pPath, pEnemy, pSchedule, MyTable )

		local pGoal = pPath:GetCurrentGoal()
		if pGoal then
			MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		end

		MyTable.MoveAlongPath( self, pPath, MyTable.flTopSpeed )
	end
} )

// NOTE: Your PlantThread should most likely support pSchedule.bAimOnly!
local random = math.random
RegisterSchedule( "PlantToShootPlant", {
	Execute = function( self, pSchedule, MyTable )
		local pEnemy = MyTable.Enemy
		if !IsValid( pEnemy ) then return true end

		local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy )

		if !pSchedule.bInitialized then
			pSchedule.bInitialized = true

			pSchedule.flSuppressTimer = 0
			pSchedule.flTargetTimer = 0

			pSchedule.flSuppressTarget = ( random() * random() * random() ) ^ 1.3 * 30
			pSchedule.flTargetTarget = ( random() * random() * random() ) ^ 1.3 * 30
		end

		// TODO: Try to get out of shooting if we need to dodge
		if !pSchedule.bDone then
			local vEnemy = pEnemy:GetPos() + pEnemy:OBBCenter()
			if !util.TraceLine( {
				start = MyTable.GetShootPos( self ),
				endpos = vEnemy,
				mask = MASK_SHOT_HULL,
				filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
			} ).Hit then
				pSchedule.pTarget = pEnemy
				pSchedule.vTarget = vEnemy
	
				if pSchedule.bPlanted then
					pSchedule.flTargetTimer = pSchedule.flTargetTimer + MyTable.m_flFrameTime
					if pSchedule.flTargetTimer > pSchedule.flTargetTarget then pSchedule.bDone = true end
				end
			else
				pSchedule.pTarget = nil

				if pSchedule.bPlanted then
					pSchedule.flSuppressTimer = pSchedule.flSuppressTimer + MyTable.m_flFrameTime
					if pSchedule.flSuppressTimer > pSchedule.flSuppressTarget then pSchedule.bDone = true end
				end
			end
		end

		local pCoroutine = pSchedule.pCoroutine

		if !pCoroutine then
			pCoroutine = coroutine.create( MyTable.PlantThread )
			pSchedule.pCoroutine = pCoroutine
			assert( coroutine.resume( pCoroutine, self, pSchedule, MyTable ) )
			return
		end

		if coroutine.status( pCoroutine ) == "dead" then MyTable.SetSchedule( self, "PlantToShoot", MyTable ) return end

		assert( coroutine.resume( pCoroutine ) )

		if pSchedule.sReturn == "DELTA" then
			pSchedule.bDone = true
		end
	end
} )
