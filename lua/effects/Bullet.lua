local VELOCITY = 8192

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_SetPos = CEntity.SetPos

local CVector = FindMetaTable "Vector"
local CVector_Set = CVector.Set
local CVector_Mul = CVector.Mul
local CVector_Sub = CVector.Sub
local CVector_Add = CVector.Add
local CVector_Normalize = CVector.Normalize
local CVector_Dot = CVector.Dot

local CurTime = CurTime

local LocalPlayer = LocalPlayer

local vTemp = Vector()

local EyePos = EyePos
local CreateSound = CreateSound

local Approach = math.Approach

local IsValid = IsValid

sound.Add {
	name = "BulletWhizLoop",
	sound = ")ambient/gas/cannister_loop.wav",
	level = 500,
	channel = CHAN_BODY
}

EFFECT.m_flSound = 0
EFFECT.m_flLastTrueVolume = 0
EFFECT.m_flLastTruePitch = 0

function EFFECT:Init( pData )
	local pWeapon = pData:GetEntity()

	local MyTable = CEntity_GetTable( self )

	if !IsValid( pWeapon ) then MyTable.m_bFirstPersonTracer = true return end

	local pOwner = pWeapon:GetOwner()

	if !IsValid( pOwner ) then
		pOwner = pWeapon
		if !IsValid( pOwner ) then MyTable.m_bFirstPersonTracer = true return end
	end

	if pOwner == LocalPlayer() then
		MyTable.m_bNoSound = true

		if !pOwner:ShouldDrawLocalPlayer() then
			MyTable.m_bFirstPersonTracer = true
			return
		end
	end

	local vEnd = pData:GetOrigin()
	local v = pData:GetStart()
	if IsValid( pWeapon ) then
		local fOverrideTracerOrigin = CEntity_GetTable( pWeapon ).OverrideTracerOrigin
		if fOverrideTracerOrigin then
			v = fOverrideTracerOrigin( pWeapon, "Bullet" )
		else
			local vRenderOrigin = pWeapon:GetRenderOrigin()
			if vRenderOrigin then v = vRenderOrigin + ( vEnd - vRenderOrigin ):GetNormalized() * 32 else
				if IsValid( pOwner ) then
					local vNew = self:GetTracerShootPos( pData:GetOrigin(), pWeapon, pData:GetAttachment() )
					if vNew:DistToSqr( v ) <= 1048576/*1024*/ then
						v = vNew
					end
				end
			end
		end
	end

	MyTable.m_pOwner = pOwner

	MyTable.m_vStart = v
	MyTable.m_vEnd = vEnd

	local dDirection = vEnd - v
	local flDistance = dDirection:Length()

	MyTable.m_flDistance = flDistance

	dDirection:Normalize()

	MyTable.m_dDirection = dDirection

	local flLifeTime = flDistance / VELOCITY
	MyTable.m_flLifeTime = flLifeTime

	MyTable.m_flDieTime = CurTime() + flLifeTime

	MyTable.m_vLocation = Vector()
end

local BULLET_WHIZ_DISTANCE = 4096

local util_TraceLine = util.TraceLine

local sqrt = math.sqrt

local FrameTime = FrameTime

local function GetTheSoundOut( MyTable )
	local flSound = MyTable.m_flSound

	MyTable.m_flSound = Approach( flSound, 0, FrameTime() )

	local pWhiz = MyTable.m_pWhiz
	if !pWhiz then return true end

	if flSound <= 0 then
		pWhiz:Stop()
		MyTable.m_pWhiz = nil
		return true
	end

	pWhiz:ChangeVolume( MyTable.m_flLastTrueVolume * flSound )
	pWhiz:ChangePitch( MyTable.m_flLastTruePitch * flSound )
end

local trFilter = {}

local trData = {
	filter = trFilter,
	mask = MASK_VISIBLE_AND_NPCS
}

