local EmitSound = EmitSound
local ParticleEmitter = ParticleEmitter
local random = math.random
local Rand = math.Rand
local sv_gravity = GetConVar "sv_gravity"
local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
local EyePos = EyePos
local sqrt = math.sqrt

sound.Add {
	name = "WaterSplashSmall",
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

	EmitSound( "WaterSplashSmall", vPos )

	local flScale = pData:GetScale()

	self.m_flScale = flScale

	local pEmitter = ParticleEmitter( vPos )

	for i = 1, random( 2, 4 ) do
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

	for i = 1, random( 4, 8 ) do
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

	for i = 1, random( 2, 4 ) do
		local pPart = pEmitter:Add( "particles/smokey", vPos )
		if pPart then
			pPart:SetVelocity( VectorRand() * 4 * flScale + Vector( 0, 0, Rand( 40, 50 ) ) * flScale )
			pPart:SetDieTime( Rand( .6, .8 ) )
			pPart:SetStartAlpha( 60 )
			pPart:SetEndAlpha( 0 )
			pPart:SetStartSize( 1 * flScale )
			pPart:SetEndSize( 4 * flScale )
			pPart:SetColor( 230, 240, 250 )
			pPart:SetGravity( Vector( 0, 0, -sv_gravity:GetFloat() ) )
			pPart:SetAirResistance( 200 )
			pPart:SetCollide( true )
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

local WATERSPLASH_BLUR_DISTANCE = 192

function EFFECT:Render()
	local MyTable = CEntity_GetTable( self )
	if MyTable.m_bCalculatedBlur then return end
	MyTable.m_bCalculatedBlur = true

	local flDistSqr = EyePos():DistToSqr( self:GetPos() )
	local flScale = MyTable.m_flScale
	local f = WATERSPLASH_BLUR_DISTANCE * flScale
	if flDistSqr > f * f then return end

	WATER_BLUR = WATER_BLUR + ( 1 - sqrt( flDistSqr ) / ( WATERSPLASH_BLUR_DISTANCE * flScale ) ) ^ 2 * flScale ^ 1.1 * .005
	RecalculateWaterBlurAmounts()
end
