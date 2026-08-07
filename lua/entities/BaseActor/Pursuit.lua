// These are the pursuit senses. Simple reusable formulas
// to decide if the target is attemping to flee, and not
// just retreating or moving cover to cover.

ACTOR_PURSUIT_DATA = {}

local min = math.min
local exp = math.exp

local function FRILerpRate( flRate, flFrameTime ) return min( 1, 1 - exp( -flRate * flFrameTime ) ) end

function ENT:UpdatePursuitSenses( pEnemy, pKey /* a.k.a pTrueEnemy */ )
	if !IsValid( pKey ) || !pKey:IsPlayer() /* dirty HACK */ then return end
	local PURSUIT_DATA = ACTOR_PURSUIT_DATA[ self:Classify() ] || {}
	for pEnemy, tData in pairs( PURSUIT_DATA ) do
		if IsValid( pEnemy ) && ( SysTime() - tData.flTime ) <= 1 then PURSUIT_DATA[ pEnemy ] = tData end
	end
	ACTOR_PURSUIT_DATA[ self:Classify() ] = PURSUIT_DATA
	local tData = PURSUIT_DATA[ pKey ]
	if !tData then tData = { flRunningAwayFactor = 0 } PURSUIT_DATA[ pKey ] = tData end
	tData.flTime = SysTime()
	local f = GetVelocity( pEnemy ):GetNormalized():Dot( ( pEnemy:GetPos() + pEnemy:OBBCenter() - self:GetPos() ):GetNormalized() )
	local fc = tData.flRunningAwayFactor
	if f > fc then
		tData.flRunningAwayFactor = Lerp( FRILerpRate( .05, FrameTime() ), tData.flRunningAwayFactor, f )
	else
		tData.flRunningAwayFactor = Lerp( FRILerpRate( .2, FrameTime() ), tData.flRunningAwayFactor, f )
	end
	return f >= .66
end
