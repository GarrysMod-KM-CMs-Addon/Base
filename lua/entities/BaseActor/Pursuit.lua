// These are the pursuit senses. Simple reusable formulas
// to decide if the target is attemping to flee, and not
// just retreating or moving cover to cover.

ACTOR_PURSUIT_DATA = {}

function ENT:UpdatePursuitSenses( pEnemy, pKey )
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
		tData.flRunningAwayFactor = Lerp( math.min( 1, .5 * FrameTime() ), tData.flRunningAwayFactor, f )
	else
		tData.flRunningAwayFactor = Lerp( math.min( 1, .25 * FrameTime() ), tData.flRunningAwayFactor, f )
	end
	return f >= .66
end
