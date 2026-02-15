ENT.flVehicleDirectionChangeChance = 1000000
ENT.flVehiclePressureStartDistance = 3072
ENT.flVehiclePressureEndDistance = 1024

local VECTOR_UP = Vector( 0, 0, 1 )

// TODO: Implement
function ENT:_VehicleRunAway( self, sched, veh, enemy ) veh:Stay() end

Actor_RegisterSchedule( "Vehicle_Base", function( self, sched )
	if table.IsEmpty( self.tEnemies ) then
		sched.Path = nil
		local veh = self.GAME_pVehicle
		if bit.band( veh.TRAVERSES, TRAVERSES_AIR ) != 0 then
			if !sched.vIdleMove || math.random( self.flVehicleDirectionChangeChance * FrameTime() ) == 1 then sched.vIdleMove = VectorRand() end
			veh:Move( sched.vIdleMove, veh.flTopSpeed )
		else
			if !sched.flIdleMoveX || !sched.flIdleMoveY || math.random( self.flVehicleDirectionChangeChance * FrameTime() ) == 1 then
				sched.flIdleMoveX = math.Rand( -1, 1 )
				sched.flIdleMoveY = math.Rand( -1, 1 )
			end
			local d = Vector( sched.flIdleMoveX, sched.flIdleMoveY ):GetNormalized()
			local b = veh:BoundingRadius()
			local flDist = b * 6
			if util.TraceLine( {
				start = veh:GetPos() + veh:OBBCenter(),
				endpos = veh:GetPos() + veh:OBBCenter() + d * flDist,
				mask = MASK_SOLID,
				filter = { self, veh }
			} ).Hit then sched.flIdleMoveX = nil sched.flIdleMoveY = nil return end
			local tr = util.TraceLine {
				start = veh:GetPos() + veh:OBBCenter(),
				endpos = veh:GetPos() + veh:OBBCenter() + d * flDist,
				mask = MASK_SOLID,
				filter = { self, veh }
			}
			if bit.band( veh.TRAVERSES, TRAVERSES_WATER ) == 0 then
				if bit.band( util.TraceLine( {
					start = veh:GetPos() + veh:OBBCenter(),
					endpos = veh:GetPos() - VECTOR_UP * b * 4,
					mask = MASK_SOLID,
					filter = { self, veh }
				} ).Contents, MASK_WATER ) != 0 then veh:ExitVehicle( self ) return end
				local bWater = bit.band( util.TraceLine( {
					start = veh:GetPos() + veh:OBBCenter(),
					endpos = veh:GetPos() - VECTOR_UP * b * 4 + d * flDist,
					mask = MASK_SOLID,
					filter = { self, veh }
				} ).Contents, MASK_WATER ) != 0
				if bWater then sched.flIdleMoveX = nil sched.flIdleMoveY = nil return
				else veh:Move( d, veh.flTopSpeed * tr.Fraction ) end
			else
				local bWater = bit.band( util.TraceLine( {
					start = veh:GetPos() + veh:OBBCenter(),
					endpos = veh:GetPos() - VECTOR_UP * b * 2 + d * flDist,
					mask = MASK_SOLID,
					filter = { self, veh }
				} ).Contents, MASK_WATER ) != 0
				local bCurrentWater = bit.band( util.TraceLine( {
					start = veh:GetPos() + veh:OBBCenter(),
					endpos = veh:GetPos() - VECTOR_UP * b * 4,
					mask = MASK_SOLID,
					filter = { self, veh }
				} ).Contents, MASK_WATER ) != 0
				if bWater then
					if bCurrentWater then
						veh:Move( d, veh.flTopSpeed * tr.Fraction )
					else
						veh:Move( d, veh.flTopSpeed * .1 )
					end
				else veh:Move( d, veh.flTopSpeed * tr.Fraction ) end
			end
			veh:Turn( d )
		end
	else
		local veh = self.GAME_pVehicle
		local enemy = self.Enemy
		if !IsValid( enemy ) then return end
		if veh:HasWeapon() then
			local v = enemy:GetPos() + enemy:OBBCenter()
			veh:AimWeapon( v )
			local tr = util.TraceLine {
				start = veh:GetShootPos(),
				endpos = v,
				mask = MASK_SHOT_HULL,
				filter = { self, veh, ent }
			}
			local bShoot
			if !tr.Hit || tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( v ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
				if veh:DoesWeaponHit( tr.HitPos ) then veh:FireWeapon() end
				bShoot = true
			else sched.bPressure = true end
			if self.flCombatState < 0 then self:_VehicleRunAway( self, sched, veh, enemy ) else
				if !sched.flGunMoveTarget then sched.flGunMoveTarget = math.Rand( 0, .4 ) end
				local f = sched.flGunMoveTarget
				f = math.Approach( sched.flGunMove || f, f, FrameTime() * .1 )
				sched.flGunMove = f
				if sched.flGunMoveTarget < .1 then sched.flGunMoveTarget = 0 end
				if f == sched.flGunMoveTarget then sched.flGunMoveTarget = math.Rand( 0, .4 ) end
				if !sched.flGunMoveTargetFar then sched.flGunMoveTargetFar = math.Rand( 0, .4 ) end
				local f = sched.flGunMoveTargetFar
				f = math.Approach( sched.flGunMoveFar || f, f, FrameTime() * .1 )
				sched.flGunMoveFar = f
				if f == sched.flGunMoveTargetFar then sched.flGunMoveTargetFar = math.Rand( .4, .6 ) end
				local fg = bShoot && math.Clamp( math.Remap( self:GetPos():Distance( enemy:GetPos() ), self.flVehiclePressureEndDistance, self.flVehiclePressureStartDistance, f, sched.flGunMoveTargetFar ), 0, 1 ) * self.flCombatState || 1
				if fg <= 0 then
					veh:Stay()
					veh:Turn( ( v - veh:GetPos() ):GetNormalized() )
					return
				end
				local v = GetVelocity( enemy )
				if !sched.Path then sched.Path = Path "Follow" end
				self:ComputeVehiclePath( sched.Path, enemy:GetPos() + v * ( veh:GetPos():Distance( enemy:GetPos() ) / veh.flTopSpeed ) )
				sched.Path:MoveCursorToClosestPosition( veh:GetPos() )
				local v = sched.Path:GetPositionOnPath( sched.Path:GetCursorPosition() )
				sched.Path:MoveCursor( veh:BoundingRadius() )
				local f = sched.Path:GetCursorPosition()
				if f >= sched.Path:GetLength() && veh:GetPos():Distance2D( sched.Path:GetEnd() ) <= veh:BoundingRadius() then veh:Stay() veh:Turn( ( enemy:GetPos() - veh:GetPos() ):GetNormalized() ) else
					local dir = ( sched.Path:GetPositionOnPath( f ) - v ):GetNormalized()
					veh:Move( dir, veh.flTopSpeed * self.flCombatState * fg )
					veh:Turn( dir )
				end
			end
		else
			if !sched.Path then sched.Path = Path "Follow" end
			if self.flCombatState < 0 then self:_VehicleRunAway( self, sched, veh, enemy ) else
				local v = GetVelocity( enemy )
				self:ComputeVehiclePath( sched.Path, enemy:GetPos() + v * ( veh:GetPos():Distance( enemy:GetPos() ) / veh.flTopSpeed ) )
				sched.Path:MoveCursorToClosestPosition( veh:GetPos() )
				local v = sched.Path:GetPositionOnPath( sched.Path:GetCursorPosition() )
				sched.Path:MoveCursor( veh:BoundingRadius() )
				local f = sched.Path:GetCursorPosition()
				if f >= sched.Path:GetLength() && veh:GetPos():Distance2D( sched.Path:GetEnd() ) <= veh:BoundingRadius() then veh:Stay() veh:Turn( ( enemy:GetPos() - veh:GetPos() ):GetNormalized() ) else
					local dir = ( sched.Path:GetPositionOnPath( f ) - v ):GetNormalized()
					veh:Move( dir, veh.flTopSpeed )
					veh:Turn( dir )
				end
			end
		end
	end
end )
