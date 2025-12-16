local table_IsEmpty = table.IsEmpty
local HasRangeAttack, HasMeleeAttack = HasRangeAttack, HasMeleeAttack
local util = util
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
local util_DistanceToLine = util.DistanceToLine
local math = math
local math_Rand = math.Rand
local unpack = unpack
local CurTime = CurTime

function ENT:DLG_MeleeReachable( pEnemy ) end
function ENT:DLG_MeleeUnReachable( pEnemy ) end

local PLANT_TIME_MINIMUM = 1
local PLANT_TIME_MAXIMUM = 2

function ENT:DLG_MaintainFire()
	// TODO: Find someone else to shoot, not us
	self.flPlantEndTime = nil
	if self.bPlanted then return end
	self:Plant()
end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

// ENT.bMeleeChargeAgainstRange - Far Cry 3 Pirate Beheader
// ENT.flMeleeChargeTauntMultiplier = 1

function ENT:DLG_MeleeTaunt() end

ENT.flCoverMoveDistance = 768

include "HoldFireCheckEnemy.lua"

local math_Rand = math.Rand

ENT.flMaintainFireTime = 0
ENT.flMaintainFireTimeMin = 2
ENT.flMaintainFireTimeMax = 6

Actor_RegisterSchedule( "Combat", function( self, sched )
	local tEnemies = sched.tEnemies || self.tEnemies
	if table_IsEmpty( tEnemies ) then return {} end
	local enemy = sched.Enemy
	if IsValid( enemy ) then enemy = enemy
	else enemy = self.Enemy if !IsValid( enemy ) then return {} end end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	if !self.bHoldFire && CurTime() > ( self.flLastEnemy + self.flHoldFireTime ) then self:DLG_HoldFire() end
	// Big thing combat
	if self:Health() > enemy:Health() * 100 then
		if self.bPlantAttack then // Lemme guess, we're a Combine Hunter?
			if sched.bMoving then
				local pPath = sched.pEnemyPath
				if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
				self:ComputeFlankPath( pPath, enemy )
				if util_TraceLine( {
					start = self:GetShootPos(),
					endpos = enemy:GetPos() + enemy:OBBCenter(),
					mask = MASK_SHOT_HULL,
					filter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
				} ).Hit then
					local aDirection
					local tGoal = pPath:NextSegment()
					if tGoal then aDirection = ( tGoal.pos - self:GetShootPos() ):Angle()
					else aDirection = ( enemy:GetPos() - self:GetShootPos() ):Angle() end
					local vTarget = enemy:GetPos() + enemy:OBBCenter()
					local vHeight = Vector( 0, 0, self.vHullDuckMaxs[ 3 ] )
					local tPitchAngles = { 0 }
					if enemy:GetPos().z > self:GetPos().z then
						for a = 5.625, 90, 5.625 do
							table.insert( tPitchAngles, a )
							table.insert( tPitchAngles, -a )
						end
					else
						for a = 5.625, 90, 5.625 do
							table.insert( tPitchAngles, -a )
							table.insert( tPitchAngles, a )
						end
					end
					local bCheckDistance, flDistSqr = self.flCombatState > 0
					if bCheckDistance then
						flDistSqr = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
						flDistSqr = flDistSqr * flDistSqr
					end
					local function fDo( vOrigin, tAngles )
						local vPos = vOrigin + vHeight
						local tWholeFilter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
						for i, flGlobalAnglePitch in ipairs( tPitchAngles ) do
							for i, flGlobalAngleYaw in ipairs( tAngles ) do
								// local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
								local aAim = aDirection + Angle( 0, flGlobalAngleYaw )
								aAim[ 1 ] = flGlobalAnglePitch
								local vAim = aAim:Forward()
								local tr = util_TraceLine {
									start = vPos,
									endpos = vPos + vAim * 999999,
									mask = MASK_SHOT_HULL,
									filter = self
								}
								local _, vPoint = util.DistanceToLine( vPos, tr.HitPos, vTarget )
								if util_TraceLine( {
									start = vPoint,
									endpos = vTarget,
									mask = MASK_SHOT_HULL,
									filter = tWholeFilter
								} ).Hit || bCheckDistance && vPoint:DistToSqr( vTarget ) > flDistSqr then continue end
								return vPoint
							end
						end
					end
					local tAngles = { 0 }
					for a = 5.625, 22.5, 5.625 do
						table.insert( tAngles, -a )
						table.insert( tAngles, a )
					end
					vTarget = fDo( self:GetShootPos(), tAngles )
					if vTarget then
						self.vaAimTargetBody = vTarget
						self.vaAimTargetPose = self.vaAimTargetBody
						if self.bPlanted then
							local b
							local tAllies = self:GetAlliesByClass()
							if tAllies then
								for pAlly in pairs( tAllies ) do if self != pAlly && IsValid( pAlly ) && pAlly.bWantsCover then b = true break end end
							else b = true end
							if !self.flPlantEndTime then self.flPlantEndTime = CurTime() + math_Rand( self.flPlantTimeMinimum || PLANT_TIME_MINIMUM, self.flPlantTimeMaximum || PLANT_TIME_MAXIMUM ) end
							if CurTime() <= self.flPlantEndTime || b then self:RangeAttackPlanted() else self:UnPlant() sched.bMoving = true end
							return
						end
						local tAllies = self:GetAlliesByClass()
						if tAllies then
							local bMaintainFire, bAtLeastOneAlly = true
							for pAlly in pairs( tAllies ) do
								if IsValid( pAlly ) && pAlly != self then
									bAtLeastOneAlly = true
									if pAlly.bSuppressing then bMaintainFire = nil break end
								end
							end
							if bAtLeastOneAlly && bMaintainFire then
								if CurTime() > self.flMaintainFireTime then
									self:DLG_MaintainFire()
									self.flMaintainFireTime = CurTime() + math.Rand( self.flMaintainFireTimeMin, self.flMaintainFireTimeMax )
								end
								return
							else self.flMaintainFireTime = CurTime() + math.Rand( self.flMaintainFireTimeMin, self.flMaintainFireTimeMax ) end
						end
						self:MoveAlongPath( pPath, self.flRunSpeed, 1 )
					else
						self.flMaintainFireTime = CurTime() + math.Rand( self.flMaintainFireTimeMin, self.flMaintainFireTimeMax )
						self:MoveAlongPath( pPath, self.flTopSpeed, 1 )
						local pGoal = sched.pEnemyPath:GetCurrentGoal()
						if pGoal then
							self.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
							self.vaAimTargetPose = self.vaAimTargetBody
						end
					end
				else
					self.vaAimTargetBody = enemy:GetPos() + enemy:OBBCenter()
					// TODO!!!
					//	self.vaAimTargetBody = util_TraceLine( {
					//		start = self:GetShootPos(),
					//		endpos = enemy:GetPos() + enemy:OBBCenter(),
					//		mask = MASK_SHOT_HULL,
					//		filter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
					//	} ).Hit && ( enemy:GetPos() + enemy:OBBCenter() ) || x
					self.vaAimTargetPose = self.vaAimTargetBody
					if self.bPlanted then
						local b
						local tAllies = self:GetAlliesByClass()
						if tAllies then
							for pAlly in pairs( tAllies ) do if self != pAlly && IsValid( pAlly ) && pAlly.bWantsCover then b = true break end end
						else b = true end
						if !self.flPlantEndTime then self.flPlantEndTime = CurTime() + math_Rand( self.flPlantTimeMinimum || PLANT_TIME_MINIMUM, self.flPlantTimeMaximum || PLANT_TIME_MAXIMUM ) end
						if CurTime() <= self.flPlantEndTime || b then self:RangeAttackPlanted() else self:UnPlant() sched.bMoving = true end
						return
					elseif math.Rand( 0, 10000 * FrameTime() ) <= 1 then self.flPlantEndTime = nil self:Plant() return end
					local tAllies = self:GetAlliesByClass()
					if tAllies then
						local bMaintainFire, bAtLeastOneAlly = true
						for pAlly in pairs( tAllies ) do
							if IsValid( pAlly ) && pAlly != self then
								bAtLeastOneAlly = true
								if pAlly.bSuppressing then bMaintainFire = nil break end
							end
						end
						if bAtLeastOneAlly && bMaintainFire then
							if CurTime() > self.flMaintainFireTime then
								self:DLG_MaintainFire()
								self.flMaintainFireTime = CurTime() + math.Rand( self.flMaintainFireTimeMin, self.flMaintainFireTimeMax )
							end
							return
						else self.flMaintainFireTime = CurTime() + math.Rand( self.flMaintainFireTimeMin, self.flMaintainFireTimeMax ) end
					else self.flMaintainFireTime = CurTime() + math.Rand( self.flMaintainFireTimeMin, self.flMaintainFireTimeMax ) end
					self:MoveAlongPath( pPath, self.flRunSpeed, 1 )
				end
			else
				self.flMaintainFireTime = CurTime() + math.Rand( self.flMaintainFireTimeMin, self.flMaintainFireTimeMax )
				local pPath = sched.pEnemyPath
				if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
				self:ComputeFlankPath( pPath, enemy )
				if util_TraceLine( {
					start = self:GetShootPos(),
					endpos = enemy:GetPos() + enemy:OBBCenter(),
					mask = MASK_SHOT_HULL,
					filter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
				} ).Hit then
					local aDirection
					local tGoal = pPath:NextSegment()
					if tGoal then aDirection = ( tGoal.pos - self:GetShootPos() ):Angle()
					else aDirection = ( enemy:GetPos() - self:GetShootPos() ):Angle() end
					local vTarget = enemy:GetPos() + enemy:OBBCenter()
					local vHeight = Vector( 0, 0, self.vHullDuckMaxs[ 3 ] )
					local tPitchAngles = { 0 }
					if enemy:GetPos().z > self:GetPos().z then
						for a = 5.625, 90, 5.625 do
							table.insert( tPitchAngles, a )
							table.insert( tPitchAngles, -a )
						end
					else
						for a = 5.625, 90, 5.625 do
							table.insert( tPitchAngles, -a )
							table.insert( tPitchAngles, a )
						end
					end
					local bCheckDistance, flDistSqr = self.flCombatState > 0
					if bCheckDistance then
						flDistSqr = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
						flDistSqr = flDistSqr * flDistSqr
					end
					local function fDo( vOrigin, tAngles )
						local vPos = vOrigin + vHeight
						local tWholeFilter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
						for i, flGlobalAnglePitch in ipairs( tPitchAngles ) do
							for i, flGlobalAngleYaw in ipairs( tAngles ) do
								// local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
								local aAim = aDirection + Angle( 0, flGlobalAngleYaw )
								aAim[ 1 ] = flGlobalAnglePitch
								local vAim = aAim:Forward()
								local tr = util_TraceLine {
									start = vPos,
									endpos = vPos + vAim * 999999,
									mask = MASK_SHOT_HULL,
									filter = self
								}
								local _, vPoint = util.DistanceToLine( vPos, tr.HitPos, vTarget )
								if util_TraceLine( {
									start = vPoint,
									endpos = vTarget,
									mask = MASK_SHOT_HULL,
									filter = tWholeFilter
								} ).Hit || bCheckDistance && vPoint:DistToSqr( vTarget ) > flDistSqr then
									continue
								end
								return vPoint
							end
						end
					end
					local tAngles = { 0 }
					for a = 5.625, 22.5, 5.625 do
						table.insert( tAngles, -a )
						table.insert( tAngles, a )
					end
					vTarget = fDo( self:GetShootPos(), tAngles )
					if vTarget then
						if self.bPlanted then
							if self:RangeAttackPlanted() then self:UnPlant() end
						else
							self:Plant()
						end
					else sched.bMoving = true end
				else
					// TODO!!!
					//	self.vaAimTargetBody = SOME_FUNCTION()
					self.vaAimTargetBody = enemy:GetPos() + enemy:OBBCenter()
					self.vaAimTargetPose = self.vaAimTargetBody
					if self.bPlanted then
						local b
						local tAllies = self:GetAlliesByClass()
						if tAllies then
							for pAlly in pairs( tAllies ) do if self != pAlly && IsValid( pAlly ) && pAlly.bWantsCover then b = true break end end
						else b = true end
						if !self.flPlantEndTime then self.flPlantEndTime = CurTime() + math_Rand( self.flPlantTimeMinimum || PLANT_TIME_MINIMUM, self.flPlantTimeMaximum || PLANT_TIME_MAXIMUM ) end
						if CurTime() <= self.flPlantEndTime || b then self:RangeAttackPlanted() else self:UnPlant() sched.bMoving = true end
					else
						self.flPlantEndTime = nil
						self:Plant()
					end
				end
			end
		end
		return
	end
	if HasMeleeAttack( self ) && !HasRangeAttack( self ) then
		if !self.bEnemiesHaveRangeAttack || self.bMeleeChargeAgainstRange then
			// TODO: Melee vs melee dance behavior
			local pPath = sched.pEnemyPath
			if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
			self:ComputeFlankPath( pPath, enemy )
			self:MoveAlongPath( pPath, self.flTopSpeed, 1 )
			if self:Visible( enemy ) then
				if math.random( 10000 * ( self.flMeleeChargeTauntMultiplier || 1 ) * FrameTime() ) == 1 then self:DLG_MeleeTaunt() return end
				local vTarget, vShoot = enemy:GetPos() + enemy:OBBCenter(), self:GetShootPos()
				self.vaAimTargetBody = vTarget
				self.vaAimTargetPose = vTarget
				local d = self.GAME_flReach || 64
				local wep = self.Weapon
				if IsValid( wep ) then d = d + wep.Melee_flRangeAdd || 0 end
				local vMins, vMaxs = self:GatherShootingBounds()
				if vTarget:Distance( vShoot ) <= d then
					if self.bHoldFire then self:ReportPositionAsClear( vTarget )
					elseif self:Disposition( util_TraceLine( {
						start = vShoot,
						endpos = vShoot + self:GetAimVector() * d,
						filter = self,
						mask = MASK_SHOT_HULL,
						mins = vMins, maxs = vMaxs
					} ).Entity ) != D_LI then self:WeaponPrimaryAttack() end
				end
			else
				local goal = pPath:GetCurrentGoal()
				local v = self:GetPos()
				if goal then
					self.vaAimTargetBody = ( goal.pos - v ):Angle()
					self.vaAimTargetPose = self.vaAimTargetBody
				end
			end
		else self:SetSchedule "TakeCover" end
		return
	end
	if self.vCover then
		local vec = self.vCover
		self.vActualCover = vec
		if !sched.Path then sched.Path = Path "Follow" end
		self:ComputePath( sched.Path, self.vCover )
		local tAllies = self:GetAlliesByClass()
		if tAllies then
			local f = self:BoundingRadius()
			f = f * f
			for ally in pairs( tAllies ) do
				if self == ally then continue end
				if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= f || ally.vActualTarget && ally.vActualTarget:DistToSqr( vec ) <= f then self.vCover = nil self:SetSchedule "TakeCover" return end
			end
		end
		local f = self.flPathTolerance
		if self:GetPos():DistToSqr( vec ) > ( f * f ) then self.vCover = nil self.tCover = nil return end
		local v = vec + Vector( 0, 0, self.vHullDuckMaxs[ 3 ] )
		// Don't even try to repath often!
		local pEnemyPath = self.pLastEnemyPath || sched.pEnemyPath
		if !pEnemyPath then
			pEnemyPath = Path "Follow"
			self:ComputePath( pEnemyPath, enemy:GetPos() )
			self.pLastEnemyPath = pEnemyPath
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
			endpos = v + d * self.vHullMaxs[ 1 ] * COVER_BOUND_SIZE,
			mask = MASK_SHOT_HULL,
			filter = self
		} ).Hit then
			self.vCover = nil
			self.tCover = nil
			self:SetSchedule "TakeCover"
			return
		end
		v = vec + Vector( 0, 0, self.vHullMaxs[ 3 ] )
		sched.bDuck = nil
		self:Stand( util_TraceLine( {
			start = v,
			endpos = v + d * self.vHullMaxs[ 1 ] * COVER_BOUND_SIZE,
			filter = self
		} ).Hit && 0 || 1 )
		self.vaAimTargetBody = d:Angle()
		self.vaAimTargetPose = self.vaAimTargetBody
		if self:CanExpose() then
			if CurTime() > ( self.flSuppressed || 0 ) then
				local flAlarm, vPos, pAlarm = math.huge, self:GetShootPos(), NULL // NULL because ent.pAlarm ( if nil ) == pAlarm ( which is nil )
				local t = __ALARMS__[ self:Classify() ]
				if t then
					for ent in pairs( t ) do
						if !IsValid( ent ) || ent.bIsOn then continue end
						local d = ent:NearestPoint( vPos ):DistToSqr( vPos )
						// Don't go out of audible range, even if an ally alarm. Why?
						// Because it's not funny to run kilometers away from the battlefield to it like an idiot
						if d >= flAlarm || Either( ent.flAudibleDistSqr == 0, self:Visible( ent ), d >= ent.flAudibleDistSqr ) then continue end
						local b
						if tAllies then for ent in pairs( tAllies ) do if ent != self && IsValid( ent ) && ent.pAlarm == pAlarm then b = true break end end end
						if b then continue end
						pAlarm, flAlarm = ent, d
					end
				end
				if IsValid( pAlarm ) then
					local s = self:SetSchedule "PullAlarm"
					s.pAlarm = pAlarm
					self.pAlarm = pAlarm
					return
				end
				t = __ALARMS__[ CLASS_NONE ]
				if t then
					for ent in pairs( t ) do
						if !IsValid( ent ) || ent.bIsOn then continue end
						local d = ent:NearestPoint( vPos ):DistToSqr( vPos )
						if d >= flAlarm || Either( ent.flAudibleDistSqr == 0, self:Visible( ent ), d >= ent.flAudibleDistSqr ) then continue end
						local b
						if tAllies then for ent in pairs( tAllies ) do if ent != self && IsValid( ent ) && ent.pAlarm == pAlarm then b = true break end end end
						if b then continue end
						pAlarm, flAlarm = ent, d
					end
				end
				if IsValid( pAlarm ) then
					local s = self:SetSchedule "PullAlarm"
					s.pAlarm = pAlarm
					self.pAlarm = pAlarm
					return
				end
				local pPath = sched.pEnemyPath
				if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
				self:ComputeFlankPath( pPath, enemy )
				if self.flCombatState < 0 && math.random( 2 ) == 1 then sched.bRetreat = true return else
					local tAllies = self:GetAlliesByClass()
					if tAllies then
						local iShootingAllies, iAllies = 0, table.Count( tAllies )
						if iAllies <= 1 then
							if math.random( 2 ) == 1 then sched[ self.flCombatState > 0 && "bAdvance" || "bRetreat" ] = true end
						else
							for ent in pairs( tAllies ) do if ent.bSuppressing then iShootingAllies = iShootingAllies + 1 end end
							if math_Rand( 0, iAllies / iShootingAllies ) <= 1 then sched[ self.flCombatState > 0 && "bAdvance" || "bRetreat" ] = true end
						end
					elseif math.random( 2 ) == 1 then sched[ self.flCombatState > 0 && "bAdvance" || "bRetreat" ] = true end
				end
				local aDirection
				local tGoal = pPath:NextSegment()
				if tGoal then aDirection = ( tGoal.pos - vec ):Angle()
				else aDirection = ( enemy:GetPos() - vec ):Angle() end
				local vTarget = enemy:GetPos() + enemy:OBBCenter()
				local vHeight = Vector( 0, 0, self.vHullDuckMaxs[ 3 ] )
				local tPitchAngles = { 0 }
				if enemy:GetPos().z > self:GetPos().z then
					for a = 5.625, 90, 5.625 do
						table.insert( tPitchAngles, a )
						table.insert( tPitchAngles, -a )
					end
				else
					for a = 5.625, 90, 5.625 do
						table.insert( tPitchAngles, -a )
						table.insert( tPitchAngles, a )
					end
				end
				local bCheckDistance, flDistSqr = self.flCombatState > 0
				if bCheckDistance then
					flDistSqr = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
					flDistSqr = flDistSqr * flDistSqr
				end
				local function fDo( tr, vOrigin, tAngles )
					if !tr.Hit then
						local vPos = vOrigin + vHeight
						local tWholeFilter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
						for i, flGlobalAnglePitch in ipairs( tPitchAngles ) do
							for i, flGlobalAngleYaw in ipairs( tAngles ) do
								// local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
								local aAim = aDirection + Angle( 0, flGlobalAngleYaw )
								aAim[ 1 ] = flGlobalAnglePitch
								local vAim = aAim:Forward()
								local tr = util_TraceLine {
									start = vPos,
									endpos = vPos + vAim * 999999,
									mask = MASK_SHOT_HULL,
									filter = self
								}
								local _, vPoint = util.DistanceToLine( vPos, tr.HitPos, vTarget )
								if util_TraceLine( {
									start = vPoint,
									endpos = vTarget,
									mask = MASK_SHOT_HULL,
									filter = tWholeFilter
								} ).Hit || bCheckDistance && vPoint:DistToSqr( vTarget ) > flDistSqr then
									continue
								end
								return vPoint
							end
						end
					end
				end
				if self.bHoldFire then
					local tAllies = self:GetAlliesByClass()
					if tAllies then
						local b = true
						for ent in pairs( tAllies ) do
							if !IsValid( ent ) || ent == self || !ent.__ACTOR__ || !IsValid( ent.Enemy ) || !ent:IsCurrentSchedule "HoldFireCheckEnemy" then continue end
							local _, pTrueEnemy = ent:SetupEnemy( ent.Enemy )
							if pTrueEnemy == trueenemy then b = nil break end
						end
						if b then
							self:SetSchedule( "HoldFireCheckEnemy" ).pEnemy = enemy
							return
						end
					else self:SetSchedule( "HoldFireCheckEnemy" ).pEnemy = enemy end
				end
				local aGeneral = Angle( aDirection )
				aGeneral[ 1 ] = 0
				local dRight = aGeneral:Right()
				local dLeft = -dRight
				local flDistance = self:OBBMaxs().x * 2
				local tCover = self.tCover
				local vLeft = tCover[ 1 ] + ( tCover[ 1 ] - tCover[ 2 ] ):GetNormalized() * flDistance
				local flAdd = self:OBBMaxs().x
				local trLeft = util_TraceHull {
					start = vLeft + vHeight,
					endpos = vLeft + dLeft * flAdd + vHeight,
					mins = vMins,
					maxs = vMaxs,
					filter = self
				}
				local tAngles = { 0 }
				for a = 5.625, 22.5, 5.625 do
					table.insert( tAngles, -a )
					table.insert( tAngles, a )
				end
				local vLeftTarget = fDo( trLeft, vLeft, tAngles )
				local flDistance = self:OBBMaxs().x * 2
				local vRight = tCover[ 1 ] + ( tCover[ 2 ] - tCover[ 1 ] ):GetNormalized() * flDistance
				local trRight = util_TraceHull {
					start = vRight + vHeight,
					endpos = vRight + dRight * flAdd + vHeight,
					mins = vMins,
					maxs = vMaxs,
					filter = self
				}
				tAngles = { 0 }
				for a = 5.625, 22.5, 5.625 do
					table.insert( tAngles, a )
					table.insert( tAngles, -a )
				end
				local vRightTarget = fDo( trRight, vRight, tAngles )
				local function SetupSchedule( vOrigin, vTarget )
					local sched = self:SetSchedule "RangeAttack"
					sched.vFrom = vOrigin
					sched.vTo = vTarget
					sched.Enemy = enemy
					sched.bSuppressing = true
				end
				if vLeftTarget && vRightTarget then
					if math.random( 2 ) == 1 then
						SetupSchedule( vLeft, vLeftTarget )
					else
						SetupSchedule( vRight, vRightTarget )
					end
					return
				elseif vLeftTarget then
					SetupSchedule( vLeft, vLeftTarget )
					return
				elseif vRightTarget then
					SetupSchedule( vRight, vRightTarget )
					return
				else
					sched[ self.flCombatState > 0 && "bAdvance" || "bRetreat" ] = true
					return
				end
				if !sched.pEnemyPath then sched.pEnemyPath = Path "Follow" end
				self:ComputeFlankPath( sched.pEnemyPath, enemy )
				if !sched.bFromCombatFormation && self.flCombatState > 0 then
					local p = sched.pEnemyPath
					local i = self:FindPathStackUpLine( p, tEnemies )
					if i then
						self.iLastEnemyPathStackUpCursor = i
						p:MoveCursorTo( i )
						local g = p:GetCurrentGoal()
						if g then
							local b = self:CreateBehaviour "CombatFormation"
							local v = p:GetPositionOnPath( i )
							b.Vector = v
							b.Direction = ( p:GetPositionOnPath( i + 1 ) - v ):GetNormalized()
							b:AddParticipant( self )
							b:GatherParticipants()
							b:Initialize()
							return
						end
					end
				end
			end
		else self.flSuppressed = CurTime() + math.Clamp( math.min( 0, ( self:GetExposedWeight() / self:Health() ) * .2 ), 0, 2 ) end
	else self:SetSchedule "TakeCover" end
end )

include "CombatStuff.lua"
