local EmitSound = EmitSound
local ParticleEmitter = ParticleEmitter
local random = math.random
local Rand = math.Rand
local sv_gravity = GetConVar "sv_gravity"
local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
local EyePos = EyePos
local sqrt = math.sqrt

sound.Add {
	name = "GekkoLandWater",
	sound = {
		"ambient/water/water_splash1.wav",
		"ambient/water/water_splash2.wav",
		"ambient/water/water_splash3.wav"
	},
	level = 130,
	pitch = { 80, 120 },
	channel = CHAN_STATIC
}

function EFFECT:Init( pData )
	local pOwner = pData:GetEntity()

	local vPos = pOwner:GetPos()

	local flWaterLevel = pOwner:WaterLevel()
	local bSplash = flWaterLevel == 1 || flWaterLevel == 2

	if bSplash then
		EmitSound( "GekkoLandWater", vPos )

		self.m_bSplash = true

		local pEmitter = ParticleEmitter( vPos )

		local flScale = 40

		for i = 1, random( 8, 12 ) do
			local vVelocity = VectorRand() * 20 * flScale
			vVelocity[ 3 ] = Rand( 20, 40 ) * flScale
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
	
		for i = 1, random( 16, 24 ) do
			local vVelocity = VectorRand() * Rand( 30, 40 ) * flScale
			vVelocity[ 3 ] = Rand( 30, 40 ) * flScale
			local pPart = pEmitter:Add( "effects/splash4", vPos )
			if pPart then
				pPart:SetVelocity( vVelocity )
				pPart:SetDieTime( Rand( 1, 2 ) )
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
	
		for i = 1, random( 6, 12 ) do
			local pPart = pEmitter:Add( "particles/smokey", vPos )
			if pPart then
				local flZ = Rand( 0, 50 )
				pPart:SetVelocity( VectorRand() * 4 * flScale + Vector( 0, 0, flZ ) * flScale )
				pPart:SetDieTime( Rand( 2, 3 ) * flZ / 50 )
				pPart:SetStartAlpha( 60 )
				pPart:SetEndAlpha( 0 )
				pPart:SetStartSize( 1 * flScale )
				pPart:SetEndSize( 4 * flScale )
				pPart:SetColor( 230, 240, 250 )
				pPart:SetGravity( Vector( 0, 0, -sv_gravity:GetFloat() * .5 ) )
				pPart:SetAirResistance( 400 )
				pPart:SetCollide( true )
			end
		end
	
		pEmitter:Finish()
	
		local pEmitter = ParticleEmitter( vPos, true )
	
		for i = 1, random( 10, 20 ) do
			local pPart = pEmitter:Add( "effects/select_ring", vPos )
			if pPart then
				pPart:SetDieTime( Rand( 1, 2 ) )
				pPart:SetStartAlpha( 150 )
				pPart:SetEndAlpha( 0 )
				pPart:SetStartSize( 0 )
				pPart:SetEndSize( Rand( 4, 6 ) * flScale )
				pPart:SetAngles( Angle( 90, 0, 0 ) ) 
				pPart:SetColor( 200, 220, 240 )
			end
		end
	
		pEmitter:Finish()

		return
	end
end

function EFFECT:Think() return false end

local BLUR_DISTANCE = 1024

function EFFECT:Render()
	local MyTable = CEntity_GetTable( self )
	if MyTable.m_bCalculatedBlur then return end
	MyTable.m_bCalculatedBlur = true

	if !MyTable.m_bSplash then return end

	local flDistSqr = EyePos():DistToSqr( self:GetPos() )
	if flDistSqr > BLUR_DISTANCE * BLUR_DISTANCE then return end

	WATER_BLUR = WATER_BLUR + ( 1 - sqrt( flDistSqr ) / BLUR_DISTANCE ) ^ 2
	RecalculateWaterBlurAmounts()
end
