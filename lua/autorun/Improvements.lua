if SERVER then
	local player_Iterator = player.Iterator
	function LocalPlayer()
		local t, f, i = player_Iterator()
		local _, p = t( f, i )
		return p
	end
end

ACCELERATION_NORMAL = 5
GRAVITY_NORMAL = 800

HUMAN_WALK_SPEED = 75
HUMAN_RUN_SPEED = 250
HUMAN_SPRINT_SPEED = 325
HUMAN_JUMP_HEIGHT = 72

// Weapon statuses and other complicated bullshit

// At the hip facing leftwards (rifles) or at the hand (pistols)
WEAPON_STANCE_PASSIVE = -1
// Shotguns are at the hip, rifles are shouldered
WEAPON_STANCE_DEFAULT = 0
// Aiming down sights
WEAPON_STANCE_AIMING = 1
// EVERYTHING but pistols/revolvers/etc at the hip
WEAPON_STANCE_HIP = 2
// EVERYTHING but pistols/revolvers/etc shouldered
WEAPON_STANCE_SHOULDER = 3

hook.Add( "PlayerStepSoundTime", "Improvements", function( ply, EType, bWalk )
	if ply:GetNW2Bool "CTRL_bSprinting" then return 350 end
	return 500
end )

local RealTime = RealTime
local FrameTime = FrameTime
local math_cos = math.cos

local CEntity = FindMetaTable "Entity"

local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local CEntity_GetTable = CEntity.GetTable
local CEntity_IsOnGround = CEntity.IsOnGround

local CPlayer_KeyDown = FindMetaTable( "Player" ).KeyDown

function QuickSlide_Can( ply, t ) if t == nil then t = CEntity_GetTable( ply ) end return !CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) && !Either( t.CTRL_bCantSlide == nil, __PLAYER_MODEL__[ ply:GetModel() ] && __PLAYER_MODEL__[ ply:GetModel() ].bCantSlide, t.CTRL_bCantSlide ) && CEntity_IsOnGround( ply ) && GetVelocity( ply ):Length() >= ( ply:GetRunSpeed() * .9 ) end

hook.Add( "StartCommand", "Improvements", function( ply, cmd )
	if cmd:KeyDown( IN_ZOOM ) then
		local ang = cmd:GetViewAngles()
		local flBreathe = RealTime() * .5
		local flForce = .5 * FrameTime()
		ang[ 1 ] = ang[ 1 ] + math_cos( flBreathe ) * flForce
		ang[ 2 ] = ang[ 2 ] + math_cos( flBreathe * .5 ) * flForce
		cmd:SetViewAngles( ang )
	end
	if CLIENT then
		if ply:GetNW2Bool "CTRL_bSliding" then
			if cmd:KeyDown( IN_DUCK ) then ply.GAME_bInDuckPressed = true
			elseif ply.GAME_bInDuckPressed then ply.GAME_bWantsToDuck = !ply.GAME_bWantsToDuck ply.GAME_bInDuckPressed = nil end
			if ply.GAME_bWantsToDuck then cmd:AddKey( IN_DUCK ) end
			//	if ply.GAME_bSprint then cmd:AddKey( IN_SPEED ) end
			//	ply.GAME_bSlid = true
		else
			//	if ply.GAME_bSlid then
			//		ply.GAME_bSlid = nil
			//		ply.GAME_bSprint = nil
			//	else
				if cmd:KeyDown( IN_DUCK ) then ply.GAME_bInDuckPressed = true
				elseif ply.GAME_bInDuckPressed then ply.GAME_bWantsToDuck = !ply.GAME_bWantsToDuck ply.GAME_bInDuckPressed = nil end
				if ply.GAME_bWantsToDuck then cmd:AddKey( IN_DUCK ) end
			//	end
			local b = cmd:GetSideMove() != 0 && cmd:GetForwardMove() >= 0 || cmd:GetForwardMove() > 0
			local bVelocity = GetVelocity( ply ):LengthSqr() > 256
			//	if b then
			//		ply.GAME_flSprintTime = CurTime() + .1
			//		if cmd:KeyDown( IN_SPEED ) && bVelocity then ply.GAME_bSprint = true end
			//	else
			//		if CurTime() > ( ply.GAME_flSprintTime || 0 ) && ( cmd:GetForwardMove() < 0 || cmd:GetSideMove() == 0 && cmd:GetForwardMove() == 0 ) then ply.GAME_bSprint = nil end
			//	end
			//	local p = ply:GetActiveWeapon()
			//	if IsValid( p ) && ( CurTime() <= p:GetNextPrimaryFire() || CurTime() <= p:GetNextSecondaryFire() ) then
			//		ply.GAME_bSprint = nil
			//	elseif ply.GAME_bSprint then cmd:AddKey( IN_SPEED ) end
			if !QuickSlide_Can( ply ) && bVelocity && cmd:KeyDown( IN_SPEED ) && b then
				cmd:RemoveKey( IN_DUCK )
				ply.GAME_bWantsToDuck = nil
				ply.GAME_bInDuckPressed = nil
			end
		end
	end
	if GameImprovements_StartCommand then GameImprovements_StartCommand( ply, cmd ) end
end )

