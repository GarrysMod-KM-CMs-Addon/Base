local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA
local ParticleEmitter = ParticleEmitter
local math_max = math.max
local math_Rand = math.Rand
local math_random = math.random

function EFFECT:Init( pData )
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	local v = pData:GetStart()
	local pWeapon, pOwner = pData:GetEntity()
	if IsValid( pWeapon ) then
		local vRenderOrigin = pWeapon:GetRenderOrigin()
		if vRenderOrigin then v = vRenderOrigin else
			pOwner = pWeapon:GetOwner()
			if IsValid( pOwner ) then v = self:GetTracerShootPos( pData:GetOrigin(), pWeapon, pData:GetAttachment() ) end
		end
	end
	local vVelocity = IsValid( pOwner ) && pOwner:GetVelocity() || vector_origin
	local pEmitter = ParticleEmitter( v )
	local f = .1
	for i = 1, 4 do
		local n = math_Rand( 0, 1 ) ^ .5
		if n > f then f = n end
	end
	for i = 1, 2 do
		local pPart = pEmitter:Add( "effects/muzzleflash" .. math_random( 1, 4 ), v )
		pPart:SetVelocity( vVelocity )
		pPart:SetDieTime( .1 )
		pPart:SetStartAlpha( 255 )
		pPart:SetEndAlpha( math_Rand( 0, 255 ) )
		pPart:SetStartSize( 1 * i * f )
		pPart:SetEndSize( 12 * i * f )
		pPart:SetRoll( math_Rand( 180, 480 ) )
		pPart:SetRollDelta( math_Rand( -1, 1 ) )
		pPart:SetColor( 255, 255, 255 )	
		pPart:SetAirResistance( 140 )
	end
	for i = 1, 3 do 
		local pPart = pEmitter:Add( "particle/particle_smokegrenade", v )
		// This is square shaped, and we don't like them squares 'round these parts
		//	pPart:SetVelocity( vVelocity + Vector( math_Rand( -20, 20 ), math_Rand( -20, 20 ), math_Rand( -20, 20 ) ) )
		pPart:SetVelocity( vVelocity + VectorRand() * math_Rand( 0, 20 ) )
		pPart:SetDieTime( math_Rand( .5, 1 ) )
		pPart:SetStartAlpha( math_Rand( 50, 155 ) )
		pPart:SetStartSize( math_Rand( .5, 1 ) * i )
		pPart:SetEndSize( math_Rand( 2, 4 ) * i )
		pPart:SetRoll( math_Rand( 180, 480 ) )
		pPart:SetRollDelta( math_Rand( -1, 1 ) )
		pPart:SetColor( 200, 200, 200 )
		pPart:SetAirResistance( 140 )
	end
	pEmitter:Finish()
end

// Yes, this is necessary as to hide the error model... why? No idea.
function EFFECT:Render() end

function EFFECT:Think() return false end
