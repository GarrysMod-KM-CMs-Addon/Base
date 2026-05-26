local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA
local ParticleEmitter = ParticleEmitter
local math_max = math.max
local math_Rand = math.Rand
local math_random = math.random

function EFFECT:Init( pData )
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	local v = pData:GetStart()
	local pWeapon, pOwner = pData:GetEntity()
	if IsValid( pWeapon ) then
		local vRenderOrigin = pWeapon:GetRenderOrigin()
		if vRenderOrigin then v = vRenderOrigin else
			pOwner = pWeapon:GetOwner()
			if IsValid( pOwner ) then v = self:GetTracerShootPos( pData:GetOrigin(), pWeapon, pData:GetAttachment() ) end
		end
	end
	self.m_pWeapon = pWeapon
	//	self.m_bMuzzleID = pData:GetFlags() == 1
	local vVelocity = IsValid( pOwner ) && pOwner:GetVelocity() || vector_origin
	local pEmitter = ParticleEmitter( v )
	local flLifeTime = 1 / pData:GetMagnitude()
	local f = 1 - .9 * math_random() * math_random()
	for i = 1, 8 do
		local l = v + VectorRand():GetNormalized() * math_Rand( 0, 4 ) * f
		local pPart = pEmitter:Add( "effects/muzzleflash" .. math_random( 1, 4 ), v )
		pPart:SetVelocity( vVelocity )
		pPart:SetPos( l )
		pPart:SetDieTime( flLifeTime )
		pPart:SetStartAlpha( 255 )
		pPart:SetEndAlpha( 255 )
		pPart:SetStartSize( 8 * f )
		pPart:SetEndSize( 8 * f )
		pPart:SetRoll( math_Rand( 180, 480 ) )
		pPart:SetRollDelta( math_Rand( -1, 1 ) )
		pPart:SetColor( 255, 255, 255 )
		pPart:SetAirResistance( 140 )
		local pPart = pEmitter:Add( "effects/muzzleflash" .. math_random( 1, 4 ), v )
		pPart:SetVelocity( vVelocity )
		pPart:SetPos( l )
		pPart:SetDieTime( flLifeTime )
		pPart:SetStartAlpha( 255 )
		pPart:SetEndAlpha( 255 )
		pPart:SetStartSize( 12 * f )
		pPart:SetEndSize( 12 * f )
		pPart:SetRoll( math_Rand( 180, 480 ) )
		pPart:SetRollDelta( math_Rand( -1, 1 ) )
		pPart:SetColor( 255, 255, 255 )
		pPart:SetAirResistance( 140 )
	end
	// Legacy smoke from when this inherited Buu's Weapon Base II muzzleflashes
	// Smoke is not needed here, but I'll leave this here for memory
	//	for i = 1, 3 do 
	//		local pPart = pEmitter:Add( "particle/particle_smokegrenade", v )
	//		// This is square shaped, and we don't like them squares 'round these parts
	//		//	pPart:SetVelocity( vVelocity + Vector( math_Rand( -20, 20 ), math_Rand( -20, 20 ), math_Rand( -20, 20 ) ) )
	//		pPart:SetVelocity( vVelocity + VectorRand():GetNormalized() * math_Rand( 0, 20 ) )
	//		pPart:SetDieTime( math_Rand( .5, 1 ) )
	//		pPart:SetStartAlpha( math_Rand( 50, 155 ) )
	//		pPart:SetStartSize( math_Rand( .5, 1 ) * i )
	//		pPart:SetEndSize( math_Rand( 2, 4 ) * i )
	//		pPart:SetRoll( math_Rand( 180, 480 ) )
	//		pPart:SetRollDelta( math_Rand( -1, 1 ) )
	//		pPart:SetColor( 200, 200, 200 )
	//		pPart:SetAirResistance( 140 )
	//	end
	//	self.m_pEmitter = pEmitter
	pEmitter:Finish()
end

function EFFECT:Render() end
function EFFECT:Think() return false end

//	function EFFECT:Render()
//		if self.m_bDeleted then return false end
//		local pWeapon = self.m_pWeapon
//		if IsValid( pWeapon ) && pWeapon:GetNW2Bool "m_bMuzzleID" != self.m_bMuzzleID then
//			local pEmitter = self.m_pEmitter
//			pEmitter:SetNoDraw( true )
//			pEmitter:Finish()
//			self.m_bDeleted = true
//		end
//	end
//	
//	function EFFECT:Think()
//		if self.m_bDeleted then return false end
//		local pWeapon = self.m_pWeapon
//		if IsValid( pWeapon ) && pWeapon:GetNW2Bool "m_bMuzzleID" != self.m_bMuzzleID then
//			local pEmitter = self.m_pEmitter
//			pEmitter:SetNoDraw( true )
//			pEmitter:Finish()
//			self.m_bDeleted = true
//			return false
//		elseif CurTime() > self.m_flThinkTime then self.m_pEmitter:Finish() return false end
//		return true
//	end
