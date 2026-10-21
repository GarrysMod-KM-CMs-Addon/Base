// PlantToShoot is just a fancy name I made when making Strogg Blaster Marine
// Actually refers to anything that likes to combat people in the open
// Do not confuse with FreeMovement, which is also in the open, but that's
// because a soldier went "GOING AFTER HIM!!"
// Technically, an enemy that can't plant (e.g. Strogg Shotgun Marine) can still use PlantToShoot

local random = math.random // random is love, random is life

// TODO: Teach 'em to shoot on the move

local TraceLine = util.TraceLine
local max = math.max

local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume
local coroutine_status = coroutine.status

local assert = assert

RegisterSchedule( "PlantToShoot", {
	Execute = function( self, pSchedule, MyTable )
		local pEnemy = MyTable.Enemy
		if !IsValid( pEnemy ) then return true end

		local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy )

		if !pSchedule.flTimer then
			pSchedule.flTimer = random() * random() * 3
		end

		pSchedule.flTimer = max( 0, pSchedule.flTimer - MyTable.m_flFrameTime )

		if pSchedule.flTimer <= 0 && MyTable.bPlantToShoot then
			local vEnemy = pEnemy:GetPos() + pEnemy:OBBCenter()

			local tr = TraceLine {
				start = MyTable.GetShootPos( self ),
				endpos = vEnemy,
				mask = MASK_SHOT_HULL,
				filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
			}

			if tr.Hit then
				// enemy in the fricking way!!! (sponsored by filian.coom)
				local pEntity = tr.Entity
				if IsValid( pEntity ) && MyTable.Disposition( self, pEntity ) == D_LI then
					pSchedule.flTimer = random() * random() * 2
				else pSchedule.flTimer = random() * random() * 1.5 end

			else
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
			local tr = TraceLine {
				start = MyTable.GetShootPos( self ),
				endpos = vEnemy,
				mask = MASK_SHOT_HULL,
				filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
			}
			if tr.Hit then
				local pEntity = tr.Entity
				if IsValid( pEntity ) && MyTable.Disposition( self, pEntity ) == D_LI then
					pSchedule.bEnemyInTheFrickingWay = true // this variable was sponsored by filian.coom
					pSchedule.bDone = true
				end

				pSchedule.pTarget = nil

				if pSchedule.bPlanted then
					pSchedule.flSuppressTimer = pSchedule.flSuppressTimer + MyTable.m_flFrameTime
					if pSchedule.flSuppressTimer > pSchedule.flSuppressTarget then pSchedule.bDone = true end
				end
			else
				pSchedule.pTarget = pEnemy
				pSchedule.vTarget = vEnemy
	
				if pSchedule.bPlanted then
					pSchedule.flTargetTimer = pSchedule.flTargetTimer + MyTable.m_flFrameTime
					if pSchedule.flTargetTimer > pSchedule.flTargetTarget then pSchedule.bDone = true end
				end
			end
		end

		local pCoroutine = pSchedule.pCoroutine

		if !pCoroutine then
			pCoroutine = coroutine_create( MyTable.PlantThread )
			pSchedule.pCoroutine = pCoroutine
			assert( coroutine_resume( pCoroutine, self, pSchedule, MyTable ) )
			return
		end

		if coroutine_status( pCoroutine ) == "dead" then
			local pSchedule = MyTable.SetSchedule( self, "PlantToShoot", MyTable )
			if MyTable.bEnemyInTheFrickingWay then pSchedule.flTimer = ( 1 - random() * random() ) * 2 end
			return
		end

		assert( coroutine_resume( pCoroutine ) )

		if pSchedule.sReturn == "DELTA" then
			pSchedule.bDone = true
		end
	end
} )