COVER_PEEK_NONE = 0
COVER_BLINDFIRE_UP = 1
COVER_BLINDFIRE_LEFT = 2
COVER_BLINDFIRE_RIGHT = 3
COVER_FIRE_LEFT = 4
COVER_FIRE_RIGHT = 5
COVER_FIRE_UP = 6

COVER_VARIANTS_NONE = 0
// Should be COVER_VARIANTS_UP, but this name just stuck with me from previous versions,
// and I like it too much to just abandon it in the older versions
COVER_VARIANTS_CENTER = 1
COVER_VARIANTS_BOTH = 1
COVER_VARIANTS_LEFT = 2
COVER_VARIANTS_RIGHT = 3

TRAVERSES_NONE = 0
TRAVERSES_WATER = 1
TRAVERSES_GROUND = 2
TRAVERSES_AIR = 4

UNIVERSAL_FOV = 80

physenv.SetGravity( Vector( 0, 0, -514.83 ) )

local cDisableLevelOfDetail = CreateConVar(
	"bDisableLevelOfDetail",
	0,
	FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_ARCHIVE,
	"Disabled LoD. Not the same LoD that changes model vertices.\n\nThe one which optimizes code.\n\nNOT RECOMMENDED!",
	0, 1
)
local SysTime = SysTime
local math_min = math.min
local physenv_GetLastSimulationTime = physenv.GetLastSimulationTime
function LevelOfDetail( pContainer, Key, flMultiplier )
	if cDisableLevelOfDetail:GetBool() then pContainer[ sKey ] = 0 return true end
	local f = pContainer[ Key ]
	if f then
		if SysTime() <= f then return end
		pContainer[ Key ] = SysTime() + math_min( ( physenv_GetLastSimulationTime() * 7500 ) ^ 1.1 * ( flMultiplier || 1 ), 6 )
		return true
	else pContainer[ Key ] = SysTime() + math_min( ( physenv_GetLastSimulationTime() * 7500 ) ^ 1.1 * ( flMultiplier || 1 ), 6 ) end
end

physenv.SetPerformanceSettings {
	MaxVelocity = 999999,
	MaxAngularVelocity = 999999
}

function FairlyTranslateBleedingToHealth( flBleeding, flMaxHealth ) return flBleeding * flMaxHealth * 2 end
function FairlyTranslateHealthToBleeding( flHealth, flMaxHealth ) return flHealth / ( flMaxHealth * 2 ) end

if SERVER then
	__VEHICLE_TABLE__ = __VEHICLE_TABLE__ || {
		[ TRAVERSES_WATER ] = {},
		[ TRAVERSES_GROUND ] = {},
		[ TRAVERSES_AIR ] = {}
	}
