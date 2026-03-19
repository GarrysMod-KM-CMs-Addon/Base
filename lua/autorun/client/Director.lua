include "autorun/Director.lua"

DIRECTOR_MUSIC_TENSION = 0
DIRECTOR_THREAT = DIRECTOR_THREAT_NULL

timer.Simple( 0, function() GAMEMODE.DrawDeathNotice = nil end )

local sound_Add = sound.Add
local util_PrecacheSound = util.PrecacheSound
local Sound = Sound
local CHAN_STATIC = CHAN_STATIC
function Director_Music( sName, sPath )
	util_PrecacheSound( sPath )
	Sound( sPath )
	sound_Add {
		name = sName,
		channel = CHAN_STATIC,
		level = 0,
		sound = "#" .. sPath
	}
end

DIRECTOR_MUSIC_IDLE_SEQUENCES = DIRECTOR_MUSIC_IDLE_SEQUENCES || {}

local math_Rand = math.Rand
DIRECTOR_MUSIC_TABLE = DIRECTOR_MUSIC_TABLE || {
	// Do NOT write anything here! Use DIRECTOR_IDLE_SEQUENCES instead!
	[ DIRECTOR_THREAT_NULL ] = {
		Base = { Execute = function( self )
			if DIRECTOR_SUPPRESS_IDLE_AMBIANCE then return end
			if !self.tHandles.Main then
				// TODO: FrameTime() isn't reliable, and we are called a LOT more
				if math_Rand( 0, 1250000 * FrameTime() ) <= 1 then
					local _, s = table.Random( DIRECTOR_MUSIC_IDLE_SEQUENCES )
					if s then Director_Music_Play( self, "Main", s ) end
				end
			end
		end }
	},
	[ DIRECTOR_THREAT_HEAT ] = {},
	[ DIRECTOR_THREAT_ALERT ] = {},
	[ DIRECTOR_THREAT_HOLD_FIRE ] = {},
	[ DIRECTOR_THREAT_COMBAT ] = {}
}

function Director_Music_Container()
	return {
		tHandles = {},
		m_flVolume = 0
	}
end

local SysTime = SysTime
local LocalPlayer = LocalPlayer
// local game_GetWorld = game.GetWorld
local table_insert = table.insert
function Director_Music_Play( self, Index, sName, flVolume, flPitch )
	// local pSound = CreateSound( game_GetWorld(), sName )
	local pSound = CreateSound( LocalPlayer(), sName )
	flVolume = flVolume || 1
	flPitch = flPitch || 100
	Director_Music_Stop( self, Index )
	pSound:PlayEx( math.max( SOUND_PATCH_ABSOLUTE_MINIMUM, flVolume * self.m_flVolume ), flPitch )
	self.tHandles[ Index ] = { pSound, flVolume, flPitch, SoundDuration( sound.GetProperties( sName ).sound ), SysTime(), sName }
end

function Director_Music_Stop( self, Index )
	local tHandles = self.tHandles
	local pSound = tHandles[ Index ]
	tHandles[ Index ] = nil
	if pSound then pSound[ 1 ]:Stop() end
end

Director_Music( "MUS_Transition_Instant", "Music/Default/Transition_Instant.wav" )

