local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA
local ParticleEmitter = ParticleEmitter
local math_max = math.max
local math_Rand = math.Rand
local math_random = math.random
local VectorRand = VectorRand
local abs = math.abs
local vector_origin = vector_origin

function EFFECT:Init( pData )
	self:SetRenderMode( RENDERMODE_TRANSALPHA )

	local v = pData:GetStart()
	local pWeapon, pOwner = pData:GetEntity()
	if IsValid( pWeapon ) then
		pOwner = pWeapon:GetOwner()
		if IsValid( pOwner ) then v = self:GetTracerShootPos( vector_origin, pWeapon, pData:GetAttachment() ) end
		if v == vector_origin then
			local vRenderOrigin = pWeapon:GetRenderOrigin()
			if vRenderOrigin then
				v = vRenderOrigin
				local a = pWeapon:GetRenderAngles()
				if a then v:Add( a:Forward() * 16 + a:Up() * 6 ) end
			end
		end
	end

	self.m_pWeapon = pWeapon

	local vVelocity = IsValid( pOwner ) && pOwner:GetVelocity() || vector_origin
	local pEmitter = ParticleEmitter( v )
	local flLifeTime = 1 / pData:GetMagnitude()
	local flScale = 1 - .75 * math_random() * math_random()

	// Fun fact: realistic muzzleflashes are so big that they cover half the screen
	if pOwner == LocalPlayer() && !pOwner:ShouldDrawLocalPlayer() then flScale = flScale * .5 end

	local aAngles = pData:GetAngles()
	local vForward = aAngles:Forward()
	local vRight = aAngles:Right()
	local vUp = aAngles:Up()

	for i = 1, 384 do // No, I am not kidding
		local pPart = pEmitter:Add( "effects/muzzleflash" .. math_random( 1, 4 ), v )
		local flResultingSpreadRight = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) )
		local flResultingSpreadUp = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) )
		local vAdd = ( vForward + flResultingSpreadRight * vRight + flResultingSpreadUp * vUp ):GetNormalized()
		pPart:SetVelocity( vVelocity + vAdd / math_max( .1, abs( flResultingSpreadRight ) + abs( flResultingSpreadUp ) ) * flScale / flLifeTime * 4 )
		pPart:SetDieTime( flLifeTime * math_Rand( .5, 1.5 ) )
		pPart:SetStartAlpha( 255 )
		pPart:SetEndAlpha( 0 )
		pPart:SetStartSize( 0 )
		pPart:SetEndSize( math_Rand( 16, 20 ) * flScale )
		pPart:SetRoll( math_Rand( 180, 480 ) )
		pPart:SetRollDelta( math_Rand( -1, 1 ) )
		pPart:SetColor( 255, 180, 120 )
		pPart:SetAirResistance( 140 )
	end

	for i = 1, 8 do
		local pPart = pEmitter:Add( "MuzzleFlashHeatHaze", v )
		local flResultingSpreadRight = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) )
		local flResultingSpreadUp = ( math_Rand( -.5, .5 ) + math_Rand( -.5, .5 ) )
		local vAdd = ( vForward + flResultingSpreadRight * vRight + flResultingSpreadUp * vUp ):GetNormalized()
		pPart:SetVelocity( vVelocity + vAdd / math_max( .1, abs( flResultingSpreadRight ) + abs( flResultingSpreadUp ) ) * flScale / flLifeTime * 4 )
		pPart:SetDieTime( flLifeTime * math_Rand( 4, 8 ) )
		pPart:SetStartAlpha( 0 )
		pPart:SetEndAlpha( 255 )
		pPart:SetStartSize( math_Rand( 32, 48 ) * flScale )
		pPart:SetEndSize( 0 )
		pPart:SetRoll( math_Rand( 180, 480 ) )
		pPart:SetRollDelta( math_Rand( -3, 3 ) )
		pPart:SetColor( 255, 180, 120 )
		pPart:SetAirResistance( 140 )
	end

	pEmitter:Finish()
end

function EFFECT:Render() end
function EFFECT:Think() return false end

