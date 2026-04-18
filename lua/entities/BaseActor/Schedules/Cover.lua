ENT.tPreScheduleResetVariables.vActualCover = false
ENT.tPreScheduleResetVariables.vActualTarget = false

function ENT:GatherCoverBounds()
	local vHullMaxs, vHullDuckMaxs = self.vHullMaxs, self.vHullDuckMaxs
	if vHullDuckMaxs && vHullDuckMaxs[ 3 ] != vHullMaxs[ 3 ] then return Vector( 0, 0, vHullDuckMaxs[ 3 ] ) end
	return Vector( 0, 0, vHullMaxs[ 3 ] )
end

include "CoverMove.lua"

local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull

Actor_RegisterSchedule( "TakeCover", function( self, sched, MyTable )
	MyTable.WEAPON_STANCE = MyTable.Moving_WEAPON_STANCE
	local tEnemies = sched.tEnemies || MyTable.tEnemies
	if table.IsEmpty( tEnemies ) then return true end
	local enemy = sched.Enemy
	if !IsValid( enemy ) then enemy = MyTable.Enemy if !IsValid( enemy ) then return true end end
	local enemy, trueenemy = MyTable.SetupEnemy( self, enemy, MyTable )
	MyTable.bWantsCover = true
	local tCover = MyTable.tCover
	local vec = MyTable.vCover
	if tCover then
		local pEntity = tCover[ 6 ]
		if pEntity != nil && !IsValid( pEntity ) then MyTable.tCover = nil MyTable.vCover = nil vec = nil tCover = nil end
	end
	if !vec || !tCover then
		if sched.bBeganSearching then return end
		sched.bBeganSearching = true
		ACTOR_QUEUE( function()
			if !IsValid( self ) || MyTable.Schedule != sched then return true end
			local pPath = MyTable.pEnemyPath || sched.pEnemyPath
			if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
			MyTable.pEnemyPath = pPath
			MyTable.ComputeFlankPath( self, pPath, enemy, MyTable )
			MyTable.vCover = nil
			self:Stand( self:GetCrouchTarget() )
			local pIterator = MyTable.SearchAreas( self, nil, nil, MyTable )
			local vEnemy = enemy:GetPos()
			local vTarget = vEnemy + enemy:OBBCenter()
			local v = MyTable.GatherCoverBounds( self, MyTable )
			local tAllies = MyTable.GetAlliesByClass( self, MyTable )
			local f = self:BoundingRadius() ^ 2
			local vMins, vMaxs = ( MyTable.vHullDuckMins || MyTable.vHullMins ) + Vector( 0, 0, MyTable.loco:GetStepHeight() ), MyTable.vHullDuckMaxs || MyTable.vHullMaxs
			local tCovers
			local d = MyTable.vHullMaxs[ 1 ] * 4
			local flSuppressionTraceFraction = MyTable.flSuppressionTraceFraction
			local RANGE_ATTACK_SUPPRESSION_BOUND_SIZE_SQR = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			while true do
				if !IsValid( self ) || MyTable.Schedule != sched then return true end
				local pArea = pIterator()
				if pArea == nil then
					// REPEAT!!! AND TRY HARDER!!!
					pIterator = MyTable.SearchAreas( self, nil, nil, MyTable )
					coroutine.yield()
				end
				tCovers = {}
				for _, t in ipairs( __COVERS_STATIC__[ pArea:GetID() ] || {} ) do table.insert( tCovers, { t, util.DistanceToLine( t[ 1 ], t[ 2 ], self:GetPos() ) } ) end
				for pEntity, tTable in pairs( __COVERS_DYNAMIC__[ pArea:GetID() ] || {} ) do
					if !IsValid( pEntity ) then continue end
					for _, t in pairs( tTable ) do table.insert( tCovers, { t, util.DistanceToLine( t[ 1 ], t[ 2 ], self:GetPos() ) } ) end
				end
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
						sched.bBeganSearching = nil
						return true
					end
				end
				coroutine.yield()
			end
		end )
		return
	end
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
		local pEnemyPath = MyTable.pEnemyPath
		if !pEnemyPath then
			pEnemyPath = Path "Follow"
			MyTable.pEnemyPath = pEnemyPath
		end
		MyTable.ComputePath( self, pEnemyPath, enemy:GetPos(), MyTable )
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
	end
	local f = MyTable.flPathTolerance
	if self:GetPos():DistToSqr( vec ) <= ( f * f ) then return true end
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
		MyTable.MoveAlongPath( self, sched.Path, MyTable.flRunSpeed, 1, Either( pEntity == nil, nil, { self, pEntity } ) )
	else
		local goal = sched.Path:GetCurrentGoal()
		if goal then
			MyTable.vaAimTargetBody = ( goal.pos - self:GetPos() ):Angle()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			MyTable.ModifyMoveAimVector( self, MyTable.vaAimTargetBody, MyTable.flTopSpeed, 1, MyTable )
		end
		MyTable.MoveAlongPathToCover( self, sched.Path, Either( pEntity == nil, nil, { self, pEntity } ) )
	end
end )
