AddCSLuaFile()
DEFINE_BASECLASS "base_point"

sound.Add {
	name = "BaseExplosionEffect.Sound",
	sound = {
		"ambient/explosions/explode_1.wav",
		"ambient/explosions/explode_2.wav",
		"ambient/explosions/explode_4.wav"
	},
	pitch = { 80, 120 },
	level = 150,
	channel = CHAN_STATIC
}

sound.Add {
	name = "BaseExplosionEffect.Water",
	sound = {
		"ambient/explosions/exp1.wav",
		"ambient/explosions/exp2.wav",
		"ambient/explosions/exp3.wav",
		"ambient/explosions/exp4.wav",
		"ambient/explosions/explode_5.wav",
		"ambient/explosions/explode_6.wav",
		"ambient/explosions/citadel_end_explosion1.wav",
		"ambient/explosions/citadel_end_explosion2.wav"
	},
	pitch = { 80, 120 },
	level = 150,
	channel = CHAN_STATIC
}

ENT.PrintName = "#env_explosion"

ENT.flMagnitude = 100

function ENT:KeyValue( Key, Value )
	Key = string.lower( Key )
	if Key == "imagnitude" || k == "magnitude" then self.flMagnitude = tonumber( v ) || 100 end
end
function ENT:AcceptInput( Key, _, _, Value )
	if string.lower( Key || "" ) == "explode" then
		self:Explode()
	end
end

// ENT.SMOKE_TRANSPARENCY = 200
// ENT.SMOKE_SPEED = .1
// ENT.SMOKE_TURN = 45

ENT.FIRE_SPEED = 100

local util_TraceLine, util_Effect, util_BlastDamage, util_ScreenShake = util.TraceLine, util.Effect, util.BlastDamage, util.ScreenShake

function ENT:Explode()
	self:EmitSound( self:WaterLevel() > 0 && "BaseExplosionEffect.Water" || "BaseExplosionEffect.Sound" )
	local flMagnitude = self.flMagnitude
	local flRange = flMagnitude * 3
	local flDist = flRange + 64
	local flDamage = flMagnitude * 64
	util_BlastDamage( self, GetOwner( self ), self:GetPos(), flDist, flDamage )
	for _ = 1, math.max( 5, flRange * .2 ) do // Effects
		local dir = VectorRand()
		local tr = util_TraceLine {
			start = self:GetPos() + dir * 50,
			endpos = self:GetPos() + dir * 50 + VectorRand() * math.Rand( 0, flRange ),
			mask = MASK_SOLID
		}
		local ed = EffectData()
		ed:SetOrigin( tr.HitPos - Vector( 0, 0, 24 ) )
		ed:SetNormal( VectorRand() )
		ed:SetFlags( 4 ) // A brighter kaboom
		util_Effect( "Explosion", ed )
	end
	local flSpeed = flDist * self.FIRE_SPEED
	for _ = 1, math.max( 5, flRange * math.Rand( .03, .06 ) ) do // Fire
		local dir = VectorRand()
		local tr = util_TraceLine {
			start = self:GetPos() + dir * 50,
			endpos = self:GetPos() + dir * 50 + VectorRand() * math.Rand( 0, flRange ),
			mask = MASK_SOLID
		}
		local p = ents.Create "prop_physics"
		p:SetPos( tr.HitPos )
		p:SetModel "models/combine_helicopter/helicopter_bomb01.mdl"
		p:SetNoDraw( true )
		p:Spawn()
		p.GAME_bFireBall = true
		local f = ents.Create "env_fire_trail"
		f:SetPos( p:GetPos() )
		f:SetParent( p )
		f:Spawn()
		p:GetPhysicsObject():AddVelocity( VectorRand() * math.Rand( 0, flSpeed ) )
		AddThinkToEntity( p, function( self ) self:Ignite( 999999 ) if math.random( GetFlameStopChance( self ) * FrameTime() ) == 1 || self:WaterLevel() != 0 then self:Remove() return true end end )
	end
	for i = 1, math.max( 5, flRange * .1 ) do
		local dir = VectorRand()
		util.Decal( "Scorch", self:GetPos() + dir * 50, self:GetPos() + dir * 50 + VectorRand() * flRange )
	end
	/*env_smokestack Just Looks Bad... For Now!
	local Smoke = ents.Create "env_smokestack"
	Smoke:SetPos( self:GetPos() )
	Smoke:SetKeyValue( "InitialState", "1" )
	Smoke:SetKeyValue( "SpreadSpeed", "0" )
	local flSpeed = flDist * self.SMOKE_SPEED
	Smoke:SetKeyValue( "Speed", flSpeed )
	local flTurn = self.SMOKE_TURN
	Smoke:SetKeyValue( "Twist", flTurn )
	Smoke:SetKeyValue( "Roll", flTurn )
	Smoke:SetKeyValue( "BaseSpread", flDist )
	Smoke:SetKeyValue( "StartSize", flDist )
	Smoke:SetKeyValue( "EndSize", "0" )
	Smoke:SetKeyValue( "Rate", "8" )
	Smoke:SetKeyValue( "JetLength", "100" )
	Smoke:SetKeyValue( "RenderColor", "32 32 32" )
	local flTransparency = self.SMOKE_TRANSPARENCY
	Smoke:SetKeyValue( "RenderAmt", flTransparency )
	Smoke:SetKeyValue( "SmokeMaterial", "particle/SmokeStack.vmt" )
	Smoke:Spawn()
	local t = CurTime()
	local flStart, flEnd = t, t + flMagnitude * .3
	AddThinkToEntity( Smoke, function( self )
		local t = math.Clamp( math.Remap( CurTime(), flStart, flEnd, flTransparency, 0 ), 0, flTransparency )
		if t == 0 then self:Remove() return true end
		self:SetKeyValue( "RenderAmt", t )
		local t = math.Clamp( math.Remap( CurTime(), flStart, flEnd, flTurn, 0 ), 0, flTurn )
		self:SetKeyValue( "Twist", t )
		self:SetKeyValue( "Roll", t )
		self:SetKeyValue( "Speed", math.Clamp( math.Remap( CurTime(), flStart, flEnd, flSpeed, 0 ), 0, flSpeed ) )
		self:SetKeyValue( "BaseSpread", math.Rand( 0, math.Clamp( math.Remap( CurTime(), flStart, flEnd, flDist, 0 ), 0, flDist ) ) )
	end )
	*/
end
