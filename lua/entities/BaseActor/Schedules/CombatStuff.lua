// TODO: Break down the file into files with the name of the schedules, like Cover.lua

ENT.tPreScheduleResetVariables.bSuppressing = false
ENT.tPreScheduleResetVariables.bWantsCover = false

function ENT:RangeAttack()
	if self.bHoldFire then return end
	self:WeaponPrimaryVolley()
	// Set back to the default values for next no-custom-template shots
	self.tWeaponPrimaryVolleyTimes = { 0, 3 }
	self.tWeaponPrimaryVolleyBreaks = { .33, .66 }
	self.tWeaponPrimaryVolleyNonAutomaticDelay = { 0, .4 }
	return true
end

// Small suppressed, does NOT want someone else to help yet
function ENT:DLG_Suppressed() end

// See the code, I have no easy way of explaining this one
ENT.flSuppressionTraceFraction = .8

ENT.flCoverMoveStart = 1
ENT.flCoverMoveStartSuppressed = 0
ENT.flCoverMoveStep = 1
ENT.flCoverMoveShort = 4
ENT.flCoverMoveNotShort = 8

local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull

function ENT:CalcMyExposedShootPositions( enemy, vPos, bDuck, vStand, vDuck )
	local enemy, trueenemy = self:SetupEnemy( enemy )
	local t, bHasShort = {}
	local vShoot = enemy:GetPos() + enemy:OBBCenter()
	if vDuck && !util_TraceLine( {
		start = vPos + vDuck,
		endpos = vShoot,
		mask = MASK_SHOT_HULL,
		filter = { self, enemy, trueenemy }
	} ).Hit || !util_TraceLine( {
		start = vPos + vStand,
		endpos = vShoot,
		mask = MASK_SHOT_HULL,
		filter = { self, enemy, trueenemy }
	} ).Hit then table.insert( t, self:GetPos() ) bHasShort = true end
	local flBase = math.abs( self:OBBMaxs().x ) + math.abs( self:OBBMins().x )
	local flStart = CurTime() <= self.flSuppressedTime && self.flCoverMoveStart || self.flCoverMoveStartSuppressed
	local flShort = flBase * ( flStart + self.flCoverMoveShort )
	local flNotShort = flBase * ( flStart + self.flCoverMoveNotShort )
	local dir = ( vShoot - vPos ):Angle():Right()
	dir[ 1 ] = 0
	local vMins, vMaxs = self:OBBMins(), self:OBBMaxs()
	vMins.z = vMins.z + 12
	vMaxs.z = vMaxs.z + 12
	local vLeft, vRight, bLeftShort, bRightShort
	local ndir = -dir
	for flDist = flBase * flStart, flNotShort, flBase * self.flCoverMoveStep do
		local vec = vPos + ndir * flDist
		if util.TraceHull( {
			start = vPos,
			endpos = vec,
			mins = vMins,
			maxs = vMaxs,
			filter = self
		} ).Hit then break end
		if vDuck && !util_TraceLine( {
			start = vec + vDuck,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		} ).Hit || !util_TraceLine( {
			start = vec + vStand,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		} ).Hit then vLeft = vec if flDist < flShort then bLeftShort = true end break end
	end
	for flDist = flBase * flStart, flNotShort, flBase * self.flCoverMoveStep do
		local vec = vPos + dir * flDist
		if util.TraceHull( {
			start = vPos,
			endpos = vec,
			mins = vMins,
			maxs = vMaxs,
			filter = self
		} ).Hit then break end
		if vDuck && !util_TraceLine( {
			start = vec + vDuck,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		} ).Hit || !util_TraceLine( {
			start = vec + vStand,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		} ).Hit then vRight = vec if flDist < flShort then bRightShort = true end break end
	end
	if bLeftShort && bRightShort then
		table.insert( t, vLeft )
		table.insert( t, vRight )
	elseif bLeftShort then
		table.insert( t, vLeft )
	elseif bRightShort then
		table.insert( t, vRight )
	else
		if !bHasShort then
			table.insert( t, vLeft )
			table.insert( t, vRight )
		end
	end
	return t
end

