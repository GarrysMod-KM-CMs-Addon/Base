// NOTE: You should probably use DLG_State_TakeCover() and DLG_State_Retreat() if you want them to shout it once
function ENT:DLG_Advancing() end
function ENT:DLG_Retreating() end
function ENT:DLG_TakeCoverGeneral() end
local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
function ENT:DLG_TakeCoverAdvance() CEntity_GetTable( self ).DLG_TakeCoverGeneral( self ) end
function ENT:DLG_TakeCoverRetreat() CEntity_GetTable( self ).DLG_TakeCoverGeneral( self ) end

local util_TraceLine = util.TraceLine

Actor_RegisterSchedule( "TakeCoverMove", function( self, sched )
	local tEnemies = sched.tEnemies || self.tEnemies
	if table.IsEmpty( tEnemies ) then return {} end
	if !self:CanExpose() then self.vCover = nil self:SetSchedule "TakeCover" return end
	local enemy = sched.Enemy
	if !IsValid( enemy ) then enemy = self.Enemy if !IsValid( enemy ) then return {} end end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	local c = self:GetWeaponClipPrimary()
	if c != -1 && c <= 0 then self:WeaponReload() end
	if self.vCover then
		if sched.bActed == nil then
			if sched.bTakeCoverAdvance then self:DLG_TakeCoverAdvance()
			elseif sched.bTakeCoverRetreat then self:DLG_TakeCoverRetreat()
			elseif sched.bAdvancing then self:DLG_Advancing()
			elseif sched.bRetreating then self:DLG_Retreating() end
			sched.bActed = true
		end
		local vec = self.vCover
		local tAllies = self:GetAlliesByClass()
		if tAllies then
			local f = self:BoundingRadius()
			f = f * f
			for ally in pairs( tAllies ) do
				if self == ally then continue end
				if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= f || ally.vActualTarget && ally.vActualTarget:DistToSqr( vec ) <= f then self.vCover = nil self.pCover = nil self:SetSchedule "TakeCover" return end
			end
			if !sched.bTriedRangeAttack then
				local b
				for ally in pairs( tAllies ) do
					if self != ally && ally.bWantsCover then
						b = true
						break
					end
				end
				if b then
					local vec = self:GetPos()
					local v, pEnemy = self:FindExposedEnemy( vec, tEnemies, sched.bDuck )
					if IsValid( pEnemy ) then
						local sched = self:SetSchedule "RangeAttack"
						sched.vFrom = v
						sched.Enemy = pEnemy
					else
						if !sched.pEnemyPath then sched.pEnemyPath = Path "Follow" end
						self:ComputeFlankPath( sched.pEnemyPath, enemy )
						local vFrom, vTo, pEnemy = self:FindSuppressEnemy( vec, tEnemies, sched.bDuck )
						if IsValid( pEnemy ) then
							local sched = self:SetSchedule "RangeAttack"
							sched.vFrom = vFrom
							sched.vTo = vTo
							sched.Enemy = pEnemy
							sched.bSuppressing = true
						end
					end
					sched.bTriedRangeAttack = true
				end
			end
		end
		local vMaxs = self.vHullDuckMaxs || self.vHullMaxs
		local v = vec + Vector( 0, 0, vMaxs[ 3 ] )
		// Don't even try to repath often!
		local pEnemyPath = self.pLastEnemyPath || sched.pEnemyPath
		if !pEnemyPath then
			pEnemyPath = Path "Follow"
			self:ComputePath( pEnemyPath, enemy:GetPos() )
			sched.pEnemyPath = pEnemyPath
		end
		pEnemyPath:MoveCursorToClosestPosition( vec )
		local d = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() )
		pEnemyPath:MoveCursor( 1 )
		d = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - d
		d[ 3 ] = 0
		d:Normalize()
		if !util_TraceLine( {
			start = v,
			endpos = v + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
			mask = MASK_SHOT_HULL,
			filter = self
		} ).Hit then self.vCover = nil self.tCover = nil return end
		if !sched.Path then sched.Path = Path "Follow" end
		self:ComputePath( sched.Path, self.vCover )
		local v = self:GetPos() + Vector( 0, 0, vMaxs[ 3 ] )
		if util_TraceLine( {
			start = v,
			endpos = v + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
			filter = self
		} ).Hit then
			local f = self.flPathTolerance
			if self:GetPos():DistToSqr( vec ) <= ( f * f ) then return true end
		end
		local tNearestEnemies = {}
		for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
		table.SortByMember( tNearestEnemies, 2, true )
		local tAllies, pEnemy = self:GetAlliesByClass()
		for _, d in ipairs( tNearestEnemies ) do
			local ent = d[ 1 ]
			local v = ent:GetPos() + ent:OBBCenter()
			local tr = util.TraceLine {
				start = self:GetShootPos(),
				endpos = v,
				mask = MASK_SHOT_HULL,
				filter = { self, ent }
			}
			if !tr.Hit || tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( v ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
				local b = true
				if ent.GAME_tSuppressionAmount then
					local flThreshold, flSoFar = ent:Health() * .1, 0
					for other, am in pairs( ent.GAME_tSuppressionAmount ) do
						if other == self || self:Disposition( other ) != D_LI || CurTime() <= ( other.flWeaponReloadTime || 0 ) then continue end
						flSoFar = flSoFar + am
						if flSoFar > flThreshold then continue end
					end
					if flSoFar > flThreshold then continue end
				else b = true end
				if b then
					self.vaAimTargetBody = ent:GetPos() + ent:OBBCenter()
					self.vaAimTargetPose = self.vaAimTargetBody
					pEnemy = ent
					if self:CanAttackHelper( ent ) then self:RangeAttack() end
					break
				end
			end
		end
		if IsValid( pEnemy ) then
			if self.bCoverDuck == true then sched.bCoverStand = nil
			elseif sched.bCoverStand == nil then sched.bCoverStand = math.random( 2 ) == 1 end
			self:MoveAlongPath( sched.Path, self.flRunSpeed, 1 )
		else
			local goal = sched.Path:GetCurrentGoal()
			if goal then
				self.vaAimTargetBody = ( goal.pos - self:GetPos() ):Angle()
				self.vaAimTargetPose = self.vaAimTargetBody
				self:ModifyMoveAimVector( self.vaAimTargetBody, self.flTopSpeed, 1 )
			end
			self:MoveAlongPathToCover( sched.Path )
		end
	else return {} end
end )
