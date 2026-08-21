RegisterSchedule( "Alert", { Execute = function( self, pSchedule, MyTable )
	local tEnemies = MyTable.tEnemies
	if !table.IsEmpty( tEnemies ) then return true end

	MyTable.EScheduleState = ACTOR_STATE_ALERT

	// TODO: Alert patrolling
	return true
end } )
