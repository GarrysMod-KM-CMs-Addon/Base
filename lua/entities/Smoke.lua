AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

scripted_ents.Register( ENT, "Smoke" )

function ENT:UpdateTransmitState() return TRANSMIT_PVS end

if SERVER then
	function ENT:KeyValue( k, v ) self:SetNetworkKeyValue( k, v ) end
	function ENT:SetupDataTables()
		self:NetworkVar( "Float", "Radius", { KeyName = "flRadius" } )
		// < -273.15 = normal smoke, otherwise shows up on thermal imaging with this temperature
		// DON'T FORGET TO SET THIS TO SOMETHING LOWER THAN -273.15 FOR NORMAL SMOKES!!!
		self:NetworkVar( "Int", "Smoke", { KeyName = "iSmoke" } )
	end
	return
end

local Vector = Vector
function ENT:ReconsiderRenderBounds()
	local f = self:GetRadius()
	self:SetRenderBounds( Vector( -f, -f, -f ), Vector( f, f, f ) )
end

function ENT:SetupDataTables()
	self:NetworkVar( "Float", "Radius", { KeyName = "flRadius" } )
	self:NetworkVar( "Int", "Smoke", { KeyName = "iSmoke" } )
	self:NetworkVarNotify( "Radius", self.ReconsiderRenderBounds )
end

function ENT:Initialize()
	self:ReconsiderRenderBounds()
	self:DrawShadow( false )
end