// We have switched to HOLD_FIRE... do we even need these anymore?
DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT = DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT || {}
DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT = DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT || {}
DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT.Default_Instant = { Execute = function( self )
	if !self.tHandles.Main then
		if self.bPartStarted then
			self.sIndex = "Idle"
			self.bPartStarted = nil
			self.bA = nil
			return true
		end
		self.bPartStarted = true
		Director_Music_Play( self, "Main", "MUS_Transition_Instant" )
	end
	return false, 0, 1
end }
DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT.Default_Fade = { Execute = function( self, flInterval, flVolumeA, flVolumeB, bCorrect )
	if !bCorrect then return true end
	if flVolumeA > 0 then
		flVolumeA = flVolumeA < .1 && math.Approach( flVolumeA, 0, flInterval ) || Lerp( .1 * flInterval, flVolumeA, 0 )
		return false, flVolumeA, flVolumeB
	end
	if self.m_ELayerTo == DIRECTOR_THREAT_NULL then return true end
	if flVolumeB == 1 then return true end
	flVolumeB = flVolumeB > .9 && math.Approach( flVolumeB, 1, flInterval ) || Lerp( .1 * flInterval, flVolumeB, 1 )
	return false, 0, flVolumeB
end }
local math_max = math.max
local pairs = pairs
function Director_Music_UpdateInternal( self, flInterval, ... )
	// This function repeats itself intentionally, because in continuous music playback,
	// even one tick is a lot of time, so we call this again to allow people to still write
	// code that passes playing to the next tick (like when changing the index),
	// since we also technically simulate the next tick
	local t = self.m_pTable
	t.Execute( self, flInterval, ... )
	local tHandles = self.tHandles
	local flVolume = self.m_flVolume
	for i = 1, 3 do
		for Index, tData in pairs( tHandles ) do
			local flPitch = tData[ 3 ] / 100
			local f = tData[ 4 ] - ( SysTime() - tData[ 5 ] ) * flPitch
			if tData[ 4 ] <= flInterval then tHandles[ Index ] = nil tData[ 1 ]:Stop() continue end
			tData[ 4 ] = f
			tData[ 5 ] = SysTime()
			local pSound = tData[ 1 ]
			pSound:ChangeVolume( math_max( SOUND_PATCH_ABSOLUTE_MINIMUM, flVolume * tData[ 2 ] ) )
			// Sadly, pitch zero pauses the sound, so we can't use that to bypass SOUND_PATCH_ABSOLUTE_MINIMUM either...
			pSound:ChangePitch( tData[ 3 ] )
		end
	end
	return t.Execute( self, flInterval, ... )
end

DIRECTOR_MUSIC_INTENSITY = 0 // Intensity right now
DIRECTOR_MUSIC_TENSION = 0 // General battle intensity

DIRECTOR_THREAT = DIRECTOR_THREAT || DIRECTOR_THREAT_NULL
DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_MUSIC_LAST_THREAT || DIRECTOR_THREAT_NULL

DIRECTOR_MUSIC = DIRECTOR_MUSIC || {}

local RealTime = RealTime

DIRECTOR_MUSIC_VO_TIME = 0

function Director_VoiceLineHook(
		flDuration ) // sName - This is actually a String of the sound's name ( Data.SoundName )
	flDuration = SoundDuration( flDuration )
	if !flDuration then return end
	if RealTime() <= DIRECTOR_MUSIC_VO_TIME && DIRECTOR_MUSIC_IN_VO_HF then return end
	local f = LocalPlayer():GetNW2Float( "DIRECTOR_MUSIC_VO_WAIT", DIRECTOR_MUSIC_VO_WAIT )
	if f <= 0 then DIRECTOR_MUSIC_VO_TIME = RealTime()
	else DIRECTOR_MUSIC_VO_TIME = RealTime() + math.min( flDuration, 8 ) + f end
	DIRECTOR_MUSIC_IN_VO = true
	DIRECTOR_MUSIC_IN_VO_HF = nil
end

function Director_VoiceLineHookToCombat( flDuration )
	if DIRECTOR_TRANSITION && DIRECTOR_TRANSITION.m_bIntroOfATrack then return end
	flDuration = SoundDuration( flDuration )
	if !flDuration then return end
	local f = LocalPlayer():GetNW2Float( "DIRECTOR_MUSIC_VO_WAIT", DIRECTOR_MUSIC_VO_WAIT )
	if f <= 0 then DIRECTOR_MUSIC_VO_TIME = RealTime()
	else DIRECTOR_MUSIC_VO_TIME = RealTime() + math.min( flDuration, 8 ) end
	DIRECTOR_MUSIC_IN_VO = true
	DIRECTOR_MUSIC_IN_VO_HF = true
end

hook.Add( "PostCleanupMap", "Director", function()
	table.Empty( DIRECTOR_MUSIC )
	DIRECTOR_TRANSITION = nil
	DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_THREAT_NULL
end )

local LocalPlayer = LocalPlayer
local CurTime = CurTime
local flLastCall = SysTime()
__HUD_SHOULD_NOT_DRAW__ = {
	CHudHistoryResource = true,
	CHudGeiger = true,
	CHudDamageIndicator = true,
	CHudHealth = true,
	CHudHistoryResource = true
}

