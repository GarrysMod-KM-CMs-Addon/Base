local SURFACE_PROP_EJECTA_COLORS = {
	[ -1 ] = { // A.k.a concrete/stone/etc
		{ 80, 80, 80 },
		{ 90, 85, 75 },
		{ 60, 60, 60 }
	},

	[ util.GetSurfaceIndex "dirt" ] = {
		{ 80, 70, 40 },
		{ 80, 70, 40 },
		{ 80, 70, 40 }
	}
}

function FX_EjectaCloud( vPos, flMagnitude, ESurfaceProp )
	// TODO: FX_EjectaCloudWater
	FX_EjectaCloudLand( vPos, flMagnitude, ESurfaceProp )
end

function FX_EjectaCloudWater( vPos, flMagnitude )
	// TODO
end

function FX_EjectaCloudLand( vPos, flMagnitude, ESurfaceProp )
	local pEmitter = ParticleEmitter( vPos )

	local flScale = flMagnitude / 800
	local flTimeScale = flScale
	if flTimeScale < 1 then flTimeScale = flTimeScale ^ .2 end

	// TODO: Optionally, autofind surfaceprops
	local tColors = SURFACE_PROP_EJECTA_COLORS[ ESurfaceProp ] || SURFACE_PROP_EJECTA_COLORS[ -1 ]
	local flColor1R, flColor1G, flColor1B = unpack( tColors[ 1 ] )
	local flColor2R, flColor2G, flColor2B = unpack( tColors[ 2 ] )
	local flColor3R, flColor3G, flColor3B = unpack( tColors[ 3 ] )

    for _ = 1, 10 * flScale do
        local pPart = pEmitter:Add( "particle/particle_composite", vPos )
        if pPart then
            pPart:SetVelocity( VectorRand():GetNormalized() * math.random( 100, 400 ) * flScale )
            pPart:SetDieTime( math.Rand( 6, 12 ) * flTimeScale )
            pPart:SetStartAlpha( 230 )
            pPart:SetEndAlpha( 0 )
            pPart:SetStartSize( 50 * flScale )
            pPart:SetEndSize( 100 * flScale )
            pPart:SetRoll( math.Rand( 150, 360 ) )
            pPart:SetRollDelta( math.Rand( -1, 1 ) )
            pPart:SetAirResistance( 100 )
            pPart:SetGravity( Vector( 0, 0, math.Rand( -100, -400 ) ) )
            pPart:SetColor( flColor1R, flColor1G, flColor1B )
            pPart:SetCollide( true )
			pPart:SetBounce( 1.5 * math.random() * math.random() )
        end
    end

    for _ = 1, 7 * flScale do
        local pPart = pEmitter:Add( "particle/smokesprites_000" .. math.random( 1, 9 ), vPos )
        if pPart then
            pPart:SetVelocity( VectorRand():GetNormalized() * math.random( 200, 600 ) * flScale )
            pPart:SetDieTime( math.Rand( 6, 12 ) * flTimeScale )
            pPart:SetStartAlpha( 255 - 200 * math.random() * math.random() * math.random() )
            pPart:SetEndAlpha( 0 )
            pPart:SetStartSize( 80 * flScale )
            pPart:SetEndSize( 100 * flScale )
            pPart:SetRoll( math.Rand( 150, 360 ) )
            pPart:SetRollDelta( math.Rand( -1, 1 ) )
            pPart:SetAirResistance( 200 )
            pPart:SetGravity( Vector( math.Rand( -20, 20 ), math.Rand( -20, 20 ), math.Rand( -20, 20 ) ) * flScale )
            pPart:SetColor( flColor2R, flColor2G, flColor2B )
            pPart:SetCollide( true )
			pPart:SetBounce( 1.5 * math.random() * math.random() )
        end
    end

    for _ = 1, 12 * flScale do
        local pPart = pEmitter:Add( "effects/fleck_cement" .. math.random( 1, 2 ), vPos )
        if pPart then
            pPart:SetVelocity( VectorRand():GetNormalized() * math.random( 0, 700 ) * flScale )
            pPart:SetDieTime( math.random( 1, 2 ) * flTimeScale )
            pPart:SetStartAlpha( 255 )
            pPart:SetEndAlpha( 0 )
            pPart:SetStartSize( math.random( 5, 10 ) * flScale )
            pPart:SetRoll( math.Rand( 0, 360 ) )
            pPart:SetRollDelta( math.Rand( -5, 5 ) )
            pPart:SetAirResistance( 40 )
            pPart:SetColor( flColor3R, flColor3G, flColor3B )
            pPart:SetGravity( Vector( 0, 0, -600 ) )
            pPart:SetCollide( true )
			pPart:SetBounce( 1.5 * math.random() * math.random() )
        end
    end

	pEmitter:Finish()
end

function EFFECT:Init( pData )
	FX_EjectaCloud( pData:GetPos(), pData:GetMagnitude(), pData:GetRadius() )
end

function EFFECT:Think() return false end
function EFFECT:Render() end