else
	ReadSpeed = CreateClientConVar(
		"ReadSpeed",
		6,
		true,
		true,
		"How fast can you read, in characters per second?",
		2.220446049250313e-16 // Epsilon to avoid division by zero
	)

	local gui_AddCaption = gui.AddCaption
	local language_GetPhrase = language.GetPhrase
	function CaptionSound( sColor, sSound )
		sSound = "Caption_" .. sSound
		local sCaption = language_GetPhrase( sSound )
		if sCaption == sSound then return end
		gui_AddCaption( sColor .. sCaption, #select( 1, sCaption:gsub( "<.->", "" ) ) / ReadSpeed:GetFloat() )
	end
end

local Vector = Vector
local math_deg = math.deg
local math_acos = math.acos

// TODO: Actually properly implement this - right now it's a simple hack for it to roughly work
function CalculateAngularVelocity( aTarget, aForward, vAngleVelocity, flTurnRate, flTurnAcceleration, flFrameTime )
	local function fForAxis( flTarget, flCurrent, flVelocity )
		return math.AngleDifference( flTarget, flCurrent ) - flVelocity
	end
	return Vector( fForAxis( aTarget[ 3 ], aForward[ 3 ], vAngleVelocity[ 1 ] ), fForAxis( aTarget[ 1 ], aForward[ 1 ], vAngleVelocity[ 2 ] ), fForAxis( aTarget[ 2 ], aForward[ 2 ], vAngleVelocity[ 3 ] ) ) * ( flFrameTime || FrameTime() )
end

function CalculateVelocity( vTarget, vPos, vCurrent, flSpeed, flAcceleration, flFrameTime )
	local vDelta = vTarget - vPos
	local flDistance = vDelta:Length()
	if flDistance == 0 then return Vector() end
	local vDir = vDelta:GetNormalized()
	return vCurrent + vDir * math.Approach( vCurrent:Length(), math_min( flSpeed, ( flAcceleration * flDistance ) ^ .5 ), flAcceleration * ( flFrameTime || FrameTime() ) )
end

function CalculateAcceleration( vVelocity, vTarget, flAcceleration, flFrameTime )
	local vDelta = vTarget - vVelocity
	local flDistance = vDelta:Length()
	if flDistance == 0 then return Vector() end
	return vDelta:GetNormalized() * math.min( flDistance, flAcceleration * ( flFrameTime || FrameTime() ) )
end

local IsValid = IsValid

local hook = hook
local hook_Add = hook.Add
local hook_Remove = hook.Remove
function AddThinkToEntity( self, func )
	local n = EntityUniqueIdentifier( self )
	hook_Add( "Think", n, function()
		if !IsValid( self ) || func( self ) then hook_Remove( "Think", n ) end
	end )
end

// DO NOT EDIT THIS!
hook_Add( "HandlePlayerDrivingNew", "Base", function( ply, plyTable, pVehicle )
	if ( !pVehicle.HandleAnimation && pVehicle.GetVehicleClass ) then
		local c = pVehicle:GetVehicleClass()
		local t = list.Get( "Vehicles" )[ c ]
		if ( t && t.Members && t.Members.HandleAnimation ) then
			pVehicle.HandleAnimation = t.Members.HandleAnimation
		else
			pVehicle.HandleAnimation = true -- Prevent this if block from trying to assign HandleAnimation again.
		end
	end

	if ( isfunction( pVehicle.HandleAnimation ) ) then
		local seq = pVehicle:HandleAnimation( ply )
		if ( seq != nil ) then
			plyTable.CalcSeqOverride = seq
		end
	end

	if ( plyTable.CalcSeqOverride == -1 ) then -- pVehicle.HandleAnimation did not give us an animation
		local class = pVehicle:GetClass()
		if ( class == "prop_vehicle_jeep" ) then
			plyTable.CalcSeqOverride = ply:LookupSequence( "drive_jeep" )
		elseif ( class == "prop_vehicle_airboat" ) then
			plyTable.CalcSeqOverride = ply:LookupSequence( "drive_airboat" )
		elseif ( class == "prop_vehicle_prisoner_pod" && pVehicle:GetModel() == "models/vehicles/prisoner_pod_inner.mdl" ) then
			-- HACK!!
			plyTable.CalcSeqOverride = ply:LookupSequence( "drive_pd" )
		else
			plyTable.CalcSeqOverride = ply:LookupSequence( "sit_rollercoaster" )
		end
	end

	local use_anims = ( plyTable.CalcSeqOverride == ply:LookupSequence( "sit_rollercoaster" ) || plyTable.CalcSeqOverride == ply:LookupSequence( "sit" ) )
	if ( use_anims && ply:GetAllowWeaponsInVehicle() && IsValid( ply:GetActiveWeapon() ) ) then
		local holdtype = ply:GetActiveWeapon():GetHoldType()
		if ( holdtype == "smg" ) then holdtype = "smg1" end

		local seqid = ply:LookupSequence( "sit_" .. holdtype )
		if ( seqid != -1 ) then
			plyTable.CalcSeqOverride = seqid
		end
	end

	return true
end )

__PLAYER_MODEL__ = {}
local __PLAYER_MODEL__ = __PLAYER_MODEL__

local hook_Run = hook.Run

CEntity_OBBMinsInternal = CEntity_OBBMinsInternal || CEntity.OBBMins
CEntity_OBBMaxsInternal = CEntity_OBBMaxsInternal || CEntity.OBBMaxs

local CEntity_OBBMinsInternal = CEntity_OBBMinsInternal
local CEntity_OBBMaxsInternal = CEntity_OBBMaxsInternal

local CEntity_GetTable = CEntity.GetTable

function CEntity:OBBMins()
	local v = CEntity_GetTable( self ).GAME_BoundMins
	if v then return v end
	return CEntity_OBBMinsInternal( self )
end
function CEntity:OBBMaxs()
	local v = CEntity_GetTable( self ).GAME_BoundMaxs
	if v then return v end
	return CEntity_OBBMaxsInternal( self )
end

local CEntity_LookupSequence = CEntity.LookupSequence
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
hook_Add( "CalcMainActivity", "Improvements", function( ply, vel )
	local veh = ply.GAME_pVehicle || ply:GetNW2Entity "GAME_pVehicle"
	if IsValid( veh ) then
		local t = ply:GetTable()
		hook_Run( "HandlePlayerDrivingNew", ply, t, veh )
		return t.CalcIdeal, t.CalcSeqOverride
	end
	if CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) then
		local f = ply.GAME_fSlidingActivity
		if f then return f( ply, vel ) end
		local a = ACT_MP_WALK
		ply.CalcIdeal = a
		local s = CEntity_LookupSequence( ply, CEntity_GetTable( ply ).CTRL_sSlidingSequence || "zombie_slump_idle_02" )
		ply.CalcSeqOverride = s
		return a, s
	end
end )

