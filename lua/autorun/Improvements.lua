if SERVER then
	local player_Iterator = player.Iterator
	function LocalPlayer()
		local t, f, i = player_Iterator()
		local _, p = t( f, i )
		return p
	end
end

DMG_RAYLEIGH = DMG_CLUB + DMG_SONIC + DMG_BLAST

local ents_Create = ents.Create

function GetAnimationDonor()
	local pExistingDonor = g_pAnimationDonor
	if IsValid( pExistingDonor ) then return pExistingDonor end

	local pDonor = ents_Create "AnimationDonor"
	pDonor:Spawn()
	return pDonor
end

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable

function ClearMeleeData( pEntity, EntityTable )
	EntityTable = EntityTable || CEntity_GetTable( pEntity )

	EntityTable.MELEE_flStart = nil
	EntityTable.MELEE_flHit = nil
	EntityTable.MELEE_flEnd = nil

	EntityTable.MELEE_flDamage = nil
	EntityTable.MELEE_flRadius = nil
	EntityTable.MELEE_vRadius = nil

	EntityTable.MELEE_bCharge = nil
end

// Not entity pointers because it is actually originally made for Actor Bullseyes
function CopyMeleeData( EntityTableTo, EntityTableFrom )
	if CurTime() > ( EntityTableFrom.MELEE_flEnd || 0 ) then return end

	EntityTableTo.MELEE_flStart = EntityTableFrom.MELEE_flStart
	EntityTableTo.MELEE_flHit = EntityTableFrom.MELEE_flHit
	EntityTableTo.MELEE_flEnd = EntityTableFrom.MELEE_flEnd

	EntityTableTo.MELEE_flDamage = EntityTableFrom.MELEE_flDamage
	EntityTableTo.MELEE_flRadius = EntityTableFrom.MELEE_flRadius
	EntityTableTo.MELEE_vRadius = EntityTableFrom.MELEE_vRadius

	EntityTableTo.MELEE_bCharge = EntityTableFrom.MELEE_bCharge
end

local IsValid = IsValid
local insert = table.insert

function SimpleRelatedFilter( pEntity )
	local tFilter = { pEntity }
	local pVehicle = pEntity.GAME_pVehicle
	if IsValid( pVehicle ) then insert( tFilter, pVehicle ) end
	return tFilter
end

function SimpleRelatedFilterDouble( pEntity, pEnemy )
	local tFilter = { pEntity, pEnemy }
	local pVehicle = pEntity.GAME_pVehicle
	if IsValid( pVehicle ) then insert( tFilter, pVehicle ) end
	local pVehicle = pEnemy.GAME_pVehicle
	if IsValid( pEnemy ) then insert( tFilter, pEnemy ) end
	return tFilter
end

local SimpleRelatedFilter = SimpleRelatedFilter
local SimpleRelatedFilterDouble = SimpleRelatedFilterDouble

function SimpleRelatedFilterSingleDouble( pEntity, pOptional )
	return IsValid( pOptional ) && SimpleRelatedFilterDouble( pEntity, pOptional ) || SimpleRelatedFilter( pEntity )
end

function SimpleRelatedFilterTriple( pEntity, pBullseye, pEnemy )
	local tFilter = { pEntity, pEnemy, pBullseye }
	local pVehicle = pEntity.GAME_pVehicle
	if IsValid( pVehicle ) then insert( tFilter, pVehicle ) end
	local pVehicle = pEnemy.GAME_pVehicle
	if IsValid( pEnemy ) then insert( tFilter, pEnemy ) end
	return tFilter
end

local SimpleRelatedFilterTriple = SimpleRelatedFilterTriple

function SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy )
	return pEnemy == pTrueEnemy && SimpleRelatedFilterDouble( self, pEnemy ) || SimpleRelatedFilterTriple( self, pEnemy, pTrueEnemy )
end

BIOLOGICAL_ONLY_DAMAGE_TYPES = {
	[ DMG_POISON ] = true,
	[ DMG_NERVEGAS ] = true,
	[ DMG_PARALYZE ] = true,
	[ DMG_RADIATION ] = true,
	[ DMG_DROWN ] = true,
	[ DMG_DROWNRECOVER ] = true
	// No DMG_ACID, as armor takes damage from acid over time!
}

ACCELERATION_NORMAL = 5
GRAVITY_NORMAL = 1200

HUMAN_SPRINT_SPEED = 350
HUMAN_JOG_SPEED = 200 + 1 / .03
HUMAN_WALK_SPEED = 75

HUMAN_JUMP_HEIGHT = 48

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

