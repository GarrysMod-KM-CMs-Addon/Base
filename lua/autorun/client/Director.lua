include "autorun/Director.lua"

timer.Simple( 0, function() GAMEMODE.DrawDeathNotice = nil end )

local sound_Add = sound.Add
local CHAN_STATIC = CHAN_STATIC
function Director_Music( sName, sPath )
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
				if math_Rand( 0, 150000 * FrameTime() ) <= 1 then
					local _, s = table.Random( DIRECTOR_MUSIC_IDLE_SEQUENCES )
					if s then Director_Music_Play( self, "Main", s ) end
				end
			end
		end }
	},
	[ DIRECTOR_THREAT_HEAT ] = {},
	[ DIRECTOR_THREAT_ALERT ] = {},
	[ DIRECTOR_THREAT_HOLD_FIRE ] = {},
	[ DIRECTOR_THREAT_COMBAT ] = {},
	[ DIRECTOR_THREAT_MAGIC ] = {}
}

function Director_Music_Container()
	return {
		tHandles = {},
		m_flVolume = 0
	}
end

local LocalPlayer = LocalPlayer
// local game_GetWorld = game.GetWorld
local table_insert = table.insert
function Director_Music_Play( self, Index, sName, flVolume, flPitch )
	// local pSound = CreateSound( game_GetWorld(), sName )
	local pSound = CreateSound( LocalPlayer(), sName )
	flVolume = flVolume || 1
	flPitch = flPitch || 100
	pSound:PlayEx( math.max( SOUND_PATCH_ABSOLUTE_MINIMUM, flVolume * self.m_flVolume ), flPitch )
	self.tHandles[ Index ] = { pSound, flVolume, flPitch, RealTime() + SoundDuration( sound.GetProperties( sName ).sound ) }
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
DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT.Default_Fade = { Execute = function( self, flVolumeA, flVolumeB, bCorrect )
	if !bCorrect then return true end
	if flVolumeA > 0 then
		flVolumeA = flVolumeA < .1 && math.Approach( flVolumeA, 0, FrameTime() ) || Lerp( .1 * FrameTime(), flVolumeA, 0 )
		return false, flVolumeA, flVolumeB
	end
	if self.m_ELayerTo == DIRECTOR_THREAT_NULL then return true end
	if flVolumeB == 1 then return true end
	flVolumeB = flVolumeB > .9 && math.Approach( flVolumeB, 1, FrameTime() ) || Lerp( .1 * FrameTime(), flVolumeB, 1 )
	return false, 0, flVolumeB
end }
function Director_Music_UpdateInternal( self, ... )
	local tNewHandles = {}
	local flVolume = self.m_flVolume
	for Index, tData in pairs( self.tHandles ) do
		if RealTime() > tData[ 4 ] then tData[ 1 ]:Stop() continue end
		tNewHandles[ Index ] = tData
		local pSound = tData[ 1 ]
		pSound:ChangeVolume( math.max( SOUND_PATCH_ABSOLUTE_MINIMUM, flVolume * tData[ 2 ] ) )
		pSound:ChangePitch( tData[ 3 ] )
	end
	self.tHandles = tNewHandles
	return self.m_pTable.Execute( self, ... )
end

DIRECTOR_MUSIC_INTENSITY = 0 // Intensity right now
DIRECTOR_MUSIC_TENSION = 0 // General battle intensity

DIRECTOR_THREAT = DIRECTOR_THREAT || DIRECTOR_THREAT_NULL
DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_MUSIC_LAST_THREAT || DIRECTOR_THREAT_NULL

DIRECTOR_MUSIC = DIRECTOR_MUSIC || {}

function Director_VoiceLineHook(
		flDuration ) // sName - This is actually a String of the sound's name ( Data.SoundName )
	flDuration = SoundDuration( flDuration )
	if !flDuration then return end
	DIRECTOR_MUSIC_VO_TIME = RealTime() + math.min( flDuration, 8 ) + DIRECTOR_MUSIC_VO_WAIT
	DIRECTOR_MUSIC_IN_VO = true
	DIRECTOR_MUSIC_IN_VO_HF = nil
