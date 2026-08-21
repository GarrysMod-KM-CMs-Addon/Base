ENT.tPreScheduleResetVariables.pTargetWeapon = false

RegisterSchedule( "PickUpGun", { Execute = function( self, pSchedule, MyTable )
	if !table.IsEmpty( MyTable.tEnemies ) then return false end

	if CurTime() > MyTable.flWeaponReloadTime then
		local t = {}
		for wep in pairs( MyTable.tWeapons ) do if wep:Clip1() < wep:GetMaxClip1() then table.insert( t, wep ) end end
		if !table.IsEmpty( t ) then
			MyTable.SetActiveWeapon( self, table.Random( t ), MyTable )
			MyTable.WeaponReload( self, MyTable )
		end
	end

	local pWeapon = pSchedule.pWeapon

	if !IsValid( pWeapon ) then return false end

	if IsValid( pWeapon:GetOwner() ) || IsValid( pWeapon:GetParent() ) then return false end

	MyTable.pTargetWeapon = pWeapon

	local v = self:GetShootPos()
	local f = MyTable.GAME_flReach
	f = f * f
	if v:DistToSqr( pWeapon:NearestPoint( v ) ) <= f || self:GetPos():DistToSqr( pWeapon:NearestPoint( self:GetPos() ) ) <= f then
		MyTable.SetActiveWeapon( self, pWeapon, MyTable )
		return true
	end

	local pPath = pSchedule.pPath

	if !pPath then
		pPath = Path "Follow"
		pSchedule.pPath = pPath
	end

	local _, b = MyTable.ComputePath( self, pPath, pWeapon:GetPos() + pWeapon:OBBCenter() )

	if b == false then return false end // NOT !b

	MyTable.WEAPON_STANCE = WEAPON_STANCE_PASSIVE

	local pGoal = pPath:GetCurrentGoal()
	if pGoal then
		MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	end

	MyTable.MoveAlongPath( self, pPath, MyTable.flJogSpeed, 1 )
end } )
