RegisterSchedule( "PickUpGun", { Execute = function( self, sched, MyTable )
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
	if IsValid( pWeapon:GetOwner() ) || IsValid( pWeapon:GetParent() ) then return false end
	local v = self:GetShootPos()
	local f = self.GAME_flReach
	f = f * f
	if v:DistToSqr( pWeapon:NearestPoint( v ) ) <= f || self:GetPos():DistToSqr( pWeapon:NearestPoint( self:GetPos() ) ) <= f then
		MyTable.SetActiveWeapon( self, pWeapon, MyTable )
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
	MyTable.MoveAlongPath( self, sched.pPath, MyTable.flJogSpeed, 1 )
end } )