local RealTime = RealTime
local FrameTime = FrameTime
local math_cos = math.cos
local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local CEntity_IsOnGround = CEntity.IsOnGround
local IN_WALK = IN_WALK
local IN_DUCK = IN_DUCK
local CPlayer_KeyDown = FindMetaTable( "Player" ).KeyDown
local SysTime = SysTime
local math_min = math.min
local physenv_GetLastSimulationTime = physenv.GetLastSimulationTime
local Vector = Vector
local math_deg = math.deg
local math_acos = math.acos
local hook_Run = hook.Run
local CEntity_LookupSequence = CEntity.LookupSequence
local CEntity_GetOwner = CEntity.GetOwner
local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local CurTime = CurTime
local CEntity_SetVelocity = CEntity.SetVelocity
local math_Approach = math.Approach
local min = math.min

physenv.SetGravity( Vector( 0, 0, -514.83 ) )

hook.Add( "PlayerStepSoundTime", "Improvements", function( ply, EType, bWalk )
	if ply:GetNW2Bool "CTRL_bSprinting" then return 350 end
	return 500
end )

function QuickSlide_Can( ply, t )
	if t == nil then t = CEntity_GetTable( ply ) end
	local flNextSlide = t.GAME_flNextSlide
	if flNextSlide && CurTime() <= flNextSlide then return end
	return !CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) && !t.CTRL_bCantSlide && CEntity_IsOnGround( ply ) && GetVelocity( ply ):Length() >= ( ply:GetRunSpeed() * .9  )
end

hook.Add( "StartCommand", "Improvements", function( ply, cmd )
	local ang = cmd:GetViewAngles()

	local PlyTable = CEntity_GetTable( ply )

	local flFrameTime = SysTime() - ( PlyTable.GAME_flLastStartCommandCall || SysTime() )
	PlyTable.GAME_flLastStartCommandCall = SysTime()

	local pActiveWeapon = ply:GetActiveWeapon()
	local flDelay, flRecoil, flMultiplier = .1, 1, 1
	local bAutomatic
	if IsValid( pActiveWeapon ) then
		local WeaponTable = CEntity_GetTable( pActiveWeapon )

		local tPrimary = WeaponTable.Primary
		if tPrimary then bAutomatic = tPrimary.Automatic end

		if WeaponTable.__WEAPON__ then
			flDelay = WeaponTable.Primary_flDelay || flDelay
			if flDelay then
				flDelay = min( flDelay, .2 )
				flRecoil = WeaponTable.flRecoil
				flMultiplier = WeaponTable.CalculateRecoilMultiplier( pActiveWeapon, ply, WeaponTable )
			end
		end
	end

	local flDecaySpeedFrameTimed = flRecoil / ( flDelay * .85 ) ^ 2 * flFrameTime

	local flRecoilImpulseUp = math_Approach( PlyTable.GAME_flRecoilImpulseUp || 0, 0, flDecaySpeedFrameTimed )
	PlyTable.GAME_flRecoilImpulseUp = flRecoilImpulseUp

	local flRecoilImpulseRight = math_Approach( PlyTable.GAME_flRecoilImpulseRight || 0, 0, flDecaySpeedFrameTimed )
	PlyTable.GAME_flRecoilImpulseRight = flRecoilImpulseRight

	ang[ 1 ] = ang[ 1 ] - flRecoilImpulseUp * flMultiplier * flFrameTime
	ang[ 2 ] = ang[ 2 ] - flRecoilImpulseRight * flMultiplier * flFrameTime

	if cmd:KeyDown( IN_ZOOM ) || cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) then
		local flBreathe = RealTime() * .5
		local flForce = flFrameTime * .5
		ang[ 1 ] = ang[ 1 ] + math_cos( flBreathe ) * flForce
		ang[ 2 ] = ang[ 2 ] + math_cos( flBreathe * .5 ) * flForce
	end

	// TODO: Implement terror when we're near lots of bodies
	local flTerror = ply:GetNW2Float( "BODY_flTerror", 0 )
	if flTerror > 0 then
		local flBreathe = RealTime() * 2 * flTerror
		local flForce = flFrameTime * 2 * flTerror
		ang[ 1 ] = ang[ 1 ] + math_cos( flBreathe ) * flForce
		ang[ 2 ] = ang[ 2 ] + math_cos( flBreathe * .5 ) * flForce
	end

	cmd:SetViewAngles( ang )

	// No, this is not a mistake. Only automatic weapons get the penalty.
	// Why? Idunno, it just feels better.
	if bAutomatic then
		if CurTime() >= ( PlyTable.GAME_flSpamPenalty || 0 ) && ply:KeyReleased( IN_ATTACK ) then PlyTable.GAME_flSpamPenalty = CurTime() + math.Rand( 0, .085 ) end
		if CurTime() <= ( PlyTable.GAME_flSpamPenalty || 0 ) then cmd:RemoveKey( IN_ATTACK ) end
	end

	if CLIENT then
		if cmd:KeyDown( IN_WALK ) then ply.GAME_bWalkPressed = true
		elseif ply.GAME_bWalkPressed then ply.GAME_bWantsToWalk = !ply.GAME_bWantsToWalk ply.GAME_bWalkPressed = nil end
		if ply.GAME_bWantsToWalk then cmd:AddKey( IN_WALK ) end
		if ply:GetNW2Bool "CTRL_bSliding" then
			if cmd:KeyDown( IN_DUCK ) then ply.GAME_bDuckPressed = true
			elseif ply.GAME_bDuckPressed then ply.GAME_bWantsToDuck = !ply.GAME_bWantsToDuck ply.GAME_bDuckPressed = nil end
			if ply.GAME_bWantsToDuck then cmd:AddKey( IN_DUCK ) end
		else
			if cmd:KeyDown( IN_DUCK ) then ply.GAME_bDuckPressed = true
			elseif ply.GAME_bDuckPressed then ply.GAME_bWantsToDuck = !ply.GAME_bWantsToDuck ply.GAME_bDuckPressed = nil end
			if ply.GAME_bWantsToDuck then cmd:AddKey( IN_DUCK ) end
			local b = cmd:GetSideMove() != 0 && cmd:GetForwardMove() >= 0 || cmd:GetForwardMove() > 0
			local bVelocity = GetVelocity( ply ):LengthSqr() > 256
			local p = ply:GetActiveWeapon()
			if ( !IsValid( p ) || CurTime() > p:GetNextPrimaryFire() && CurTime() > p:GetNextSecondaryFire() ) && !QuickSlide_Can( ply ) && bVelocity && cmd:KeyDown( IN_SPEED ) && b then
				cmd:RemoveKey( IN_DUCK )
				ply.GAME_bWantsToDuck = nil
				ply.GAME_bDuckPressed = nil
				ply.GAME_bWantsToWalk = nil
				ply.GAME_bWalkPressed = nil
			end
		end
	end

	// Lovely crouch jumping fix! :D
	if ply:IsOnGround() then
		ply.GAME_bDuckLast = cmd:KeyDown( IN_DUCK )
	else
		if ply.GAME_bDuckLast then
			// So, technically, crouch jumping only extends height if you crouch midair.
			// We're letting people uncrouch midair for logical reasons - air doesn't
			// just magically paralyze all your muscles. I really do want people to
			// be able to crouch in air too, but that extends height... you know,
			// the literal reason this fix exists?
			if !cmd:KeyDown( IN_DUCK ) then ply.GAME_bDuckLast = nil end
		else cmd:RemoveKey( IN_DUCK ) end
	end

	if GameImprovements_StartCommand then GameImprovements_StartCommand( ply, cmd ) end
