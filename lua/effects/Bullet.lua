VELOCITY = 3072

local VECTOR_ADD_SUB = Vector( 12, 12, 12 )

function EFFECT:Init( pData )
	local vEnd = pData:GetOrigin()
	local v = pData:GetStart()
	local pWeapon = pData:GetEntity()
	if IsValid( pWeapon ) then
		local vRenderOrigin = pWeapon:GetRenderOrigin()
		if vRenderOrigin then v = vRenderOrigin + ( vEnd - vRenderOrigin ):GetNormalized() * 32 else
			local pOwner = pWeapon:GetOwner()
			if IsValid( pOwner ) then v = self:GetTracerShootPos( pData:GetOrigin(), pWeapon, pData:GetAttachment() ) end
		end
	end
	self.vStart = v
	self.vEnd = vEnd
	local dDirection = vEnd - v
	local flDistance = dDirection:Length()
	self.flDistance = flDistance
	dDirection:Normalize()
	self.dDirection = dDirection
	local flLifeTime = flDistance / VELOCITY
	self.flLifeTime = flLifeTime
	self.flDieTime = CurTime() + flLifeTime
	self.vPos = v
	self:SetRenderBoundsWS( v, vEnd, VECTOR_ADD_SUB )
end

function EFFECT:Think()
	local flLifeTime = self.flLifeTime
	self.vPos = self.vStart + ( self.dDirection * ( self.flDistance * ( flLifeTime - ( self.flDieTime - CurTime() ) ) / flLifeTime ) )
	return CurTime() < self.flDieTime
end

local mMaterial = Material "effects/ar2_altfire1b"
local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite
local DynamicLight = DynamicLight
local COLOR = Color( 255, 64, 0 )
function EFFECT:Render()
	local vPos = self.vPos
	local dDirection = self.dDirection
	render_SetMaterial( mMaterial )
	local l = VELOCITY * .05
	for i = 0, l do
		local f = i / l
		render_DrawSprite( vPos - dDirection * l * ( i * -.002 ), 4 * f, 4 * f, COLOR )
	end
	// Tracer lights are messy as shit. Even though we don't have to worry
	// about overriding ephemeral lights, we still override whatever is
	// at the owner's entity index, including other tracers, and this system
	// is so complicated even for me to write, that I'd rather simply NOT.
	//	local pLight = DynamicLight( self:EntIndex() )
	//	if pLight then
	//		pLight.pos = self.vPos
	//		pLight.r = 255
	//		pLight.g = 255
	//		pLight.b = 255
	//		pLight.brightness = 4
	//		pLight.decay = 1000
	//		pLight.size = 96
	//		pLight.dietime = CurTime() + 1
	//	end
end
