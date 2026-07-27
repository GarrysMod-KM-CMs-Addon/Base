local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA
local ParticleEmitter = ParticleEmitter
local math_max = math.max
local math_Rand = math.Rand
local math_random = math.random
local VectorRand = VectorRand
local abs = math.abs
local vector_origin = vector_origin

EFFECT.flLifeTime = 0

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

	self.m_pEntity = pEntity

	local vVelocity = IsValid( pOwner ) && pOwner:GetVelocity() || vector_origin
	local pEmitter = ParticleEmitter( fGetPos() )
	local flLifeTime = 1 / pData:GetMagnitude()
	local flScale = 1 - .75 * math_random() * math_random()
	local flHeatHazeScale = 1

	if pOwner == LocalPlayer() && !pOwner:ShouldDrawLocalPlayer() then
		flScale = flScale * .5
	else flHeatHazeScale = 1 / 3 end

	local aAngles = pData:GetAngles()
	local vForward = Vector( 1, 0, 0 )
	local vRight = Vector( 0, -1, 0 )
	local vUp = Vector( 0, 0, 1 )

	for i = 1, 64 do // No, I am not kidding
		local pPart = pEmitter:Add( "effects/muzzleflash" .. math_random( 1, 4 ), fGetPos() )

		local flResultingSpreadRight = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) )
		local flResultingSpreadUp = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) )
		local vAdd = ( vForward + flResultingSpreadRight * vRight + flResultingSpreadUp * vUp ):GetNormalized()
		pPart:SetVelocity( vVelocity + vAdd / math_max( .1, abs( flResultingSpreadRight ) + abs( flResultingSpreadUp ) ) * flScale / flLifeTime * 4 )
		pPart.m_vOffset = Vector()

		pPart:SetDieTime( flLifeTime * math_Rand( .5, 1.5 ) )
		pPart:SetStartAlpha( 255 )
		pPart:SetEndAlpha( 0 )
		pPart:SetStartSize( 0 )
		pPart:SetEndSize( math_Rand( 16, 20 ) * flScale )
		pPart:SetRoll( math_Rand( 180, 480 ) )
		pPart:SetRollDelta( math_Rand( -1, 1 ) )
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

	for i = 1, 8 do
		local pPart = pEmitter:Add( "MuzzleFlashHeatHaze", fGetPos() )

		local flResultingSpreadRight = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) )
		local flResultingSpreadUp = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) )
		local vAdd = ( vForward + flResultingSpreadRight * vRight + flResultingSpreadUp * vUp ):GetNormalized()
		pPart:SetVelocity( vVelocity + vAdd / math_max( .1, abs( flResultingSpreadRight ) + abs( flResultingSpreadUp ) ) * flScale / flLifeTime * 4 )
		pPart.m_vOffset = Vector()

		pPart:SetDieTime( flLifeTime * math_Rand( 4, 8 ) )
		pPart:SetStartAlpha( 0 )
		pPart:SetEndAlpha( 255 )
		pPart:SetStartSize( math_Rand( 32, 48 ) * flScale * flHeatHazeScale )
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

	pEmitter:Finish()

	self.flLifeTime = CurTime() + 48 * flScale
end

function EFFECT:Render() end
function EFFECT:Think() return CurTime() <= self.flLifeTime end
