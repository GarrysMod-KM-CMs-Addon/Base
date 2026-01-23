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

Actor_RegisterSchedule( "TakeCover", function( self, sched, MyTable )
	local tEnemies = sched.tEnemies || MyTable.tEnemies
	if table.IsEmpty( tEnemies ) then return {} end
	local enemy = sched.Enemy
	if !IsValid( enemy ) then enemy = MyTable.Enemy if !IsValid( enemy ) then return {} end end
	local enemy, trueenemy = MyTable.SetupEnemy( self, enemy, MyTable )
	MyTable.bWantsCover = true
	local vec = MyTable.vCover
	if !vec || !MyTable.tCover then
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
			if !tr.Hit || tr.Fraction > MyTable.flSuppressionTraceFraction && tr.HitPos:Distance( v ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
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
					MyTable.vaAimTargetBody = ent:GetPos() + ent:OBBCenter()
					MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
					if MyTable.GetWeaponClipPrimary( self, MyTable ) <= 0 then MyTable.WeaponReload( self, MyTable ) end
					if MyTable.CanAttackHelper( self, ent, MyTable ) then
						MyTable.RangeAttack( self )
					end
					break
				end
			end
		end
		if LevelOfDetail( sched, "flNextSearch" ) then
			local pPath = MyTable.pLastEnemyPath || sched.pEnemyPath
			if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
			MyTable.pLastEnemyPath = pPath
			MyTable.ComputeFlankPath( self, pPath, enemy, MyTable )
			MyTable.vCover = nil
			self:Stand( self:GetCrouchTarget() )
			local pIterator = sched.pIterator
			if !sched.pIterator then
				pIterator = MyTable.SearchAreas( self, nil, nil, MyTable )
				sched.pIterator = pIterator
			end
			local vEnemy = enemy:GetPos()
			local vTarget = vEnemy + enemy:OBBCenter()
			local v = sched.vCoverBounds || MyTable.GatherCoverBounds( self, MyTable )
			sched.vCoverBounds = v
			local tAllies = MyTable.GetAlliesByClass( self, MyTable )
			local f = sched.flBoundingRadiusTwo || ( self:BoundingRadius() ^ 2 )
			sched.flBoundingRadiusTwo = f
			local vMins, vMaxs = sched.vMins || ( MyTable.vHullDuckMins || MyTable.vHullMins ) + Vector( 0, 0, MyTable.loco:GetStepHeight() ), MyTable.vHullDuckMaxs || MyTable.vHullMaxs
			sched.vMins = vMins
			local tCovers = {}
			local d = MyTable.vHullMaxs.x * 4
			local flSuppressionTraceFraction = MyTable.flSuppressionTraceFraction
			local RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			for _ = 0, 16 do
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
						pPath:MoveCursor( self:BoundingRadius() * MyTable.flPathStabilizer )
						dDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() ) - dDirection
						dDirection[ 3 ] = 0
						dDirection:Normalize()
						if dDirection:IsZero() then
							dDirection = vEnemy - vCover
							dDirection[ 3 ] = 0
							dDirection:Normalize()
						end
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
						if !util_TraceLine( {
							start = v,
							endpos = v + dDirection * vMaxs[ 1 ] * COVER_BOUND_SIZE,
							filter = self
						} ).Hit then continue end
						local tr = util_TraceLine {
							start = v,
							endpos = vTarget,
							mask = MASK_SHOT_HULL,
							filter = { self, enemy, trueenemy }
						}
						if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:DistToSqr( vTarget ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR then
							local d = vEnemy - vCover
							d[ 3 ] = 0
							d:Normalize()
							if !util_TraceLine( {
								start = v,
								endpos = v + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
								filter = self
							} ).Hit then continue end
						end
						if tAllies then
							local b
							for pAlly in pairs( tAllies ) do
								if self == pAlly then continue end
								if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vCover ) <= f || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vCover ) <= f then b = true break end
							end
							if b then continue end
						end
						MyTable.vCover = vCover
						MyTable.tCover = tCover
						return
					end
				end
			end
		end
		return
	end
	sched.pIterator = nil
	MyTable.vActualCover = MyTable.vCover
	if !sched.Path then sched.Path = Path "Follow" end
	MyTable.ComputePath( self, sched.Path, MyTable.vCover, MyTable )
	if LevelOfDetail( sched, "flNextCheck" ) then
		local tAllies = MyTable.GetAlliesByClass( self, MyTable )
		if tAllies then
			local f = self:BoundingRadius()
			f = f * f
			for ally in pairs( tAllies ) do
				if self == ally then continue end
				if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= f || ally.vActualTarget && ally.vActualTarget:DistToSqr( vec ) <= f then self.vCover = nil return end
			end
		end
		local vMaxs = MyTable.vHullDuckMaxs || MyTable.vHullMaxs
		local v = vec + Vector( 0, 0, vMaxs[ 3 ] )
		// Don't even try to repath often!
		local pEnemyPath = MyTable.pLastEnemyPath || sched.pEnemyPath
		if !pEnemyPath then
			pEnemyPath = Path "Follow"
			MyTable.ComputeFlankPath( self, pEnemyPath, enemy, MyTable )
			sched.pEnemyPath = pEnemyPath
		end
		pEnemyPath:MoveCursorToClosestPosition( vec )
		local d = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() )
		pEnemyPath:MoveCursor( self:BoundingRadius() * MyTable.flPathStabilizer )
		d = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - d
		d[ 3 ] = 0
		d:Normalize()
		if d:IsZero() then d = enemy:GetPos() - vec d[ 3 ] = 0 d:Normalize() end
		if !util_TraceLine( {
			start = v,
			endpos = v + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
			mask = MASK_SHOT_HULL,
			filter = self
		} ).Hit then MyTable.vCover = nil MyTable.tCover = nil return end
		local v = self:GetPos() + Vector( 0, 0, vMaxs[ 3 ] )
		if util_TraceLine( {
			start = v,
			endpos = v + d * vMaxs[ 1 ] * COVER_BOUND_SIZE,
			filter = self
		} ).Hit then
			local f = MyTable.flPathTolerance
			if self:GetPos():DistToSqr( vec ) <= ( f * f ) then return true end
		end
	end
	local tNearestEnemies = {}
	for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
	table.SortByMember( tNearestEnemies, 2, true )
	local c = MyTable.GetWeaponClipPrimary( self, MyTable )
	if c != -1 && c <= 0 then MyTable.WeaponReload( self, MyTable ) end
	local tAllies, pEnemy = MyTable.GetAlliesByClass( self, MyTable )
	for _, d in ipairs( tNearestEnemies ) do
		local ent = d[ 1 ]
		local v = ent:GetPos() + ent:OBBCenter()
		local tr = util_TraceLine {
			start = self:GetShootPos(),
			endpos = v,
			mask = MASK_SHOT_HULL,
			filter = { self, ent }
		}
		if !tr.Hit || tr.Fraction > MyTable.flSuppressionTraceFraction && tr.HitPos:Distance( v ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
			local b = true
			if tr.Hit && ent.GAME_tSuppressionAmount then
				local flThreshold, flSoFar = ent:Health() * .1, 0
				for other, am in pairs( ent.GAME_tSuppressionAmount ) do
					if other == self || self:Disposition( other ) != D_LI || CurTime() <= ( other.flWeaponReloadTime || 0 ) then continue end
					flSoFar = flSoFar + am
					if flSoFar > flThreshold then continue end
				end
				if flSoFar > flThreshold then continue end
			else b = true end
			if b then
				MyTable.vaAimTargetBody = ent:GetPos() + ent:OBBCenter()
				MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
				pEnemy = ent
				if MyTable.CanAttackHelper( self, ent, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
				break
			end
		end
	end
	if IsValid( pEnemy ) then
		MyTable.MoveAlongPath( self, sched.Path, MyTable.flRunSpeed, 1 )
	else
		local goal = sched.Path:GetCurrentGoal()
		if goal then
			MyTable.vaAimTargetBody = ( goal.pos - self:GetPos() ):Angle()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			MyTable.ModifyMoveAimVector( self, MyTable.vaAimTargetBody, MyTable.flTopSpeed, 1, MyTable )
		end
		MyTable.MoveAlongPathToCover( self, sched.Path )
	end
end )