// So, this is how you get nigh perfect looping in Lua.
// There are 26 HUD elements which this is called for per frame.
// Meaning 1560 calls per second if you have 60 FPS.
// But before you raise your pitchforks and start throwing
// tomatoes at me, remember who I am. I wrote what is
// essentially triple A Ubisoft quality into Garry's Mod.
// I have always been a huge stickler for the performance.
// I would not do this without reason, and I am not doing
// this in a messy way, either. In Python, you can use
// pygame in separate threads, since it yields until
// the sound finishes playing. But that's simply not
// possible in Lua. Plus, even on my shitty ass computer,
// the FPS merely drops from 40 FPS to 30, and from 60 FPS to 40.
// Point is, I know how to make performant code.
// As terrifying to performance because of length it looks, it's not.
// Bottom line: Do NOT "optimize" or "refactor" this. This ISN'T spaghetti code,
// nor is it hacky. I'm not a casual Garry's Mod addon maker, this addon is a PROFESSIONAL passion project xD
// My point is, I know what I'm doing.

function DIRECTOR_CLIENT_TICK( flInterval )
	local ply = LocalPlayer()
	if !IsValid( ply ) then return end // NO!
	for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
		if !DIRECTOR_MUSIC[ ELayer ] then
			// Feel free to uncomment this for testing
			//	if ELayer == DIRECTOR_THREAT_COMBAT then
			//		local t = DIRECTOR_MUSIC_TABLE[ ELayer ].TRACK
			//		if t then
			//			local p = Director_Music_Container()
			//			p.m_pTable = t
			//			p.m_flStartTime = CurTime()
			//			local f = p.Time
			//			p.m_flEndTime = f && f() || ( CurTime() + math_Rand( 120, 240 ) )
			//			DIRECTOR_MUSIC[ ELayer ] = p
			//			continue
			//		end
			//	end
			local t = table.Random( DIRECTOR_MUSIC_TABLE[ ELayer ] )
			if t then
				local b
				for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
					local p = DIRECTOR_MUSIC[ ELayer ]
					if p && p.m_pTable == t then b = true break end
				end
				if b then continue end
				local p = Director_Music_Container()
				p.m_pTable = t
				p.m_flStartTime = CurTime()
				local f = p.Time
				p.m_flEndTime = f && f() || ( CurTime() + math_Rand( 120, 240 ) )
				DIRECTOR_MUSIC[ ELayer ] = p
			else
				local p = Director_Music_Container()
				p.m_pTable = { Execute = function() end }
				DIRECTOR_MUSIC[ ELayer ] = p
			end
		end
	end
	if DIRECTOR_MUSIC_IN_VO then
		DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_THREAT_COMBAT
		if DIRECTOR_MUSIC_IN_VO_HF then
			local t = DIRECTOR_MUSIC[ DIRECTOR_THREAT_COMBAT ].m_pTable
			local f = t.CheckIntro
			if f && f "HoldFire" then
				DIRECTOR_TRANSITION = Director_Music_Container()
				DIRECTOR_TRANSITION.m_pTable = { Execute = t.Intro }
				DIRECTOR_TRANSITION.m_flVolume = 1
				DIRECTOR_TRANSITION.m_bToCombat = true
				DIRECTOR_TRANSITION.m_ELayerFrom = DIRECTOR_THREAT_HOLD_FIRE
				DIRECTOR_TRANSITION.m_ELayerTo = DIRECTOR_THREAT_COMBAT
				DIRECTOR_TRANSITION.m_bIntroOfATrack = true
				DIRECTOR_THREAT = DIRECTOR_THREAT_COMBAT
				net.Start "DR_ClientWantsToBeInCombat" net.SendToServer()
				return
			end
			DIRECTOR_MUSIC_WAS_HOLD_FIRE = true
			if RealTime() <= DIRECTOR_MUSIC_VO_TIME then
				for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
					local pContainer = DIRECTOR_MUSIC[ ELayer ]
					if pContainer then
						Director_Music_UpdateInternal( pContainer, flInterval )
						if ELayer == DIRECTOR_THREAT_HOLD_FIRE then
							pContainer.m_flVolume = 1
						else pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, FrameTime() ) end
					end
				end
			else DIRECTOR_MUSIC_IN_VO = nil end
		else
			if RealTime() > DIRECTOR_MUSIC_VO_TIME then
				DIRECTOR_MUSIC_IN_VO = nil
				DIRECTOR_TRANSITION = nil
				for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
					local pContainer = DIRECTOR_MUSIC[ ELayer ]
					if pContainer then
						Director_Music_UpdateInternal( pContainer, flInterval )
						if ELayer == DIRECTOR_THREAT_HOLD_FIRE then
							pContainer.m_flVolume = 1
						else pContainer.m_flVolume = 0 end
					end
				end
			else
				if DIRECTOR_TRANSITION then
					if DIRECTOR_TRANSITION.m_flVolume <= 0 then
						DIRECTOR_TRANSITION = nil
					else
						DIRECTOR_TRANSITION.m_flVolume = math.Approach( DIRECTOR_TRANSITION.m_flVolume, 0, FrameTime() )
					end
				end
				for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
					local pContainer = DIRECTOR_MUSIC[ ELayer ]
					if pContainer then
						Director_Music_UpdateInternal( pContainer, flInterval )
						pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, FrameTime() )
					end
				end
			end
		end
		return
	elseif DIRECTOR_TRANSITION then
		local b
		if DIRECTOR_TRANSITION.m_bToCombat then
			b = DIRECTOR_THREAT >= DIRECTOR_THREAT_COMBAT
		else b = DIRECTOR_THREAT < DIRECTOR_THREAT_COMBAT end
		local ELayerFrom, ELayerTo, flInitialVolumeA, flInitialVolumeB = DIRECTOR_TRANSITION.m_ELayerFrom, DIRECTOR_TRANSITION.m_ELayerTo
		for ELayer, pContainer in pairs( DIRECTOR_MUSIC ) do
			if ELayer == ELayerFrom then
				flInitialVolumeA = pContainer.m_flVolume
			elseif ELayer == ELayerTo then
				flInitialVolumeB = pContainer.m_flVolume
			end
			if flInitialVolumeA && flInitialVolumeB then break end
		end
		local bDone, flVolumeA, flVolumeB = Director_Music_UpdateInternal( DIRECTOR_TRANSITION, flInterval, flInitialVolumeA || 0, flInitialVolumeB || 0, b )
		DIRECTOR_MUSIC_LAST_THREAT = ELayerTo
		flVolumeA = flVolumeA || 0
		flVolumeB = flVolumeB || 1
		if bDone then DIRECTOR_TRANSITION = nil end
		for ELayer, pContainer in pairs( DIRECTOR_MUSIC ) do
			if pContainer then
				if ELayer == ELayerFrom then
					pContainer.m_flVolume = flVolumeA
				elseif ELayer == ELayerTo then
					pContainer.m_flVolume = flVolumeB
				else
					pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, FrameTime() )
				end
				Director_Music_UpdateInternal( pContainer, flInterval )
			end
		end
		return
	elseif DIRECTOR_THREAT == DIRECTOR_THREAT_HOLD_FIRE then
		local pSource = DIRECTOR_MUSIC[ DIRECTOR_THREAT_COMBAT ]
		local t = pSource.m_pTable
		local f = t.CheckIntro
		if f && f "HoldFire" then
			DIRECTOR_TRANSITION = Director_Music_Container()
			DIRECTOR_TRANSITION.m_pTable = { Execute = t.Intro }
			DIRECTOR_TRANSITION.m_pSource = pSource
			DIRECTOR_TRANSITION.m_flVolume = 1
			DIRECTOR_TRANSITION.m_bToCombat = true
			DIRECTOR_TRANSITION.m_ELayerFrom = DIRECTOR_THREAT_HOLD_FIRE
			DIRECTOR_TRANSITION.m_ELayerTo = DIRECTOR_THREAT_COMBAT
			DIRECTOR_TRANSITION.m_bIntroOfATrack = true
			DIRECTOR_THREAT = DIRECTOR_THREAT_COMBAT
			DIRECTOR_MUSIC_WAS_HOLD_FIRE = nil
			net.Start "DR_ClientWantsToBeInCombat" net.SendToServer()
			return
		end
		for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
			local pContainer = DIRECTOR_MUSIC[ ELayer ]
			if pContainer then
				if ELayer == DIRECTOR_THREAT then
					pContainer.m_flVolume = 1
				else pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, FrameTime() ) end
				Director_Music_UpdateInternal( pContainer, flInterval )
			end
		end
		DIRECTOR_MUSIC_WAS_HOLD_FIRE = true
		if DIRECTOR_TRANSITION then
			if DIRECTOR_TRANSITION.m_flVolume <= 0 then
				DIRECTOR_TRANSITION = nil
			else
				DIRECTOR_TRANSITION.m_flVolume = math.Approach( DIRECTOR_TRANSITION.m_flVolume, 0, FrameTime() )
			end
		end
	elseif DIRECTOR_MUSIC_WAS_HOLD_FIRE then
		 DIRECTOR_MUSIC_WAS_HOLD_FIRE = nil
		for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
			local pContainer = DIRECTOR_MUSIC[ ELayer ]
			if pContainer then
				if ELayer == DIRECTOR_THREAT then
					pContainer.m_flVolume = 1
					local f = pContainer.m_pTable
					if f then
						f = f.KickStart
						if f then f( pContainer ) end
					end
				else pContainer.m_flVolume = 0 end
				//	if ELayer == DIRECTOR_THREAT then
				//		if pContainer.m_flVolume == 1 then DIRECTOR_MUSIC_WAS_HOLD_FIRE = nil end
				//		pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 1, FrameTime() )
				//	else pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, FrameTime() ) end
				Director_Music_UpdateInternal( pContainer, flInterval )
			end
		end
		DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_THREAT_COMBAT
		if DIRECTOR_TRANSITION then
			if DIRECTOR_TRANSITION.m_flVolume <= 0 then
				DIRECTOR_TRANSITION = nil
			else
				DIRECTOR_TRANSITION.m_flVolume = math.Approach( DIRECTOR_TRANSITION.m_flVolume, 0, FrameTime() )
			end
		end
		return
	end
	if DIRECTOR_MUSIC_LAST_THREAT < DIRECTOR_THREAT_COMBAT && DIRECTOR_THREAT >= DIRECTOR_THREAT_COMBAT then
		DIRECTOR_TRANSITION = Director_Music_Container()
		local t = table.Random( DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT )
		DIRECTOR_TRANSITION.m_pTable = t
		DIRECTOR_TRANSITION.m_flVolume = 1
		DIRECTOR_TRANSITION.m_bToCombat = true
		DIRECTOR_TRANSITION.m_ELayerFrom = DIRECTOR_MUSIC_LAST_THREAT
		DIRECTOR_TRANSITION.m_ELayerTo = DIRECTOR_THREAT
		return
	elseif DIRECTOR_MUSIC_LAST_THREAT >= DIRECTOR_THREAT_COMBAT && DIRECTOR_THREAT < DIRECTOR_THREAT_COMBAT then
		DIRECTOR_TRANSITION = Director_Music_Container()
		local t = table.Random( DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT )
		DIRECTOR_TRANSITION.m_pTable = t
		DIRECTOR_TRANSITION.m_flVolume = 1
		DIRECTOR_TRANSITION.m_ELayerFrom = DIRECTOR_MUSIC_LAST_THREAT
		DIRECTOR_TRANSITION.m_ELayerTo = DIRECTOR_THREAT
		return
	end
	// Do NOT mistake this for the fade transition!
	// This is completely different, and used to fade between
	// idle/heat/alert tracks!
	for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
		local pContainer = DIRECTOR_MUSIC[ ELayer ]
		if pContainer then
			Director_Music_UpdateInternal( pContainer , flInterval )
			if ELayer == DIRECTOR_THREAT then
				pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 1, .1 * RealFrameTime() )
			else
				if table.IsEmpty( pContainer.tHandles ) || pContainer.m_flVolume <= 0 then pContainer.m_flVolume = 0 end
				Director_Music_UpdateInternal( pContainer, flInterval )
				pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, RealFrameTime() * .1 )
				if pContainer.m_flVolume <= 0 && CurTime() > ( pContainer.m_flEndTime || 0 ) then DIRECTOR_MUSIC[ ELayer ] = nil end
			end
		end
	end
