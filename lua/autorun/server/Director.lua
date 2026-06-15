local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local player_Iterator = player.Iterator
local IsValid = IsValid
local Vector = Vector
local util_Decal = util.Decal
local math_Rand = math.Rand
local LerpVector = LerpVector
local VECTOR_DOWN = Vector( 0, 0, -1 )
local math_abs = math.abs
local math_AngleDifference = math.AngleDifference
local math_Approach = math.Approach
local math_max = math.max
local math_min = math.min
local util_TraceLine = util.TraceLine
local MASK_SHOT_HULL = MASK_SHOT_HULL
local CEntity_SetNW2Int = CEntity.SetNW2Int
local math_Clamp = math.Clamp
local Lerp = Lerp
local CEntity_SetNW2Float = CEntity.SetNW2Float
local DamageInfo = DamageInfo
local DMG_DROWN = DMG_DROWN
local CurTime = CurTime
local CEntity_GetNW2Float = CEntity.GetNW2Float
local math_exp = math.exp
local FrameTime = FrameTime
local RealTime = RealTime
local math_Rand = math.Rand
local CEntity_SetNW2Vector = CEntity.SetNW2Vector
local CEntity_SetNW2Bool = CEntity.SetNW2Bool
local tostring = tostring
local ents_FindInPVS = ents.FindInPVS
local math_random = math.random

include "autorun/Director.lua"

util.AddNetworkString "DR_ClientWantsToBeInCombat"

net.Receive( "DR_ClientWantsToBeInCombat", function( _, ply )
	if ply.DR_EThreat == DIRECTOR_THREAT_HOLD_FIRE then
		ply.DR_EThreat = DIRECTOR_THREAT_COMBAT
	end
end )

function Director_GetThreat( pPlayer, pEntity )
	if IsValid( pEntity.Enemy ) then return DIRECTOR_THREAT_HOLD_FIRE end
	local f = pEntity.GetEnemy
	if f && IsValid( f( pEntity ) ) then return DIRECTOR_THREAT_HOLD_FIRE end
	local f = pEntity.GetNPCState
	if f then
		f = f( pEntity )
		if f == NPC_STATE_COMBAT then
			return DIRECTOR_THREAT_HOLD_FIRE
		elseif f == NPC_STATE_ALERT then
			return DIRECTOR_THREAT_ALERT
		else
			local f = pEntity.Disposition
			if f then
				f = f( pEntity, pPlayer )
				if f == D_FR || f == D_HT then return DIRECTOR_THREAT_HEAT end
			end
		end
	else
		local f = pEntity.Disposition
		if f then
			f = f( pEntity, pPlayer )
			if f == D_FR || f == D_HT then return DIRECTOR_THREAT_HEAT end
		end
	end
	return DIRECTOR_THREAT_NULL
end

local cVisibleHostileReinforcementCountDown = CreateConVar(
	"bVisibleHostileReinforcementCountDown",
	1,
	FCVAR_NEVER_AS_STRING,
	"Allow clients to see how much is left until enemy reinforcements?",
	0, 1
)

