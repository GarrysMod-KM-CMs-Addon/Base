local math_Rand = math.Rand
local util_TraceLine = util.TraceLine
local math_random = math.random

local vGravity = Vector( 0, 0, -800 )
local vGravityWater = Vector( 0, 0, -100 )

local bit_band = bit.band
local util_PointContents = util.PointContents
local CONTENTS_WATER = CONTENTS_WATER

local CurTime = CurTime

local ParticleEmitter = ParticleEmitter

local MASK_SOLID = MASK_SOLID

local render_GetLightColor = render.GetLightColor

local Lerp = Lerp

local cMaterialRemainsMaxLifeTime = CreateClientConVar(
	"flMaterialRemainsMaxLifeTime",
	"12",
	true,
	nil, 
	"How long can blown off material parts be on the ground?",
	8, 32
)

sound.Add {
	name = "BulletImpactMetal",
	sound = { "physics/metal/metal_sheet_impact_bullet1.wav", "physics/metal/metal_sheet_impact_bullet2.wav" },
	level = 90,
	pitch = { 80, 120 },
	channel = CHAN_STATIC
}

sound.Add {
	name = "BulletImpactConcrete",
	sound = { "physics/concrete/concrete_break2.wav", "physics/concrete/concrete_break3.wav" },
	level = 90,
	pitch = { 80, 120 },
	channel = CHAN_STATIC
}

sound.Add {
	name = "BulletImpactPlaster",
	sound = { "physics/plaster/ceilingtile_break1.wav", "physics/plaster/ceilingtile_break2.wav" },
	level = 90,
	pitch = { 80, 120 },
	channel = CHAN_STATIC
}

local EmitSound = EmitSound

local vWhite, vOrange = Vector( 255, 255, 255 ), Vector( 255, 128, 64 )

