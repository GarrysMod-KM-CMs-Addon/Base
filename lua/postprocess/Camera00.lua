// Fun fact: it got its name because I had no idea which camera I was going for until they very end...
// or maybe I still don't, depends on when you're reading this! If I haven't named it, I still don't :)

CreateClientConVar( "PostProcess_Camera_00", "0", false, false )

surface.CreateFont( "AxonBodyCamFont", {
    font = "Lucida Console",
    size = 28,
    weight = 500,
    antialias = true
} )

local AVAILABLE_TIME_ZONES = {
	"0000",

	"-1200",
	"-1100",
	"-1000",
	"-0900",
	"-0800",
	"-0700",
	"-0600",
	"-0500",
	"-0400",
	"-0330",
	"-0300",
	"-0200",
	"-0100",

	"+0100",
	"+0200",
	"+0300",
	"+0330",
	"+0400",
	"+0430",
	"+0500",
	"+0530",
	"+0545",
	"+0600",
	"+0630",
	"+0700",
	"+0800",
	"+0845",
	"+0900",
	"+0930",
	"+1000",
	"+1030",
	"+1100",
	"+1200",
	"+1245",
	"+1300",
	"+1400"
}

local NUM_AVAILABLE_TIME_ZONES = #AVAILABLE_TIME_ZONES

if !CAMERA00_ADD_TIMEZONE then
	CAMERA00_ADD_TIMEZONE = AVAILABLE_TIME_ZONES[ math.random( 1, NUM_AVAILABLE_TIME_ZONES ) ]
	CAMERA00_ADD_IDENTIFIER = "AXON BODY 3  X60" .. string.format( "%X%05X", math.random( 10, 15 ), math.random( 0, 1048575 ) )
end

cvars.AddChangeCallback( "PostProcess_Camera_00", function( _ /* sName */, _ /* Old */, New )
	if New != "1" || !GAMEMODE:PostProcessPermitted "PostProcess_Camera_00" then
		g_pCurrentScreenspaceEffectsModifyColor.Camera_00 = nil
		g_pCurrentScreenspaceEffectsPreBuiltIn.Camera_00 = nil
		return
	end

	g_pCurrentScreenspaceEffectsModifyColor.Camera_00 = function()
		g_pDrawColorModify[ "$pp_colour_addr" ] = g_pDrawColorModify[ "$pp_colour_addr" ] + -.15
		g_pDrawColorModify[ "$pp_colour_addg" ] = g_pDrawColorModify[ "$pp_colour_addg" ] + -.05
		g_pDrawColorModify[ "$pp_colour_addb" ] = g_pDrawColorModify[ "$pp_colour_addb" ] + .12

		g_pDrawColorModify[ "$pp_colour_mulr" ] = g_pDrawColorModify[ "$pp_colour_mulr" ] + .05
		g_pDrawColorModify[ "$pp_colour_mulg" ] = g_pDrawColorModify[ "$pp_colour_mulg" ] + .22
		g_pDrawColorModify[ "$pp_colour_mulb" ] = g_pDrawColorModify[ "$pp_colour_mulb" ] + .45

		g_pDrawColorModify[ "$pp_colour_brightness" ] = g_pDrawColorModify[ "$pp_colour_brightness" ] + -.12
		g_pDrawColorModify[ "$pp_colour_contrast" ] = g_pDrawColorModify[ "$pp_colour_contrast" ] * 1.65
		g_pDrawColorModify[ "$pp_colour_colour" ] = g_pDrawColorModify[ "$pp_colour_colour" ] * .45
	end

	g_pCurrentScreenspaceEffectsPreBuiltIn.Camera_00 = function()
		DrawMaterialOverlay( "models/props_c17/fisheyelens", -.02 )
		DrawSharpen( 3, 1.2 )
		DrawMotionBlur( .45, .85, 0 )
		local _, flY = draw.SimpleTextOutlined( os.date( "%Y-%m-%d  %H:%M:%S " .. CAMERA00_ADD_TIMEZONE ), "AxonBodyCamFont", ScrW() * .75, ScrH() * .02, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, color_black )
		draw.SimpleTextOutlined( CAMERA00_ADD_IDENTIFIER, "AxonBodyCamFont", ScrW() * .75, ScrH() * .02 + flY, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, color_black )
	end
end )

list.Set( "PostProcess", "#PostProcess_Camera_00", {
	icon = "gui/postprocess/bloom.png",
	convar = "PostProcess_Camera_00",
	category = "#PostProcess_Cameras",
} )
