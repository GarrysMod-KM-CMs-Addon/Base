include "MoveToLoS.lua"

RegisterSchedule( "VehicleAirEngage", { Execute = function( self, pSchedule, MyTable )
	local tEnemies = MyTable.tEnemies
	if table.IsEmpty( tEnemies ) then return true end
	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end
	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy )
	local pVehicle = MyTable.GAME_pVehicle
	if bit.band( pVehicle.TRAVERSES, TRAVERSES_AIR ) == 0 then MyTable.SetSchedule( self, "VehicleBase", MyTable ) return end
	if !pSchedule.vPoint then pSchedule.vPoint = self:GetPos() end
	local vCenter = self:GetPos() + self:OBBCenter()
	local f = pVehicle:BoundingRadius() * 2
	if vCenter:DistToSqr( pSchedule.vPoint ) <= ( f * f ) then
		pVehicle:Move( CalculateVelocity( pSchedule.vPoint, vCenter, pVehicle:GetPhysicsObject():GetVelocity(), pVehicle.flTopSpeed * .1, pVehicle.flAcceleration ) )
	else pVehicle:Move( CalculateVelocity( pSchedule.vPoint, vCenter, pVehicle:GetPhysicsObject():GetVelocity(), pVehicle.flTopSpeed, pVehicle.flAcceleration ) ) end
	local vEnemy = pEnemy:GetPos() + pEnemy:OBBCenter()
	local dToEnemy = vEnemy - vCenter
	local a = dToEnemy:Angle()
	dToEnemy:Normalize()
	a[ 1 ] = 0
	a[ 3 ] = 0
	pVehicle:Turn( a )
	pVehicle:AimWeapon( vEnemy )

	if !MyTable.bHoldFire && pVehicle:MachineGunWeaponCanHit( vEnemy, pTrueEnemy ) && pVehicle:MachineGunWeaponHits( vEnemy, pTrueEnemy ) then
		MyTable.flWeaponPrimaryVolleyTimeMin = 0
		MyTable.flWeaponPrimaryVolleyTimeMax = 8

		MyTable.flWeaponPrimaryVolleyBreakMin = 0
		MyTable.flWeaponPrimaryVolleyBreakMax = 2

		if MyTable.WeaponPrimaryVolleyContainer( self, "VehicleMachineGun", true, MyTable ) then pVehicle:FireMachineGunWeapon() end
	end

	local vShoot = self:GetShootPos()

	local tr = util.TraceLine {
		start = vShoot,
		endpos = vEnemy,
		filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy ),
		mask = MASK_SHOT_HULL
	}

	if MyTable.UpdatePursuitSenses( self, pEnemy, pTrueEnemy, MyTable ) then
		// TODO: Pursuit
	end

	if tr.Hit then
		if pSchedule.bSearching then return end

		ACTOR_QUEUE( function()
			if !IsValid( self ) || !IsValid( pVehicle ) || !IsValid( pEnemy ) || !IsValid( pTrueEnemy ) || self.Schedule != pSchedule then return true end

			local vCenter = pVehicle:GetPos() + pVehicle:OBBCenter()
			local flBoundingRadius = pVehicle:BoundingRadius()

			local flBias = .5 - math.random() * math.random() * .5
			while flBias <= 1 do
				if !IsValid( self ) || !IsValid( pVehicle ) || !IsValid( pEnemy ) || !IsValid( pTrueEnemy ) || self.Schedule != pSchedule then return true end

				local f = vCenter:Distance( vEnemy )
				local flDistance = 0
				while flDistance <= f * 2 do
					local flCurrent = flDistance
					flDistance = flDistance + math.Rand( f * .125, f * .5 )

					local d = LerpVector( 1 - flBias, VectorRand():GetNormalized(), dToEnemy ):GetNormalized()

					local trJustToBeSafe = util.TraceLine {
						start = vCenter,
						endpos = vCenter + d * ( flCurrent + flBoundingRadius * 2 ),
						filter = self,
						mask = MASK_SOLID
					}

					if trJustToBeSafe.Hit then coroutine.yield() continue end

					local tr = util.TraceLine {
						start = vCenter,
						endpos = vCenter + d * flCurrent,
						filter = self,
						mask = MASK_SOLID
					}

					local trToTarget = util.TraceLine {
						start = tr.HitPos,
						endpos = vEnemy,
						filter = IsValid( pTrueEnemy ) && { self, pVehicle, pEnemy, pTrueEnemy } || { self, pVehicle, pEnemy },
						mask = MASK_SOLID
					}

					if trToTarget.Hit then coroutine.yield() continue end
					MyTable.SetSchedule( self, "VehicleAirMoveToLoS", MyTable ).vPoint = tr.HitPos
				end

				flBias = flBias + math.Rand( 0, .2 )
			end
		end )

		return
	end
end } )
