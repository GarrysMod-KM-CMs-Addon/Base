// TODO: Break down the file into files with the name of the schedules, like Cover.lua

ENT.tPreScheduleResetVariables.bSuppressing = false
ENT.tPreScheduleResetVariables.bWantsCover = false

function ENT:RangeAttack()
	if self.bHoldFire then return end
	self:WeaponPrimaryVolley()
	self.flWeaponPrimaryVolleyTimeMin = 0
	self.flWeaponPrimaryVolleyTimeMax = 3
	self.flWeaponPrimaryVolleyBreakMin = 0
	self.flWeaponPrimaryVolleyBreakMax = 1
	self.flWeaponPrimaryVolleyNonAutomaticDelayMin = 0
	self.flWeaponPrimaryVolleyNonAutomaticDelayMax = .4
	return true
end

// Small suppressed, does NOT want someone else to help yet
function ENT:DLG_Suppressed() end
// Large suppressed, DOES want someone else to help now
// No functionality here for now, but it'll be here, so do BaseClass.DLG_Pinned( self, MyTable )
function ENT:DLG_Pinned( MyTable ) end

// See the code, I have no easy way of explaining this one
ENT.flSuppressionTraceFraction = .8

local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull

ENT.flHoldFireTime = 48

function ENT:DLG_HoldFire()
	self.bHoldFire = true
	local tAllies = self:GetAlliesByClass()
	if tAllies then
		for ent in pairs( tAllies ) do
			if IsValid( ent ) then ent.bHoldFire = true end
		end
	end
end

function ENT:DLG_FiringAtAnExposedTarget( enemy ) end
function ENT:DLG_Suppressing( enemy ) end

// These are only said once per take cover/retreat
function ENT:DLG_State_TakeCover() end
function ENT:DLG_State_Retreat() end // "GET THE HELL OUTTA HERE!! GET BACK TO COVER!!!" *gunfire*

ENT.flLastAttackCombatState = 1