local EFFECTS = {
	[ util.GetSurfaceIndex "metal" ] = function( self, pData )
		local vPos = pData:GetOrigin()

		EmitSound( "BulletImpactMetal", vPos, nil, nil, math_Rand( 1 / 3, 1 ) )

		local pLight = EphemeralLight()
		if pLight then
			pLight.brightness = math_Rand( 5, 7 )
			pLight.size = 128 * ( 1 - .5 * math_random() * math_random() )
			local f = math_Rand( 2 / 3, 1 + 1 / 3 )
			pLight.dietime = CurTime() + f
			pLight.decay = 1000 / f
			pLight.pos = vPos
			local v = LerpVector( math_random(), vWhite, vOrange )
			pLight.r = v[ 1 ]
			pLight.g = v[ 2 ]
			pLight.b = v[ 3 ]
		end

		local vDir = ( vPos - pData:GetStart() ):GetNormalized()

		local tr = util_TraceLine {
			start = vPos - vDir * 6,
			endpos = vPos + vDir * 6,
			mask = MASK_SOLID
		}

		local dNormal = tr.HitNormal

		local pEmitter = ParticleEmitter( vPos )

		local pImpact = pEmitter:Add( "sprites/light_glow02_add", vPos )
		pImpact:SetAngles( AngleRand() )
		pImpact:SetDieTime( math_Rand( .06, .12 ) )
		pImpact:SetStartAlpha( 255 )
		pImpact:SetEndAlpha( 0 )
		pImpact:SetStartSize( math_Rand( 24, 32 ) )
		pImpact:SetEndSize( math_Rand( 24, 32 ) )
		pImpact:SetRoll( math_Rand( 0, 360 ) )
		pImpact:SetRollDelta( math_Rand( -4, 4 ) )
		local v = LerpVector( math_random(), vWhite, vOrange )
		pImpact:SetColor( v[ 1 ], v[ 2 ], v[ 3 ] )

		for i = 1, math_random( 4, 6 ) do
			local pPart = pEmitter:Add( "effects/spark", vPos )
			if pPart then
				local v = LerpVector( .2, dNormal, VectorRand() )
				v:Normalize()
				pPart:SetAngles( v:Angle() )
				pPart:SetDieTime( math_Rand( 0, .8 ) )
				pPart:SetStartAlpha( 255 )
				pPart:SetEndAlpha( 0 )
				pPart:SetStartSize( math_Rand( 0, 3 ) )
				pPart:SetEndSize( math_Rand( 0, 3 ) )
				pPart:SetCollide( true )
				pPart:SetBounce( .9 )
				pPart:SetGravity( vGravity )
				pPart:SetVelocity( v * math_Rand( 256, 512 ) )
				pPart:SetRoll( math_Rand( 0, 360 ) )
				pPart:SetRollDelta( math_Rand( -4, 4 ) )
				local v = LerpVector( math_random(), vWhite, vOrange )
				pPart:SetColor( v[ 1 ], v[ 2 ], v[ 3 ] )
			end
		end

		local pHaze = pEmitter:Add( "MetalImpactHeatHaze", vPos )

		pHaze:SetDieTime( math_Rand( .7, 1.4 ) )

		pHaze:SetStartSize( math_Rand( 24, 32 ) )
		pHaze:SetEndSize( math_Rand( 12, 18 ) )

		pHaze:SetRoll( math_Rand( 0, 360 ) )
		pHaze:SetRollDelta( math_Rand( -4, 4 ) )

		pHaze:SetStartAlpha( 255 )
		pHaze:SetEndAlpha( 0 )

		pEmitter:Finish()
	end,

	[ util.GetSurfaceIndex "concrete" ] = function( self, pData )
		local vPos = pData:GetOrigin()

		EmitSound( "BulletImpactConcrete", vPos, nil, nil, math_Rand( 1 / 3, 1 ) )

		local pLight = EphemeralLight()
		if pLight then
			pLight.brightness = math_Rand( 3, 5 )
			pLight.size = 96 * ( 1 - .5 * math_random() * math_random() )
			local f = math_Rand( 2 / 3, 1 + 1 / 3 )
			pLight.dietime = CurTime() + f
			pLight.decay = 1000 / f
			pLight.pos = vPos
			local v = LerpVector( math_random(), vWhite, vOrange )
			pLight.r = v[ 1 ]
			pLight.g = v[ 2 ]
			pLight.b = v[ 3 ]
		end

		local vDir = ( vPos - pData:GetStart() ):GetNormalized()

		local tr = util_TraceLine {
			start = vPos - vDir * 6,
			endpos = vPos + vDir * 6,
			mask = MASK_SOLID
		}

		local dNormal = tr.HitNormal

		local pEmitter = ParticleEmitter( vPos )

		local pImpact = pEmitter:Add( "sprites/light_glow02_add", vPos )
		pImpact:SetAngles( AngleRand() )
		pImpact:SetDieTime( math_Rand( .06, .12 ) )
		pImpact:SetStartAlpha( 255 )
		pImpact:SetEndAlpha( 0 )
		pImpact:SetStartSize( math_Rand( 24, 32 ) )
		pImpact:SetEndSize( math_Rand( 24, 32 ) )
		pImpact:SetRoll( math_Rand( 0, 360 ) )
		pImpact:SetRollDelta( math_Rand( -4, 4 ) )
		local v = LerpVector( math_random(), vWhite, vOrange )
		pImpact:SetColor( v[ 1 ], v[ 2 ], v[ 3 ] )

		for i = 1, math_random( 4, 6 ) do
			local pPart = pEmitter:Add( "effects/spark", vPos )
			if pPart then
				local v = LerpVector( .2, dNormal, VectorRand() )
				v:Normalize()
				pPart:SetAngles( v:Angle() )
				pPart:SetDieTime( math_Rand( 0, .8 ) )
				pPart:SetStartAlpha( 255 )
				pPart:SetEndAlpha( 0 )
				pPart:SetStartSize( math_Rand( 0, 3 ) )
				pPart:SetEndSize( math_Rand( 0, 3 ) )
				pPart:SetCollide( true )
				pPart:SetBounce( .9 )
				pPart:SetGravity( vGravity )
				pPart:SetVelocity( v * math_Rand( 256, 512 ) )
				pPart:SetRoll( math_Rand( 0, 360 ) )
				pPart:SetRollDelta( math_Rand( -4, 4 ) )
				local v = LerpVector( math_random(), vWhite, vOrange )
				pPart:SetColor( v[ 1 ], v[ 2 ], v[ 3 ] )
			end
		end

		for i = 1, math_random( 3, 6 ) do
			local pPart = pEmitter:Add( "particles/smokey", vPos )
			if pPart then
				local v = LerpVector( .2, dNormal, VectorRand() ):GetNormalized()
				pPart:SetBounce( math_Rand( 0, .25 ) )
				pPart:SetAngles( v:Angle() )
				pPart:SetDieTime( math_Rand( 0, .5 ) )
				pPart:SetStartAlpha( math_Rand( 190, 255 ) )
				pPart:SetEndAlpha( 0 )
				pPart:SetStartSize( math_Rand( 0, 16 ) )
				pPart:SetEndSize( math_Rand( 0, 16 ) )
				pPart:SetCollide( true )
				pPart:SetVelocity( v * math_Rand( 256, 512 ) )
				pPart:SetNextThink( CurTime() )
				pPart:SetThinkFunction( function( pPart )
					local vPos = pPart:GetPos()
					local vColor = render_GetLightColor( vPos )
					pPart:SetColor(
						Lerp( vColor[ 1 ] ^ .33, 0, 192 ),
						Lerp( vColor[ 2 ] ^ .33, 0, 192 ),
						Lerp( vColor[ 3 ] ^ .33, 0, 192 )
					)
					if bit_band( util_PointContents( vPos ), CONTENTS_WATER ) == 0 then
						pPart:SetGravity( vGravity )
					else pPart:SetGravity( vGravityWater ) end
					pPart:SetNextThink( CurTime() )
				end )
				pPart:SetRoll( math_Rand( 0, 360 ) )
				pPart:SetRollDelta( math_Rand( -30, 30 ) )
			end
		end

		local pHaze = pEmitter:Add( "ConcreteImpactHeatHaze", vPos )

		pHaze:SetDieTime( math_Rand( .8, 1.6 ) )

		pHaze:SetStartSize( math_Rand( 24, 32 ) )
		pHaze:SetEndSize( math_Rand( 12, 18 ) )

		pHaze:SetRoll( math_Rand( 0, 360 ) )
		pHaze:SetRollDelta( math_Rand( -4, 4 ) )

		pHaze:SetStartAlpha( 255 )
		pHaze:SetEndAlpha( 0 )

		pEmitter:Finish()
	end,

	[ util.GetSurfaceIndex "brick" ] = function( self, pData )
		local vPos = pData:GetOrigin()

		EmitSound( "BulletImpactConcrete", vPos, nil, nil, math_Rand( 1 / 3, 1 ) )

		local pLight = EphemeralLight()
		if pLight then
			pLight.brightness = math_Rand( 3, 5 )
			pLight.size = 96 * ( 1 - .5 * math_random() * math_random() )
			local f = math_Rand( 2 / 3, 1 + 1 / 3 )
			pLight.dietime = CurTime() + f
			pLight.decay = 1000 / f
			pLight.pos = vPos
			local v = LerpVector( math_random(), vWhite, vOrange )
			pLight.r = v[ 1 ]
			pLight.g = v[ 2 ]
			pLight.b = v[ 3 ]
		end

		local vDir = ( vPos - pData:GetStart() ):GetNormalized()

		local tr = util_TraceLine {
			start = vPos - vDir * 6,
			endpos = vPos + vDir * 6,
			mask = MASK_SOLID
		}

		local dNormal = tr.HitNormal

		local pEmitter = ParticleEmitter( vPos )

		local pImpact = pEmitter:Add( "sprites/light_glow02_add", vPos )
		pImpact:SetAngles( AngleRand() )
		pImpact:SetDieTime( math_Rand( .06, .12 ) )
		pImpact:SetStartAlpha( 255 )
		pImpact:SetEndAlpha( 0 )
		pImpact:SetStartSize( math_Rand( 24, 32 ) )
		pImpact:SetEndSize( math_Rand( 24, 32 ) )
		pImpact:SetRoll( math_Rand( 0, 360 ) )
		pImpact:SetRollDelta( math_Rand( -4, 4 ) )
		local v = LerpVector( math_random(), vWhite, vOrange )
		pImpact:SetColor( v[ 1 ], v[ 2 ], v[ 3 ] )

		for i = 1, math_random( 4, 6 ) do
			local pPart = pEmitter:Add( "effects/spark", vPos )
			if pPart then
				local v = LerpVector( .2, dNormal, VectorRand() )
				v:Normalize()
				pPart:SetAngles( v:Angle() )
				pPart:SetDieTime( math_Rand( 0, .8 ) )
				pPart:SetStartAlpha( 255 )
				pPart:SetEndAlpha( 0 )
				pPart:SetStartSize( math_Rand( 0, 3 ) )
				pPart:SetEndSize( math_Rand( 0, 3 ) )
				pPart:SetCollide( true )
				pPart:SetBounce( .9 )
				pPart:SetGravity( vGravity )
				pPart:SetVelocity( v * math_Rand( 256, 512 ) )
				pPart:SetRoll( math_Rand( 0, 360 ) )
				pPart:SetRollDelta( math_Rand( -4, 4 ) )
				local v = LerpVector( math_random(), vWhite, vOrange )
				pPart:SetColor( v[ 1 ], v[ 2 ], v[ 3 ] )
			end
		end

		for i = 1, math_random( 3, 6 ) do
			local pPart = pEmitter:Add( "particles/smokey", vPos )
			if pPart then
				local v = LerpVector( .2, dNormal, VectorRand() ):GetNormalized()
				pPart:SetBounce( math_Rand( 0, .25 ) )
				pPart:SetAngles( v:Angle() )
				pPart:SetDieTime( math_Rand( 0, .5 ) )
				pPart:SetStartAlpha( math_Rand( 190, 255 ) )
				pPart:SetEndAlpha( 0 )
				pPart:SetStartSize( math_Rand( 0, 16 ) )
				pPart:SetEndSize( math_Rand( 0, 16 ) )
				pPart:SetCollide( true )
				pPart:SetVelocity( v * math_Rand( 256, 512 ) )
				pPart:SetNextThink( CurTime() )
				pPart:SetThinkFunction( function( pPart )
					local vPos = pPart:GetPos()
					local vColor = render_GetLightColor( vPos )
					pPart:SetColor(
						Lerp( vColor[ 1 ] ^ .33, 0, 192 ),
						Lerp( vColor[ 2 ] ^ .33, 0, 192 ),
						Lerp( vColor[ 3 ] ^ .33, 0, 192 )
					)
					if bit_band( util_PointContents( vPos ), CONTENTS_WATER ) == 0 then
						pPart:SetGravity( vGravity )
					else pPart:SetGravity( vGravityWater ) end
					pPart:SetNextThink( CurTime() )
				end )
				pPart:SetRoll( math_Rand( 0, 360 ) )
				pPart:SetRollDelta( math_Rand( -30, 30 ) )
			end
		end

		local pHaze = pEmitter:Add( "ConcreteImpactHeatHaze", vPos )

		pHaze:SetDieTime( math_Rand( .8, 1.6 ) )

		pHaze:SetStartSize( math_Rand( 24, 32 ) )
		pHaze:SetEndSize( math_Rand( 12, 18 ) )

		pHaze:SetRoll( math_Rand( 0, 360 ) )
		pHaze:SetRollDelta( math_Rand( -4, 4 ) )

		pHaze:SetStartAlpha( 255 )
		pHaze:SetEndAlpha( 0 )

		pEmitter:Finish()
	end,

	[ util.GetSurfaceIndex "sand" ] = function( self, pData )
		local vPos = pData:GetOrigin()
		local vDir = ( vPos - pData:GetStart() ):GetNormalized()
		local tr = util_TraceLine {
			start = vPos - vDir * 6,
			endpos = vPos + vDir * 6,
			mask = MASK_SOLID
		}
		local dNormal = tr.HitNormal
		local pEmitter = ParticleEmitter( vPos )
		for i = 1, math_random( 2, 8 ) do
			local pPart = pEmitter:Add( "particles/smokey", vPos )
			if pPart then
				local v = LerpVector( .5, dNormal, VectorRand() ):GetNormalized()
				pPart:SetAngles( v:Angle() )
				pPart:SetDieTime( math_Rand( 0, cMaterialRemainsMaxLifeTime:GetFloat() ) )
				pPart:SetStartAlpha( math_Rand( 190, 255 ) )
				pPart:SetEndAlpha( 0 )
				pPart:SetStartSize( math_Rand( 0, 64 ) )
				pPart:SetEndSize( math_Rand( 0, 64 ) )
				pPart:SetCollide( true )
				pPart:SetVelocity( v * math_Rand( 128, 384 ) )
				pPart:SetNextThink( CurTime() )
				pPart:SetThinkFunction( function( pPart )
					local vPos = pPart:GetPos()
					local vColor = render_GetLightColor( vPos )
					pPart:SetColor(
						Lerp( vColor[ 1 ] ^ .33, 0, 230 ),
						Lerp( vColor[ 2 ] ^ .33, 0, 213 ),
						Lerp( vColor[ 3 ] ^ .33, 0, 186 )
					)
					if bit_band( util_PointContents( vPos ), CONTENTS_WATER ) == 0 then
						pPart:SetGravity( vGravity )
					else pPart:SetGravity( vGravityWater ) end
					pPart:SetNextThink( CurTime() )
				end )
				pPart:SetRoll( math_Rand( 0, 360 ) )
				pPart:SetRollDelta( math_Rand( -4, 4 ) )
			end
		end
		pEmitter:Finish()
	end,

	[ util.GetSurfaceIndex "grass" ] = function( self, pData )
		local vPos = pData:GetOrigin()
		local vDir = ( vPos - pData:GetStart() ):GetNormalized()
		local tr = util_TraceLine {
			start = vPos - vDir * 6,
			endpos = vPos + vDir * 6,
			mask = MASK_SOLID
		}
		local dNormal = tr.HitNormal
		local pEmitter = ParticleEmitter( vPos )
		for i = 1, math_random( 2, 8 ) do
			local pPart = pEmitter:Add( "particles/smokey", vPos )
			if pPart then
				local v = LerpVector( .2, dNormal, VectorRand() ):GetNormalized()
				pPart:SetAngles( v:Angle() )
				pPart:SetDieTime( math_Rand( 0, 1 ) )
				pPart:SetStartAlpha( math_Rand( 190, 255 ) )
				pPart:SetEndAlpha( 0 )
				pPart:SetStartSize( math_Rand( 0, 32 ) )
				pPart:SetEndSize( math_Rand( 0, 32 ) )
				pPart:SetCollide( true )
				pPart:SetVelocity( v * math_Rand( 256, 512 ) )
				pPart:SetNextThink( CurTime() )
				pPart:SetThinkFunction( function( pPart )
					local vPos = pPart:GetPos()
					local vColor = render_GetLightColor( vPos )
					pPart:SetColor(
						Lerp( vColor[ 1 ] ^ .33, 0, 143 ),
						Lerp( vColor[ 2 ] ^ .33, 0, 151 ),
						Lerp( vColor[ 3 ] ^ .33, 0, 121 )
					)
					if bit_band( util_PointContents( vPos ), CONTENTS_WATER ) == 0 then
						pPart:SetGravity( vGravity )
					else pPart:SetGravity( vGravityWater ) end
					pPart:SetNextThink( CurTime() )
				end )
				pPart:SetRoll( math_Rand( 0, 360 ) )
				pPart:SetRollDelta( math_Rand( -4, 4 ) )
			end
		end
		for i = 1, math_random( 2, 8 ) do
			local pPart = pEmitter:Add( "particles/smokey", vPos )
			if pPart then
				local v = LerpVector( .5, dNormal, VectorRand() ):GetNormalized()
				pPart:SetAngles( v:Angle() )
				pPart:SetDieTime( math_Rand( 0, cMaterialRemainsMaxLifeTime:GetFloat() ) )
				pPart:SetStartAlpha( math_Rand( 190, 255 ) )
				pPart:SetEndAlpha( 0 )
				pPart:SetStartSize( math_Rand( 0, 32 ) )
				pPart:SetEndSize( math_Rand( 0, 32 ) )
				pPart:SetCollide( true )
				pPart:SetVelocity( v * math_Rand( 128, 384 ) )
				pPart:SetNextThink( CurTime() )
				pPart:SetThinkFunction( function( pPart )
					local vPos = pPart:GetPos()
					local vColor = render_GetLightColor( vPos )
					pPart:SetColor(
						Lerp( vColor[ 1 ] ^ .33, 0, 125 ),
						Lerp( vColor[ 2 ] ^ .33, 0, 80 ),
						Lerp( vColor[ 3 ] ^ .33, 0, 25 )
					)
					if bit_band( util_PointContents( vPos ), CONTENTS_WATER ) == 0 then
						pPart:SetGravity( vGravity )
					else pPart:SetGravity( vGravityWater ) end
					pPart:SetNextThink( CurTime() )
				end )
				pPart:SetRoll( math_Rand( 0, 360 ) )
				pPart:SetRollDelta( math_Rand( -4, 4 ) )
			end
		end
		pEmitter:Finish()
	end,

	[ util.GetSurfaceIndex "plaster" ] = function( self, pData )
		local vPos = pData:GetOrigin()
		EmitSound( "BulletImpactPlaster", vPos, nil, nil, math_Rand( 1 / 3, 1 ) )
		local vDir = ( vPos - pData:GetStart() ):GetNormalized()
		local tr = util_TraceLine {
			start = vPos - vDir * 6,
			endpos = vPos + vDir * 6,
			mask = MASK_SOLID
		}
		local dNormal = tr.HitNormal
		local pEmitter = ParticleEmitter( vPos )
		for i = 1, math_random( 1, 4 ) do
			local pPart = pEmitter:Add( "particles/smokey", vPos )
			if pPart then
				local v = LerpVector( .5, dNormal, VectorRand() ):GetNormalized()
				pPart:SetAngles( v:Angle() )
				pPart:SetDieTime( math_Rand( 0, cMaterialRemainsMaxLifeTime:GetFloat() ) )
				pPart:SetStartAlpha( math_Rand( 190, 255 ) )
				pPart:SetEndAlpha( 0 )
				pPart:SetStartSize( math_Rand( 0, 32 ) )
				pPart:SetEndSize( math_Rand( 0, 32 ) )
				pPart:SetCollide( true )
				pPart:SetVelocity( v * math_Rand( 128, 384 ) )
				pPart:SetNextThink( CurTime() )
				pPart:SetThinkFunction( function( pPart )
					local vPos = pPart:GetPos()
					local vColor = render_GetLightColor( vPos )
					pPart:SetColor(
						Lerp( vColor[ 1 ] ^ .33, 0, 166 ),
						Lerp( vColor[ 2 ] ^ .33, 0, 150 ),
						Lerp( vColor[ 3 ] ^ .33, 0, 130 )
					)
					if bit_band( util_PointContents( vPos ), CONTENTS_WATER ) == 0 then
						pPart:SetGravity( vGravity )
					else pPart:SetGravity( vGravityWater ) end
					pPart:SetNextThink( CurTime() )
				end )
				pPart:SetRoll( math_Rand( 0, 360 ) )
				pPart:SetRollDelta( math_Rand( -4, 4 ) )
			end
		end
		pEmitter:Finish()
	end
}

function EFFECT:Init( pData )
	//	print( util.GetSurfacePropName( pData:GetSurfaceProp() ) )
	local f = EFFECTS[ pData:GetSurfaceProp() ]
	if f then f( self, pData ) end
end

function EFFECT:Think() return false end

function EFFECT:Render() end