hook.Add( "PlayerFootstep", "Improvements", function( ply, ... )
	if ply:GetNW2Bool "CTRL_bSliding" then return true end
	if ply:WaterLevel() > 0 then
		local pEffectData = EffectData()
		pEffectData:SetOrigin( vec || ply:GetPos() )
		pEffectData:SetScale( ply:BoundingRadius() * .2 )
		pEffectData:SetFlags( 0 )
		util.Effect( "watersplash", pEffectData )
	end
	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	if v then
		v = v.PlayerFootstep
		if v then return v( ply, ... ) end
	end
end )

function SetHumanPlayer( ply )
	ply:SetNPCClass( CLASS_HUMAN )
	ply:SetHealth( 100 )
	ply:SetMaxHealth( 100 )
	ply:SetRunSpeed( HUMAN_SPRINT_SPEED )
	ply:SetWalkSpeed( HUMAN_RUN_SPEED )
	ply:SetSlowWalkSpeed( HUMAN_WALK_SPEED )
	ply:SetJumpPower( ( 2 * GetConVarNumber "sv_gravity" * HUMAN_JUMP_HEIGHT ) ^ .5 )
	ply:SetDuckSpeed( .25 )
	ply:SetUnDuckSpeed( .25 )
	ply:SetCrouchedWalkSpeed( 1 )
	ply:SetViewOffset( Vector( 0, 0, 56 ) )
	ply:SetViewOffsetDucked( Vector( 0, 0, 28 ) )
	ply:SetHull( Vector( -16, -16, 0 ), Vector( 16, 16, 72 ) )
	ply:SetHullDuck( Vector( -16, -16, 0 ), Vector( 16, 16, 32 ) )
end

