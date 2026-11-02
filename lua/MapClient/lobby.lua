// TODOTODOTODO
hook.Add( "HUDPaint", "", function()
end )

timer.Simple( .1, function ()
	hook.Add( "HUDShouldDraw", "Graphics", function( sName )
		return sName == "CHudGMod" || sName == "CHudChat"
	end )
end )
