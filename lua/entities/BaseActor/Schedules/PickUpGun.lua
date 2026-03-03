Actor_RegisterSchedule( "PickUpGun", function( self, sched, MyTable )
	if !table.IsEmpty( self.tEnemies ) then return false end
	if CurTime() > MyTable.flWeaponReloadTime then
		local t = {}
		for wep in pairs( MyTable.tWeapons ) do if wep:Clip1() < wep:GetMaxClip1() then table.insert( t, wep ) end end
		if !table.IsEmpty( t ) then
			MyTable.SetActiveWeapon( self, table.Random( t ), MyTable )
			MyTable.WeaponReload( self, MyTable )
		end
	end
	local pWeapon = sched.pWeapon
	if !IsValid( pWeapon ) then return false end
	if IsValid( pWeapon:GetOwner() ) then return false end
	local v = self:GetShootPos()
	local f = self.GAME_flReach
	if v:DistToSqr( pWeapon:NearestPoint( v ) ) <= ( f * f ) then
		self:SetActiveWeapon( pWeapon )
		return true
	end
	if !sched.pPath then sched.pPath = Path "Follow" end
	local _, b = self:ComputePath( sched.pPath, pWeapon:GetPos() + pWeapon:OBBCenter() )
	if b == false then return false end // NOT !b
	local pGoal = sched.pPath:GetCurrentGoal()
	if pGoal then
		MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	end
	MyTable.MoveAlongPath( self, sched.pPath, MyTable.flRunSpeed, 1 )
end )
