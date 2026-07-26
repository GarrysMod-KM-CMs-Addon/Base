local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA
local ParticleEmitter = ParticleEmitter
local math_max = math.max
local math_Rand = math.Rand
local math_random = math.random
local VectorRand = VectorRand
local abs = math.abs
local vector_origin = vector_origin

local vWhite, vOrange = Vector( 255, 255, 255 ), Vector( 255, 128, 64 )

function EFFECT:Init( pData )
	self:SetRenderMode( RENDERMODE_TRANSALPHA )

	local fGetPos, fGetAngles = function() return vector_origin end, function() return angle_zero end

	local v = pData:GetStart()
	local pEntity, pOwner = pData:GetEntity()

	local fGetMuzzleFlashPosition = pEntity.GetMuzzleFlashPosition
	if fGetMuzzleFlashPosition then
		local iGetMaterialIndex = pData:GetMaterialIndex()
		fGetPos = function()
			if !IsValid( pEntity ) then return vector_origin end
			return fGetMuzzleFlashPosition( pEntity, "MuzzleFlashGeneric", iGetMaterialIndex )
		end
	end

	local fGetMuzzleFlashAngles = pEntity.GetMuzzleFlashAngles
	if fGetMuzzleFlashAngles then
		local iGetMaterialIndex = pData:GetMaterialIndex()
		fGetAngles = function()
			if !IsValid( pEntity ) then return angle_zero end
			return fGetMuzzleFlashAngles( pEntity, "MuzzleFlashGeneric", iGetMaterialIndex )
		end
	end

	if !fGetMuzzleFlashPosition && IsValid( pEntity ) then
		pOwner = pEntity:GetOwner()
		if IsValid( pOwner ) then
			local iAttachment = pData:GetAttachment()
			v = self:GetTracerShootPos( vector_origin, pEntity, iAttachment )
			fGetPos = function()
				if !IsValid( self ) then return vector_origin end
				return self:GetTracerShootPos( vector_origin, pEntity, iAttachment )
			end
		end
		if v == vector_origin then
			fGetPos = function()
				if !IsValid( pEntity ) then return vector_origin end

				// Render origin changes the "real" position of the entity on the client,
				// thus GetPos() and GetAngles() can be used to never worry about nil values

				//	local vRenderOrigin = pEntity:GetRenderOrigin()
				//	local aRenderAngles = pEntity:GetRenderAngles()
				//	if aRenderAngles then vRenderOrigin = vRenderOrigin + aRenderAngles:Forward() * 13 + aRenderAngles:Up() * 6 end

				local vRenderOrigin = pEntity:GetPos()
				local aRenderAngles = pEntity:GetAngles()
				vRenderOrigin = vRenderOrigin + aRenderAngles:Forward() * 13 + aRenderAngles:Up() * 6

				return vRenderOrigin
			end
		end
	end

	if !fGetMuzzleFlashAngles then
		fGetAngles = function()
			if !IsValid( pOwner ) then return angle_zero end
			return pOwner:EyeAngles()
		end
	end

	self.m_pWeapon = pWeapon

	local vVelocity = IsValid( pOwner ) && pOwner:GetVelocity() || vector_origin
	local pEmitter = ParticleEmitter( fGetPos() )
	local flLifeTime = 1 / pData:GetMagnitude()
	local flScale = 1 - .75 * math_random() * math_random()

	// Fun fact: realistic muzzleflashes are so big that they cover half the screen
	if pOwner == LocalPlayer() && !pOwner:ShouldDrawLocalPlayer() then flScale = flScale * .5 end

	local aAngles = pData:GetAngles()
	local vForward = aAngles:Forward()
	local vRight = aAngles:Right()
	local vUp = aAngles:Up()

	for i = 1, 8 do
		local pPart = pEmitter:Add( "MuzzleFlashSuppressedHeatHaze", fGetPos() )

		local flResultingSpreadRight = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) )
		local flResultingSpreadUp = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) )
		local vAdd = ( vForward + flResultingSpreadRight * vRight + flResultingSpreadUp * vUp ):GetNormalized()
		pPart:SetVelocity( vVelocity + vAdd / math_max( .1, abs( flResultingSpreadRight ) + abs( flResultingSpreadUp ) ) * flScale / flLifeTime * 4 )
		pPart.m_vOffset = Vector()

		pPart:SetDieTime( flLifeTime * math_Rand( 4, 8 ) )
		pPart:SetStartAlpha( 0 )
		pPart:SetEndAlpha( 255 )
		pPart:SetStartSize( math_Rand( 16, 24 ) * flScale )
		pPart:SetEndSize( 0 )
		pPart:SetRoll( math_Rand( 180, 480 ) )
		pPart:SetRollDelta( math_Rand( -3, 3 ) )
		pPart:SetColor( 255, 180, 120 )
		pPart:SetAirResistance( 140 )

		pPart:SetNextThink( CurTime() )
		pPart:SetThinkFunction( function()
			local vOffset = pPart.m_vOffset
			vOffset:Add( pPart:GetVelocity() * FrameTime() )
			local v = Vector( vOffset )
			v:Rotate( fGetAngles() )
			v:Add( fGetPos() )
			pPart:SetPos( v )
			pPart:SetNextThink( CurTime() )
		end )
	end

	for i = 1, math_random( 1, 3 ) do
		local pPart = pEmitter:Add( "effects/spark", fGetPos() )

		local flResultingSpreadRight = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) ) * .2
		local flResultingSpreadUp = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) ) * .2
		local vAdd = ( vForward + flResultingSpreadRight * vRight + flResultingSpreadUp * vUp ):GetNormalized()
		local vResultingVelocity = vVelocity + vAdd / math_max( .1, abs( flResultingSpreadRight ) + abs( flResultingSpreadUp ) ) * flScale / flLifeTime * math_Rand( 20, 40 )
		pPart:SetVelocity( vResultingVelocity )
		// TODO: Parenting... seems?... to not be working for sparks?
		// I don't know why, and I'm too lazy to find out right now.
		//	pPart.m_vOffset = Vector()

		pPart:SetAngles( vResultingVelocity:Angle() )
		pPart:SetDieTime( flLifeTime * math_Rand( .5, 1 ) )
		pPart:SetStartAlpha( 255 )
		pPart:SetEndAlpha( 0 )
		pPart:SetStartSize( math_Rand( 0, 2 ) )
		pPart:SetEndSize( math_Rand( 0, 2 ) )
		pPart:SetRoll( math_Rand( 0, 360 ) )
		pPart:SetRollDelta( math_Rand( -4, 4 ) )
		local v = LerpVector( math_random(), vWhite, vOrange )
		pPart:SetColor( v[ 1 ], v[ 2 ], v[ 3 ] )

		//	pPart:SetNextThink( CurTime() )
		//	pPart:SetThinkFunction( function()
		//		local vOffset = pPart.m_vOffset
		//		vOffset:Add( pPart:GetVelocity() * FrameTime() )
		//		local v = Vector( vOffset )
		//		v:Rotate( fGetAngles() )
		//		v:Add( fGetPos() )
		//		pPart:SetPos( v )
		//		pPart:SetNextThink( CurTime() )
		//	end )
	end

	for i = 1, 3 do
		local pPart = pEmitter:Add( "particle/particle_smokegrenade", fGetPos() )
		pPart:SetVelocity( vVelocity + Vector( math.Rand( -20, 20 ), math.Rand( -20, 20 ), math.Rand( -20, 20 ) ) )
		pPart:SetDieTime( math.Rand( .5, 1 ) )
		pPart:SetStartAlpha( math.Rand( 50, 155 ) )
		pPart:SetStartSize( math.Rand( .5, 1 ) * i )
		pPart:SetEndSize( math.Rand( 2, 3 ) * i )
		pPart:SetRoll( math.Rand( 180, 480 ) )
		pPart:SetRollDelta( math.Rand( -1, 1 ) )
		pPart:SetColor( 200, 200, 200 )
		pPart:SetAirResistance( 140 )
	end

	pEmitter:Finish()
end

function EFFECT:Render() end
function EFFECT:Think() return false end

