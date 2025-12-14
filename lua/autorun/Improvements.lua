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

local math = math
local math_min = math.min
local math_deg = math.deg
local math_acos = math.acos

function CalculateAngularVelocity( dTarget, dForward, vAngleVelocity, flTurnRate, flTurnAcceleration )
	local flCross = dForward:Cross( dTarget )
	if flCross:IsZero() then flCross = Vector( 0, 0, 1 ) end
	flCross:Normalize()
	local vTarget = flCross * math_min( math_deg( math_acos( dForward:Dot( dTarget ) ) ), flTurnRate )
	local vFinal = vTarget - vAngleVelocity
	local flMaxStep = flTurnAcceleration * FrameTime()
	local flLength = vFinal:Length()
	if flLength > flMaxStep then vFinal = vFinal * ( flMaxStep / flLength ) end
	return vFinal
end

function CalculateVelocity( vTarget, vPos, vCurrent, flSpeed, flAcceleration, flFrameTime )
	local vDelta = vTarget - vPos
	local flDistance = vDelta:Length()
	if flDistance == 0 then return Vector( 0, 0, 0 ) end
	local vDir = vDelta:GetNormalized()
	local flMaxSpeedToStop = ( 2 * flAcceleration * flDistance ) ^ .5
	flSpeed = math_min( vCurrent:Length() + flAcceleration * ( flFrameTime || FrameTime() ), flMaxSpeedToStop )
	return vDir * flSpeed - vCurrent
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
local CEntity = FindMetaTable "Entity"
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
		local a = ACT_MP_WALK
		ply.CalcIdeal = a
		local s = CEntity_LookupSequence( ply, CEntity_GetTable( ply ).CTRL_sSlidingSequence || "zombie_slump_idle_02" )
		ply.CalcSeqOverride = s
		return a, s
	end
	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	if v then
		v = v.CalcMainActivity
		if v then
			local t = ply:GetTable()
			local a, s = v( ply, t )
			t.CalcIdeal = a
			t.CalcSeqOverride = s
			return a, s
		end
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
	ply:SetRunSpeed( HUMAN_RUN_SPEED )
	ply:SetWalkSpeed( HUMAN_PROWL_SPEED )
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
		local v = __PLAYER_MODEL__[ ply:GetModel() ]
		if v then
			v = v.PlayerSpawnAny
			if v then return v( ply ) else SetHumanPlayer( ply ) end
		else SetHumanPlayer( ply ) end
	end )
end )

hook.Add( "PlayerInitialSpawn", "Improvements", function( ply )
	timer.Simple( 0, function()
		if !IsValid( ply ) then return end
		local v = __PLAYER_MODEL__[ ply:GetModel() ]
		if v then
			v = v.PlayerSpawnAny
			if v then return v( ply ) else SetHumanPlayer( ply ) end
		else SetHumanPlayer( ply ) end
	end )
end )

hook.Add( "PlayerHandleAnimEvent", "Improvements", function( ply, ... )
	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	if v then
		v = v.PlayerHandleAnimEvent
		if v then return v( ply, ... ) else ply:SetNPCClass( CLASS_HUMAN ) end
	else ply:SetNPCClass( CLASS_HUMAN ) end
end )

hook.Add( "TranslateActivity", "Improvements", function( ply, ... )
	local c = ply:GetModel()
	local v = __PLAYER_MODEL__[ c ]
	if v then
		v = v.TranslateActivity
		if v then return v( ply, ... ) end
	end
end )

hook.Add( "GetFallDamage", "Improvements", function( ply, ... )
	local c = ply:GetModel()
	local v = __PLAYER_MODEL__[ c ]
	if v then
		v = v.GetFallDamage
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
	if IsValid( v ) then return GetVelocity( v ) end
	if EntTable.__GetVelocity__ then return EntTable:__GetVelocity__() end
	if ent:IsPlayer() || ent:IsNPC() then return CEntity_GetVelocity( ent ) else
		if ent:IsNextBot() then
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
	return Vector( 0, 0, 0 )
end

for _, n in ipairs( file.Find( "Player/*.lua", "LUA" ) ) do ProtectedCall( function() include( "Player/" .. n ) end ) end
