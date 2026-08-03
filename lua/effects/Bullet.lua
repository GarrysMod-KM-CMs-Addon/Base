local VELOCITY = 6144

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local CurTime = CurTime

local LocalPlayer = LocalPlayer

local vTemp = Vector()
local vTemp2 = Vector()

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

function EFFECT:Think()
	local MyTable = CEntity_GetTable( self )

	local flLifeTime = MyTable.flLifeTime
	vTemp:Set( MyTable.vStart )

	vTemp2:Set( MyTable.dDirection )
	vTemp2:Mul( MyTable.flDistance * ( flLifeTime - ( MyTable.flDieTime - CurTime() ) ) / flLifeTime )

	vTemp:Add( vTemp2 )

	self:SetPos( vTemp )

	return CurTime() <= CEntity_GetTable( self ).flDieTime
end

local mMaterial = Material "effects/ar2_altfire1b"
local COLOR = Color( 255, 128, 64 )

local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite

local DynamicLight = DynamicLight

function EFFECT:Render()
	local MyTable = CEntity_GetTable( self )

	if MyTable.m_bFirstPersonTracer then return end

	local flLifeTime = MyTable.flLifeTime
	vTemp:Set( MyTable.vStart )

	vTemp2:Set( MyTable.dDirection )
	vTemp2:Mul( MyTable.flDistance * ( flLifeTime - ( MyTable.flDieTime - CurTime() ) ) / flLifeTime )

	vTemp:Add( vTemp2 )

	self:SetPos( vTemp )

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
