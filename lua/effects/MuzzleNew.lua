function EFFECT:Init( pData )
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	local pWeapon = pData:GetEntity()
	if !IsValid( pWeapon ) then return end
	local pOwner = pWeapon:GetOwner()
	if !IsValid( pOwner ) then return end
	local v = self:GetTracerShootPos( pData:GetOrigin(), pWeapon, pData:GetAttachment() )
	local vVelocity = pOwner:GetVelocity()
	local pEmitter = ParticleEmitter( v )
	for i = 1, 2 do
		local pPart = pEmitter:Add( "effects/muzzleflash" .. math.random( 1, 4 ), v )
		pPart:SetVelocity( vVelocity )
		pPart:SetDieTime( .1 )
		pPart:SetStartAlpha( 255 )
		pPart:SetEndAlpha( math.Rand( 0, 255 ) )
		pPart:SetStartSize( 1 * i )
		pPart:SetEndSize( 12 * i )
		pPart:SetRoll( math.Rand( 180, 480 ) )
		pPart:SetRollDelta( math.Rand( -1, 1 ) )
		pPart:SetColor( 255, 255, 255 )	
		pPart:SetAirResistance( 140 )
	end
	for i = 1, 3 do 
		local pPart = pEmitter:Add( "particle/particle_smokegrenade", v )
		pPart:SetVelocity( vVelocity + Vector( math.Rand( -20, 20 ), math.Rand( -20, 20 ), math.Rand( -20, 20 ) ) )
		pPart:SetDieTime( math.Rand( .5, 1 ) )
		pPart:SetStartAlpha( math.Rand( 50, 155 ) )
		pPart:SetStartSize( math.Rand( .5, 1 ) * i )
		pPart:SetEndSize( math.Rand( 2, 4 ) * i )
		pPart:SetRoll( math.Rand( 180, 480 ) )
		pPart:SetRollDelta( math.Rand( -1, 1 ) )
		pPart:SetColor( 200, 200, 200 )
		pPart:SetAirResistance( 140 )
	end
	pEmitter:Finish()
end

function EFFECT:Think() return false end
function EFFECT:Render() end
