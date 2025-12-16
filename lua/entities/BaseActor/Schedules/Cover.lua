ENT.tPreScheduleResetVariables.vActualCover = false
ENT.tPreScheduleResetVariables.vActualTarget = false

function ENT:GatherCoverBounds()
	if self.vHullDuckMaxs && self.vHullDuckMaxs.z != self.vHullMaxs.z then return Vector( 0, 0, self.vHullDuckMaxs.z * .65625 ) end
	return Vector( 0, 0, self.vHullMaxs.z )
end

include "CoverMove.lua"
include "CoverUnReachable.lua"

local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull

Actor_RegisterSchedule( "TakeCover", function( self, sched )
	local tEnemies = sched.tEnemies || self.tEnemies
	if table.IsEmpty( tEnemies ) then return {} end
	local enemy = sched.Enemy
	if !IsValid( enemy ) then enemy = self.Enemy if !IsValid( enemy ) then return {} end end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	self.bWantsCover = true
	if self.vCover then
		sched.pIterator = nil
		local vec = self.vCover
		self.vActualCover = self.vCover
		local tAllies = self:GetAlliesByClass()
		if tAllies then
			local f = self:BoundingRadius()
			f = f * f
			for ally in pairs( tAllies ) do
				if self == ally then continue end
				if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= f || ally.vActualTarget && ally.vActualTarget:DistToSqr( vec ) <= f then self.vCover = nil return end
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
		local c = self:GetWeaponClipPrimary()
		if c != -1 && c <= 0 then self:WeaponReload() end
		local tAllies, pEnemy = self:GetAlliesByClass()
		for _, d in ipairs( tNearestEnemies ) do
			local ent = d[ 1 ]
			local v = ent:GetPos() + ent:OBBCenter()
			local tr = util_TraceLine {
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
					if self:CanAttackHelper( ent:GetPos() + ent:OBBCenter() ) then self:RangeAttack() end
					break
				end
			end
		end
		if IsValid( pEnemy ) then
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
	else
		local pPath = sched.pEnemyPath
		if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
		self:ComputeFlankPath( pPath, enemy )
		self.vCover = nil
		local tNearestEnemies = {}
		for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
		table.SortByMember( tNearestEnemies, 2, true )
		local tAllies, pEnemy = self:GetAlliesByClass()
		for _, d in ipairs( tNearestEnemies ) do
			local ent = d[ 1 ]
			local v = ent:GetPos() + ent:OBBCenter()
			local tr = util_TraceLine {
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
					if self:GetWeaponClipPrimary() <= 0 then self:WeaponReload() end
					if self:CanAttackHelper( ent:GetPos() + ent:OBBCenter() ) then
						self:RangeAttack()
					end
					break
				end
			end
		end
		self:Stand( self:GetCrouchTarget() )
		local pIterator = sched.pIterator
		if !sched.pIterator then
			pIterator = self:SearchAreas()
			sched.pIterator = pIterator
		end
		local vEnemy = enemy:GetPos()
		local v = sched.vCoverBounds || self:GatherCoverBounds()
		sched.vCoverBounds = v
		local tAllies = self:GetAlliesByClass()
		local f = sched.flBoundingRadiusTwo || ( self:BoundingRadius() ^ 2 )
		sched.flBoundingRadiusTwo = f
		local vMins, vMaxs = sched.vMins || ( self.vHullDuckMins || self.vHullMins ) + Vector( 0, 0, self.loco:GetStepHeight() ), self.vHullDuckMaxs || self.vHullMaxs
		sched.vMins = vMins
		local tCovers = {}
		local d = self.vHullMaxs.x * 4
		for _ = 0, 64 do
			local pArea = pIterator()
			if pArea == nil then
				// REPEAT!!! AND TRY HARDER!!!
				sched.pIterator = nil
				return
			end
			table.Empty( tCovers )
			for _, t in ipairs( __COVERS_STATIC__[ pArea:GetID() ] || {} ) do table.insert( tCovers, { t, util.DistanceToLine( t[ 1 ], t[ 2 ], self:GetPos() ) } ) end
			for _, t in ipairs( __COVERS_DYNAMIC__[ pArea:GetID() ] || {} ) do table.insert( tCovers, { t, util.DistanceToLine( t[ 1 ], t[ 2 ], self:GetPos() ) } ) end
			table.SortByMember( tCovers, 2, true )
			for _, t in ipairs( tCovers ) do
				local tCover = t[ 1 ]
				local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
				local vDirection = vEnd - vStart
				local flStep, flStart, flEnd
				if vStart:DistToSqr( self:GetPos() ) <= vEnd:DistToSqr( self:GetPos() ) then
					flStart, flEnd, flStep = 0, vDirection:Length(), vMaxs[ 1 ]
				else
					flStart, flEnd, flStep = vDirection:Length(), 0, -vMaxs[ 1 ]
				end
				vDirection:Normalize()
				local vOff = tCover[ 3 ] && vDirection:Angle():Right() || -vDirection:Angle():Right()
				vOff = vOff * vMaxs[ 1 ] * math.max( 1.25, COVER_BOUND_SIZE * .5 )
				for iCurrent = flStart, flEnd, flStep do
					local vCover = vStart + vDirection * iCurrent + vOff
					pPath:MoveCursorToClosestPosition( vCover )
					local dDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() )
					pPath:MoveCursor( 1 )
					dDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() ) - dDirection
					dDirection[ 3 ] = 0
					dDirection:Normalize()
					if util_TraceHull( {
						start = vCover,
						endpos = vCover,
						mins = vMins,
						maxs = vMaxs,
						filter = self
					} ).Hit then continue end
					local v = vCover + Vector( 0, 0, vMaxs[ 3 ] )
					if !util_TraceLine( {
						start = v,
						endpos = v + dDirection * vMaxs[ 1 ] * COVER_BOUND_SIZE,
						filter = self
					} ).Hit then continue end
					if tAllies then
						local b
						for pAlly in pairs( tAllies ) do
							if self == pAlly then continue end
							if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vCover ) <= f || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vCover ) <= f then b = true break end
						end
						if b then continue end
					end
					self.vCover = vCover
					self.tCover = tCover
					return
				end
			end
		end
	end
end )
