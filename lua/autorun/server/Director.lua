local player_Iterator = player.Iterator

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local IsValid = IsValid

local Vector = Vector

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
		if IsValid( pFlashlight ) then pFlashlight:SetPos( ply:GetShootPos() ) end
		local v = __PLAYER_MODEL__[ ply:GetModel() ]
		if v then
			v = v.Think
			if v then v( ply, PlyTable ) end
		end
		local flReinforcements, bAlarm, bAlarmCoolDown
		local b = !cVisibleHostileReinforcementCountDown:GetBool()
		for pEntity in pairs( __ALARMS_ACTIVE__ ) do
			if !IsValid( pEntity ) then continue end
			if pEntity:NearestPoint( ply:EyePos() ):DistToSqr( ply:EyePos() ) > 16777216/*4096*/ then continue end
			bAlarm = true
			if b then continue end
			if pEntity:Classify() != ply:Classify() then
				local flStart, flEnd = pEntity.flReinforcementStartTime, pEntity.flReinforcementEndTime
				if flStart && flEnd then
					flReinforcements = math.min( 1 - ( CurTime() - flStart ) / ( flEnd - flStart ), flReinforcements || 1 )
				end
				local f = pEntity.flCoolDown
				if f && CurTime() < f then bAlarmCoolDown = true end
			end
		end
		ply:SetNW2Float( "ALARM_flHostileReinforcements", flReinforcements || 0 )
		ply:SetNW2Float( "GAME_flOxygenLimit", PlyTable.GAME_flOxygenLimit || 30 )
		if ply:Alive() then
			local o = ply:GetNW2Float( "GAME_flOxygen", ply:GetNW2Float( "GAME_flOxygenLimit", -1 ) )
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
			local f = ply:GetNW2Float( "GAME_flBleeding", 0 )
			if f > 0 && f > .0016 && CurTime() > ( PlyTable.GAME_flNextBleed || 0 ) then
				ply:EmitSound "Bleed"
				local v = ply:GetPos()
				local f = ply:BoundingRadius()
				util.Decal( "Blood", v, v + Vector( 0, 0, ply:OBBMins()[ 3 ] - f * 12 ), ply )
				v = v + ply:OBBCenter()
				f = f * 4
				local d = ply:GetRight()
				v = ply:NearestPoint( v + d * 999999 )
				util.Decal( "Blood", v, v + d * f, ply )
				local d = -d
				v = ply:NearestPoint( v + d * 999999 )
				util.Decal( "Blood", v, v + d * f, ply )
				local d = ply:GetForward()
				v = ply:NearestPoint( v + d * 999999 )
				util.Decal( "Blood", v, v + d * f, ply )
				local d = -d
				v = ply:NearestPoint( v + d * 999999 )
				util.Decal( "Blood", v, v + d * f, ply )
				PlyTable.GAME_flNextBleed = CurTime() + math.Clamp( .033 / f, .5, 12 ) * math.Rand( .9, 1.1 )
			end
			local flBlood = math.Clamp( ply:GetNW2Float( "GAME_flBlood", 1 ) + ( f > 0 && ( .0016 - f ) || .016 ) * FrameTime(), 0, 1 )
			ply:SetNW2Float( "GAME_flBlood", flBlood )
			o = o - FrameTime()
			ply:SetNW2Float( "GAME_flOxygen", math.Clamp(

			o + ( ply:WaterLevel() >= 3 && 0 || (
			1 / ( 1 + math.exp( -18 * ( flBlood - .55 ) ) ) * // Blood efficiency formula
			( 1 + ( ply.GAME_flOxygenRegen || ( ply:GetNW2Float( "GAME_flOxygenLimit", 0 ) * .5 ) ) ) ) )

			* FrameTime(), 0, ply:GetNW2Float( "GAME_flOxygenLimit", 0 ) ) )
		else
			ply:SetNW2Float( "GAME_flOxygen", ply:GetNW2Float( "GAME_flOxygenLimit", 0 ) )
			ply:SetNW2Float( "GAME_flBlood", 1 )
			ply:SetNW2Float( "GAME_flBleeding", 0 )
		end
		ply:SetViewOffset( ply:GetViewOffset() )
		ply:SetViewOffsetDucked( ply:GetViewOffsetDucked() )
		ply:SetCanZoom( false )
		local h = ply:Health() / ply:GetMaxHealth()
		ply:SetDSP( h <= .165 && 16 || h <= .33 && 15 || h <= .66 && 14 || 1 )
		PlyTable.GAME_flSuppression = math.Approach( PlyTable.GAME_flSuppression || 0, 0, math.max( ply:Health() * 2, ( PlyTable.GAME_flSuppression || 0 ) * .33 ) * FrameTime() )
		local EThreat, flIntensity = DIRECTOR_THREAT_NULL, ( PlyTable.GAME_flSuppression || 0 ) / ( ply:Health() * 6 )
		local tMusicEntities = PlyTable.DR_tMusicEntities || {}
		local vEye = ply:EyePos()
		if RealTime() > ( PlyTable.DR_flNextUpdate || 0 ) then
			local aEye, flFoVHalf = ply:EyeAngles(), ply:GetInfoNum( "fov_desired", UNIVERSAL_FOV ) * .5
			for _, pEntity in ipairs( ents.FindInPVS( ply ) ) do
				if !ply:Visible( pEntity ) then continue end
				local ETheirThreat = Director_GetThreat( ply, pEntity )
				if ETheirThreat <= DIRECTOR_THREAT_NULL then continue end
				local a = ( pEntity:GetPos() + pEntity:OBBCenter() - vEye ):Angle()
				if math.abs( math.AngleDifference( aEye[ 1 ], a[ 1 ] ) ) > flFoVHalf then continue end
				if math.abs( math.AngleDifference( aEye[ 2 ], a[ 2 ] ) ) > flFoVHalf then continue end
				tMusicEntities[ pEntity ] = true
			end
			PlyTable.DR_flNextUpdate = RealTime() + math.Rand( .1, .2 )
		end
		local tSpotted = PlyTable.DR_tSpotted || {}
		local tNewMusicEntities = {}
		// We're doin' shit to them, so add it!
		local flAllSuppression, flAllHealth, flAllThreat, bAtLeastOneWhoIsNotIdle = 0, 0, 0
		for pEntity in pairs( tMusicEntities ) do
			if !IsValid( pEntity ) then continue end
			local ETheirThreat = Director_GetThreat( ply, pEntity )
			if ETheirThreat <= DIRECTOR_THREAT_NULL then continue end
			if ETheirThreat > DIRECTOR_THREAT_HEAT then bAtLeastOneWhoIsNotIdle = true end
			// TODO: Improve this, dammit!
			if pEntity:NearestPoint( vEye ):DistToSqr( vEye ) > 9437184/*3072*/ then continue end
			local f = pEntity.Disposition
			if f && f( pEntity, ply ) == D_LI then
				flAllThreat = flAllThreat - ( pEntity.GAME_flThreat || 1 )
			else
				flAllSuppression = flAllSuppression + ( pEntity.GAME_flSuppression || 0 )
				f = pEntity:Health()
				if f > 0 then flAllHealth = flAllHealth + f end
				if f > 0 then flAllThreat = flAllThreat + ( pEntity.GAME_flThreat || 1 ) end
			end
			tNewMusicEntities[ pEntity ] = true
			f = tSpotted[ pEntity ]
			if f then if CurTime() > f then EThreat = ETheirThreat end
			else tSpotted[ pEntity ] = CurTime() + .5 end
		end
		local tNewSpotted = {}
		for pEntity, flTime in pairs( tSpotted ) do
			if !IsValid( pEntity ) then continue end
			if !tNewMusicEntities[ pEntity ] then continue end
			tNewSpotted[ pEntity ] = flTime
		end
		PlyTable.DR_tSpotted = tNewSpotted
		local f = flAllSuppression / flAllHealth
		if f != f then f = 0 end // NaN
		flIntensity = flIntensity + f
		PlyTable.DR_tMusicEntities = tNewMusicEntities
		if EThreat == DIRECTOR_THREAT_HOLD_FIRE || EThreat == DIRECTOR_THREAT_COMBAT then Achievement_Miscellaneous( ply, "Combat" ) else PlyTable.DR_bMagic = nil end
		if bAlarm || PlyTable.DR_EThreat == DIRECTOR_THREAT_COMBAT && EThreat == DIRECTOR_THREAT_HOLD_FIRE then EThreat = DIRECTOR_THREAT_COMBAT end
		if PlyTable.DR_bMagic || bAtLeastOneWhoIsNotIdle && flAllThreat * ( bAlarmCoolDown && 2 || 1 ) > ply:Health() * .12 then
			EThreat = DIRECTOR_THREAT_MAGIC
			PlyTable.DR_bMagic = true
		end
		ply.DR_EThreat = EThreat
		ply:SendLua( "DIRECTOR_THREAT=" .. tostring( EThreat ) )
		ply:SendLua( "DIRECTOR_MUSIC_INTENSITY=" .. tostring( flIntensity ) )
		local flTension = PlyTable.DR_flMusicTension || 0
		if flTension > flIntensity then flTension = Lerp( .1 * FrameTime(), flTension || 0, flIntensity )
		else flTension = Lerp( .25 * FrameTime(), flTension || 0, flIntensity ) end
		if flTension != flTension then flTension = 0 end // NaN
		PlyTable.DR_flMusicTension = flTension
		ply:SendLua( "DIRECTOR_MUSIC_TENSION=" .. tostring( flTension ) )
	end
end )