RegisterSchedule( "RangeAttack", { Execute = function( self, sched, MyTable )
	MyTable.WEAPON_STANCE = WEAPON_STANCE_AIMING
	MyTable.vActualCover = MyTable.vCover
	MyTable.vActualTarget = sched.vFrom
	MyTable.bSuppressing = true
	MyTable.bAttacking = true
	local f, o = MyTable.flCombatState, MyTable.flLastAttackCombatState
	if f < -.2 && o >= -.2 then
		MyTable.DLG_State_Retreat( self, MyTable )
	elseif f <= .2 && o > .2 then
		MyTable.DLG_State_TakeCover( self, MyTable )
	end
	MyTable.flLastAttackCombatState = f
	local enemy = MyTable.Enemy
	if !IsValid( enemy ) then return true end
	local enemy, trueenemy = MyTable.SetupEnemy( self, enemy, MyTable )
	if !sched.vFrom then return false end
	if !MyTable.CanExpose( self, MyTable ) then MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable ) MyTable.DLG_Suppressed( self, MyTable ) return end
	local tEnemies = sched.tEnemies || MyTable.tEnemies
	if table.IsEmpty( tEnemies ) then return true end
	local c = MyTable.GetWeaponClipPrimary( self, MyTable )
	if c != -1 && c <= 0 then MyTable.WeaponReload( self, MyTable ) end
	if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
	local tAllies = MyTable.GetAlliesByClass( self, MyTable )
	if !MyTable.vCover || !MyTable.tCover then
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
			if wep.bSpecial then continue end
			local t = wep.Primary_flDelay || 0
			if t <= 0 then continue end
			local d = wep.Primary_flDamage || 0
			if d <= 0 then continue end
			local nws = math.abs( flHealth - 1 / ( wep.Primary.Automatic && t || t + MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax ) * d * ( wep.Primary_iNum || 1 ) )
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
		if util_TraceLine( {
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
			if !sched.flTime then sched.flTime = CurTime() + math.Rand( MyTable.flShootTimeMin, MyTable.flShootTimeMax )
			elseif sched.flTime == -1 then
				local b = true
				for ally in pairs( tAllies ) do if self != ally && IsValid( ally ) && ally.bWantsCover then b = nil break end end
				if b then
					MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable )
					return
				end
			elseif CurTime() > sched.flTime then
				local b = true
				for ally in pairs( tAllies ) do if self != ally && IsValid( ally ) && ally.bWantsCover then sched.flTime = -1 b = nil break end end
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
			MyTable.flWeaponPrimaryVolleyTimeMin = 2
			MyTable.flWeaponPrimaryVolleyTimeMax = 4
			MyTable.flWeaponPrimaryVolleyBreakMin = .2
			MyTable.flWeaponPrimaryVolleyBreakMax = .4
			MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMin = 0
			MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax = .2
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
						if MyTable.CanAttackHelper( self, ent, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
						break
					end
				end
			end
			if sched.bMove then
				if IsValid( pEnemy ) then
					if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
					local flDist = MyTable.flWalkSpeed * 4
					flDist = flDist * flDist
					if self:GetPos():DistToSqr( sched.vFrom ) > flDist || sched.bDuck then
						local flDist = MyTable.flJogSpeed * 4
						flDist = flDist * flDist
						if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
							MyTable.MoveAlongPath( self, sched.Path, MyTable.flTopSpeed, 1 )
						else MyTable.MoveAlongPath( self, sched.Path, MyTable.flJogSpeed, 1 ) end
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
						local flDist = MyTable.flJogSpeed * 4
						flDist = flDist * flDist
						if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
							MyTable.MoveAlongPath( self, sched.Path, MyTable.flTopSpeed, 1 )
						else MyTable.MoveAlongPath( self, sched.Path, MyTable.flJogSpeed, 1 ) end
					else MyTable.MoveAlongPath( self, sched.Path, MyTable.flWalkSpeed, 0 ) end
				end
			else MyTable.MoveAlongPath( self, sched.Path, MyTable.flWalkSpeed, 0 ) end
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
		if trStand.Hit && ( !trDuck || trDuck.Hit ) then
			local pEnemyPath = MyTable.pEnemyPath
			if !pEnemyPath then
				pEnemyPath = Path "Follow"
				MyTable.ComputePath( self, pEnemyPath, enemy:GetPos(), MyTable )
				MyTable.pEnemyPath = pEnemyPath
			end
			for i = 1, 4 do
				pEnemyPath:MoveCursorToClosestPosition( sched.vFrom )
				pEnemyPath:MoveCursor( math.min( self:BoundingRadius() * 4 * i ) )
				sched.vFrom = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() )
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
				if !trStand.Hit || ( trDuck && !trDuck.Hit ) then
					local s = MyTable.SetSchedule( self, "FreeMovementMove", MyTable )
					s.vPoint = sched.vFrom
					s.bGotALineOfSightBefore = true
					return
				end
			end
			MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable )
			return
		end
		if !sched.Path then sched.Path = Path "Follow" end
		MyTable.ComputePath( self, sched.Path, sched.vFrom, MyTable )
		local flHealth = enemy:Health()
		local ws, w = 0 // Weapon strength
		for wep in pairs( self.tWeapons ) do
			if wep.bSpecial then continue end
			local t = wep.Primary_flDelay || 0
			if t <= 0 then continue end
			local d = wep.Primary_flDamage || 0
			if d <= 0 then continue end
			local nws = math.abs( flHealth - 1 / ( wep.Primary.Automatic && t || t + MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax ) * d * ( wep.Primary_iNum || 1 ) )
			if nws < ws then w, ws = wep, nws end
		end
		if IsValid( w ) then MyTable.SetActiveWeapon( self, w, MyTable ) end
		local f = MyTable.flPathTolerance
		if self:GetPos():DistToSqr( sched.vFrom ) <= ( f * f ) && ( !trStand.Hit || trDuck && !trDuck.Hit ) then
			if !sched.flTime then sched.flTime = CurTime() + math.Rand( MyTable.flShootTimeMin, MyTable.flShootTimeMax )
			elseif sched.flTime == -1 then
				local b = true
				if tAllies then for ally in pairs( tAllies ) do if self != ally && IsValid( ally ) && ally.bWantsCover then b = nil break end end end
				if b then
					MyTable.SetSchedule( self, sched.bMove && "TakeCoverMove" || "TakeCover", MyTable )
					return
				end
			elseif CurTime() > sched.flTime then
				local b = true
				if tAllies then for ally in pairs( tAllies ) do if self != ally && IsValid( ally ) && ally.bWantsCover then sched.flTime = -1 b = nil break end end end
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
					MyTable.flWeaponPrimaryVolleyTimeMin = 0
					MyTable.flWeaponPrimaryVolleyTimeMax = 0

					MyTable.flWeaponPrimaryVolleyBreakMin = 0
					MyTable.flWeaponPrimaryVolleyBreakMax = 0

					MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMin = 0
					MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax = .2
				end
			end
			if MyTable.CanAttackHelper( self, enemy, MyTable ) then
				MyTable.RangeAttack( self, MyTable )
			end
		else
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
						if MyTable.CanAttackHelper( self, ent, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
						break
					end
				end
			end
			if sched.bMove then
				if IsValid( pEnemy ) then
					if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
					local flDist = MyTable.flWalkSpeed * 4
					flDist = flDist * flDist
					if self:GetPos():DistToSqr( sched.vFrom ) > flDist || sched.bDuck then
						local flDist = MyTable.flJogSpeed * 4
						flDist = flDist * flDist
						if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
							MyTable.MoveAlongPath( self, sched.Path, MyTable.flTopSpeed, 1 )
						else MyTable.MoveAlongPath( self, sched.Path, MyTable.flJogSpeed, 1 ) end
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
						local flDist = MyTable.flJogSpeed * 4
						flDist = flDist * flDist
						if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
							MyTable.MoveAlongPath( self, sched.Path, MyTable.flTopSpeed, 1 )
						else MyTable.MoveAlongPath( self, sched.Path, MyTable.flJogSpeed, 1 ) end
					else MyTable.MoveAlongPath( self, sched.Path, MyTable.flWalkSpeed, 0 ) end
				end
			else MyTable.MoveAlongPath( self, sched.Path, MyTable.flWalkSpeed, 0 ) end
		end
	end
end } )
