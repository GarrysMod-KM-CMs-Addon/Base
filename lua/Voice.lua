if VOICE_NORMAL then return end

VOICE_LOBBY = 1
VOICE_NORMAL = 2
VOICE_ONLY = 3

local l_EVoiceMode = VOICE_NORMAL

local l_tSetVoiceMode = {
	[ VOICE_LOBBY ] = function()
		hook.Add( "PlayerCanHearPlayersVoice", "GameImprovements", function() return true end )
		hook.Add( "PlayerCanSeePlayersChat", "GameImprovements", function() return true end )
	end,

	[ VOICE_NORMAL ] = function()
		hook.Add( "PlayerCanHearPlayersVoice", "GameImprovements", function( pListener, pSpeaker )
			if !pSpeaker:Alive() then return false end

			if pListener:GetPos():DistToSqr( pSpeaker:GetPos() ) > ( pSpeaker.GAME_flSpeakDistanceSqr || 13249600/*3640*/ ) then return false end

			return true, true
		end )

		hook.Add( "PlayerCanSeePlayersChat", "GameImprovements", function( _/*sText*/, _/*bTeamOnly*/, pListener, pSpeaker )
			if !IsValid( pSpeaker ) then return true end

			if !pSpeaker:Alive() then return false end

			return pListener:GetPos():DistToSqr( pSpeaker:GetPos() ) <= ( pSpeaker.GAME_flSpeakDistanceSqr || 13249600/*3640*/ )
		end )
	end,

	[ VOICE_ONLY ] = function()
		hook.Add( "PlayerCanHearPlayersVoice", "GameImprovements", function( pListener, pSpeaker )
			if !pSpeaker:Alive() then return false end

			if pListener:GetPos():DistToSqr( pSpeaker:GetPos() ) > ( pSpeaker.GAME_flSpeakDistanceSqr || 13249600/*3640*/ ) then return false end

			return true, true
		end )

		hook.Add( "PlayerCanSeePlayersChat", "GameImprovements", function( _/*sText*/, _/*bTeamOnly*/, pListener, pSpeaker )
			if !IsValid( pSpeaker ) then return true end

			return false
		end )
	end
}

function CORE_VOICE_MODE( ENew )
	local fAction = l_tSetVoiceMode[ ENew ]
	if fAction then
		fAction()
		l_EVoiceMode = ENew
	end
end

function CORE_GET_VOICE_MODE() return l_EVoiceMode end

CORE_VOICE_MODE( VOICE_NORMAL )
