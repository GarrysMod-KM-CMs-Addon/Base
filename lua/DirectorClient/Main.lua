// Internal - the heart of the DirectorClient, you might want to include DirectorClient instead

include "autorun/DirectorShared.lua"

// Use DirectorSpecial( nil ) to resume normal playing
function DirectorSpecial( pTrack ) DIRECTOR_SPECIAL = pTrack end

g_pDirectorStateData = g_pDirectorStateData || {}

DIRECTOR_STREAM_FLAGS = "noplay noblock"

function DirectorSetStateInternal( pState )
	g_pDirectorStateData = {}
	g_pDirectorStateVariable = pState
end

local random = math.random

local PlayFile = sound.PlayFile

local timer_Simple = timer.Simple

local SysTime = SysTime

local SoundDuration = SoundDuration

local yield = coroutine.yield

// This... works... for... some... reason???
DIRECTOR_HOLD_TIME = 9.5

function DRSTV_QuietRiser()
	local pTrack = g_pDirectorStateData.pTrack

	local pData = pTrack.pData
	local pComponents = pData.Components

	local pRisers = pData.IntroTypes.QuietRiser
	local sRiser = pRisers[ random( 1, #pRisers ) ]

	local pRiser = pComponents[ sRiser ]

	local pStation
	PlayFile( "sound/" .. pRiser.File, DIRECTOR_STREAM_FLAGS, function( pHere ) pStation = pHere end )
	while pStation == nil do yield() end
	pStation:Play()
	local flLength = SoundDuration( pRiser.File )

	local pNext = pRiser.Next
	local sNext = pNext[ math.random( 1, #pNext ) ]
	pNext = pComponents[ sNext ]

	local pNextStation
	sound.PlayFile( "sound/" .. pNext.File, DIRECTOR_STREAM_FLAGS, function( pHere ) pNextStation = pHere end )
	while pNextStation == nil do yield() end
	local flNextLength = SoundDuration( pNext.File )

	local pSpecial, pNextStationSpecial = pNext.Special
	sound.PlayFile( "sound/" .. pSpecial.File, DIRECTOR_STREAM_FLAGS, function( pHere ) pNextStationSpecial = pHere end )
	while pNextStationSpecial == nil do yield() end

	local flLastCall = SysTime()
	local flTimeBetweenCalls = 0
	while pStation:GetTime() + flTimeBetweenCalls * DIRECTOR_HOLD_TIME < flLength do
		flTimeBetweenCalls = ( flTimeBetweenCalls + SysTime() - flLastCall ) * .5
		flLastCall = SysTime()
		yield()
	end
	timer_Simple( .1, function() local _ = pStation end )

	DirectorSetStateInternal( DRSTV_HitsWithSpecial )
	g_pDirectorStateData.pTrack = pTrack
	g_pDirectorStateData.sLoadedCurrent = sNext
	g_pDirectorStateData.pLoadedCurrent = pNextStation
	g_pDirectorStateData.pLoadedCurrentSpecial = pNextStationSpecial
	g_pDirectorStateData.flLoadedCurrentTime = flNextLength
end

function DRSTV_HitsWithSpecial()
	local pTrack = g_pDirectorStateData.pTrack

	local pLoadedCurrent = g_pDirectorStateData.pLoadedCurrent
	local flLoadedCurrentTime = g_pDirectorStateData.flLoadedCurrentTime
	local pLoadedCurrentSpecial = g_pDirectorStateData.pLoadedCurrentSpecial

	local flNormal, flSpecial = g_pDirectorStateData.flNormal || 1, g_pDirectorStateData.flSpecial || 0

	pLoadedCurrent:Play()
	pLoadedCurrentSpecial:SetVolume( 0 )
	pLoadedCurrentSpecial:Play()

	local pData = pTrack.pData
	local pComponents = pData.Components

	local pCurrent = pComponents[ g_pDirectorStateData.sLoadedCurrent ]

	local pNext
	local sIs = pCurrent.Is
	if sIs then pNext = pComponents[ sIs ].Next
	else pNext = pCurrent.Next end

	local sNext = pNext[ math.random( 1, #pNext ) ]
	pNext = pComponents[ sNext ]
	if pNext.Loop then
		sNext = pNext.Loop
		pNext = pComponents[ sNext ]
	end

	local pNextStation
	PlayFile( "sound/" .. pNext.File, DIRECTOR_STREAM_FLAGS, function( pHere ) pNextStation = pHere end )
	while pNextStation == nil do yield() end
	local flNextLength = SoundDuration( pNext.File )

	local pSpecial, pNextStationSpecial = pNext.Special
	PlayFile( "sound/" .. pSpecial.File, DIRECTOR_STREAM_FLAGS, function( pHere ) pNextStationSpecial = pHere end )
	while pNextStationSpecial == nil do yield() end

	local flLastCall = SysTime()
	local flTimeBetweenCalls = 0
	while pLoadedCurrent:GetTime() + flTimeBetweenCalls * DIRECTOR_HOLD_TIME < flLoadedCurrentTime do
		pLoadedCurrentSpecial:SetTime( pLoadedCurrent:GetTime() )

		pLoadedCurrent:SetVolume( flNormal )
		pLoadedCurrentSpecial:SetVolume( flSpecial )

		flTimeBetweenCalls = ( flTimeBetweenCalls + SysTime() - flLastCall ) * .5
		flLastCall = SysTime()

		yield()
	end
	timer_Simple( .1, function() local _ = pLoadedCurrent, pLoadedCurrentSpecial end )

	DirectorSetStateInternal( DRSTV_HitsWithSpecial )
	g_pDirectorStateData.flNormal = flNormal
	g_pDirectorStateData.flSpecial = flSpecial
	g_pDirectorStateData.pTrack = pTrack
	g_pDirectorStateData.sLoadedCurrent = sNext
	g_pDirectorStateData.pLoadedCurrent = pNextStation
	g_pDirectorStateData.pLoadedCurrentSpecial = pNextStationSpecial
	g_pDirectorStateData.flLoadedCurrentTime = flNextLength
end

function DRSTV_PlayFromNull()
	local pTrack = g_pDirectorStateData.pTrack

	local pData = pTrack.pData

	local pIntroTypes = pData.IntroTypes
	if pIntroTypes then
		local pQuietRisers = pIntroTypes.QuietRiser
		if pQuietRisers then
			DirectorSetStateInternal( DRSTV_QuietRiser )
			g_pDirectorStateData.pTrack = pTrack
		end
	end
end

function DRSTV_Null()
	if DIRECTOR_SPECIAL then
		DirectorSetStateInternal( DRSTV_PlayFromNull )
		g_pDirectorStateData.pTrack = DIRECTOR_SPECIAL
	end
end

g_pDirectorStateVariable = g_pDirectorStateVariable || DRSTV_Null
//	g_pDirectorStateVariable = DRSTV_Null

hook.Add( "PostCleanupMap", "Director", function()
	g_pDirectorStateVariable = DRSTV_Null
	g_pDirectorStateData = {}
	g_pDirectorCoroutine = nil
end )

local function RunStateVariable() g_pDirectorStateVariable() end

local coroutine_status = coroutine.status
local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume

g_pDirectorCoroutine = coroutine_create( RunStateVariable )

function DIRECTOR_CLIENT_TICK()
	if !g_pDirectorCoroutine || coroutine_status( g_pDirectorCoroutine ) == "dead" then g_pDirectorCoroutine = coroutine_create( RunStateVariable ) end

	local bError, sResult = coroutine_resume( g_pDirectorCoroutine )
	if !bError then
		ErrorNoHaltWithStack( sResult )
		g_pDirectorCoroutine = nil
	end
end

include "Loaders.lua"
