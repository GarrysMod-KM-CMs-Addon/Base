function EFFECT:Init( pData )
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	local pWeapon = pData:GetEntity()
	if !IsValid( pWeapon ) then return end
	local pOwner = pWeapon:GetOwner()
	if !IsValid( pOwner ) then return end
	local v = self:GetTracerShootPos( pData:GetOrigin(), pWeapon, pData:GetAttachment() )
	local vVelocity = pOwner:GetVelocity()
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
