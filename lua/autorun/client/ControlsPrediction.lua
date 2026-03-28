hook.Add( "StartCommand", "GameImprovements", function( ply, cmd )
	if !ply:Alive() then return end
	ply.m_iOriginalButtons = cmd:GetButtons()
	/* No lol
	if cmd:KeyDown( IN_ZOOM ) then
		if SysTime() <= ( ply.m_flZoomOutTime || 0 ) then
			cmd:RemoveKey( IN_ZOOM )
		elseif !ply.m_bWasZooming then
			if SysTime() > ( ply.m_flZoomOutTime || 0 ) then
				ply.m_flZoomInTime = SysTime() + .4
				ply.m_bWasZooming = true
			end
		end
	else
		if ply.m_bWasZooming then
			if SysTime() > ( ply.m_flZoomInTime || 0 ) then
				ply.m_flZoomOutTime = SysTime() + .4
				ply.m_bWasZooming = nil
			end
			cmd:AddKey( IN_ZOOM )
		end
	end
	*/
	ply.m_bWantsToZoom = cmd:KeyDown( IN_ZOOM )
end )