ENT.flNextSurroundParticles = 0
ENT.flNextDrawParticles = 0
local EyePos = EyePos
local math_Rand = math.Rand
function ENT:Draw()
	if VISION_INFRARED then
		if self:GetSmoke() < -273.15 then return end
		local vPos, vEye = self:GetPos(), EyePos()
		local flRadius = self:GetRadius()
		if vPos:DistToSqr( vEye ) <= ( flRadius * flRadius ) then
			if CurTime() > self.flNextSurroundParticles then
				local pPlayer = LocalPlayer()
				local pEmitter = ParticleEmitter( vEye )
				local flTime = math.Clamp( 1 / pPlayer:GetVelocity():Length() * 200, .1, 2 ) * math_Rand( .75, 1.25 )
				local flPitchOffset, flYawOffset = math_Rand( 0, 360 ), math_Rand( 0, 360 )
				local flBoundingRadius = pPlayer:BoundingRadius()
				local flOffset = flBoundingRadius * 10
				local flSize = flBoundingRadius * 15
				local flDieTime = flTime * 4
				local cColor = VISION_INFRARED( self:GetSmoke() )
				local R, G, B = cColor.r, cColor.g, cColor.b
				for flYaw = 0, 360, math_Rand( 45, 90 ) do
					for flPitch = 0, 360, math_Rand( 45, 90 ) do
						local flSizeScale = math_Rand( 1, 2 )
						local v = vEye + Angle( flPitchOffset + flPitch, flYawOffset + flYaw ):Forward() * flOffset * flSizeScale
						local pPart = pEmitter:Add( "effects/thick_smoke", v )
						if pPart then
							pPart:SetDieTime( flDieTime )
							pPart:SetStartAlpha( 255 )
							pPart:SetEndAlpha( 0 )
							pPart:SetStartSize( 0 )
							pPart:SetEndSize( flSize * flSizeScale )
							pPart:SetVelocity( ( vEye - v ) / flDieTime / flSizeScale * .05 )
							pPart:SetRoll( math_Rand( 0, 360 ) )
							pPart:SetRollDelta( math_Rand( .165, .33 ) )
							pPart:SetColor( R, G, B )
						end
					end
				end
				pEmitter:Finish()
				self.flNextSurroundParticles = CurTime() + flTime
			end
		elseif CurTime() > self.flNextDrawParticles then
			local pPlayer = LocalPlayer()
			local pEmitter = ParticleEmitter( vEye )
			local flTime = math.Clamp( 1 / self:GetVelocity():Length() * 200, .1, 2 ) * math_Rand( .75, 1.25 )
			local flPitchOffset, flYawOffset = math_Rand( 0, 360 ), math_Rand( 0, 360 )
			local flBoundingRadius = pPlayer:BoundingRadius()
			local flDieTime = flTime * 6
			local cColor = VISION_INFRARED( self:GetSmoke() )
			local R, G, B = cColor.r, cColor.g, cColor.b
			for flYaw = 0, 360, math_Rand( 40, 60 ) do
				for flPitch = 0, 360, math_Rand( 40, 60 ) do
					local flSizeScale = math_Rand( .05, .2 )
					local d = Angle( flPitchOffset + flPitch, flYawOffset + flYaw ):Forward()
					local v = vPos + d * flRadius * flSizeScale * .33
					local pPart = pEmitter:Add( "effects/thick_smoke", v )
					if pPart then
						pPart:SetDieTime( flDieTime )
						pPart:SetStartAlpha( 255 )
						pPart:SetEndAlpha( 0 )
						pPart:SetStartSize( 0 )
						pPart:SetEndSize( flRadius * ( 1 - flSizeScale ) * .4 )
						pPart:SetVelocity( d * flRadius / flSizeScale / flDieTime * .1 )
						pPart:SetRoll( math_Rand( 0, 360 ) )
						pPart:SetRollDelta( math_Rand( .165, .33 ) )
						pPart:SetColor( R, G, B )
					end
				end
			end
			pEmitter:Finish()
			self.flNextDrawParticles = CurTime() + flTime
		end
		return
	end
	local vPos, vEye = self:GetPos(), EyePos()
	local flRadius = self:GetRadius()
	if vPos:DistToSqr( vEye ) <= ( flRadius * flRadius ) then
		if CurTime() > self.flNextSurroundParticles then
			local pPlayer = LocalPlayer()
			local pEmitter = ParticleEmitter( vEye )
			local flTime = math.Clamp( 1 / pPlayer:GetVelocity():Length() * 200, .1, 2 ) * math_Rand( .75, 1.25 )
			local flPitchOffset, flYawOffset = math_Rand( 0, 360 ), math_Rand( 0, 360 )
			local flBoundingRadius = pPlayer:BoundingRadius()
			local flOffset = flBoundingRadius * 10
			local flSize = flBoundingRadius * 15
			local flDieTime = flTime * 4
			local cColor = self:GetColor()
			local R, G, B = cColor.r, cColor.g, cColor.b
			for flYaw = 0, 360, math_Rand( 45, 90 ) do
				for flPitch = 0, 360, math_Rand( 45, 90 ) do
					local flSizeScale = math_Rand( 1, 2 )
					local v = vEye + Angle( flPitchOffset + flPitch, flYawOffset + flYaw ):Forward() * flOffset * flSizeScale
					local pPart = pEmitter:Add( "effects/thick_smoke", v )
					if pPart then
						pPart:SetDieTime( flDieTime )
						pPart:SetStartAlpha( 255 )
						pPart:SetEndAlpha( 0 )
						pPart:SetStartSize( 0 )
						pPart:SetEndSize( flSize * flSizeScale )
						pPart:SetLighting( true )
						pPart:SetVelocity( ( vEye - v ) / flDieTime / flSizeScale * .05 )
						pPart:SetRoll( math_Rand( 0, 360 ) )
						pPart:SetRollDelta( math_Rand( .165, .33 ) )
						pPart:SetColor( R, G, B )
					end
				end
			end
			pEmitter:Finish()
			self.flNextSurroundParticles = CurTime() + flTime
		end
	elseif CurTime() > self.flNextDrawParticles then
		local pPlayer = LocalPlayer()
		local pEmitter = ParticleEmitter( vEye )
		local flTime = math.Clamp( 1 / self:GetVelocity():Length() * 200, .1, 2 ) * math_Rand( .75, 1.25 )
		local flPitchOffset, flYawOffset = math_Rand( 0, 360 ), math_Rand( 0, 360 )
		local flBoundingRadius = pPlayer:BoundingRadius()
		local flDieTime = flTime * 6
		local cColor = self:GetColor()
		local R, G, B = cColor.r, cColor.g, cColor.b
		for flYaw = 0, 360, math_Rand( 40, 60 ) do
			for flPitch = 0, 360, math_Rand( 40, 60 ) do
				local flSizeScale = math_Rand( .05, .2 )
				local d = Angle( flPitchOffset + flPitch, flYawOffset + flYaw ):Forward()
				local v = vPos + d * flRadius * flSizeScale * .33
				local pPart = pEmitter:Add( "effects/thick_smoke", v )
				if pPart then
					pPart:SetDieTime( flDieTime )
					pPart:SetStartAlpha( 255 )
					pPart:SetEndAlpha( 0 )
					pPart:SetStartSize( 0 )
					pPart:SetEndSize( flRadius * ( 1 - flSizeScale ) * .4 )
					pPart:SetLighting( true )
					pPart:SetVelocity( d * flRadius / flSizeScale / flDieTime * .1 )
					pPart:SetRoll( math_Rand( 0, 360 ) )
					pPart:SetRollDelta( math_Rand( .165, .33 ) )
					pPart:SetColor( R, G, B )
				end
			end
		end
		pEmitter:Finish()
		self.flNextDrawParticles = CurTime() + flTime
	end
end