end

local flLastHUDShouldDrawCall, flHUDShouldDrawTime = SysTime(), 0
hook.Add( "HUDShouldDraw", "Director", function( sName )
	local t = SysTime() - flLastHUDShouldDrawCall
	flHUDShouldDrawTime = math.Approach( flHUDShouldDrawTime, t, .1 )
	flLastHUDShouldDrawCall = SysTime()
	DIRECTOR_CLIENT_TICK( flHUDShouldDrawTime )
	return __HUD_SHOULD_NOT_DRAW__[ sName ] == nil
end )
local flLastHUDPaintCall, flHUDPaintTime = SysTime(), 0
hook.Add( "HUDPaint", "Director", function()
	local t = SysTime() - flLastHUDPaintCall
	flHUDPaintTime = math.Approach( flHUDPaintTime, t, .1 )
	flLastHUDPaintCall = SysTime()
	DIRECTOR_CLIENT_TICK( flHUDPaintTime )
end )
local flLastPreDrawHUDCall, flPreDrawHUDTime = SysTime(), 0
hook.Add( "PreDrawHUD", "Director", function()
	local t = SysTime() - flLastPreDrawHUDCall
	flPreDrawHUDTime = math.Approach( flPreDrawHUDTime, t, .1 )
	flLastPreDrawHUDCall = SysTime()
	DIRECTOR_CLIENT_TICK( flPreDrawHUDTime )
end )
local flLastPostDrawHUDCall, flPostDrawHUDTime = SysTime(), 0
hook.Add( "PostDrawHUD", "Director", function()
	local t = SysTime() - flLastPostDrawHUDCall
	flPostDrawHUDTime = math.Approach( flPostDrawHUDTime, t, .1 )
	flLastPostDrawHUDCall = SysTime()
	DIRECTOR_CLIENT_TICK( flPostDrawHUDTime )
end )
local flLastDrawOverlayCall, flDrawOverlayTime = SysTime(), 0
hook.Add( "DrawOverlay", "Director", function()
	local t = SysTime() - flLastDrawOverlayCall
	flDrawOverlayTime = math.Approach( flDrawOverlayTime, t, .1 )
	flLastDrawOverlayCall = SysTime()
	DIRECTOR_CLIENT_TICK( flDrawOverlayTime )
end )
local flLastPreDrawEffectsCall, flPreDrawEffectsTime = SysTime(), 0
hook.Add( "PreDrawEffects", "Director", function()
	local t = SysTime() - flLastPreDrawEffectsCall
	flPreDrawEffectsTime = math.Approach( flPreDrawEffectsTime, t, .1 )
	flLastPreDrawEffectsCall = SysTime()
	DIRECTOR_CLIENT_TICK( flPreDrawEffectsTime )
end )
local flLastPostDrawEffectsCall, flPostDrawEffectsTime = SysTime(), 0
hook.Add( "PostDrawEffects", "Director", function()
	local t = SysTime() - flLastPostDrawEffectsCall
	flPostDrawEffectsTime = math.Approach( flPostDrawEffectsTime, t, .1 )
	flLastPostDrawEffectsCall = SysTime()
	DIRECTOR_CLIENT_TICK( flPostDrawEffectsTime )
end )
local flLastPreDrawViewModelCall, flPreDrawViewModelTime = SysTime(), 0
hook.Add( "PreDrawViewModel", "Director", function()
	local t = SysTime() - flLastPreDrawViewModelCall
	flPreDrawViewModelTime = math.Approach( flPreDrawViewModelTime, t, .1 )
	flLastPreDrawViewModelCall = SysTime()
	DIRECTOR_CLIENT_TICK( flPreDrawViewModelTime )
end )
local flLastThinkCall, flThinkTime = SysTime(), 0
hook.Add( "Think", "Director", function()
	local t = SysTime() - flLastThinkCall
	flThinkTime = math.Approach( flThinkTime, t, .1 )
	flLastThinkCall = SysTime()
	DIRECTOR_CLIENT_TICK( flThinkTime )
end )
local flLastTickCall, flTickTime = SysTime(), 0
hook.Add( "Tick", "Director", function()
	local t = SysTime() - flLastTickCall
	flTickTime = math.Approach( flTickTime, t, .1 )
	flLastTickCall = SysTime()
	DIRECTOR_CLIENT_TICK( flTickTime )
end )
local flLastRenderScreenspaceEffectsCall, flRenderScreenspaceEffectsTime = SysTime(), 0
hook.Add( "RenderScreenspaceEffects", "Director", function()
	local t = SysTime() - flLastRenderScreenspaceEffectsCall
	flRenderScreenspaceEffectsTime = math.Approach( flRenderScreenspaceEffectsTime, t, .1 )
	flLastRenderScreenspaceEffectsCall = SysTime()
	DIRECTOR_CLIENT_TICK( flRenderScreenspaceEffectsTime )
end )
