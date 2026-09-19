ENT.flShootTimeMin = 2
ENT.flShootTimeMax = 12

ENT.GAME_flSuppression = 0

ENT.flSuppressionHide = .2

function ENT:CanExpose( MyTable ) return self.GAME_flSuppression <= self:Health() * self.flSuppressionHide end

function ENT:GetMySuppressionHealth( MyTable )
	return ( ( MyTable.bIsFootSoldier || self:Health() <= 1000 ) && 100 || self:Health() )
end

local IteratorFactory = include "SuppressionIterator.lua"

local yield = coroutine.yield

function ENT:FindRealSuppressionTarget( pSchedule, vPos, pEnemy, pTrueEnemy, bGenerous, pEnemyPath )
	if pSchedule.bSearchingForRealSuppressTarget then return end

	ACTOR_QUEUE( function()
		if !IsValid( self ) || !IsValid( pEnemy ) || self.Schedule != pSchedule then return end

		pEnemyPath = pEnemyPath || self.pEnemyPath
		if !pEnemyPath then
			pEnemyPath = Path "Follow"

			while true do
				if !IsValid( self ) || !IsValid( pEnemy ) || self.Schedule != pSchedule then return end

				if LevelOfDetail( pSchedule, "flNextPath" ) then
					self:ComputeFlankPath( pEnemyPath, pEnemy )
					break
				end

				self.pEnemyPath = pEnemyPath

				yield()
			end

			return
		end

		pEnemyPath:MoveCursorToClosestPosition( vPos )
		local flCursor = pEnemyPath:GetCursorPosition()
		local aTowards = pEnemyPath:GetPositionOnPath( flCursor )
		pEnemyPath:MoveCursor( Lerp( PATH_STABILIZER, flCursor, pEnemyPath:GetLength() ) )
		aTowards = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - vPos
		aTowards:Normalize()
		aTowards = aTowards:Angle()

		local pIterator = IteratorFactory( aTowards[ 1 ], aTowards[ 2 ] )
		for flPitch, flYaw in pIterator do
			if !IsValid( self ) || !IsValid( pEnemy ) || self.Schedule != pSchedule then return end

			aTowards[ 1 ] = flPitch
			aTowards[ 2 ] = flYaw

			local tFilter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )

			local vEnemy = pEnemy:GetPos()
			vEnemy:Add( pEnemy:OBBCenter() )

			local trRay = util.TraceLine {
				start = vPos,
				start = vPos + aTowards:Forward() * 999999,
				mask = MASK_SHOT_HULL,
				filter = tFilter
			}

			local flDistance, vPoint = util.DistanceToLine( vPos, trRay.HitPos, vEnemy )

			if bGenerous then
				local trPoint = util.TraceLine {
					start = vPoint,
					endpos = vEnemy,
					mask = MASK_SHOT_HULL,
					filter = tFilter
				}

				// TODO: Do a more generous check here to allow firing at where the enemy will come from
				if trPoint.Hit then yield() continue end

				pSchedule.vSuppressionPoint = vPoint
				if flDistance > RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then pSchedule.bSuppressionDontWarn = true end
				return
			else
				if flDistance > RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then yield() continue end

				local trPoint = util.TraceLine {
					start = vPoint,
					endpos = vEnemy,
					mask = MASK_SHOT_HULL,
					filter = tFilter
				}

				if trPoint.Hit then yield() continue end

				pSchedule.vSuppressionPoint = vPoint
				return
			end

			yield()
		end
	end )
end

// TODO: Find a lightweight "on the move" suppress target, and validate it
// Also a function to manage both

function ENT:ManageOnTheMoveSuppressionTarget( pSchedule, pEnemy, pTrueEnemy, pEnemyPath )
	if pSchedule.vSuppressionPoint then
		if !self:ValidateOnTheMoveSuppressionTarget( pSchedule, pEnemy, pTrueEnemy, pEnemyPath ) then
			pSchedule.vSuppressionPoint = nil
		end
	end

	local vSuppressionPoint = pSchedule.vSuppressionPoint
	if !vSuppressionPoint then
		vSuppressionPoint = self:FindOnTheMoveSuppressionTarget( pSchedule, pEnemy, pTrueEnemy, pEnemyPath )
		pSchedule.vSuppressionPoint = vSuppressionPoint
	end

	return vSuppressionPoint
end

function ENT:FindOnTheMoveSuppressionTarget( pSchedule, pEnemy, pTrueEnemy, pEnemyPath )
	// TODO
end

function ENT:ValidateOnTheMoveSuppressionTarget( pSchedule, pEnemy, pTrueEnemy, pEnemyPath )
	// TODO: Check if we can shoot it and if it makes sense
end
