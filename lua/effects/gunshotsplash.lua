local EmitSound = EmitSound
local ParticleEmitter = ParticleEmitter
local random = math.random
local Rand = math.Rand
local sv_gravity = GetConVar "sv_gravity"

sound.Add {
	name = "GunshotSplash",
	sound = {
		"ambient/water/water_splash1.wav",
		"ambient/water/water_splash2.wav",
		"ambient/water/water_splash3.wav"
	},
	level = 90,
	pitch = { 80, 120 },
	channel = CHAN_STATIC
}

function EFFECT:Init( pData )
	local vPos = pData:GetOrigin()

	EmitSound( "GunshotSplash", vPos )

	local flScale = pData:GetScale()

	local pEmitter = ParticleEmitter( vPos )

	for i = 1, random( 8, 12 ) do
		local vVelocity = VectorRand() * 20 * flScale
		vVelocity[ 3 ] = Rand( 60, 120 ) * flScale
		local pPart = pEmitter:Add( "particles/smokey", vPos )
		if pPart then
			pPart:SetVelocity( vVelocity )
			pPart:SetDieTime( Rand( .4, .8 ) )
			pPart:SetStartAlpha( 200 )
			pPart:SetEndAlpha( 0 )
			pPart:SetStartSize( Rand( .1, .2 ) * flScale )
			pPart:SetEndSize( Rand( .5, 1.5 ) * flScale )
			pPart:SetRoll( Rand( 0, 360 ) )
			pPart:SetRollDelta( Rand( -2, 2 ) )
			pPart:SetAirResistance( 100 )
			pPart:SetGravity( Vector( 0, 0, -sv_gravity:GetFloat() ) )
			pPart:SetColor( 220, 235, 245 )
		end
	end

	for i = 1, random( 15, 25 ) do
		local vVelocity = VectorRand() * Rand( 80, 160 ) * flScale
		vVelocity[ 3 ] = Rand( 80, 160 ) * flScale
		local pPart = pEmitter:Add( "effects/splash4", vPos )
		if pPart then
			pPart:SetVelocity( vVelocity )
			pPart:SetDieTime( Rand( .5, 1 ) )
			pPart:SetStartAlpha( 255 )
			pPart:SetEndAlpha( 0 )
			pPart:SetStartSize( Rand( .05, .2 ) * flScale )
			pPart:SetEndSize( 0 )
			pPart:SetRoll( Rand( 0, 360 ) )
			pPart:SetGravity( Vector( 0, 0, -sv_gravity:GetFloat() ) )
			pPart:SetAirResistance( 50 )
			pPart:SetCollide( true )
			pPart:SetBounce( .3 )
			pPart:SetColor( 240, 245, 255 )
		end
	end

	for i = 1, 3 do
		local pPart = pEmitter:Add( "particles/smokey", vPos )
		if pPart then
			pPart:SetVelocity( VectorRand() * 6 * flScale + Vector( 0, 0, 4 ) * flScale )
			pPart:SetDieTime( Rand( .8, 1.4 ) )
			pPart:SetStartAlpha( 60 )
			pPart:SetEndAlpha( 0 )
			pPart:SetStartSize( 1 * flScale )
			pPart:SetEndSize( 4 * flScale )
			pPart:SetColor( 230, 240, 250 )
		end
	end

	pEmitter:Finish()

	local pEmitter = ParticleEmitter( vPos, true )

	for i = 1, random( 10, 20 ) do
		local pPart = pEmitter:Add( "effects/select_ring", vPos )
		if pPart then
			pPart:SetDieTime( Rand( .6, .9 ) )
			pPart:SetStartAlpha( 150 )
			pPart:SetEndAlpha( 0 )
			pPart:SetStartSize( 0 )
			pPart:SetEndSize( Rand( 4, 6 ) * flScale )
			pPart:SetAngles( Angle( 90, 0, 0 ) ) 
			pPart:SetColor( 200, 220, 240 )
		end
	end

	pEmitter:Finish()
end

function EFFECT:Think() return false end

function EFFECT:Render() end
