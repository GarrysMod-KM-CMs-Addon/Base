ENT.flMyJumpiness = 5

// TODO: The funcs below should clamp the velocity so we can't move farther than flMaxJumpHeight * 3,
// plus the IsInterceptJumpLegal functions should calculate the real intercept position instead of
// just measuring the distance to the target itself.

// Why is this called Legal and not Can? Simple.
// Intercept jumps are cinematic, not physically correct,
// 'cause fuck it, the IRVING's ballin'.
// Thus, we are asking if it's KINDA fair to jump there
function ENT:IsInterceptJumpLegal( pTarget, flJumpHeight, bIgnoreZ, flSpecificJumpHeight )
	if !self:IsOnGround() then return end

	flJumpHeight = flJumpHeight || self.flJumpHeight

	return self:IsInterceptJumpLegalInternal( pTarget, flJumpHeight, flJumpHeight * self.flMyJumpiness, bIgnoreZ, flSpecificJumpHeight )
end

// Only jump if it will be a (relatively) smol jump
function ENT:IsInterceptJumpLegalShort( pTarget, flJumpHeight, bIgnoreZ, flSpecificJumpHeight )
	if !self:IsOnGround() then return end

	flJumpHeight = flJumpHeight || self.flJumpHeight

	return self:IsInterceptJumpLegalInternal( pTarget, flJumpHeight, flJumpHeight * self.flMyJumpiness / 3, bIgnoreZ, flSpecificJumpHeight )
end

function ENT:IsInterceptJumpLegalMedium( pTarget, flJumpHeight, bIgnoreZ, flSpecificJumpHeight )
	if !self:IsOnGround() then return end

	flJumpHeight = flJumpHeight || self.flJumpHeight

	return self:IsInterceptJumpLegalInternal( pTarget, flJumpHeight, flJumpHeight * self.flMyJumpiness * 2 / 3, bIgnoreZ, flSpecificJumpHeight )
end

