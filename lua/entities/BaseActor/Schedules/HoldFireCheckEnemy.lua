// True: Semi-good outcome, there is no one there
// False: Bad outcome. The enemy is still there, and since we walked up, we aren't in the best position!
local table_IsEmpty = table.IsEmpty
Actor_RegisterSchedule( "HoldFireCheckEnemy", function( self, sched )
	local tEnemies = sched.tEnemies || self.tEnemies
	if table_IsEmpty( tEnemies ) then return true end
	if !self.bHoldFire then return false end
	local pEnemy = sched.pEnemy
	if IsValid( pEnemy ) then pEnemy = pEnemy
	else pEnemy = self.Enemy if !IsValid( pEnemy ) then return true end end
	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )
	local pEnemyPath = self.pLastEnemyPath || sched.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		self.pLastEnemyPath = pEnemyPath
		sched.pEnemyPath = pEnemyPath
	end
	local v = pEnemy:GetPos()
	self:ComputePath( pEnemyPath, v )
	v = v + pEnemy:OBBCenter()
	local f, b = self:GetPos():Distance( v ), self:BoundingRadius()
	if self:Visible( pEnemy ) && f <= b * 16 then
		// TODO: Replace all of this bullshit with two checks:
		// first off, sweep in front of us, then, behind us
		// (yes, I straight up stole this idea from Splinter Cell: Blacklist)
		local a = ( v - self:GetShootPos() ):Angle()
		a[ 1 ] = math.sin( RealTime() * 2 ) * 22.5
		a[ 2 ] = a[ 2 ] + math.sin( RealTime() * .25 ) * 360
		self.vaAimTargetBody = a
		self.vaAimTargetPose = self.vaAimTargetBody
		if !sched.flTime then sched.flTime = CurTime() + 8 end
		if CurTime() > sched.flTime then self:ReportPositionAsClear( pEnemy:GetPos() + pEnemy:OBBCenter() ) end
	else
		self.vaAimTargetBody = v
		self.vaAimTargetPose = self.vaAimTargetBody
		self:MoveAlongPath( pEnemyPath, f <= b * 32 && self.flWalkSpeed || self.flRunSpeed, 1 )
	end
end )

include "CombatStuff.lua"
