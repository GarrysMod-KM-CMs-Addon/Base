// TODO: Outros. I already have special outros, but not normal outros yet.

// NOTE: Heat and Alert might get better code sometime.
// Don't set something to both just 'cause "it should play during both in the game".
// Alert should get code that makes it transition into Heat if no one's aggressively searching.
// Register calm tracks into Heat (such as The Dread from SCP:CB), and
// aggressive ones (such as Tell Me the Opsuit's Not Flammable from Splinter Cell: Blacklist) into Alert.
// Aggressive search is unused for now, but is meant to be an aggressive search, like SWAT room breaching.
// suddenly jogging to cover and corner peeking even though you've already cleared there, etcetera.
// It should include near combat themes, like this: https://youtu.be/vv86Tm-Wrvs?list=RDvv86Tm-Wrvs&t=690
// Themes there can probably be added into Alert? I'm still not sure if and how I'm gonna
// make the themes change based on the PLAYER'S stealth intensity,
// it's more like that one dream idea you can do on words but can't do in real life 'cause you're too weak

include "autorun/Director.lua"

// Here are some weapon things that are too small to give them another file
VIEWMODEL_CAMERA_ANIMATIONS = VIEWMODEL_CAMERA_ANIMATIONS || {}

WPN_PISTOL = 1
WPN_RIFLE = 2
WPN_RIFLEUP = 3
WPN_SHOTGUN = 4
WPN_SNIPER = 5

DIRECTOR_MUSIC_TENSION = 0
DIRECTOR_THREAT = DIRECTOR_THREAT_NULL

timer.Simple( 0, function() GAMEMODE.DrawDeathNotice = nil end )

local sound_Add = sound.Add
local CHAN_STATIC = CHAN_STATIC
function RegisterTrack( sName, sPath )
	sound_Add {
		name = sName,
		channel = CHAN_STATIC,
		level = 0,
		sound = "#" .. sPath
	}
end

ENGINE_READ_SOUND = {}

local timer_Simple = timer.Simple

local CreateSound = CreateSound

local LocalPlayer = LocalPlayer

local math_Rand = math.Rand

function LoadTrackNow( sName )
	local ply = LocalPlayer()
	if !IsValid( LocalPlayer() ) || ENGINE_READ_SOUND[ sName ] then return end
	local pSound = CreateSound( ply, sName )
	pSound:PlayEx( SOUND_PATCH_ABSOLUTE_MINIMUM, 100 )
	timer_Simple( math_Rand( .05, .1 ), function() pSound:Stop() end )
	ENGINE_READ_SOUND[ sName ] = true
end

local LoadTrackNow = LoadTrackNow

function LoadTrack( sName )
	if !IsValid( LocalPlayer() ) || ENGINE_READ_SOUND[ sName ] then return end
	timer_Simple( math_Rand( .05, .1 ), function() LoadTrackNow( sName ) end )
end

// DO NOT!!! Touch any of these manually!
DIRECTOR_NUM_NULL_THEMES = 0
DIRECTOR_NUM_HEAT_THEMES = DIRECTOR_NUM_HEAT_THEMES || 0
DIRECTOR_NUM_ALERT_THEMES = DIRECTOR_NUM_ALERT_THEMES || 0
DIRECTOR_NUM_AGGRESSIVE_SEARCH_THEMES = DIRECTOR_NUM_AGGRESSIVE_SEARCH_THEMES || 0
DIRECTOR_NUM_HOLD_FIRE_THEMES = DIRECTOR_NUM_HOLD_FIRE_THEMES || 0
DIRECTOR_NUM_COMBAT_THEMES = DIRECTOR_NUM_COMBAT_THEMES || 0

// The director will never play the same table pointer twice, for your convenience. However, there is still
// one way to accidentally shoot yourself in the leg, and that is messing up your own pointers.
// If you want a theme to play in multiple states, MAKE SURE THAT THE TABLE POINTER IS THE SAME,
// to avoid it being in state A AND state B which would break it, as the director thinks they're different.
// As if it gets in state A and B at the same time, it will glitch violently, since both want the sound handle.
// But do not worry, as long as everything is done correctly (see example below), that will never happen.
// For example:
/*
local t = {
	Execute = function( self )
		if self.m_flVolume <= 0 then StopMusic( self, "Main" ) return end
		if !self.tHandles.Main then PlayMusic( self, "Main", "MUS_MyDoubleTrack" ) end
	end
}
DIRECTOR_ALLOCATE_HEAT_THEME( "DIRECTOR_TRACK_HEAT_MyDoubleTrack", t )
DIRECTOR_ALLOCATE_ALERT_THEME( "DIRECTOR_TRACK_ALERT_MyDoubleTrack", t )
*/

function DIRECTOR_ALLOCATE_HEAT_THEME( sName, tTable )
	local ECurrent = _G[ sName ]
	if ECurrent then
		DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_HEAT ][ ECurrent ] = tTable
		return
	end
	DIRECTOR_NUM_HEAT_THEMES = DIRECTOR_NUM_HEAT_THEMES + 1
	_G[ sName ] = DIRECTOR_NUM_HEAT_THEMES
	DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_HEAT ][ DIRECTOR_NUM_HEAT_THEMES ] = tTable
