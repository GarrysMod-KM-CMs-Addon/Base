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
	for i = 1, 3 do
		local pPart = pEmitter:Add( "particle/particle_smokegrenade", v )
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

function EFFECT:Think() return false end
function EFFECT:Render() end
