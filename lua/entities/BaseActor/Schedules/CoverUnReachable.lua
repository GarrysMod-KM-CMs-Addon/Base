local table_IsEmpty = table.IsEmpty
local HasRangeAttack = HasRangeAttack
local __SCHEDULE__ = __SCHEDULE__
local CurTime = CurTime
local math_Rand = math.Rand
local unpack = unpack
ENT.tUnReachableComputeTimes = { 4, 6 }

Actor_RegisterSchedule( "TakeCoverWhileUnReachable", function( self, sched )
	local enemy = self:SetupEnemy( self.Enemy )
	if table_IsEmpty( self.tEnemies ) || !IsValid( enemy ) || HasRangeAttack( self ) then return true end
	local p = sched.Path || Path "Follow"
	sched.Path = p
	local f = self.flNextUnReachableCompute
	if !f then f = CurTime() + math_Rand( unpack( self.tUnReachableComputeTimes ) ) end
	self.flNextUnReachableCompute = f
	if CurTime() > f then
		self.flNextUnReachableCompute = CurTime() + math_Rand( unpack( self.tUnReachableComputeTimes ) )
		local p, b = self:ComputeFlankPath( p, enemy )
		if p != true && b then
			self:DLG_MeleeReachable( enemy )
			self.vCover = nil
			return true
		end
	end
	f = self.__SCHEDULE__.TakeCover || __SCHEDULE__.TakeCover
	f = f( self, sched )
	if f != nil then return f end
end )