end

function DIRECTOR_ALLOCATE_ALERT_THEME( sName, tTable )
	local ECurrent = _G[ sName ]
	if ECurrent then
		DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_ALERT ][ ECurrent ] = tTable
		return
	end
	DIRECTOR_NUM_ALERT_THEMES = DIRECTOR_NUM_ALERT_THEMES + 1
	_G[ sName ] = DIRECTOR_NUM_ALERT_THEMES
	DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_ALERT ][ DIRECTOR_NUM_ALERT_THEMES ] = tTable
end

function DIRECTOR_ALLOCATE_AGGRESSIVE_SEARCH_THEME( sName, tTable )
	local ECurrent = _G[ sName ]
	if ECurrent then
		DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_AGGRESSIVE_SEARCH ][ ECurrent ] = tTable
		return
	end
	DIRECTOR_NUM_AGGRESSIVE_SEARCH_THEMES = DIRECTOR_NUM_AGGRESSIVE_SEARCH_THEMES + 1
	_G[ sName ] = DIRECTOR_NUM_AGGRESSIVE_SEARCH_THEMES
	DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_AGGRESSIVE_SEARCH ][ DIRECTOR_NUM_AGGRESSIVE_SEARCH_THEMES ] = tTable
end

function DIRECTOR_ALLOCATE_HOLD_FIRE_THEME( sName, tTable )
	local ECurrent = _G[ sName ]
	if ECurrent then
		DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_HOLD_FIRE ][ ECurrent ] = tTable
		return
	end
	DIRECTOR_NUM_HOLD_FIRE_THEMES = DIRECTOR_NUM_HOLD_FIRE_THEMES + 1
	_G[ sName ] = DIRECTOR_NUM_HOLD_FIRE_THEMES
	DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_HOLD_FIRE ][ DIRECTOR_NUM_HOLD_FIRE_THEMES ] = tTable
end

function DIRECTOR_ALLOCATE_COMBAT_THEME( sName, tTable )
	local ECurrent = _G[ sName ]
	if ECurrent then
		DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_COMBAT ][ ECurrent ] = tTable
		return
	end
	DIRECTOR_NUM_COMBAT_THEMES = DIRECTOR_NUM_COMBAT_THEMES + 1
	_G[ sName ] = DIRECTOR_NUM_COMBAT_THEMES
	DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_COMBAT ][ DIRECTOR_NUM_COMBAT_THEMES ] = tTable
end

DIRECTOR_MUSIC_TABLE = DIRECTOR_MUSIC_TABLE || {
	[ DIRECTOR_THREAT_NULL ] = {},
	[ DIRECTOR_THREAT_HEAT ] = {},
	[ DIRECTOR_THREAT_ALERT ] = {},
	[ DIRECTOR_THREAT_AGGRESSIVE_SEARCH ] = {},
	[ DIRECTOR_THREAT_HOLD_FIRE ] = {},
	[ DIRECTOR_THREAT_COMBAT ] = {}
}

local __VARNAME__ = {
	[ DIRECTOR_THREAT_NULL ] = "DIRECTOR_NUM_NULL_THEMES",
	[ DIRECTOR_THREAT_HEAT ] = "DIRECTOR_NUM_HEAT_THEMES",
	[ DIRECTOR_THREAT_ALERT ] = "DIRECTOR_NUM_ALERT_THEMES",
	[ DIRECTOR_THREAT_AGGRESSIVE_SEARCH ] = "DIRECTOR_NUM_AGGRESSIVE_SEARCH_THEMES",
	[ DIRECTOR_THREAT_HOLD_FIRE ] = "DIRECTOR_NUM_HOLD_FIRE_THEMES",
	[ DIRECTOR_THREAT_COMBAT ] = "DIRECTOR_NUM_COMBAT_THEMES"
}

function DirectorContainerInternal() return { tHandles = {}, m_flVolume = 0 } end
local DirectorContainerInternal = DirectorContainerInternal

local SysTime = SysTime
// local game_GetWorld = game.GetWorld
local table_insert = table.insert
function PlayMusic( self, Index, sName, flVolume, flPitch )
	// local pSound = CreateSound( game_GetWorld(), sName )
	local pSound = CreateSound( LocalPlayer(), sName )
	flVolume = flVolume || 1
	flPitch = flPitch || 100
	StopMusic( self, Index )
	pSound:PlayEx( math.max( SOUND_PATCH_ABSOLUTE_MINIMUM, flVolume * self.m_flVolume ), flPitch )
	self.tHandles[ Index ] = { pSound, flVolume, flPitch, SoundDuration( sound.GetProperties( sName ).sound ), SysTime(), sName }
end

function StopMusic( self, Index )
	if !self then return end
	local tHandles = self.tHandles
	local pSound = tHandles[ Index ]
	tHandles[ Index ] = nil
	if pSound then pSound[ 1 ]:Stop() end
end

RegisterTrack( "MUS_Transition_Instant", "Music/Default/Transition_Instant.wav" )

