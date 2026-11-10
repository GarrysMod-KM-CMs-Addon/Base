// Director server API isn't exposed properly as a require'able thingy.
// Why? Simple. I don't see a reason too. No one really needs what is defined here,
// as nothing major actually IS defined here. If you think otherwise, feel free to tell me.

local min = math.min
local exp = math.exp

local function FRILerpRate( flRate, flFrameTime ) return min( 1, 1 - exp( -flRate * flFrameTime ) ) end

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local player_Iterator = player.Iterator
local IsValid = IsValid
local Vector = Vector
local util_Decal = util.Decal
local math_Rand = math.Rand
local LerpVector = LerpVector
local math_abs = math.abs
local math_AngleDifference = math.AngleDifference
local math_Approach = math.Approach
local math_max = math.max
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

		CallPlayerClassHook( ply, "PlayerTick", PlyTable )

		local pFlashlight = PlyTable.GAME_pFlashlight
		local vEyePos = ply:EyePos()
		local aAim = ply:EyeAngles()
		local dAim = aAim:Forward()
		if IsValid( pFlashlight ) then pFlashlight:SetPos( vEyePos + dAim * 32 ) end

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

		local flReinforcements
		local b = !cVisibleHostileReinforcementCountDown:GetBool()
		for pEntity in pairs( __ALARMS_ACTIVE__ ) do
			if !IsValid( pEntity ) then continue end
			if pEntity:NearestPoint( vEyePos ):DistToSqr( vEyePos ) > 16777216/*4096*/ then continue end
			if b then continue end
			if pEntity:Classify() != ply:Classify() then
				local flStart, flEnd = pEntity.flReinforcementStartTime, pEntity.flReinforcementEndTime
				if flStart && flEnd then
					flReinforcements = min( 1 - ( CurTime() - flStart ) / ( flEnd - flStart ), flReinforcements || 1 )
				end
			end
		end

		CEntity_SetNW2Float( ply, "ALARM_flHostileReinforcements", flReinforcements || 0 )

		if CurTime() > ( PlyTable.DIRECTOR_MUSIC_VO_WAIT_RECOVER_TIME || 0 ) then
			CEntity_SetNW2Float( ply, "DIRECTOR_MUSIC_VO_WAIT", math_Clamp( Lerp( FRILerpRate( .5, FrameTime() ), ply:GetNW2Float( "DIRECTOR_MUSIC_VO_WAIT", DIRECTOR_MUSIC_VO_WAIT ), DIRECTOR_MUSIC_VO_WAIT ), 0, DIRECTOR_MUSIC_VO_WAIT ) )
		end

		CEntity_SetNW2Float( ply, "GAME_flOxygenLimit", PlyTable.GAME_flOxygenLimit || 60 )

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
					local f = ply:BoundingRadius() * ( 1 + 2 / 3 )
					v:Add( ply:OBBCenter() )
					for i = 1, math_random( 2 ) do
						local d = VectorRand()
						d:Normalize()
						v = ply:NearestPoint( v + d * f )
						util_Decal( "Blood", v, v + d * f, ply )
					end
					PlyTable.GAME_flBleedTimeLeft = 1
				else PlyTable.GAME_flBleedTimeLeft = flTimeLeft - f * 128 * math_Rand( .9, 1.1 ) * FrameTime() end
			end

			ply:SetNW2Float( "GAME_flBleeding", math_Clamp( f - .00005 * FrameTime(), 0, 1 ) )

			flBlood = math_Clamp( flBlood + ( f > 0 && ( .0016 - f ) || .016 ) * FrameTime(), 0, 1 )
			ply:SetNW2Float( "GAME_flBlood", flBlood )
			o = o - FrameTime()
			ply:SetNW2Float( "GAME_flOxygen", math_Clamp(
				o + ( ( !ply:GetNW2Bool "GAME_bControlling" && ply:WaterLevel() >= 3 ) && 0 || (
					( 1 / ( 1 + math_exp( -18 * ( flBlood - .55 ) ) ) ) * // Blood regeneration formula
					( 1 + CEntity_GetNW2Float( ply, "GAME_flOxygenRegeneration", 2 ) )
				) * FrameTime() ),
				0, 
				CEntity_GetNW2Float( ply, "GAME_flOxygenLimit", 0 )
			) )
		else
			CEntity_SetNW2Float( ply, "GAME_flOxygen", CEntity_GetNW2Float( ply, "GAME_flOxygenLimit", 0 ) )
			CEntity_SetNW2Float( ply, "GAME_flBlood", 1 )
			CEntity_SetNW2Float( ply, "GAME_flBleeding", 0 )
		end

		// TODO: Allow others to change these?
		local f = ply:GetModelScale()
		ply:SetViewOffset( Vector( 0, 0, 56 * f ) )
		ply:SetViewOffsetDucked( Vector( 0, 0, 38 * f ) )
		ply:SetHull( HULL_HUMAN_MINS, HULL_HUMAN_MAXS )
		ply:SetHullDuck( HULL_HUMAN_DUCK_MINS, HULL_HUMAN_DUCK_MAXS )

		ply:SetCanZoom( false )

		local flHealthPart = ply:Health() / ply:GetMaxHealth()
		ply:SetDSP( flHealthPart <= .3 && 16 || flHealthPart <= .4 && 15 || flHealthPart <= .9 && 14 || 1 )

		PlyTable.GAME_flSuppression = math_Approach( PlyTable.GAME_flSuppression || 0, 0, math_max( ply:Health() * 2, ( PlyTable.GAME_flSuppression || 0 ) / 3 ) * FrameTime() )

		hook.Run( "PostDirectorPlayerThink", ply )
	end
end )
