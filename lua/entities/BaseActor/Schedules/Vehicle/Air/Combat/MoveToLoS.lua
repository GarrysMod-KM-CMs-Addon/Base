RegisterSchedule( "VehicleAirMoveToLoS", { Execute = function( self, sched, MyTable )
	local tEnemies = MyTable.tEnemies
	if table.IsEmpty( tEnemies ) then return true end
	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end
	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy )
	local pVehicle = MyTable.GAME_pVehicle
	if bit.band( pVehicle.TRAVERSES, TRAVERSES_AIR ) == 0 then MyTable.SetSchedule( self, "VehicleBase", MyTable ) return end
	if !sched.vPoint then sched.vPoint = self:GetPos() end
	local vEnemy = pEnemy:GetPos() + pEnemy:OBBCenter()
	local vCenter = pVehicle:GetPos() + pVehicle:OBBCenter()
	local a = ( vEnemy - vCenter ):Angle()
	a[ 1 ] = 0
	a[ 3 ] = 0
	pVehicle:Turn( a )
	pVehicle:AimWeapon( vEnemy )
	if !self.bHoldFire && pVehicle:DoesWeaponHit( vEnemy, pEnemy ) then pVehicle:FireWeapon() end
	local vPoint = sched.vPoint
	local tr = util.TraceLine {
		start = vPoint,
		endpos = vEnemy,
		filter = IsValid( pTrueEnemy ) && { self, pEnemy, pTrueEnemy } || { self, pEnemy },
		mask = MASK_SHOT_HULL
	}
	// If we can't see them from there, tell engage to find us a new point...
	if tr.Hit then MyTable.SetSchedule( self, "VehicleAirEngage", MyTable ) return end
	pVehicle:Move( CalculateVelocity( vPoint, vCenter, pVehicle:GetPhysicsObject():GetVelocity(), pVehicle.flTopSpeed, pVehicle.flAcceleration ) )
	if vCenter:DistToSqr( vPoint ) <= ( pVehicle:BoundingRadius() * pVehicle:BoundingRadius() ) then
		MyTable.SetSchedule( self, "VehicleAirEngage", MyTable )
	end
end } )