function ENT:FindExposedEnemy( vShoot, tEnemies, bDuck )
	local tEnemiesDist = {}
	for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tEnemiesDist, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
	table.SortByMember( tEnemiesDist, 2, true )
	if table.IsEmpty( tEnemiesDist ) then return end
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	for _, d in pairs( tEnemiesDist ) do
		local enemy = d[ 1 ]
		local t = self:CalcMyExposedShootPositions( enemy, vShoot, bDuck, vStand, vDuck )
		if table.IsEmpty( t ) then continue end
		return table.Random( t ), enemy
	end
end

function ENT:CalcMySuppressionShootPositions( enemy, vPos, bDuck, vStand, vDuck )
	local enemy, trueenemy = self:SetupEnemy( enemy )
	local t, bHasShort = {}
	if bDuck then
		local tr = util_TraceLine {
			start = vPos + vStand,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( vPos ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
			bHasShort = true
			table.insert( t, { vPos, tr.HitPos } )
		end
	end
	local vShoot = enemy:GetPos() + enemy:OBBCenter()
	local flBase = math.abs( self:OBBMaxs().x ) + math.abs( self:OBBMins().x )
	local flStart = CurTime() <= self.flSuppressedTime && self.flCoverMoveStart || self.flCoverMoveStartSuppressed
	local flShort = flBase * ( flStart + self.flCoverMoveShort )
	local flNotShort = flBase * ( flStart + self.flCoverMoveNotShort )
	local dir = ( vShoot - vPos ):Angle():Right()
	dir[ 1 ] = 0
	local vMins, vMaxs = self:OBBMins(), self:OBBMaxs()
	vMins.z = vMins.z + 12
	vMaxs.z = vMaxs.z + 12
	local vLeft, vRight, vLeftTarget, vRightTarget, bLeftShort, bRightShort
	local ndir = -dir
	for flDist = flBase * flStart, flNotShort, flBase * self.flCoverMoveStep do
		local vec = vPos + ndir * flDist
		if util.TraceHull( {
			start = vPos,
			endpos = vec,
			mins = vMins,
			maxs = vMaxs,
			filter = self
		} ).Hit then break end
		if vDuck then
			local trStand = util_TraceLine {
				start = vec + vStand,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			local trDuck = util_TraceLine {
				start = vec + vDuck,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			local bStand = trStand.Fraction > self.flSuppressionTraceFraction && trStand.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			local bDuck = trDuck.Fraction > self.flSuppressionTraceFraction && trDuck.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			if bStand && bDuck then
				vLeft = vec
				vLeftTarget = math.random( 2 ) == 1 && trStand.HitPos || trDuck.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			elseif bStand then
				vLeft = vec
				vLeftTarget = trStand.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			elseif bDuck then
				vLeft = vec
				vLeftTarget = trDuck.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			end
		else
			local tr = util_TraceLine {
				start = vec + vStand,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
				vLeft = vec
				vLeftTarget = tr.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			end
		end
	end
	for flDist = flBase * flStart, flNotShort, flBase * self.flCoverMoveStep do
		local vec = vPos + dir * flDist
		if util.TraceHull( {
			start = vPos,
			endpos = vec,
			mins = vMins,
			maxs = vMaxs,
			filter = self
		} ).Hit then break end
		if vDuck then
			local trStand = util_TraceLine {
				start = vec + vStand,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			local trDuck = util_TraceLine {
				start = vec + vDuck,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			local bStand = trStand.Fraction > self.flSuppressionTraceFraction && trStand.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			local bDuck = trDuck.Fraction > self.flSuppressionTraceFraction && trDuck.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			if bStand && bDuck then
				vLeft = vec
				vLeftTarget = math.random( 2 ) == 1 && trStand.HitPos || trDuck.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			elseif bStand then
				vLeft = vec
				vLeftTarget = trStand.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			elseif bDuck then
				vLeft = vec
				vLeftTarget = trDuck.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			end
		else
			local tr = util_TraceLine {
				start = vec + vStand,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
				vLeft = vec
				vLeftTarget = tr.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			end
		end
	end
	if !vLeft then bLeftShort = nil end
	if !bRight then bRightShort = nil end
	if bLeftShort && bRightShort then
		table.insert( t, { vLeft, vLeftTarget } )
		table.insert( t, { vRight, vRightTarget } )
	elseif bLeftShort then
		table.insert( t, { vLeft, vLeftTarget } )
	elseif bRightShort then
		table.insert( t, { vRight, vRightTarget } )
	else
		if !bHasShort then
			if vLeft then table.insert( t, { vLeft, vLeftTarget } ) end
			if vRight then table.insert( t, { vRight, vRightTarget } ) end
		end
	end
	return t
end

function ENT:FindSuppressEnemy( vShoot, tEnemies, bDuck )
	local tEnemiesDist = {}
	for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tEnemiesDist, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
	table.SortByMember( tEnemiesDist, 2, true )
	if table.IsEmpty( tEnemiesDist ) then return end
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	for _, d in pairs( tEnemiesDist ) do
		local enemy = d[ 1 ]
		local t = self:CalcMySuppressionShootPositions( enemy, vShoot, bDuck, vStand, vDuck )
		if table.IsEmpty( t ) then continue end
		t = table.Random( t )
		if t[ 1 ] && t[ 2 ] then return t[ 1 ], t[ 2 ], enemy end
	end
end

ENT.flHoldFireTime = 16

function ENT:DLG_HoldFire()
	self.bHoldFire = true
	local tAllies = self:GetAlliesByClass()
	if tAllies then
		for _, ent in ipairs( tAllies ) do
			if !IsValid( ent ) then continue end
			ent.bHoldFire = true
		end
	end
end

function ENT:DLG_FiringAtAnExposedTarget( enemy ) end
function ENT:DLG_Suppressing( enemy ) end

// These are only said once per take cover/retreat
function ENT:DLG_State_TakeCover() end // “GET THE HELL OUTTA HERE!! GET BACK TO COVER!!!” *Burst of gunfire.*
function ENT:DLG_State_Retreat() end // “PULL BAAACK!!!” *Burst of gunfire.*

ENT.flLastAttackCombatState = 1

Actor_RegisterSchedule( "RangeAttack", function( self, sched, MyTable )
	MyTable.vActualCover = MyTable.vCover
	MyTable.vActualTarget = sched.vFrom
	MyTable.bSuppressing = true
	local f, o = MyTable.flCombatState, MyTable.flLastAttackCombatState
	if f < -.2 && o >= -.2 then
		MyTable.DLG_State_Retreat( self, MyTable )
	elseif f <= .2 && o > .2 then
		MyTable.DLG_State_TakeCover( self, MyTable )
	end
	MyTable.flLastAttackCombatState = f
	local enemy, trueenemy = MyTable.SetupEnemy( self, sched.Enemy, MyTable )
	if !IsValid( enemy ) || !sched.vFrom then return {} end
	if !MyTable.CanExpose( self, MyTable ) then MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable ) MyTable.DLG_Suppressed( self, MyTable ) return end
	local tEnemies = sched.tEnemies || MyTable.tEnemies
	if table.IsEmpty( tEnemies ) then return {} end
	local c = MyTable.GetWeaponClipPrimary( self, MyTable )
	if c != -1 && c <= 0 then MyTable.WeaponReload( self, MyTable ) end
	if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
	sched.bWantsCover = sched.bMove
	local tAllies = MyTable.GetAlliesByClass( self, MyTable )
	if !MyTable.vCover then
		if table.Count( tAllies ) > 1 then
			local bNoEnemy = true
			for ent in pairs( MyTable.tEnemies ) do
				if !IsValid( ent ) then continue end
				local v = ent:GetPos() + ent:OBBCenter()
				local tr = util_TraceLine {
					start = self:GetShootPos(),
					endpos = v,
					mask = MASK_SHOT_HULL,
					filter = { self, ent }
				}
				if ( !tr.Hit || tr.Fraction > self.flSuppressionTraceFraction ) && tr.HitPos:Distance( v ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
					local b
					if ent.GAME_tSuppressionAmount then
						local flThreshold, flSoFar = ent:Health() * .1, 0
						for other, am in pairs( ent.GAME_tSuppressionAmount ) do
							if other == self || self:Disposition( other ) != D_LI || !other.bSuppressing || CurTime() <= ( other.flWeaponReloadTime || 0 ) then continue end
							flSoFar = flSoFar + am
							if flSoFar > flThreshold then continue end
						end
						if flSoFar <= flThreshold then bNoEnemy = nil break end
					else bNoEnemy = true break end
					if b then bNoEnemy = nil break end
				end
			end
			if bNoEnemy then MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable ) return end
		end
	end
	MyTable.bSuppressing = true
	if sched.bSuppressing then
		local vStand, vDuck = Vector( 0, 0, MyTable.vHullMaxs.z )
		if MyTable.vHullDuckMaxs && vStand.z != MyTable.vHullDuckMaxs.z then vDuck = Vector( 0, 0, MyTable.vHullDuckMaxs.z ) end
		local vEnemy = enemy:GetPos() + enemy:OBBCenter()
		local trStand, trDuck = util_TraceLine {
			start = sched.vFrom + vStand,
			endpos = vEnemy,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if vDuck then
			trDuck = util_TraceLine {
				start = sched.vFrom + vDuck,
				endpos = vEnemy,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
		end
		if !trStand.Hit || trDuck && !trDuck.Hit then sched.bSuppressing = nil return end
		v = sched.vTo
		local trStand, trDuck = util_TraceLine {
			start = sched.vFrom + vStand,
			endpos = v,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if vDuck then
			trDuck = util_TraceLine {
				start = sched.vFrom + vDuck,
				endpos = v,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
		end
		if trStand.Hit && ( !trDuck || trDuck.Hit ) then MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable ) return end
		if !sched.Path then sched.Path = Path "Follow" end
		MyTable.ComputePath( self, sched.Path, sched.vFrom, MyTable )
		local flHealth = enemy:Health()
		local ws, w = 0 // Weapon Strength
		for wep in pairs( MyTable.tWeapons ) do
			local t = wep.Primary_flDelay || 0
			if t <= 0 then continue end
			local d = wep.Primary_flDamage || 0
			if d <= 0 then continue end
			local nws = math.abs( flHealth - 1 / ( wep.Primary.Automatic && t || t + MyTable.tWeaponPrimaryVolleyNonAutomaticDelay[ 2 ] ) * d * ( wep.Primary_iNum || 1 ) )
			if nws < ws then w, ws = wep, nws end
		end
		local trCurStand, trCurDuck = util_TraceLine {
			start = self:GetPos() + vStand,
			endpos = v,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if vDuck then
			trCurDuck = util_TraceLine {
				start = self:GetPos() + vDuck,
				endpos = v,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
		end
		if self.flCombatState > 0 && v:DistToSqr( vEnemy ) > ( RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE ) ||
		util_TraceLine( {
			start = v,
			endpos = vEnemy,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		} ).Hit then return false end
		local f = MyTable.flPathTolerance
		local vMins, vMaxs = MyTable.GatherShootingBounds( self, MyTable )
		if self:GetPos():DistToSqr( sched.vFrom ) <= ( f * f ) && !util_TraceHull( {
			start = self:GetShootPos(),
			endpos = v,
			mask = MASK_SHOT_HULL,
			mins = vMins,
			maxs = vMaxs,
			filter = { self, enemy, trueenemy }
		} ).Hit then
			if !sched.Time then sched.Time = CurTime() + math.Rand( MyTable.flShootTimeMin, MyTable.flShootTimeMax )
			elseif sched.Time == -1 then
				local b = true
				for ally in pairs( tAllies ) do if self != ally && IsValid( ally ) && ally.bWantsCover then b = nil break end end
				if b then
					MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable )
					return
				end
			elseif CurTime() > sched.Time then
				local b = true
				for ally in pairs( tAllies ) do if self != ally && IsValid( ally ) && ally.bWantsCover then sched.Time = -1 b = nil break end end
				if b then
					MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable )
					return
				end
			end
			if !sched.bWasInShootPosition then MyTable.DLG_Suppressing( self, enemy, MyTable ) end
			sched.bWasInShootPosition = true
			if !trDuck || trDuck && trDuck.Hit then
				self:Stand( 1 )
			elseif trDuck then
				self:Stand( sched.bDuck && 0 || 1 )
			end
			MyTable.vaAimTargetBody = v
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			MyTable.tWeaponPrimaryVolleyTimes = { 2, 4 }
			MyTable.tWeaponPrimaryVolleyBreaks = { .2, .4 }
			MyTable.tWeaponPrimaryVolleyNonAutomaticDelay = { .1, .2 }
			if MyTable.CanAttackHelper( self, v, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
		else
			local tNearestEnemies = {}
			for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
			table.SortByMember( tNearestEnemies, 2, true )
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
						pEnemy = ent
						if MyTable.CanAttackHelper( self, ent:GetPos() + ent:OBBCenter(), MyTable ) then MyTable.RangeAttack( self, MyTable ) end
						break
					end
				end
			end
			if IsValid( pEnemy ) then
				if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
				local flDist = MyTable.flWalkSpeed * 4
				flDist = flDist * flDist
				if self:GetPos():DistToSqr( sched.vFrom ) > flDist || sched.bDuck then
					local flDist = MyTable.flRunSpeed * 4
					flDist = flDist * flDist
					if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
						MyTable.MoveAlongPath( self, sched.Path, MyTable.flTopSpeed, 1 )
					else MyTable.MoveAlongPath( self, sched.Path, MyTable.flRunSpeed, 1 ) end
				else MyTable.MoveAlongPath( self, sched.Path, MyTable.flWalkSpeed, 0 ) end
			else
				local goal = sched.Path:GetCurrentGoal()
				if goal then
					MyTable.vaAimTargetBody = ( goal.pos - self:GetPos() ):Angle()
					MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
					if sched.bMove then MyTable.ModifyMoveAimVector( self, MyTable.vaAimTargetBody, MyTable.flTopSpeed, 1, MyTable ) end
				end
				if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
				local flDist = MyTable.flWalkSpeed * 4
				flDist = flDist * flDist
				if self:GetPos():DistToSqr( sched.vFrom ) > flDist || sched.bDuck then
					local flDist = MyTable.flRunSpeed * 4
					flDist = flDist * flDist
					if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
						MyTable.MoveAlongPath( self, sched.Path, MyTable.flTopSpeed, 1 )
					else MyTable.MoveAlongPath( self, sched.Path, MyTable.flRunSpeed, 1 ) end
				else MyTable.MoveAlongPath( self, sched.Path, MyTable.flWalkSpeed, 0 ) end
			end
		end
	else
		local vStand, vDuck = Vector( 0, 0, MyTable.vHullMaxs.z )
		if MyTable.vHullDuckMaxs && vStand.z != MyTable.vHullDuckMaxs.z then vDuck = Vector( 0, 0, MyTable.vHullDuckMaxs.z ) end
		local v = enemy:GetPos() + enemy:OBBCenter()
		local trStand, trDuck = util_TraceLine {
			start = sched.vFrom + vStand,
			endpos = v,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if vDuck then
			trDuck = util_TraceLine {
				start = sched.vFrom + vDuck,
				endpos = v,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
		end
		if trStand.Hit && ( !trDuck || trDuck.Hit ) then MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable ) return end
		if !sched.Path then sched.Path = Path "Follow" end
		MyTable.ComputePath( self, sched.Path, sched.vFrom, MyTable )
		local flHealth = enemy:Health()
		local ws, w = 0 // Weapon Strength
		for wep in pairs( self.tWeapons ) do
			local t = wep.Primary_flDelay || 0
			if t <= 0 then continue end
			local d = wep.Primary_flDamage || 0
			if d <= 0 then continue end
			local nws = math.abs( flHealth - 1 / ( wep.Primary.Automatic && t || t + MyTable.tWeaponPrimaryVolleyNonAutomaticDelay[ 2 ] ) * d * ( wep.Primary_iNum || 1 ) )
			if nws < ws then w, ws = wep, nws end
		end
		if IsValid( w ) then MyTable.SetActiveWeapon( self, w, MyTable ) end
		local f = MyTable.flPathTolerance
		if self:GetPos():DistToSqr( sched.vFrom ) <= ( f * f ) && ( !trStand.Hit || trDuck && !trDuck.Hit ) then
			if !sched.Time then sched.Time = CurTime() + math.Rand( MyTable.flShootTimeMin, MyTable.flShootTimeMax )
			elseif sched.Time == -1 then
				local b = true
				if tAllies then for ally in pairs( tAllies ) do if self != ally && IsValid( ally ) && ally.bWantsCover then b = nil break end end end
				if b then
					MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable )
					return
				end
			elseif CurTime() > sched.Time then
				local b = true
				if tAllies then for ally in pairs( tAllies ) do if self != ally && IsValid( ally ) && ally.bWantsCover then sched.Time = -1 b = nil break end end end
				if b then
					MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable )
					return
				end
			end
			if !sched.bWasInShootPosition then MyTable.DLG_FiringAtAnExposedTarget( self, enemy, MyTable ) end
			sched.bWasInShootPosition = true
			if !trDuck || trDuck && trDuck.Hit then
				self:Stand( 1 )
			elseif trDuck then
				self:Stand( sched.bDuck && 0 || 1 )
			end
			MyTable.vaAimTargetBody = enemy:GetPos() + enemy:OBBCenter()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			local pWeapon = MyTable.Weapon
			if !IsValid( pWeapon ) then return false end
			local flRecoil = pWeapon.flRecoil
			if flRecoil then
				local flDistance = self:GetShootPos():Distance( MyTable.vaAimTargetBody )
				if flRecoil <= 0 || flDistance < 1792 / flRecoil then // To Hell everything, I'm magdumping your ass
					MyTable.tWeaponPrimaryVolleyTimes = { 0, 0 }
					MyTable.tWeaponPrimaryVolleyBreaks = { 0, 0 }
					MyTable.tWeaponPrimaryVolleyNonAutomaticDelay = { 0, 0 }
				end
			end
			if MyTable.CanAttackHelper( self, enemy:GetPos() + enemy:OBBCenter(), MyTable ) then
				MyTable.RangeAttack( self, MyTable )
			end
		else
			if sched.bMove then
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
						if !tr.Hit && CurTime() > MyTable.flWeaponPrimaryVolleyTime && ent.GAME_tSuppressionAmount then
							local flThreshold = ent:Health() * .1
							for other, am in pairs( ent.GAME_tSuppressionAmount ) do
								if other != self && am > flThreshold then b = nil break end
							end
						end
						if b then
							MyTable.vaAimTargetBody = ent:GetPos() + ent:OBBCenter()
							MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
							pEnemy = ent
							if MyTable.CanAttackHelper( self, ent:GetPos() + ent:OBBCenter(), MyTable ) then MyTable.RangeAttack( self, MyTable ) end
							break
						end
					end
				end
				if IsValid( pEnemy ) then
					if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
					local flDist = MyTable.flWalkSpeed * 4
					flDist = flDist * flDist
					if self:GetPos():DistToSqr( sched.vFrom ) > flDist || sched.bDuck then
						local flDist = MyTable.flRunSpeed * 4
						flDist = flDist * flDist
						if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
							MyTable.MoveAlongPath( self, sched.Path, MyTable.flTopSpeed, 1 )
						else MyTable.MoveAlongPath( self, sched.Path, MyTable.flRunSpeed, 1 ) end
					else MyTable.MoveAlongPath( self, sched.Path, MyTable.flWalkSpeed, 0 ) end
				else
					local goal = sched.Path:GetCurrentGoal()
					if goal then
						MyTable.vaAimTargetBody = ( goal.pos - self:GetPos() ):Angle()
						MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
						if sched.bMove then MyTable.ModifyMoveAimVector( MyTable.vaAimTargetBody, MyTable.flTopSpeed, 1 ) end
					end
					if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
					local flDist = self.flWalkSpeed * 4
					flDist = flDist * flDist
					if self:GetPos():DistToSqr( sched.vFrom ) > flDist || sched.bDuck then
						local flDist = MyTable.flRunSpeed * 4
						flDist = flDist * flDist
						if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
							MyTable.MoveAlongPath( self, sched.Path, MyTable.flTopSpeed, 1 )
						else MyTable.MoveAlongPath( self, sched.Path, MyTable.flRunSpeed, 1 ) end
					else MyTable.MoveAlongPath( self, sched.Path, MyTable.flWalkSpeed, 0 ) end
				end
			else MyTable.MoveAlongPath( self, sched.Path, MyTable.flWalkSpeed, 0 ) end
		end
	end
end )
