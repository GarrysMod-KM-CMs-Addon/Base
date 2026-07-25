local table_IsEmpty = table.IsEmpty

ENT.CombatHeavy_WEAPON_STANCE = WEAPON_STANCE_HIP

RegisterSchedule( "CombatHeavy", { Execute = function( self, sched, MyTable )
	local tEnemies = sched.tEnemies || MyTable.tEnemies
	if table_IsEmpty( tEnemies ) then return true end
	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end
	if MyTable.flCombatState < 0 then MyTable.SetSchedule( self, "Combat", MyTable ) return end
	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )
	local pPath = MyTable.pEnemyPath
	if !pPath then pPath = Path "Follow" MyTable.pEnemyPath = pPath end
	MyTable.ComputeFlankPath( self, pPath, pEnemy, MyTable )
	MyTable.MoveAlongPath( self, pPath, MyTable.flJogSpeed, 1 )
	MyTable.WEAPON_STANCE = MyTable.CombatHeavy_WEAPON_STANCE
	local pWeapon = MyTable.Weapon
	if !IsValid( pWeapon ) then return false end
	local iClip = MyTable.GetWeaponClipPrimary( self, MyTable )
	if iClip != -1 && iClip <= 0 then MyTable.WeaponReload( self, MyTable ) end
	local vEnemy = pEnemy:GetPos() + pEnemy:OBBCenter()
	if !util.TraceLine( {
		start = self:GetShootPos(),
		endpos = vEnemy,
		mask = MASK_SHOT_HULL,
		filter = SimpleRelatedFilterDouble( self, pEnemy )
	} ).Hit then
		MyTable.vaAimTargetBody = vEnemy
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		if MyTable.CanAttackHelper( self, pEnemy, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
		local flHealth = pEnemy:Health()
		local ws, w = 0 // Weapon strength
		for wep in pairs( MyTable.tWeapons ) do
			if wep.bSpecial then continue end
			local t = wep.Primary_flDelay || 0
			if t <= 0 then continue end
			local d = wep.Primary_flDamage || 0
			if d <= 0 then continue end
			local nws = math.abs( flHealth - 1 / ( wep.Primary.Automatic && t || t + MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax ) * d * ( wep.Primary_iNum || 1 ) )
			if nws > ws then w, ws = wep, nws end
		end
		if IsValid( w ) then MyTable.SetActiveWeapon( self, w, MyTable ) end
		return
	end
	local tGoal = pPath:GetCurrentGoal()
	if tGoal then MyTable.vaAimTargetBody = ( tGoal.pos - self:GetPos() ):Angle() MyTable.vaAimTargetPose = MyTable.vaAimTargetBody end
end } )