local VectorZ28 = Vector( 0, 0, 28 )
hook.Add( "Tick", "Director", function()
	for _, ply in player_Iterator() do
		local PlyTable = CEntity_GetTable( ply )
		local pFlashlight = PlyTable.GAME_pFlashlight
		local vEyePos = ply:EyePos()
		local aAim = ply:EyeAngles()
		local aViewPunch = ply:GetViewPunchAngles()
		aAim:Add( aViewPunch )
		local dAim = aAim:Forward()
		if IsValid( pFlashlight ) then
			pFlashlight:SetPos( vEyePos + dAim * 32 )
			pFlashlight:SetLocalAngles( aViewPunch )
		end
		local vShoot = ply:GetShootPos()
		local trShoot = util_TraceLine {
			start = vShoot,
			endpos = vShoot + dAim * 1536,
			filter = ply,
			mask = MASK_SHOT_HULL
		}
		local b = true
		local pEntity = trShoot.Entity
		if IsValid( pEntity ) then
			local f = pEntity.Disposition
			if f then
				f = f( pEntity, ply )
				if f == D_LI then
					CEntity_SetNW2Int( ply, "DR_EAimingAt", 2 )
					b = nil
				else
					CEntity_SetNW2Int( ply, "DR_EAimingAt", 1 )
					b = nil
				end
			end
		end
		if b then CEntity_SetNW2Int( ply, "DR_EAimingAt", nil ) end
		local flReinforcements, bAlarm, bAlarmCoolDown
		local b = !cVisibleHostileReinforcementCountDown:GetBool()
		for pEntity in pairs( __ALARMS_ACTIVE__ ) do
			if !IsValid( pEntity ) then continue end
			if pEntity:NearestPoint( vEyePos ):DistToSqr( vEyePos ) > 16777216/*4096*/ then continue end
			bAlarm = true
			if b then continue end
			if pEntity:Classify() != ply:Classify() then
				local flStart, flEnd = pEntity.flReinforcementStartTime, pEntity.flReinforcementEndTime
				if flStart && flEnd then
					flReinforcements = math_min( 1 - ( CurTime() - flStart ) / ( flEnd - flStart ), flReinforcements || 1 )
				end
				local f = pEntity.flCoolDown
				if f && CurTime() < f then bAlarmCoolDown = true end
			end
		end
		CEntity_SetNW2Float( ply, "ALARM_flHostileReinforcements", flReinforcements || 0 )
		CEntity_SetNW2Float( ply, "DIRECTOR_MUSIC_VO_WAIT", math_Clamp( Lerp( math_min( 1, .5 * FrameTime() ), ply:GetNW2Float( "DIRECTOR_MUSIC_VO_WAIT", DIRECTOR_MUSIC_VO_WAIT ), DIRECTOR_MUSIC_VO_WAIT ), 0, DIRECTOR_MUSIC_VO_WAIT ) )
		CEntity_SetNW2Float( ply, "GAME_flOxygenLimit", PlyTable.GAME_flOxygenLimit || 72 )
		if ply:Alive() then
			local o = CEntity_GetNW2Float( ply, "GAME_flOxygen", CEntity_GetNW2Float( ply, "GAME_flOxygenLimit", -1 ) )
			if o == 0 then
				ply:SetHealth( 0 )
				local d = DamageInfo()
				d:SetAttacker( ply )
				d:SetInflictor( ply )
				d:SetDamage( 1 )
				d:SetDamageType( DMG_DROWN )
				ply:TakeDamageInfo( d )
				continue
			end
			local flBlood = CEntity_GetNW2Float( ply, "GAME_flBlood", 1 )
			local f = CEntity_GetNW2Float( ply, "GAME_flBleeding", 0 )
			if flBlood > 0 && f > 0 && f > .0016 then
				local flTimeLeft = PlyTable.GAME_flBleedTimeLeft || 0
				if flTimeLeft <= 0 then
					ply:EmitSound "Bleed"
					local v = ply:GetPos()
					local f = ply:BoundingRadius()
					util_Decal( "Blood", v, v + LerpVector( math_Rand( 0, .25 ), VECTOR_DOWN, VectorRand():GetNormalized() ):GetNormalized() * f * 12, ply )
					v:Add( ply:OBBCenter() )
					f = f * 4
					for i = 1, math_random( 3 ) do
						local d = VectorRand()
						d:Normalize()
						v = ply:NearestPoint( v + d * math_Rand( 0, f ) )
						util_Decal( "Blood", v, v + d * f, ply )
					end
					PlyTable.GAME_flBleedTimeLeft = 1
				else PlyTable.GAME_flBleedTimeLeft = flTimeLeft - f * 256 * math_Rand( .9, 1.1 ) * FrameTime() end
			end
			flBlood = math_Clamp( flBlood + ( f > 0 && ( .0016 - f ) || .016 ) * FrameTime(), 0, 1 )
			ply:SetNW2Float( "GAME_flBlood", flBlood )
			o = o - FrameTime()
			ply:SetNW2Float( "GAME_flOxygen", math_Clamp(

			o + ( ply:WaterLevel() >= 3 && 0 || (
			1 / ( 1 + math_exp( -18 * ( flBlood - .55 ) ) ) * // Blood efficiency formula
			( 1 + ( PlyTable.GAME_flOxygenRegen || ( CEntity_GetNW2Float( ply, "GAME_flOxygenLimit", 0 ) * .5 ) ) ) ) )

			* FrameTime(), 0, CEntity_GetNW2Float( ply, "GAME_flOxygenLimit", 0 ) ) )
		else
			CEntity_SetNW2Float( ply, "GAME_flOxygen", CEntity_GetNW2Float( ply, "GAME_flOxygenLimit", 0 ) )
			CEntity_SetNW2Float( ply, "GAME_flBlood", 1 )
			CEntity_SetNW2Float( ply, "GAME_flBleeding", 0 )
		end
		// TODO: Allow others to change the view offsets
		local f = ply:GetModelScale()
		ply:SetViewOffset( Vector( 0, 0, 64 ) * f )
		ply:SetViewOffsetDucked( Vector( 0, 0, 40 ) * f )
		ply:SetCanZoom( false )
		local h = ply:Health() / ply:GetMaxHealth()
		ply:SetDSP( h <= .3 && 16 || h <= .4 && 15 || h <= .5 && 14 || 1 )
		PlyTable.GAME_flSuppression = math_Approach( PlyTable.GAME_flSuppression || 0, 0, math_max( ply:Health() * 2, ( PlyTable.GAME_flSuppression || 0 ) * .33 ) * FrameTime() )
		local EThreat = DIRECTOR_THREAT_NULL
		local tMusicEntities = PlyTable.DR_tMusicEntities || {}
		if RealTime() > ( PlyTable.DR_flNextUpdate || 0 ) then
			local aEye, flFoVHalf = ply:EyeAngles(), ply:GetInfoNum( "fov_desired", UNIVERSAL_FOV ) * .5
			for _, pEntity in ipairs( ents_FindInPVS( ply ) ) do
				if !ply:Visible( pEntity ) then continue end
				local ETheirThreat = Director_GetThreat( ply, pEntity )
				if ETheirThreat <= DIRECTOR_THREAT_NULL then continue end
				local a = ( pEntity:GetPos() + pEntity:OBBCenter() - vEyePos ):Angle()
				if math_abs( math_AngleDifference( aEye[ 1 ], a[ 1 ] ) ) > flFoVHalf then continue end
				if math_abs( math_AngleDifference( aEye[ 2 ], a[ 2 ] ) ) > flFoVHalf then continue end
				tMusicEntities[ pEntity ] = true
			end
			PlyTable.DR_flNextUpdate = RealTime() + math_Rand( .1, .2 )
		end
		local tSpotted = PlyTable.DR_tSpotted || {}
		local tNewMusicEntities = {}
		local flAllSuppression, flAllHealth = 0, 0
		local tThreatDirections = {}
		local pVehicle = PlyTable.GAME_pVehicle
		for pEntity in pairs( tMusicEntities ) do
			if !IsValid( pEntity ) || pEntity.__ACTOR_BULLSEYE__ then continue end
			local ETheirThreat = Director_GetThreat( ply, pEntity )
			if ETheirThreat <= DIRECTOR_THREAT_NULL then continue end
			if pEntity:Visible( ply ) || IsValid( pVehicle ) && pEntity:Visible( pVehicle ) then
				local f = pEntity.GetEnemy
				if f then
					f = f( pEntity )
					if IsValid( f ) && f == ply then
						table.insert( tThreatDirections, pEntity )
					end
				end
			end
			// TODO: Improve this, dammit!
			if pEntity:NearestPoint( vEyePos ):DistToSqr( vEyePos ) > 9437184/*3072*/ then
				tNewMusicEntities[ pEntity ] = true
				tSpotted[ pEntity ] = nil
				continue
			end
			// We're doin' shit to them, so add it!
			// (Or someone else's doin' shit to them)
			flAllSuppression = flAllSuppression + ( pEntity.GAME_flSuppression || 0 )
			flAllHealth = flAllHealth + pEntity:Health()
			tNewMusicEntities[ pEntity ] = true
			f = tSpotted[ pEntity ]
			if f then if CurTime() > f then EThreat = ETheirThreat end
			else tSpotted[ pEntity ] = CurTime() + DIRECTOR_MUSIC_VO_WAIT end
		end
		local i = 1
		while true do
			local sI = tostring( i )
			local s = "GAME_v3DThreat" .. sI
			local v = ply:GetNW2Vector( s )
			if v == vector_origin then break end
			CEntity_SetNW2Vector( ply, s )
			CEntity_SetNW2Bool( ply, "GAME_b3DThreat" .. sI )
			i = i + 1
		end
		for i, pEntity in ipairs( tThreatDirections ) do
			local sI = tostring( i )
			CEntity_SetNW2Vector( ply, "GAME_v3DThreat" .. sI, pEntity:GetPos() + pEntity:OBBCenter() )
			CEntity_SetNW2Bool( ply, "GAME_b3DThreat" .. sI, pEntity.GAME_bHurtEnemy )
		end
		local tNewSpotted = {}
		for pEntity, flTime in pairs( tSpotted ) do
			if !IsValid( pEntity ) then continue end
			if !tNewMusicEntities[ pEntity ] then continue end
			tNewSpotted[ pEntity ] = flTime
		end
		PlyTable.DR_tSpotted = tNewSpotted
		flIntensity = math.max( 0, flAllSuppression ) / flAllHealth
		if flIntensity != flIntensity then flIntensity = 0 end // nan
		PlyTable.DR_tMusicEntities = tNewMusicEntities
		if EThreat >= DIRECTOR_THREAT_HOLD_FIRE then Achievement_Miscellaneous( ply, "Combat" ) end
		if bAlarm || PlyTable.DR_EThreat == DIRECTOR_THREAT_COMBAT && EThreat == DIRECTOR_THREAT_HOLD_FIRE then EThreat = DIRECTOR_THREAT_COMBAT end
		PlyTable.DR_EThreat = EThreat
		ply:SendLua( "DIRECTOR_THREAT=" .. tostring( EThreat ) )
		local sIntensity = tostring( flIntensity )
		if !tonumber( sIntensity ) then sIntensity = "0" end
		ply:SendLua( "DIRECTOR_MUSIC_INTENSITY=" .. sIntensity )
		local flTension = PlyTable.DR_flMusicTension || 0
		if flTension > flIntensity then flTension = Lerp( .1 * FrameTime(), flTension || 0, flIntensity )
		else flTension = Lerp( .25 * FrameTime(), flTension || 0, flIntensity ) end
		if flTension != flTension then flTension = 0 end // nan
		PlyTable.DR_flMusicTension = flTension
		local sTension = tostring( flTension )
		if !tonumber( sTension ) then sTension = "0" end
		ply:SendLua( "DIRECTOR_MUSIC_TENSION=" .. sTension )
		hook.Run( "PostDirectorPlayerThink", ply )
	end
end )
