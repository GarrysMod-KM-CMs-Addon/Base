if !CLASS_HUMAN_TERRORIST then Add_NPC_Class "CLASS_HUMAN_TERRORIST" end

__ALARM_REINFORCEMENTS__[ CLASS_HUMAN_TERRORIST ] = function( pAlarm, vPos, flDifficultyMultiplier )
	local iToSpawn = math.Round( math.random( 8, 12 ) * flDifficultyMultiplier )
	if iToSpawn <= 0 then return end
	local pArea, flDistance = navmesh.GetNearestNavArea( vPos )
	if !pArea then return end
	local tQueue, tVisited = { { pArea, 0 } }, { [ pArea:GetID() ] = true }
	while !table.IsEmpty( tQueue ) && iToSpawn > 0 do
		pArea, flDistance = unpack( table.remove( tQueue ) )
		for _, t in ipairs( pArea:GetAdjacentAreaDistances() ) do
			local pNew = t.area
			local id = pNew:GetID()
			if tVisited[ id ] then continue end
			tVisited[ id ] = true
			if pNew:IsUnderwater() then continue end
			table.insert( tQueue, { pNew, ( flDistance + t.dist ) * math.Rand( 0, 1 ) } )
		end
		local vCenter = pArea:GetCenter()
		if !Alarm_IsClouded( vCenter + Vector( 0, 0, 72 ), vPos, pAlarm ) then continue end
		if util.TraceHull( {
			start = vCenter,
			endpos = vCenter,
			mins = HULL_HUMAN_MINS + Vector( 0, 0, 12 ),
			maxs = HULL_HUMAN_MAXS,
			mask = MASK_SOLID
		} ).Hit then continue end
		local pActor = ents.Create "HumanTerrorist"
		pActor:SetPos( vCenter )
		pActor:SetAngles( Angle( 0, math.Rand( 0, 360 ), 0 ) )
		pActor:Spawn()
		// Don't pass the second argument, as it is MyTable!
		local sWeapon = table.Random( list.GetForEdit( "NPC" ).HumanTerrorist.Weapons )
		pActor:Give( sWeapon )
		iToSpawn = iToSpawn - 1
	end
end