end

function Director_VoiceLineHookToCombat( flDuration )
	if DIRECTOR_TRANSITION && DIRECTOR_TRANSITION.m_bIntroOfATrack then return end
	flDuration = SoundDuration( flDuration )
	if !flDuration then return end
	DIRECTOR_MUSIC_VO_TIME = RealTime() + math.min( flDuration, 8 )
	DIRECTOR_MUSIC_IN_VO = true
	DIRECTOR_MUSIC_IN_VO_HF = true
end

local LocalPlayer = LocalPlayer
hook.Add( "RenderScreenspaceEffects", "Director", function()
	local ply = LocalPlayer()
	for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
		if !DIRECTOR_MUSIC[ ELayer ] then
			local t = table.Random( DIRECTOR_MUSIC_TABLE[ ELayer ] )
			if t then
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
	// This thing is so important that we ignore voiceline pauses, too!
	if DIRECTOR_THREAT == DIRECTOR_THREAT_MAGIC then
		local bAllReady = true
		for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
			local pContainer = DIRECTOR_MUSIC[ ELayer ]
			if pContainer then
				if ELayer != DIRECTOR_THREAT_MAGIC then
					if table.IsEmpty( pContainer.tHandles ) || pContainer.m_flVolume <= 0 then
						pContainer.m_flVolume = 0
					else bAllReady = nil end
				end
				Director_Music_UpdateInternal( pContainer )
				pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, FrameTime() * .1 )
			end
		end
		if bAllReady then
			for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
				local pContainer = DIRECTOR_MUSIC[ ELayer ]
				if pContainer then
					Director_Music_UpdateInternal( pContainer )
					pContainer.m_flVolume = ELayer == DIRECTOR_THREAT_MAGIC && 1 || 0
				end
			end
			DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_THREAT_COMBAT
		end
		return
	elseif DIRECTOR_MUSIC_IN_VO then
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
						Director_Music_UpdateInternal( pContainer )
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
						Director_Music_UpdateInternal( pContainer )
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
						Director_Music_UpdateInternal( pContainer )
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
		local bDone, flVolumeA, flVolumeB = Director_Music_UpdateInternal( DIRECTOR_TRANSITION, flInitialVolumeA || 0, flInitialVolumeB || 0, b )
		DIRECTOR_MUSIC_LAST_THREAT = ELayerTo
		flVolumeA = flVolumeA || 0
		flVolumeB = flVolumeB || 1
		if bDone then DIRECTOR_TRANSITION = nil end
		for ELayer, pContainer in pairs( DIRECTOR_MUSIC ) do
			if pContainer then
				Director_Music_UpdateInternal( pContainer )
				if ELayer == ELayerFrom then
					pContainer.m_flVolume = flVolumeA
				elseif ELayer == ELayerTo then
					pContainer.m_flVolume = flVolumeB
				else
					pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, FrameTime() )
				end
			end
		end
		return
	elseif DIRECTOR_THREAT == DIRECTOR_THREAT_HOLD_FIRE then
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
				Director_Music_UpdateInternal( pContainer )
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
				Director_Music_UpdateInternal( pContainer )
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
			Director_Music_UpdateInternal( pContainer )
			if ELayer == DIRECTOR_THREAT then
				pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 1, .1 * RealFrameTime() )
			else
				if table.IsEmpty( pContainer.tHandles ) || pContainer.m_flVolume <= 0 then pContainer.m_flVolume = 0 end
				Director_Music_UpdateInternal( pContainer )
				pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, RealFrameTime() * .1 )
				if pContainer.m_flVolume <= 0 && CurTime() > ( pContainer.m_flEndTime || 0 ) then DIRECTOR_MUSIC[ ELayer ] = nil end
			end
		end
	end
end )

hook.Add( "PostCleanupMap", "Director", function()
	table.Empty( DIRECTOR_MUSIC )
	DIRECTOR_TRANSITION = nil
	DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_THREAT_NULL
end )
