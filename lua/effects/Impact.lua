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
	"16",
	true,
	nil, 
	"How long can blown off material parts be on the ground?",
	8, 32
)

local EFFECTS = {
	[ util.GetSurfaceIndex "metal" ] = function( self, pData )
		local vPos = pData:GetOrigin()
		local pLight = EphemeralLight()
		if pLight then
			pLight.brightness = math_Rand( 6, 8 )
			pLight.size = math_Rand( 32, 128 )
			local f = math_Rand( .66, 1.33 )
			pLight.dietime = CurTime() + f
			pLight.decay = 1000 / f
			pLight.pos = vPos
			pLight.r = 255
			pLight.g = 255
			pLight.b = 255
		end
		local vDir = ( vPos - pData:GetStart() ):GetNormalized()
		local tr = util_TraceLine {
			start = vPos - vDir * 6,
			endpos = vPos + vDir * 6,
			mask = MASK_SOLID
		}
		local dNormal = tr.HitNormal
		local pEmitter = ParticleEmitter( vPos )
		for i = 1, math_random( 8, 24 ) do
			local pPart = pEmitter:Add( "effects/spark", vPos )
			if pPart then
				local v = LerpVector( .2, dNormal, VectorRand() ):GetNormalized()
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
			end
		end
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
