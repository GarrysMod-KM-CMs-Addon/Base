Actor_RegisterSchedule( "VehicleAirEngage", function( self, sched, MyTable )
	local tEnemies = sched.tEnemies || MyTable.tEnemies
	if table.IsEmpty( tEnemies ) then return true end
	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end
	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy )
	local pVehicle = MyTable.GAME_pVehicle
	if bit.band( pVehicle.TRAVERSES, TRAVERSES_AIR ) == 0 then MyTable.SetSchedule( self, "VehicleBase", MyTable ) return end
	if !sched.vPoint then sched.vPoint = self:GetPos() end
	local vCenter = self:GetPos() + self:OBBCenter()
	local f = pVehicle:BoundingRadius() * 2
	if vCenter:DistToSqr( sched.vPoint ) <= ( f * f ) then
		pVehicle:Move( CalculateVelocity( sched.vPoint, vCenter, pVehicle:GetPhysicsObject():GetVelocity(), pVehicle.flTopSpeed * .1, pVehicle.flAcceleration ) )
	else pVehicle:Move( CalculateVelocity( sched.vPoint, vCenter, pVehicle:GetPhysicsObject():GetVelocity(), pVehicle.flTopSpeed, pVehicle.flAcceleration ) ) end
	local vEnemy = pEnemy:GetPos() + pEnemy:OBBCenter()
	local dToEnemy = vEnemy - vCenter
	local a = dToEnemy:Angle()
	dToEnemy:Normalize()
	a[ 1 ] = 0
	a[ 3 ] = 0
	pVehicle:Turn( a )
	pVehicle:AimWeapon( vEnemy )
	if !self.bHoldFire && pVehicle:DoesWeaponHit( vEnemy, pEnemy ) then pVehicle:FireWeapon() end
	local vShoot = self:GetShootPos()
	local tr = util.TraceLine {
		start = vShoot,
		endpos = vEnemy,
		filter = IsValid( pTrueEnemy ) && { self, pVehicle, pEnemy, pTrueEnemy } || { self, pVehicle, pEnemy },
		mask = MASK_SHOT_HULL
	}
	if tr.Hit then
		debugoverlay.Line( vShoot, vEnemy, .1, Color( 255, 0, 0 ), true )
		local vCenter = pVehicle:GetPos() + pVehicle:OBBCenter()
		local flBoundingRadius = pVehicle:BoundingRadius()
		for flBias = 0, 1, math.Rand( .1, .2 ) do
			for i = 1, 3 do
				for flDistance = 0, math.Rand( 0, math.min( flBoundingRadius * 32, vCenter:Distance( vEnemy ) * 2 ) ), math.Rand( flBoundingRadius * .5, flBoundingRadius * 4 ) do
					local d = LerpVector( 1 - flBias, VectorRand():GetNormalized(), dToEnemy ):GetNormalized()
					local trJustToBeSafe = util.TraceLine {
						start = vCenter,
						endpos = vCenter + d * ( flDistance + flBoundingRadius * 2 ),
						filter = self,
						mask = MASK_SOLID
					}
					if trJustToBeSafe.Hit then
						debugoverlay.Line( tr.StartPos, tr.HitPos, .1, Color( 255, 0, 0 ), true )
						continue
					end
					local tr = util.TraceLine {
						start = vCenter,
						endpos = vCenter + d * flDistance,
						filter = self,
						mask = MASK_SOLID
					}
					local trToTarget = util.TraceLine {
						start = tr.HitPos,
						endpos = vEnemy,
						filter = IsValid( pTrueEnemy ) && { self, pVehicle, pEnemy, pTrueEnemy } || { self, pVehicle, pEnemy },
						mask = MASK_SOLID
					}
					if trToTarget.Hit then
						debugoverlay.Line( tr.StartPos, tr.HitPos, .1, Color( 0, 255, 0 ), true )
						debugoverlay.Line( trToTarget.StartPos, trToTarget.HitPos, .1, Color( 255, 0, 0 ), true )
						continue
					end
					debugoverlay.Line( tr.StartPos, tr.HitPos, 1, Color( 0, 255, 0 ), true )
					debugoverlay.Line( trToTarget.StartPos, trToTarget.HitPos, 1, Color( 0, 255, 0 ), true )
					MyTable.SetSchedule( self, "VehicleAirMoveToLoS", MyTable ).vPoint = tr.HitPos
				end
			end
		end
	else
		debugoverlay.Line( vShoot, vEnemy, .1, Color( 0, 255, 0 ), true )
	end
end )