// We have switched to HOLD_FIRE... do we even need these anymore?
DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT = DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT || {}
DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT = DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT || {}

DIRECTOR_NUM_TRANSITIONS_TO_COMBAT = DIRECTOR_NUM_TRANSITIONS_TO_COMBAT || 0
DIRECTOR_NUM_TRANSITIONS_FROM_COMBAT = DIRECTOR_NUM_TRANSITIONS_FROM_COMBAT || 0

function DIRECTOR_ALLOCATE_TRANSITION_TO_COMBAT( sName, tTable )
	local ECurrent = _G[ sName ]
	if ECurrent then
		DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT[ ECurrent ] = tTable
		return
	end
	DIRECTOR_NUM_TRANSITIONS_TO_COMBAT = DIRECTOR_NUM_TRANSITIONS_TO_COMBAT + 1
	_G[ sName ] = DIRECTOR_NUM_TRANSITIONS_TO_COMBAT
	DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT[ DIRECTOR_NUM_TRANSITIONS_TO_COMBAT ] = tTable
end
function DIRECTOR_ALLOCATE_TRANSITION_FROM_COMBAT( sName, tTable )
	local ECurrent = _G[ sName ]
	if ECurrent then
		DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT[ ECurrent ] = tTable
		return
	end
	DIRECTOR_NUM_TRANSITIONS_FROM_COMBAT = DIRECTOR_NUM_TRANSITIONS_FROM_COMBAT + 1
	_G[ sName ] = DIRECTOR_NUM_TRANSITIONS_FROM_COMBAT
	DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT[ DIRECTOR_NUM_TRANSITIONS_FROM_COMBAT ] = tTable
end

DIRECTOR_ALLOCATE_TRANSITION_TO_COMBAT( "DIRECTOR_TRANSITION_TO_COMBAT_Instant", {
	Execute = function( self )
		if !self.tHandles.Main then
			if self.bPartStarted then
				self.sIndex = "Idle"
				self.bPartStarted = nil
				self.bA = nil
				return true
			end
			self.bPartStarted = true
			PlayMusic( self, "Main", "MUS_Transition_Instant" )
		end
		return false, 0, 1
	end
} )

DIRECTOR_ALLOCATE_TRANSITION_FROM_COMBAT( "DIRECTOR_TRANSITION_FROM_COMBAT_Fade", {
	Execute = function( self, flInterval, flVolumeA, flVolumeB, bCorrect )
		if !bCorrect then
			if flVolumeB > 0 then
				flVolumeB = flVolumeB < .1 && math.Approach( flVolumeB, 0, flInterval ) || Lerp( .1 * flInterval, flVolumeB, 0 )
				return false, flVolumeA, flVolumeB
			end
			if self.m_ELayerFrom == DIRECTOR_THREAT_NULL then return true end
			if flVolumeA >= 1 then return true end
			flVolumeA = flVolumeA > .9 && math.Approach( flVolumeA, 1, flInterval ) || Lerp( .1 * flInterval, flVolumeA, 1 )
			return false, 0, flVolumeA
		end
		if flVolumeA > 0 then
			flVolumeA = flVolumeA < .1 && math.Approach( flVolumeA, 0, flInterval ) || Lerp( .1 * flInterval, flVolumeA, 0 )
			return false, flVolumeA, flVolumeB
		end
		if self.m_ELayerTo == DIRECTOR_THREAT_NULL then return true end
		if flVolumeB >= 1 then return true end
		flVolumeB = flVolumeB > .9 && math.Approach( flVolumeB, 1, flInterval ) || Lerp( .1 * flInterval, flVolumeB, 1 )
		return false, 0, flVolumeB
	end
} )

local math_max = math.max
local pairs = pairs

LAST_DIRECTOR_CLIENT_TICK = SysTime()