end )

local cDisableLevelOfDetail = CreateConVar(
	"bDisableLevelOfDetail",
	0,
	FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_ARCHIVE,
	"Disabled LoD. Not the same LoD that changes model vertices.\n\nThe one which optimizes code.\n\nNOT RECOMMENDED!",
	0, 1
)

function LevelOfDetail( pContainer, Key, flMultiplier )
	if cDisableLevelOfDetail:GetBool() then pContainer[ sKey ] = 0 return true end
	local f = pContainer[ Key ]
	if f then
		if CurTime() <= f then return end
		pContainer[ Key ] = CurTime() + math_min( ( physenv_GetLastSimulationTime() * 7500 ) ^ 1.1 * ( flMultiplier || 1 ), 6 )
		return true
	else pContainer[ Key ] = CurTime() + math_min( ( physenv_GetLastSimulationTime() * 7500 ) ^ 1.1 * ( flMultiplier || 1 ), 6 ) end
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
	// TODO: Maybe add a server option to replace this with the sound duration of the source?
	ReadSpeed = CreateClientConVar(
		"ReadSpeed",
		10,
		true,
		true,
		"How fast can you read? In characters per second.",
		6
	)

	local ReadSpeed = ReadSpeed

	local table_concat = table.concat
	local tBuffer = { "<I>", "", "", "<I>" }
	local gui_AddCaption = gui.AddCaption
	local language_GetPhrase = language.GetPhrase
	local gsub = string.gsub
	local math_min = math.min
	local Format = Format
	local random = math.random
	local string_Explode = string.Explode
	
	local net_ReadColor = net.ReadColor
	local net_ReadString = net.ReadString
	local net_ReadFloat = net.ReadFloat

	net.Receive( "CaptionSound", function()
		local cColor = net_ReadColor( false )
		local sSound = net_ReadString()
		local flDuration = net_ReadFloat()
		sSound = "Caption_" .. sSound
		local sCaption = language_GetPhrase( sSound )
		if sCaption == sSound then return end

		sCaption = gsub( sCaption, "%[(.-)%]", function( sMatch )
			local tOptions = string_Explode( "/", sMatch )
			return tOptions[ random( #tOptions ) ]
		end )

		tBuffer[ 2 ] = Format( "<clr:%d,%d,%d>", cColor.r, cColor.g, cColor.b )
		tBuffer[ 3 ] = sCaption

		local sLength = #gsub( sCaption, "<.->", "" ) // For measuring actual length

		gui_AddCaption( table_concat( tBuffer ), math_min( flDuration, sLength / ReadSpeed:GetFloat() ) )
	end )
end

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

CEntity_OBBMinsInternal = CEntity_OBBMinsInternal || CEntity.OBBMins
CEntity_OBBMaxsInternal = CEntity_OBBMaxsInternal || CEntity.OBBMaxs

local CEntity_OBBMinsInternal = CEntity_OBBMinsInternal
local CEntity_OBBMaxsInternal = CEntity_OBBMaxsInternal

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

hook.Add( "PlayerFootstep", "Improvements", function( ply, vPos )
	local flSpeed = GetVelocity( ply ):Length()
	if ply:GetNW2Bool "CTRL_bSliding" then return true end

	local flForce = 1

	if flSpeed <= ply:GetWalkSpeed() * 1.1 then
		flForce = 1.5
	elseif flSpeed <= ply:GetRunSpeed() * 1.1 then
		flForce = 2
	end

	// Tip_Walking8: Different surfaces make different amounts of noise. The loudest is water, the exception being the ocean floor, walking on which makes almost no sound.
	if ply:WaterLevel() == 1 then
		local pEffectData = EffectData()
		pEffectData:SetOrigin( vPos )
		pEffectData:SetScale( flForce * 5 )
		util.Effect( "FootstepSplash", pEffectData )
	end
end )

function SetHumanPlayer( ply )
	ply:SetNPCClass( CLASS_HUMAN )
	ply:SetHealth( 100 )
	ply:SetMaxHealth( 100 )
	ply:SetRunSpeed( HUMAN_SPRINT_SPEED )
	ply:SetWalkSpeed( HUMAN_JOG_SPEED )
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

function GetOwner( self )
	local owner = CEntity_GetOwner( self )
	if IsValid( owner ) then return GetOwner( owner ) end
	return self
end

function GetVelocity( ent )
	local EntTable = CEntity_GetTable( ent )
	local v = EntTable.__VELOCITY__
	if v then return v end
	v = EntTable.GAME_pVehicle
	if IsValid( pVehicle ) && pVehicle != ent then return GetVelocity( v ) end
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

function SetVelocity( ent, vVelocity )
	local EntTable = CEntity_GetTable( ent )
	local pVehicle = EntTable.GAME_pVehicle
	if IsValid( pVehicle ) && pVehicle != ent then SetVelocity( pVehicle, vVelocity ) return end
	if EntTable.__SetVelocity__ then EntTable.__SetVelocity__( ent, vVelocity, EntTable ) end
	if ent:IsPlayer() then
		CEntity_SetVelocity( ent, vVelocity - CEntity_GetVelocity( ent ) )
	elseif ent:IsNPC() then CEntity_SetVelocity( ent, vVelocity ) else
		if SERVER && ent:IsNextBot() then EntTable.loco:SetVelocity( vVelocity ) return end
		local phys = CEntity_GetPhysicsObject( ent )
		if IsValid( phys ) then phys:SetVelocity( vVelocity ) end
	end
end

function AddVelocity( ent, vVelocity )
	local EntTable = CEntity_GetTable( ent )
	local pVehicle = EntTable.GAME_pVehicle
	if IsValid( pVehicle ) && pVehicle != ent then AddVelocity( pVehicle, vVelocity ) return end
	if EntTable.__AddVelocity__ then EntTable._AddVelocity__( ent, vVelocity, EntTable ) end
	if ent:IsPlayer() then
		CEntity_SetVelocity( ent, vVelocity )
	elseif ent:IsNPC() then CEntity_SetVelocity( ent, CEntity_GetVelocity( ent ) + vVelocity ) else
		if SERVER && ent:IsNextBot() then
			local pLocomotion = EntTable.loco
			pLocomotion:SetVelocity( pLocomotion:GetVelocity() + vVelocity )
			return
		end
		local phys = CEntity_GetPhysicsObject( ent )
		if IsValid( phys ) then phys:AddVelocity( vVelocity ) end
	end
end

if CLIENT then
	g_pActiveGlowEntities = g_pActiveGlowEntities || {}

	hook.Add( "PostDrawTranslucentRenderables", "ZBufferFuckery", function( bDepth, bSkybox )
		if bSkybox then return end

		for pEntity, fFunction in pairs( g_pActiveGlowEntities ) do
			if !IsValid( pEntity ) then 
				g_pActiveGlowEntities[ pEntity ] = nil 
				continue 
			end

			if pEntity:IsDormant() then continue end

			fFunction( pEntity )
		end
	end )
end
