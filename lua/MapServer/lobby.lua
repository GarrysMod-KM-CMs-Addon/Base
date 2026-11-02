hook.Add( "InitPostEntity", "Campaign", function()
	if engine.ActiveGamemode() != "campaign" || game.SinglePlayer() then
		if engine.ActiveGamemode() != "campaign" && game.SinglePlayer() then
			ErrorNoHaltWithStack "Gamemode must be campaign and the game must be set to multiplayer (even if you play solo)"
		elseif game.SinglePlayer() then
			ErrorNoHaltWithStack "The game must be set to multiplayer (even if you play solo)"
		else
			ErrorNoHaltWithStack "Gamemode must be campaign"
		end

		hook.Add( "Think", "Shit", function()
			for _, pPlayer in player.Iterator() do
				pPlayer:ConCommand "disconnect"
			end
		end )
	end
end )

hook.Add( "PlayerSpawn", "Campaign", function( pPlayer )
	pPlayer:GodEnable()
	pPlayer:SetNoDraw( true )
	pPlayer:SetHealth( 1e8 )
	pPlayer:SetMaxHealth( 1e8 )
end )

hook.Add( "IsSpawnpointSuitable", "Campaign", function() return true end )

include "Voice.lua"
CORE_VOICE_MODE( VOICE_LOBBY )