function DirectorUpdateContainerInternal( self, ... )
	// This function repeats itself intentionally, because in continuous music playback,
	// even one tick is a lot of time, so we call this again to allow people to still write
	// code that passes playing to the next tick (like when changing the index),
	// since we also technically simulate the next tick
	local t = self.m_pTable
	local flInterval = SysTime() - LAST_DIRECTOR_CLIENT_TICK
	t.Execute( self, flInterval, ... )
	local tHandles = self.tHandles
	local flVolume = self.m_flVolume
	//	for Index, tData in pairs( tHandles ) do
	//		local pSound = tData[ 1 ]
	//		f = flVolume * tData[ 2 ]
	//		if f <= SOUND_PATCH_ABSOLUTE_MINIMUM then
	//			tData[ 5 ] = SysTime()
	//			pSound:ChangeVolume( SOUND_PATCH_ABSOLUTE_MINIMUM )
	//			pSound:ChangePitch( 0 )
	//			continue
	//		else
	//			pSound:ChangeVolume( f )
	//			pSound:ChangePitch( tData[ 3 ] )
	//		end
	//		local flPitch = pSound:GetPitch()
	//		local f = 0
	//		if flPitch > 0 then f = tData[ 4 ] - ( SysTime() - tData[ 5 ] ) * ( flPitch / 100 ) end
	//		if tData[ 4 ] <= flInterval then tHandles[ Index ] = nil tData[ 1 ]:Stop() continue end
	//		tData[ 4 ] = f
	//		tData[ 5 ] = SysTime()
	//	end
	local ply = LocalPlayer()
	local h = ply:Health() / ply:GetMaxHealth()
	if flVolume <= SOUND_PATCH_ABSOLUTE_MINIMUM then
		for Index, tData in pairs( tHandles ) do
			local pSound = tData[ 1 ]
			tData[ 5 ] = SysTime()
			pSound:ChangeVolume( SOUND_PATCH_ABSOLUTE_MINIMUM )
			pSound:ChangePitch( 0 )
		end
	else
		local flPitcher = ply:GetNW2Float( "BODY_flTerror", 0 )
		flPitcher = 1 - flPitcher * .2 - flPitcher * .6 * math.abs( math.sin( RealTime() * .1 ) )
		for Index, tData in pairs( tHandles ) do
			local pSound = tData[ 1 ]
			f = flVolume * tData[ 2 ]
			pSound:ChangeVolume( math_max( f, SOUND_PATCH_ABSOLUTE_MINIMUM ) )
			pSound:ChangePitch( tData[ 3 ] * flPitcher )
			local flPitch = pSound:GetPitch()
			local f = 0
			if flPitch > 0 then f = tData[ 4 ] - ( SysTime() - tData[ 5 ] ) * ( flPitch / 100 ) end
			if tData[ 4 ] <= flInterval then tHandles[ Index ] = nil tData[ 1 ]:Stop() continue end
			tData[ 4 ] = f
			tData[ 5 ] = SysTime()
		end
	end
	return t.Execute( self, flInterval, ... )
end

local DirectorUpdateContainerInternal = DirectorUpdateContainerInternal

// FIXME: Until I implement support for m_pContainerFrom instead of
// m_ELayerFrom, this is gonna break when one special changes to another
function DIRECTOR_BEGIN_SPECIAL( pTable )
	if DIRECTOR_SPECIAL then if pTable == DIRECTOR_SPECIAL.m_pTable then return end end
	local p = DirectorContainerInternal()
	p.m_pTable = pTable
	DIRECTOR_SPECIAL = p
end

// FIXME: Properly implement this whole thing, including outros
function DIRECTOR_END_SPECIAL()
	local t = DIRECTOR_SPECIAL.m_pTable
	local f = t.CheckOutro
	if f && f "Special" then
		DIRECTOR_SPECIAL_OUTRO = DirectorContainerInternal()
		DIRECTOR_SPECIAL_OUTRO.m_pTable = { Execute = t.Outro }
		DIRECTOR_SPECIAL_OUTRO.m_pSource = DIRECTOR_SPECIAL
		DIRECTOR_SPECIAL_OUTRO.m_flVolume = 1
		DIRECTOR_SPECIAL_OUTRO.m_bFromCombat = true
		DIRECTOR_SPECIAL_OUTRO.m_bOutroOfATrack = true
		DIRECTOR_SPECIAL_OUTRO.m_ELayerTo = DIRECTOR_THREAT
	else DIRECTOR_SPECIAL = nil DIRECTOR_SPECIAL_INTRO = nil DIRECTOR_SPECIAL_OUTRO = nil end
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
	DIRECTOR_MUSIC = {}
	DIRECTOR_TRANSITION = nil
	DIRECTOR_SPECIAL = nil
	DIRECTOR_SPECIAL_INTRO = nil
	DIRECTOR_SPECIAL_OUTRO = nil
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

local math_random = math.random