hook.Add( "PlayerSpawn", "Improvements", function( ply )
	timer.Simple( 0, function()
		if !IsValid( ply ) then return end
		local sClass = player_manager.GetPlayerClass( ply )
		if sClass == "player_default" || sClass == "player_sandbox" then SetHumanPlayer( ply ) end
	end )
end )

hook.Add( "PlayerInitialSpawn", "Improvements", function( ply )
	timer.Simple( 0, function()
		if !IsValid( ply ) then return end
		local sClass = player_manager.GetPlayerClass( ply )
		if sClass == "player_default" || sClass == "player_sandbox" then SetHumanPlayer( ply ) end
	end )
end )

hook.Add( "PlayerHandleAnimEvent", "Improvements", function( ply, ... )
	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	if v then
		v = v.PlayerHandleAnimEvent
		if v then return v( ply, ... ) end
	end
end )

hook.Add( "TranslateActivity", "Improvements", function( ply, ... )
	local c = ply:GetModel()
	local v = __PLAYER_MODEL__[ c ]
	if v then
		v = v.TranslateActivity
		if v then return v( ply, ... ) end
	end
end )

hook.Add( "CalcView", "Improvements", function( ply, ... )
	local c = ply:GetModel()
	local v = __PLAYER_MODEL__[ c ]
	if v then
		v = v.CalcView
		if v then return v( ply, ... ) end
	end
end )

local CEntity = FindMetaTable "Entity"
local CEntity_GetOwner = CEntity.GetOwner
function GetOwner( self )
	local owner = CEntity_GetOwner( self )
	if IsValid( owner ) then return GetOwner( owner ) end
	return self
end

local CEntity_GetTable = CEntity.GetTable
local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local Vector = Vector
local CurTime = CurTime
function GetVelocity( ent )
	local EntTable = CEntity_GetTable( ent )
	local v = EntTable.__VELOCITY__
	if v then return v end
	v = EntTable.GAME_pVehicle
	if IsValid( v ) && v != ent then return GetVelocity( v ) end
	if EntTable.__GetVelocity__ then return EntTable.__GetVelocity__( ent, EntTable ) end
	if ent:IsPlayer() || ent:IsNPC() then return CEntity_GetVelocity( ent ) else
		if SERVER && ent:IsNextBot() then
			local v = EntTable.loco:GetVelocity()
			if v == vector_origin && EntTable.GAME_vVelocity then
				return Vector( EntTable.GAME_vVelocity )
			else
				EntTable.GAME_vVelocity = v
				EntTable.GAME_flVelocityFixUpTime = CurTime() + .1
				return v
			end
		end
		local phys = CEntity_GetPhysicsObject( ent )
		if IsValid( phys ) then return phys:GetVelocity() end
	end
	return Vector()
end

local CEntity_GetTable = CEntity.GetTable
local CEntity_SetVelocity = CEntity.SetVelocity
local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local Vector = Vector
local CurTime = CurTime
function SetVelocity( ent, vVelocity )
	local EntTable = CEntity_GetTable( ent )
	v = EntTable.GAME_pVehicle
	if IsValid( v ) && v != ent then SetVelocity( v, vVelocity ) end
	if EntTable.__SetVelocity__ then EntTable.__SetVelocity__( ent, vVelocity, EntTable ) end
	if ent:IsPlayer() then
		CEntity_SetVelocity( ent, vVelocity - CEntity_GetVelocity( ent ) )
	elseif ent:IsNPC() then CEntity_SetVelocity( ent, vVelocity ) else
		if SERVER && ent:IsNextBot() then EntTable.loco:SetVelocity( vVelocity ) return end
		local phys = CEntity_GetPhysicsObject( ent )
		if IsValid( phys ) then phys:SetVelocity( vVelocity ) end
	end
end

for _, n in ipairs( file.Find( "Player/*.lua", "LUA" ) ) do ProtectedCall( function() include( "Player/" .. n ) end ) end

// Assumes there is only one sound attached, and assumes everything is valid!
function SoundScriptDuration( sSound ) return SoundDuration( sound.GetProperties( sSound ).sound ) end

local sPath = "Map/" .. game.GetMap() .. ".lua"
if file.Exists( sPath, "LUA" ) then include( sPath ) end