// Maybe allow vTarget instead of pTarget? And maybe a vTarget override?
// Not gonna code it right now as there's no reason right now.
function ENT:IsInterceptJumpLegalInternal( pTarget, flMaxJumpHeight, flJumpDistance, bIgnoreZ, flSpecificJumpHeight, vPos )
	vPos = vPos || self:GetPos()

	local vTarget = pTarget:GetPos()

	if ( vTarget[ 3 ] - vPos[ 3 ] ) > flMaxJumpHeight then return end

	local tFilter = SimpleRelatedFilterDouble( self, pTarget )

	local flDistance2D = vPos:Distance2D( vTarget + pTarget:OBBCenter() )

	//
	// Try to find...
	//

	//
	// 1. The direct jump
	//

	repeat
		local flJumpHeight = flSpecificJumpHeight || flDistance2D * ( math.random( 2 ) == 1 && ( 1 / 3 + ( math.random() * math.random() ) * 2 / 3 ) || math.Rand( 1 / 3, 2 ) )

		local flEnemyZ, flMyZ = vTarget[ 3 ], vPos[ 3 ]
		if flEnemyZ > flMyZ then flJumpHeight = flJumpHeight + flEnemyZ - flMyZ end

		if flJumpHeight > flMaxJumpHeight then break end
	
		local flGravity = self:GetMyGravity()
	
		local flVelocityZ = math.sqrt( 2 * flGravity * flJumpHeight )
	
		local flTime = ( 2 * flVelocityZ ) / flGravity
	
		local vIntercept = vTarget + GetVelocity( pTarget ) * flTime
	
		local vDirection = vIntercept - vPos
		vDirection[ 3 ] = 0
	
		local flDistance = vDirection:Length()
	
		if flDistance > flJumpDistance then break end
	
		local vApex = LerpVector( .5, vPos, vIntercept )
		vApex[ 3 ] = vApex[ 3 ] + flJumpHeight

		if util.TraceLine( {
			start = vPos + Vector( 0, 0, self:OBBMaxs()[ 3 ] ),
			endpos = vApex,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit || util.TraceLine( {
			start = vApex,
			endpos = vIntercept,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit then
			//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 255, 0, 0 ), true )
			//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 255, 0, 0 ), true )

			break
		end

		//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 0, 255, 0 ), true )
		//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 0, 255, 0 ), true )

		self.flLastLegalJumpHeight = flJumpHeight
		return flJumpHeight
	until true

	//
	// 2. The random jump
	//

	for _ = 1, 3 do
		local flJumpHeight = flDistance2D * ( math.random( 2 ) == 1 && ( 1 / 3 + ( math.random() * math.random() ) * 2 / 3 ) || math.Rand( 1 / 3, 2 ) )

		local flEnemyZ, flMyZ = vTarget[ 3 ], vPos[ 3 ]
		if flEnemyZ > flMyZ then flJumpHeight = flJumpHeight + flEnemyZ - flMyZ end
	
		if flJumpHeight > flMaxJumpHeight then break end
	
		local flGravity = self:GetMyGravity()
	
		local flVelocityZ = math.sqrt( 2 * flGravity * flJumpHeight )
	
		local flTime = ( 2 * flVelocityZ ) / flGravity
	
		local vIntercept = vTarget + GetVelocity( pTarget ) * flTime
	
		local vDirection = vIntercept - vPos
		vDirection[ 3 ] = 0
	
		local flDistance = vDirection:Length()
	
		if flDistance > flJumpDistance then break end
	
		local vApex = LerpVector( .5, vPos, vIntercept )
		vApex[ 3 ] = vApex[ 3 ] + flJumpHeight

		if util.TraceLine( {
			start = vPos + Vector( 0, 0, self:OBBMaxs()[ 3 ] ),
			endpos = vApex,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit || util.TraceLine( {
			start = vApex,
			endpos = vIntercept,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit then
			//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 255, 0, 0 ), true )
			//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 255, 0, 0 ), true )

			break
		end

		//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 0, 255, 0 ), true )
		//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 0, 255, 0 ), true )

		self.flLastLegalJumpHeight = flJumpHeight
		return flJumpHeight
	end

	//
	// 3. The max random jump
	//

	for _ = 1, 3 do
		local flJumpHeight = flMaxJumpHeight * ( math.random( 2 ) == 1 && ( 1 / 3 + ( math.random() * math.random() ) * 2 / 3 ) || math.Rand( 1 / 3, 2 ) )

		local flEnemyZ, flMyZ = vTarget[ 3 ], vPos[ 3 ]
		if flEnemyZ > flMyZ then flJumpHeight = flJumpHeight + flEnemyZ - flMyZ end
	
		if flJumpHeight > flMaxJumpHeight then break end
	
		local flGravity = self:GetMyGravity()
	
		local flVelocityZ = math.sqrt( 2 * flGravity * flJumpHeight )
	
		local flTime = ( 2 * flVelocityZ ) / flGravity
	
		local vIntercept = vTarget + GetVelocity( pTarget ) * flTime
	
		local vDirection = vIntercept - vPos
		vDirection[ 3 ] = 0
	
		local flDistance = vDirection:Length()
	
		if flDistance > flJumpDistance then break end
	
		local vApex = LerpVector( .5, vPos, vIntercept )
		vApex[ 3 ] = vApex[ 3 ] + flJumpHeight

		if util.TraceLine( {
			start = vPos + Vector( 0, 0, self:OBBMaxs()[ 3 ] ),
			endpos = vApex,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit || util.TraceLine( {
			start = vApex,
			endpos = vIntercept,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit then
			//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 255, 0, 0 ), true )
			//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 255, 0, 0 ), true )

			break
		end

		//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 0, 255, 0 ), true )
		//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 0, 255, 0 ), true )

		self.flLastLegalJumpHeight = flJumpHeight
		return flJumpHeight
	end

	//
	// 4. The strict jump
	//

	local bInverseOrder = math.random( 2 ) == 1
	for flJumpHeight = bInverseOrder && flDistance2D || ( flMaxJumpHeight * .01 ), bInverseOrder && ( flMaxJumpHeight * .01 ) || flDistance2D, flDistance2D * ( bInverseOrder && -.4 || .4 ) do
		local flJumpHeight = math.max( flMaxJumpHeight * .01, flJumpHeight )

		local flEnemyZ, flMyZ = vTarget[ 3 ], vPos[ 3 ]
		if flEnemyZ > flMyZ then flJumpHeight = flJumpHeight + flEnemyZ - flMyZ end
	
		if flJumpHeight > flMaxJumpHeight then continue end
	
		local flGravity = self:GetMyGravity()
	
		local flVelocityZ = math.sqrt( 2 * flGravity * flJumpHeight )
	
		local flTime = ( 2 * flVelocityZ ) / flGravity
	
		local vIntercept = vTarget + GetVelocity( pTarget ) * flTime
	
		local vDirection = vIntercept - vPos
		vDirection[ 3 ] = 0
	
		local flDistance = vDirection:Length()
	
		if flDistance > flJumpDistance then continue end
	
		local vApex = LerpVector( .5, vPos, vIntercept )
		vApex[ 3 ] = vApex[ 3 ] + flJumpHeight

		if util.TraceLine( {
			start = vPos + Vector( 0, 0, self:OBBMaxs()[ 3 ] ),
			endpos = vApex,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit || util.TraceLine( {
			start = vApex,
			endpos = vIntercept,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit then
			//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 255, 0, 0 ), true )
			//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 255, 0, 0 ), true )

			continue
		end

		//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 0, 255, 0 ), true )
		//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 0, 255, 0 ), true )

		self.flLastLegalJumpHeight = flJumpHeight
		return flJumpHeight
	end

	//
	// 5. The max strict jump
	//

	local bInverseOrder = math.random( 2 ) == 1
	for flJumpHeight = bInverseOrder && flMaxJumpHeight || ( flMaxJumpHeight * .01 ), bInverseOrder && ( flMaxJumpHeight * .01 ) || flMaxJumpHeight, flMaxJumpHeight * ( bInverseOrder && -.4 || .4 ) do
		local flJumpHeight = math.max( flMaxJumpHeight * .01, flJumpHeight )

		local flEnemyZ, flMyZ = vTarget[ 3 ], vPos[ 3 ]
		if flEnemyZ > flMyZ then flJumpHeight = flJumpHeight + flEnemyZ - flMyZ end
	
		if flJumpHeight > flMaxJumpHeight then continue end
	
		local flGravity = self:GetMyGravity()
	
		local flVelocityZ = math.sqrt( 2 * flGravity * flJumpHeight )
	
		local flTime = ( 2 * flVelocityZ ) / flGravity
	
		local vIntercept = vTarget + GetVelocity( pTarget ) * flTime
	
		local vDirection = vIntercept - vPos
		vDirection[ 3 ] = 0
	
		local flDistance = vDirection:Length()
	
		if flDistance > flJumpDistance then continue end
	
		local vApex = LerpVector( .5, vPos, vIntercept )
		vApex[ 3 ] = vApex[ 3 ] + flJumpHeight

		if util.TraceLine( {
			start = vPos + Vector( 0, 0, self:OBBMaxs()[ 3 ] ),
			endpos = vApex,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit || util.TraceLine( {
			start = vApex,
			endpos = vIntercept,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit then
			//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 255, 0, 0 ), true )
			//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 255, 0, 0 ), true )

			continue
		end

		//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 0, 255, 0 ), true )
		//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 0, 255, 0 ), true )

		self.flLastLegalJumpHeight = flJumpHeight
		return flJumpHeight
	end

	//
	// And finally, the max jump
	//

	repeat
		local flJumpHeight = flMaxJumpHeight

		local flEnemyZ, flMyZ = vTarget[ 3 ], vPos[ 3 ]
		if flEnemyZ > flMyZ then flJumpHeight = flJumpHeight + flEnemyZ - flMyZ end
	
		if flJumpHeight > flMaxJumpHeight then break end
	
		local flGravity = self:GetMyGravity()
	
		local flVelocityZ = math.sqrt( 2 * flGravity * flJumpHeight )
	
		local flTime = ( 2 * flVelocityZ ) / flGravity
	
		local vIntercept = vTarget + GetVelocity( pTarget ) * flTime
	
		local vDirection = vIntercept - vPos
		vDirection[ 3 ] = 0
	
		local flDistance = vDirection:Length()
	
		if flDistance > flJumpDistance then break end
	
		local vApex = LerpVector( .5, vPos, vIntercept )
		vApex[ 3 ] = vApex[ 3 ] + flJumpHeight

		if util.TraceLine( {
			start = vPos + Vector( 0, 0, self:OBBMaxs()[ 3 ] ),
			endpos = vApex,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit || util.TraceLine( {
			start = vApex,
			endpos = vIntercept,
			mask = MASK_SOLID,
			filter = tFilter
		} ).Hit then
			//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 255, 0, 0 ), true )
			//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 255, 0, 0 ), true )

			break
		end

		//DEBUG	debugoverlay.Line( vPos, vApex, 10, Color( 0, 255, 0 ), true )
		//DEBUG	debugoverlay.Line( vApex, vIntercept, 10, Color( 0, 255, 0 ), true )

		self.flLastLegalJumpHeight = flJumpHeight
		return flJumpHeight
	until true

	//	local vTravel = vDirection:GetNormalized()

	//	local vResult = vTravel * ( flDistance / flTime )
	//	vResult[ 3 ] = vResult[ 3 ] + flVelocityZ
end

function ENT:InterceptJump( pTarget, flDesiredJumpHeight, flMaxJumpHeight )
	if !self:IsOnGround() then return end

	local pLocomotion = self.loco

	local vPos = self:GetPos()
	local vTarget = pTarget:GetPos()

	flMaxJumpHeight = flMaxJumpHeight || pLocomotion:GetJumpHeight()

	local flJumpHeight = self.flLastLegalJumpHeight || math.min(
		flDesiredJumpHeight ||
		math.max( flMaxJumpHeight * .01, ( vPos:Distance2D( vTarget + pTarget:OBBCenter() ) * ( math.random( 2 ) == 1 && ( 1 / 3 + ( math.random() * math.random() ) * 2 / 3 ) || math.Rand( 1 / 3, 2 ) ) ) ),
		flMaxJumpHeight )

	local flGravity = self:GetMyGravity()

	local flVelocityZ = math.sqrt( 2 * flGravity * flJumpHeight )

	local flTime = ( 2 * flVelocityZ ) / flGravity

	local vIntercept = vTarget + GetVelocity( pTarget ) * flTime

	local vDirection = vIntercept - vPos
	vDirection[ 3 ] = 0

	local flDistance = vDirection:Length()
	local vTravel = vDirection:GetNormalized()
	
	local vResult = vTravel * ( flDistance / flTime )
	vResult[ 3 ] = vResult[ 3 ] + flVelocityZ

	pLocomotion:SetJumpHeight( 1 )
	pLocomotion:Jump()
	pLocomotion:SetJumpHeight( flMaxJumpHeight )

	self:PostJumpInternal()

	pLocomotion:SetVelocity( vResult )

	return vIntercept
end