function DIRECTOR_CLIENT_TICK()
	// Not now! I'm a dumbass.
	// LAST_DIRECTOR_CLIENT_TICK = SysTime()
	local ply = LocalPlayer()
	if !IsValid( ply ) then LAST_DIRECTOR_CLIENT_TICK = SysTime() return end // NO!
	for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
		if !DIRECTOR_MUSIC[ ELayer ] then
			local t = DIRECTOR_MUSIC_TABLE[ ELayer ][ math_random( 1, _G[ __VARNAME__[ ELayer ] ] ) ]
			if t then
				local b
				for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
					local p = DIRECTOR_MUSIC[ ELayer ]
					if p && p.m_pTable == t then b = true break end
				end
				if b then continue end
				local p = DirectorContainerInternal()
				p.m_pTable = t
				p.m_flStartTime = CurTime()
				local f = p.Time
				p.m_flEndTime = f && f() || ( CurTime() + math_Rand( 120, 240 ) )
				DIRECTOR_MUSIC[ ELayer ] = p
			else
				local p = DirectorContainerInternal()
				p.m_pTable = { Execute = function() end }
				DIRECTOR_MUSIC[ ELayer ] = p
			end
		end
	end
	if DIRECTOR_SPECIAL then
		if !DIRECTOR_SPECIAL_INTRO then
			local t = DIRECTOR_SPECIAL.m_pTable
			local f = t.CheckIntro
			if f && f "Special" then
				DIRECTOR_SPECIAL_INTRO = DirectorContainerInternal()
				DIRECTOR_SPECIAL_INTRO.m_pTable = { Execute = t.Intro }
				DIRECTOR_SPECIAL_INTRO.m_pSource = DIRECTOR_SPECIAL
				DIRECTOR_SPECIAL_INTRO.m_flVolume = 1
				DIRECTOR_SPECIAL_INTRO.m_bToCombat = true
				DIRECTOR_SPECIAL_INTRO.m_bIntroOfATrack = true
				DIRECTOR_SPECIAL_INTRO.m_ELayerFrom = DIRECTOR_THREAT
				LAST_DIRECTOR_CLIENT_TICK = SysTime()
				return
			end
			LAST_DIRECTOR_CLIENT_TICK = SysTime()
			return
		elseif DIRECTOR_SPECIAL_INTRO != "DONE" then
			local ELayerFrom, ELayerTo, flInitialVolumeA, flInitialVolumeB = DIRECTOR_SPECIAL_INTRO.m_ELayerFrom, DIRECTOR_SPECIAL_INTRO.m_ELayerTo
			for ELayer, pContainer in pairs( DIRECTOR_MUSIC ) do
				if ELayer == ELayerFrom then flInitialVolumeA = pContainer.m_flVolume break end
			end
			local bDone, flVolumeA, flVolumeB = DirectorUpdateContainerInternal( DIRECTOR_SPECIAL_INTRO, flInitialVolumeA || 0, DIRECTOR_SPECIAL.m_flVolume || 0, true )
			DIRECTOR_MUSIC_LAST_THREAT = ELayerFrom
			flVolumeA = flVolumeA || 0
			flVolumeB = flVolumeB || 1
			if bDone then DIRECTOR_SPECIAL_INTRO = "DONE" end
			for ELayer, pContainer in pairs( DIRECTOR_MUSIC ) do
				if pContainer then
					if ELayer == ELayerFrom then
						pContainer.m_flVolume = flVolumeA
					else
						pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, SysTime() - LAST_DIRECTOR_CLIENT_TICK )
					end
					DirectorUpdateContainerInternal( pContainer )
				end
			end
			DIRECTOR_SPECIAL.m_flVolume = flVolumeB
			DirectorUpdateContainerInternal( DIRECTOR_SPECIAL )
			LAST_DIRECTOR_CLIENT_TICK = SysTime()
			return
		elseif DIRECTOR_SPECIAL_OUTRO then
			local ELayerFrom, ELayerTo, flInitialVolumeA, flInitialVolumeB = DIRECTOR_SPECIAL_OUTRO.m_ELayerFrom, DIRECTOR_SPECIAL_OUTRO.m_ELayerTo, DIRECTOR_SPECIAL.m_flVolume
			local bDone, flVolumeA, flVolumeB = DirectorUpdateContainerInternal( DIRECTOR_SPECIAL_OUTRO, flInitialVolumeA || 0, DIRECTOR_SPECIAL.m_flVolume || 0, true )
			DIRECTOR_MUSIC_LAST_THREAT = ELayerFrom
			flVolumeA = flVolumeA || 0
			flVolumeB = flVolumeB || 1
			if bDone then
				DIRECTOR_SPECIAL = nil
				DIRECTOR_SPECIAL_INTRO = nil
				DIRECTOR_SPECIAL_OUTRO = nil
				return
			end
			for ELayer, pContainer in pairs( DIRECTOR_MUSIC ) do
				if pContainer then
					if ELayer == ELayerFrom then
						pContainer.m_flVolume = flVolumeA
					else
						pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, SysTime() - LAST_DIRECTOR_CLIENT_TICK )
					end
					DirectorUpdateContainerInternal( pContainer )
				end
			end
			DIRECTOR_SPECIAL.m_flVolume = flVolumeA
			DirectorUpdateContainerInternal( DIRECTOR_SPECIAL )
			LAST_DIRECTOR_CLIENT_TICK = SysTime()
			return
		end
		for ELayer, pContainer in pairs( DIRECTOR_MUSIC ) do
			if pContainer then
				pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, SysTime() - LAST_DIRECTOR_CLIENT_TICK )
				DirectorUpdateContainerInternal( pContainer )
			end
		end
		DIRECTOR_SPECIAL.m_flVolume = math.Approach( DIRECTOR_SPECIAL.m_flVolume, 1, SysTime() - LAST_DIRECTOR_CLIENT_TICK )
		DirectorUpdateContainerInternal( DIRECTOR_SPECIAL )
		LAST_DIRECTOR_CLIENT_TICK = SysTime()
		return
	elseif DIRECTOR_MUSIC_IN_VO && ( !DIRECTOR_TRANSITION || !DIRECTOR_TRANSITION.m_bIntroOfATrack ) then
		DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_THREAT_COMBAT
		if DIRECTOR_MUSIC_IN_VO_HF then
			// Doesn't work like that anymore!
			//	local t = DIRECTOR_MUSIC[ DIRECTOR_THREAT_COMBAT ].m_pTable
			//	local f = t.CheckIntro
			//	if f && f "HoldFire" then
			//		DIRECTOR_MUSIC_IN_VO = nil
			//		DIRECTOR_TRANSITION = DirectorContainerInternal()
			//		DIRECTOR_TRANSITION.m_pTable = { Execute = t.Intro }
			//		DIRECTOR_TRANSITION.m_flVolume = 1
			//		DIRECTOR_TRANSITION.m_bToCombat = true
			//		DIRECTOR_TRANSITION.m_ELayerFrom = DIRECTOR_THREAT_HOLD_FIRE
			//		DIRECTOR_TRANSITION.m_ELayerTo = DIRECTOR_THREAT_COMBAT
			//		DIRECTOR_TRANSITION.m_bIntroOfATrack = true
			//		DIRECTOR_THREAT = DIRECTOR_THREAT_COMBAT
			//		net.Start "DR_ClientWantsToBeInCombat" net.SendToServer()
			//		LAST_DIRECTOR_CLIENT_TICK = SysTime()
			//		return
			//	end
			DIRECTOR_MUSIC_WAS_HOLD_FIRE = true
			if RealTime() <= DIRECTOR_MUSIC_VO_TIME then
				for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
					local pContainer = DIRECTOR_MUSIC[ ELayer ]
					if pContainer then
						DirectorUpdateContainerInternal( pContainer )
						if ELayer == DIRECTOR_THREAT_HOLD_FIRE then
							pContainer.m_flVolume = 1
						else pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, SysTime() - LAST_DIRECTOR_CLIENT_TICK ) end
					end
				end
				local pCombat = DIRECTOR_MUSIC[ DIRECTOR_THREAT_COMBAT ]
				if pCombat then pCombat.m_pTable.Load( pCombat ) end
			else
				local pSource = DIRECTOR_MUSIC[ DIRECTOR_THREAT_COMBAT ]
				local t = pSource.m_pTable
				local f = t.CheckIntro
				if f && f "HoldFire" then
					DIRECTOR_MUSIC_IN_VO = nil
					DIRECTOR_TRANSITION = DirectorContainerInternal()
					DIRECTOR_TRANSITION.m_pTable = { Execute = t.Intro }
					DIRECTOR_TRANSITION.m_pSource = pSource
					DIRECTOR_TRANSITION.m_flVolume = 1
					DIRECTOR_TRANSITION.m_bToCombat = true
					DIRECTOR_TRANSITION.m_ELayerFrom = DIRECTOR_THREAT_HOLD_FIRE
					DIRECTOR_TRANSITION.m_ELayerTo = DIRECTOR_THREAT_COMBAT
					DIRECTOR_TRANSITION.m_bIntroOfATrack = true
					DIRECTOR_THREAT = DIRECTOR_THREAT_COMBAT
					net.Start "DR_ClientWantsToBeInCombat" net.SendToServer()
					LAST_DIRECTOR_CLIENT_TICK = SysTime()
					return
				end
				DIRECTOR_MUSIC_IN_VO = nil
			end
		else
			if RealTime() > DIRECTOR_MUSIC_VO_TIME then
				DIRECTOR_MUSIC_IN_VO = nil
				DIRECTOR_TRANSITION = nil
				for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
					local pContainer = DIRECTOR_MUSIC[ ELayer ]
					if pContainer then
						DirectorUpdateContainerInternal( pContainer )
						if ELayer == DIRECTOR_THREAT_HOLD_FIRE then
							pContainer.m_flVolume = 1
						else pContainer.m_flVolume = 0 end
					end
				end
				local pCombat = DIRECTOR_MUSIC[ DIRECTOR_THREAT_COMBAT ]
				if pCombat then pCombat.m_pTable.Load( pCombat ) end
			else
				if DIRECTOR_TRANSITION then
					if DIRECTOR_TRANSITION.m_flVolume <= 0 then
						DIRECTOR_TRANSITION = nil
					else
						DIRECTOR_TRANSITION.m_flVolume = math.Approach( DIRECTOR_TRANSITION.m_flVolume, 0, SysTime() - LAST_DIRECTOR_CLIENT_TICK )
					end
				end
				for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
					local pContainer = DIRECTOR_MUSIC[ ELayer ]
					if pContainer then
						DirectorUpdateContainerInternal( pContainer )
						pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, SysTime() - LAST_DIRECTOR_CLIENT_TICK )
					end
				end
				local pHoldFire = DIRECTOR_MUSIC[ DIRECTOR_THREAT_HOLD_FIRE ]
				if pHoldFire then pHoldFire.m_pTable.Load( pHoldFire ) end
			end
		end
		LAST_DIRECTOR_CLIENT_TICK = SysTime()
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
		local bDone, flVolumeA, flVolumeB = DirectorUpdateContainerInternal( DIRECTOR_TRANSITION, flInitialVolumeA || 0, flInitialVolumeB || 0, b )
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
					pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, SysTime() - LAST_DIRECTOR_CLIENT_TICK )
				end
				DirectorUpdateContainerInternal( pContainer )
			end
		end
		LAST_DIRECTOR_CLIENT_TICK = SysTime()
		return
	elseif DIRECTOR_THREAT == DIRECTOR_THREAT_HOLD_FIRE then
		local pSource = DIRECTOR_MUSIC[ DIRECTOR_THREAT_COMBAT ]
		// Doesn't work like that anymore!
		//	local t = pSource.m_pTable
		//	local f = t.CheckIntro
		//	if f && f "HoldFire" then
		//		DIRECTOR_TRANSITION = DirectorContainerInternal()
		//		DIRECTOR_TRANSITION.m_pTable = { Execute = t.Intro }
		//		DIRECTOR_TRANSITION.m_pSource = pSource
		//		DIRECTOR_TRANSITION.m_flVolume = 1
		//		DIRECTOR_TRANSITION.m_bToCombat = true
		//		DIRECTOR_TRANSITION.m_ELayerFrom = DIRECTOR_THREAT_HOLD_FIRE
		//		DIRECTOR_TRANSITION.m_ELayerTo = DIRECTOR_THREAT_COMBAT
		//		DIRECTOR_TRANSITION.m_bIntroOfATrack = true
		//		DIRECTOR_THREAT = DIRECTOR_THREAT_COMBAT
		//		DIRECTOR_MUSIC_WAS_HOLD_FIRE = nil
		//		net.Start "DR_ClientWantsToBeInCombat" net.SendToServer()
		//		LAST_DIRECTOR_CLIENT_TICK = SysTime()
		//		return
		//	end
		for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
			local pContainer = DIRECTOR_MUSIC[ ELayer ]
			if pContainer then
				if ELayer == DIRECTOR_THREAT then
					pContainer.m_flVolume = 1
				else pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, SysTime() - LAST_DIRECTOR_CLIENT_TICK ) end
				DirectorUpdateContainerInternal( pContainer )
			end
		end
		DIRECTOR_MUSIC_WAS_HOLD_FIRE = true
		if DIRECTOR_TRANSITION then
			if DIRECTOR_TRANSITION.m_flVolume <= 0 then
				DIRECTOR_TRANSITION = nil
			else
				DIRECTOR_TRANSITION.m_flVolume = math.Approach( DIRECTOR_TRANSITION.m_flVolume, 0, SysTime() - LAST_DIRECTOR_CLIENT_TICK )
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
				//		pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 1, SysTime() - LAST_DIRECTOR_CLIENT_TICK )
				//	else pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, SysTime() - LAST_DIRECTOR_CLIENT_TICK ) end
				DirectorUpdateContainerInternal( pContainer )
			end
		end
		DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_THREAT_COMBAT
		if DIRECTOR_TRANSITION then
			if DIRECTOR_TRANSITION.m_flVolume <= 0 then
				DIRECTOR_TRANSITION = nil
			else
				DIRECTOR_TRANSITION.m_flVolume = math.Approach( DIRECTOR_TRANSITION.m_flVolume, 0, SysTime() - LAST_DIRECTOR_CLIENT_TICK )
			end
		end
		LAST_DIRECTOR_CLIENT_TICK = SysTime()
		return
	end
	if DIRECTOR_MUSIC_LAST_THREAT < DIRECTOR_THREAT_COMBAT && DIRECTOR_THREAT >= DIRECTOR_THREAT_COMBAT then
		DIRECTOR_TRANSITION = DirectorContainerInternal()
		local t = DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT[ math_random( 1, DIRECTOR_NUM_TRANSITIONS_TO_COMBAT ) ]
		DIRECTOR_TRANSITION.m_pTable = t
		DIRECTOR_TRANSITION.m_flVolume = 1
		DIRECTOR_TRANSITION.m_bToCombat = true
		DIRECTOR_TRANSITION.m_ELayerFrom = DIRECTOR_MUSIC_LAST_THREAT
		DIRECTOR_TRANSITION.m_ELayerTo = DIRECTOR_THREAT
		LAST_DIRECTOR_CLIENT_TICK = SysTime()
		return
	elseif DIRECTOR_MUSIC_LAST_THREAT >= DIRECTOR_THREAT_COMBAT && DIRECTOR_THREAT < DIRECTOR_THREAT_COMBAT then
		DIRECTOR_TRANSITION = DirectorContainerInternal()
		local t = DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT[ math_random( 1, DIRECTOR_NUM_TRANSITIONS_FROM_COMBAT ) ]
		DIRECTOR_TRANSITION.m_pTable = t
		DIRECTOR_TRANSITION.m_flVolume = 1
		DIRECTOR_TRANSITION.m_ELayerFrom = DIRECTOR_MUSIC_LAST_THREAT
		DIRECTOR_TRANSITION.m_ELayerTo = DIRECTOR_THREAT
		LAST_DIRECTOR_CLIENT_TICK = SysTime()
		return
	end
	// Do NOT mistake this for the fade transition!
	// This is completely different, and used to fade between
	// idle/heat/alert tracks!
	for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
		local pContainer = DIRECTOR_MUSIC[ ELayer ]
		if pContainer then
			DirectorUpdateContainerInternal( pContainer )
			if ELayer == DIRECTOR_THREAT then
				pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 1, .1 * ( SysTime() - LAST_DIRECTOR_CLIENT_TICK ) )
			else
				if table.IsEmpty( pContainer.tHandles ) || pContainer.m_flVolume <= 0 then pContainer.m_flVolume = 0 end
				DirectorUpdateContainerInternal( pContainer )
				pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, .1 * ( SysTime() - LAST_DIRECTOR_CLIENT_TICK ) )
				if pContainer.m_flVolume <= 0 && CurTime() > ( pContainer.m_flEndTime || 0 ) then DIRECTOR_MUSIC[ ELayer ] = nil end
			end
		end
	end
	LAST_DIRECTOR_CLIENT_TICK = SysTime()
