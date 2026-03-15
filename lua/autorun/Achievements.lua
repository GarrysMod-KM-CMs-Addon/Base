// NOTE: Achievements have a VERY limited API for now!

if CLIENT then
	AchievementsMenuList = AchievementsMenuList || {}
	AchievementsMenuPages = AchievementsMenuPages || {}
	AchievementsMenuPageDrew = AchievementsMenuPageDrew || {}
	AchievementsMenuPage = AchievementsMenuPage || 1

	local language_GetPhrase = language.GetPhrase

	local function AchievementsMenuDrawPage()
		for _, pPanel in ipairs( AchievementsMenuPageDrew ) do pPanel:Remove() end
		AchievementsMenuPageDrew = {}
		local flMenuWidth, flMenuHeight = ScrW() * .75, ScrH() * .75
		local flInitialOffset = flMenuWidth * .02
		local flOffset = flMenuHeight * .02
		local flOffsetSoFar = flInitialOffset
		local flWidth = flMenuWidth - flInitialOffset * 2
		local flWidthOffset = flInitialOffset
		local flHeight = flMenuWidth * .04
		local flTextWidthOffset = flWidth * .0066
		local flTextWidth = flWidth - flTextWidthOffset * 2
		local iCount = 0
		for _, sAchievement in ipairs( AchievementsMenuPages[ AchievementsMenuPage ] || {} ) do
			iCount = iCount + 1
			local pOverlay = vgui.Create( "DPanelOverlay", AchievementsMenu )
			table.insert( AchievementsMenuPageDrew, pOverlay )
			function pOverlay:Paint( w, h ) draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) ) end
			pOverlay:SetPos( flWidthOffset, flOffsetSoFar )
			pOverlay:SetSize( flWidth, flHeight )
			sAchievement = "Achievement_" .. sAchievement
			local pOverlayTextA = vgui.Create( "DLabel", pOverlay )
			pOverlayTextA:SetPos( flTextWidthOffset, -flHeight * .25 )
			pOverlayTextA:SetSize( flTextWidth, flHeight )
			pOverlayTextA:SetText( language_GetPhrase( sAchievement .. "_Header" ) )
			local pOverlayTextB = vgui.Create( "DLabel", pOverlay )
			pOverlayTextB:SetPos( flTextWidthOffset, flHeight * .25 )
			pOverlayTextB:SetSize( flTextWidth, flHeight )
			pOverlayTextB:SetText( language_GetPhrase( sAchievement .. "_Text" ) )
			flOffsetSoFar = flOffsetSoFar + flHeight + flOffset
		end
		if iCount > 9 then return end
		net.Start "AchievementsQuery" net.WriteString( AchievementsMenuLastAchievement ) net.SendToServer()
	end

	net.Receive( "AchievementsQuery", function( len )
		if !IsValid( AchievementsMenu ) then return end
		local sAchievement = net.ReadString()
		AchievementsMenuLastAchievement = sAchievement
		if AchievementsMenuList[ sAchievement ] then return end
		AchievementsMenuList[ sAchievement ] = true
		local i = math.max( #AchievementsMenuPages )
		local t = AchievementsMenuPages[ i ]
		if t then
			if #t > 9 then AchievementsMenuPages[ i + 1 ] = { sAchievement }
			else table.insert( t, sAchievement ) end
		else AchievementsMenuPages[ i ] = { sAchievement } end
		AchievementsMenuDrawPage()
	end )

	function AchievementsMenuOpen()
		if IsValid( AchievementsMenu ) then return end
		AchievementsMenu = vgui.Create "DFrame"
		AchievementsMenu:SetTitle( language_GetPhrase "Achievements" )
		local flMenuWidth, flMenuHeight = ScrW() * .75, ScrH() * .75
		AchievementsMenu:SetSize( flMenuWidth, flMenuHeight )
		AchievementsMenu:Center()
		AchievementsMenu:MakePopup()
		net.Start "AchievementsQuery" net.SendToServer()
		function AchievementsMenu:OnClose()
			AchievementsMenuPage = 1
			table.Empty( AchievementsMenuList )
			table.Empty( AchievementsMenuPages )
			table.Empty( AchievementsMenuPageDrew )
		end
		function AchievementsMenu:Paint( w, h ) draw.RoundedBox( 0, 0, 0, w, h, Color( 75, 75, 75 ) ) end
		local pButtonPrev = vgui.Create( "DColorButton", AchievementsMenu )
		pButtonPrev:SetText( "  " .. language_GetPhrase "AchievementsMenuPagePrev" )
		local f = flMenuWidth * .025
		pButtonPrev:SetSize( f, f )
		pButtonPrev:SetPos( 0, flMenuHeight - f )
		pButtonPrev:SetColor( Color( 0, 0, 0 ) )
		pButtonPrev.DoClick = function()
			AchievementsMenuPage = math.max( 0, AchievementsMenuPage - 1 )
			AchievementsMenuDrawPage()
		end
		local pButtonNext = vgui.Create( "DColorButton", AchievementsMenu )
		pButtonNext:SetText( "  " .. language_GetPhrase "AchievementsMenuPageNext" )
		pButtonNext:SetSize( f, f )
		pButtonNext:SetPos( f, flMenuHeight - f )
		pButtonNext:SetColor( Color( 0, 0, 0 ) )
		pButtonNext.DoClick = function()
			AchievementsMenuPage = math.min( #AchievementsMenuPages + 1, AchievementsMenuPage + 1 )
			AchievementsMenuDrawPage()
		end
	end

	concommand.Add( "Achievements", function() if IsValid( AchievementsMenu ) then AchievementsMenu:Close() else AchievementsMenuOpen() end end )

	local surface_PlaySound = surface.PlaySound
	local chat_AddText = chat.AddText
	// Called when we get an achievement
	local cAchievementTextColor = Color( 255, 255, 0 )
	function Achievement_Acquire( sName )
		surface_PlaySound "Achievement.wav"
		sName = "Achievement_Acquire_" .. sName
		chat_AddText( cAchievementTextColor, "✦ ", language_GetPhrase( sName .. "_Header" ), cAchievementTextColor, " : ", language_GetPhrase( sName .. "_Text" ), cAchievementTextColor, " ✦" )
	end
	function Achievement_Miscellaneous( sName )
		surface_PlaySound "Achievement.wav"
		sName = "Achievement_Miscellaneous_" .. sName
		chat_AddText( cAchievementTextColor, "✦ ", language_GetPhrase( sName .. "_Header" ), cAchievementTextColor, " : ", language_GetPhrase( sName .. "_Text" ), cAchievementTextColor, " ✦" )
	end
	return
end

util.AddNetworkString "AchievementsQuery"

net.Receive( "AchievementsQuery", function( len, ply )
	local sLast = net.ReadString()
	if sLast == "" then sLast = nil end
	local t = __ACHIEVEMENTS_ACQUIRED__[ ply:SteamID64() ]
	if t then
		local sAchievement = next( t, sLast )
		if !sAchievement then return end
		net.Start "AchievementsQuery" net.WriteString( sAchievement ) net.Send( ply )
	end
end )

__ACHIEVEMENTS__ = __ACHIEVEMENTS__ || {}

// SteamID64 -> { String = true }
__ACHIEVEMENTS_ACQUIRED__ = __ACHIEVEMENTS_ACQUIRED__ || util.JSONToTable( file.Read( "Achievements/" .. engine.ActiveGamemode() .. ".json" ) || "[]", true, true )

function ACHIEVEMENT_ACQUIRE( sClass ) __ACHIEVEMENTS__[ "Acquire_" .. sClass ] = true end

function ACHIEVEMENT_MISCELLANEOUS( sName ) __ACHIEVEMENTS__[ "Miscellaneous_" .. sName ] = true end

function Achievement_Miscellaneous( ply, sName )
	local s = ply:SteamID64()
	local t = __ACHIEVEMENTS_ACQUIRED__[ s ]
	local sAchievement = "Miscellaneous_" .. sName
	if t then
		if !t[ sAchievement ] then
			ply:SendLua( "Achievement_Miscellaneous(\"" .. sName ..  "\")" )
			t[ sAchievement ] = true
		end
	else
		ply:SendLua( "Achievement_Miscellaneous(\"" .. sName .. "\")" )
		__ACHIEVEMENTS_ACQUIRED__[ s ] = { [ sAchievement ] = true }
	end
end

function Achievement_Has( ply, sName )
	local s = ply:SteamID64()
	local t = __ACHIEVEMENTS_ACQUIRED__[ s ]
	if t then if t[ sName ] then return true end end
end

function Achievement_Miscellaneous_Grant( ply, sName )
	local s = ply:SteamID64()
	local t = __ACHIEVEMENTS_ACQUIRED__[ s ]
	if t then
		ply:SendLua( "Achievement_Miscellaneous(\"" .. sName ..  "\")" )
		t[ "Miscellaneous_" .. sName ] = true
	else
		ply:SendLua( "Achievement_Miscellaneous(\"" .. sName .. "\")" )
		__ACHIEVEMENTS_ACQUIRED__[ s ] = { [ sName ] = true }
	end
end

ACHIEVEMENT_MISCELLANEOUS "Kill"
ACHIEVEMENT_MISCELLANEOUS "Fall"
ACHIEVEMENT_MISCELLANEOUS "Combat"
ACHIEVEMENT_MISCELLANEOUS "WeaponReloadFull"
ACHIEVEMENT_MISCELLANEOUS "Slide"

ACHIEVEMENT_MISCELLANEOUS "CoverGrate"
ACHIEVEMENT_MISCELLANEOUS "CoverPeek"
ACHIEVEMENT_MISCELLANEOUS "CoverBlindFire"
ACHIEVEMENT_MISCELLANEOUS "CoverBlindFireKill"
