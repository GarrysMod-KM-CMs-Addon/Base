include "Air/Combat/Engage.lua"

Actor_RegisterSchedule( "VehicleBase", function( self, sched, MyTable )
	local pEnemy = MyTable.Enemy
	if IsValid( pEnemy ) then
		if bit.band( MyTable.GAME_pVehicle.TRAVERSES, TRAVERSES_AIR ) != 0 then MyTable.SetSchedule( self, "VehicleAirEngage", MyTable ) return end
		return true
	end
end )