end

local flLastHUDShouldDrawCall, flHUDShouldDrawTime = SysTime(), 0
hook.Add( "HUDShouldDraw", "Director", function( sName )
	local t = SysTime() - flLastHUDShouldDrawCall
	flHUDShouldDrawTime = math.Approach( flHUDShouldDrawTime, t, .1 )
	flLastHUDShouldDrawCall = SysTime()
	DIRECTOR_CLIENT_TICK()
	return __HUD_SHOULD_NOT_DRAW__[ sName ] == nil
end )
local flLastHUDPaintCall, flHUDPaintTime = SysTime(), 0
hook.Add( "HUDPaint", "Director", function()
	local t = SysTime() - flLastHUDPaintCall
	flHUDPaintTime = math.Approach( flHUDPaintTime, t, .1 )
	flLastHUDPaintCall = SysTime()
	DIRECTOR_CLIENT_TICK()
end )
local flLastPreDrawHUDCall, flPreDrawHUDTime = SysTime(), 0
hook.Add( "PreDrawHUD", "Director", function()
	local t = SysTime() - flLastPreDrawHUDCall
	flPreDrawHUDTime = math.Approach( flPreDrawHUDTime, t, .1 )
	flLastPreDrawHUDCall = SysTime()
	DIRECTOR_CLIENT_TICK()
end )
local flLastPostDrawHUDCall, flPostDrawHUDTime = SysTime(), 0
hook.Add( "PostDrawHUD", "Director", function()
	local t = SysTime() - flLastPostDrawHUDCall
	flPostDrawHUDTime = math.Approach( flPostDrawHUDTime, t, .1 )
	flLastPostDrawHUDCall = SysTime()
	DIRECTOR_CLIENT_TICK()
end )
local flLastDrawOverlayCall, flDrawOverlayTime = SysTime(), 0
hook.Add( "DrawOverlay", "Director", function()
	local t = SysTime() - flLastDrawOverlayCall
	flDrawOverlayTime = math.Approach( flDrawOverlayTime, t, .1 )
	flLastDrawOverlayCall = SysTime()
	DIRECTOR_CLIENT_TICK()
end )
local flLastPreDrawEffectsCall, flPreDrawEffectsTime = SysTime(), 0
hook.Add( "PreDrawEffects", "Director", function()
	local t = SysTime() - flLastPreDrawEffectsCall
	flPreDrawEffectsTime = math.Approach( flPreDrawEffectsTime, t, .1 )
	flLastPreDrawEffectsCall = SysTime()
	DIRECTOR_CLIENT_TICK()
end )
local flLastPostDrawEffectsCall, flPostDrawEffectsTime = SysTime(), 0
hook.Add( "PostDrawEffects", "Director", function()
	local t = SysTime() - flLastPostDrawEffectsCall
	flPostDrawEffectsTime = math.Approach( flPostDrawEffectsTime, t, .1 )
	flLastPostDrawEffectsCall = SysTime()
	DIRECTOR_CLIENT_TICK()
end )
local flLastPreDrawViewModelCall, flPreDrawViewModelTime = SysTime(), 0
hook.Add( "PreDrawViewModel", "Director", function()
	local t = SysTime() - flLastPreDrawViewModelCall
	flPreDrawViewModelTime = math.Approach( flPreDrawViewModelTime, t, .1 )
	flLastPreDrawViewModelCall = SysTime()
	DIRECTOR_CLIENT_TICK()
end )
local flLastThinkCall, flThinkTime = SysTime(), 0
hook.Add( "Think", "Director", function()
	local t = SysTime() - flLastThinkCall
	flThinkTime = math.Approach( flThinkTime, t, .1 )
	flLastThinkCall = SysTime()
	DIRECTOR_CLIENT_TICK()
end )
local flLastTickCall, flTickTime = SysTime(), 0
hook.Add( "Tick", "Director", function()
	local t = SysTime() - flLastTickCall
	flTickTime = math.Approach( flTickTime, t, .1 )
	flLastTickCall = SysTime()
	DIRECTOR_CLIENT_TICK()
end )
local flLastRenderScreenspaceEffectsCall, flRenderScreenspaceEffectsTime = SysTime(), 0
hook.Add( "RenderScreenspaceEffects", "Director", function()
	local t = SysTime() - flLastRenderScreenspaceEffectsCall
	flRenderScreenspaceEffectsTime = math.Approach( flRenderScreenspaceEffectsTime, t, .1 )
	flLastRenderScreenspaceEffectsCall = SysTime()
	DIRECTOR_CLIENT_TICK()
end )