local function Update( self, MyTable, bDontUpdateSound )
	if CurTime() > MyTable.m_flDieTime then return end

	local flLifeTime = MyTable.m_flLifeTime

	local vLocation = MyTable.m_vLocation

	CVector_Set( vLocation, MyTable.m_vStart )

	CVector_Set( vTemp, MyTable.m_dDirection )
	CVector_Mul( vTemp, MyTable.m_flDistance * ( flLifeTime - ( MyTable.m_flDieTime - CurTime() ) ) / flLifeTime )

	CVector_Add( vLocation, vTemp )

	CEntity_SetPos( self, vLocation )

	if MyTable.m_bNoSound || bDontUpdateSound then return end

	local vEyePos = EyePos()
	local flDistSqr = vEyePos:DistToSqr( vLocation )
	if flDistSqr > BULLET_WHIZ_DISTANCE * BULLET_WHIZ_DISTANCE then
		GetTheSoundOut( MyTable )
		return
	end

	local ply = LocalPlayer()

	trFilter[ 1 ] = nil
	trFilter[ 2 ] = nil
	trFilter[ 3 ] = nil

	local pOwner = MyTable.m_pOwner

	if IsValid( pOwner ) && pOwner != ply then
		trFilter[ 1 ] = ply
		trFilter[ 2 ] = pOwner

		local pViewEntity = ply:GetViewEntity()
		if IsValid( pViewEntity ) then trFilter[ 3 ] = pViewEntity end
	else
		trFilter[ 1 ] = ply

		local pViewEntity = ply:GetViewEntity()
		if IsValid( pViewEntity ) then trFilter[ 2 ] = pViewEntity end
	end

	trData.startpos = vEyePos
	trData.endpos = vLocation

	if util_TraceLine( trData ).Hit then
		GetTheSoundOut( MyTable )
		return
	end

	local pWhiz = MyTable.m_pWhiz
	if !pWhiz then
		pWhiz = CreateSound( self, "BulletWhizLoop" )
		pWhiz:PlayEx( 0, 0 )
		MyTable.m_pWhiz = pWhiz
	end

	CVector_Set( vTemp, vEyePos )
	CVector_Sub( vTemp, vLocation )
	CVector_Normalize( vTemp )

	local flDot = CVector_Dot( MyTable.m_dDirection, vTemp )

	local flVolume = 1 - sqrt( flDistSqr ) / BULLET_WHIZ_DISTANCE
	MyTable.m_flLastTrueVolume = flVolume

	local flPitch = 150 + flDot * 50
	MyTable.m_flLastTruePitch = flPitch

	local flSound = MyTable.m_flSound
	MyTable.m_flSound = Approach( flSound, 1, 15 * FrameTime() )

	pWhiz:ChangeVolume( flVolume * flSound )
	pWhiz:ChangePitch( flPitch * flSound )
end

function EFFECT:Think()
	local MyTable = CEntity_GetTable( self )

	if MyTable.m_bFirstPersonTracer then
		local pWhiz = MyTable.m_pWhiz
		if pWhiz then pWhiz:Stop() MyTable.m_pWhiz = nil end
		return false
	end

	Update( self, MyTable )

	if CurTime() > MyTable.m_flDieTime then return !GetTheSoundOut( MyTable ) end
	return true
end

local mMaterial = Material "effects/ar2_altfire1b"
local COLOR = Color( 255, 128, 64 )

local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite

local DynamicLight = DynamicLight

function EFFECT:Render()
	local MyTable = CEntity_GetTable( self )

	if MyTable.m_bFirstPersonTracer then
		local pWhiz = MyTable.m_pWhiz
		if pWhiz then pWhiz:Stop() MyTable.m_pWhiz = nil end
		return
	end

	if CurTime() > MyTable.m_flDieTime then return end

	Update( self, MyTable, true )

	local vPos = MyTable.m_vLocation
	local dDirection = MyTable.m_dDirection

	render_SetMaterial( mMaterial )

	for i = 0, 1, 1 / 20 do
		CVector_Set( vTemp, dDirection )
		CVector_Mul( vTemp, i * -15 )
		CVector_Add( vTemp, vPos )
	
		render_DrawSprite( vTemp, 8, 8, COLOR )
	end

	// Tracer lights are messy as shit. Even though we don't have to worry
	// about overriding ephemeral lights, we still override whatever is
	// at the owner's entity index, including other tracers, and this system
	// is so complicated even for me to write, that I'd rather simply NOT.
	//	local pLight = DynamicLight( self:EntIndex() )
	//	if pLight then
	//		pLight.pos = vPos
	//		pLight.r = 255
	//		pLight.g = 255
	//		pLight.b = 255
	//		pLight.brightness = 4
	//		pLight.decay = 1000
	//		pLight.size = 96
	//		pLight.dietime = CurTime() + 1
	//	end
end
