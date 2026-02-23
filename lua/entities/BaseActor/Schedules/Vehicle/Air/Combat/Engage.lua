Actor_RegisterSchedule( "VehicleAirEngage", function( self, sched, MyTable )
	local tEnemies = sched.tEnemies || MyTable.tEnemies
	if table.IsEmpty( tEnemies ) then return true end
	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end
	local pVehicle = MyTable.GAME_pVehicle
	if bit.band( pVehicle.TRAVERSES, TRAVERSES_AIR ) == 0 then MyTable.SetSchedule( self, "VehicleBase", MyTable ) return end
	if !sched.vPoint then sched.vPoint = self:GetPos() end
	pVehicle:Stay()
	local v = pEnemy:GetPos() + pEnemy:OBBCenter()
	local a = ( v - ( self:GetPos() + self:OBBCenter() ) ):Angle()
	a[ 1 ] = 0
	a[ 3 ] = 0
	pVehicle:Turn( a )
	pVehicle:AimWeapon( v )
end )
