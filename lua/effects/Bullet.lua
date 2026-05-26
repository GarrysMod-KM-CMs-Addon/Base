local VELOCITY = 3072

function EFFECT:Init( pData )
	local vEnd = pData:GetOrigin()
	local v = pData:GetStart()
	local pWeapon = pData:GetEntity()
	if IsValid( pWeapon ) then
		local vRenderOrigin = pWeapon:GetRenderOrigin()
		if vRenderOrigin then v = vRenderOrigin + ( vEnd - vRenderOrigin ):GetNormalized() * 32 else
			local pOwner = pWeapon:GetOwner()
			if IsValid( pOwner ) then
				local vNew = self:GetTracerShootPos( pData:GetOrigin(), pWeapon, pData:GetAttachment() )
				if vNew:DistToSqr( v ) <= 1048576/*1024*/ then
					v = vNew
				end
			end
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
end

function EFFECT:Think()
	local flLifeTime = self.flLifeTime
	self:SetPos( self.vStart + ( self.dDirection * ( self.flDistance * ( flLifeTime - ( self.flDieTime - CurTime() ) ) / flLifeTime ) ) )
	return CurTime() < self.flDieTime
end

local mMaterial = Material "effects/ar2_altfire1b"
local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite
local DynamicLight = DynamicLight
local COLOR = Color( 255, 128, 64 )
function EFFECT:Render()
	local vPos = self:GetPos()
	local dDirection = self.dDirection
	render_SetMaterial( mMaterial )
	local l = 20
	for i = 0, l do
		local f = i / l
		render_DrawSprite( vPos - dDirection * l * ( i * -.02 ), 12 * f, 12 * f, COLOR )
	end
	// Tracer lights are messy as shit. Even though we don't have to worry
	// about overriding ephemeral lights, we still override whatever is
	// at the owner's entity index, including other tracers, and this system
	// is so complicated even for me to write, that I'd rather simply NOT.
	//	local pLight = DynamicLight( self:EntIndex() )
	//	if pLight then
	//		pLight.pos = self:GetPos()
	//		pLight.r = 255
	//		pLight.g = 255
	//		pLight.b = 255
	//		pLight.brightness = 4
	//		pLight.decay = 1000
	//		pLight.size = 96
	//		pLight.dietime = CurTime() + 1
	//	end
end
