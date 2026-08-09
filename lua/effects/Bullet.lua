local VELOCITY = 6144

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local CurTime = CurTime

local LocalPlayer = LocalPlayer

local vTemp = Vector()
local vTemp2 = Vector()

local EyePos = EyePos
local CreateSound = CreateSound

sound.Add {
	name = "BulletWhizLoop",
	sound = ")ambient/gas/cannister_loop.wav",
	level = 500,
	channel = CHAN_BODY
}

function EFFECT:Init( pData )
	local pWeapon = pData:GetEntity()
	local pOwner = pWeapon:GetOwner()
	local MyTable = CEntity_GetTable( self )
	if pOwner == LocalPlayer() && !pOwner:ShouldDrawLocalPlayer() then MyTable.m_bFirstPersonTracer = true end
	local vEnd = pData:GetOrigin()
	local v = pData:GetStart()
	if IsValid( pWeapon ) then
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

	MyTable.m_pOwner = pOwner

	MyTable.vStart = v
	MyTable.vEnd = vEnd

	local dDirection = vEnd - v
	local flDistance = dDirection:Length()

	MyTable.flDistance = flDistance

	dDirection:Normalize()

	MyTable.dDirection = dDirection

	local flLifeTime = flDistance / VELOCITY
	MyTable.flLifeTime = flLifeTime

	MyTable.flDieTime = CurTime() + flLifeTime
end

local BULLET_WHIZ_DISTANCE_VISIBLE = 4096
local BULLET_WHIZ_DISTANCE_OBSCURED = 512

local util_TraceLine = util.TraceLine

local sqrt = math.sqrt

local function Update( self, MyTable, bDontUpdateSound )
	local flLifeTime = MyTable.flLifeTime
	vTemp:Set( MyTable.vStart )

	vTemp2:Set( MyTable.dDirection )
	vTemp2:Mul( MyTable.flDistance * ( flLifeTime - ( MyTable.flDieTime - CurTime() ) ) / flLifeTime )

	vTemp:Add( vTemp2 )

	self:SetPos( vTemp )

	if bDontUpdateSound then return end

	local vEyePos = EyePos()
	local flDistSqr = vEyePos:DistToSqr( vTemp )
	if flDistSqr > BULLET_WHIZ_DISTANCE_VISIBLE * BULLET_WHIZ_DISTANCE_VISIBLE then
		local pWhiz = MyTable.m_pWhiz
		if pWhiz then pWhiz:Stop() MyTable.m_pWhiz = nil end
		return
	end

	local pOwner = MyTable.m_pOwner

	local ply = LocalPlayer()

	local bUseShort
	local tFilter = ( IsValid( pOwner ) && pOwner != ply ) && { ply, pOwner } || { ply }
	local pViewEntity = ply:GetViewEntity()
	if IsValid( pViewEntity ) then table.insert( tFilter, pViewEntity ) end

	if util_TraceLine( {
		start = vEyePos,
		endpos = vTemp,
		filter = tFilter,
		mask = MASK_VISIBLE_AND_NPCS
	} ).Hit then
		if flDistSqr > BULLET_WHIZ_DISTANCE_OBSCURED * BULLET_WHIZ_DISTANCE_OBSCURED then
			local pWhiz = MyTable.m_pWhiz
			if pWhiz then pWhiz:Stop() MyTable.m_pWhiz = nil end
			return
		end
		bUseShort = true
	end

	local pWhiz = MyTable.m_pWhiz
	if !pWhiz then
		pWhiz = CreateSound( self, "BulletWhizLoop" )
		pWhiz:PlayEx( 0, 0 )
		MyTable.m_pWhiz = pWhiz
	end

	local flDot = MyTable.dDirection:Dot( ( vEyePos - vTemp ):GetNormalized() )

	pWhiz:ChangeVolume( 1 - sqrt( flDistSqr ) / ( bUseShort && BULLET_WHIZ_DISTANCE_OBSCURED || BULLET_WHIZ_DISTANCE_VISIBLE ) )
	pWhiz:ChangePitch( 150 + flDot * 50 )
end

function EFFECT:Think()
	local MyTable = CEntity_GetTable( self )

	if MyTable.m_bFirstPersonTracer then
		local pWhiz = MyTable.m_pWhiz
		if pWhiz then pWhiz:Stop() MyTable.m_pWhiz = nil end
		return false
	end

	Update( self, MyTable )

	if CurTime() > CEntity_GetTable( self ).flDieTime then
		local pWhiz = MyTable.m_pWhiz
		if pWhiz then pWhiz:Stop() MyTable.m_pWhiz = nil end
		return false
	end
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

	Update( self, MyTable, true )

	local vPos = self:GetPos()
	local dDirection = MyTable.dDirection

	render_SetMaterial( mMaterial )

	for i = 0, 40 do
		vTemp:Set( vPos )
		vTemp2:Set( dDirection )
		vTemp2:Mul( -i )
		vTemp:Sub( vTemp2 )

		render_DrawSprite( vTemp, 12, 12, COLOR )
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
