local math = math
local math_Remap = math.Remap
function GetFlameStopChance( self ) return math_Remap( GetVelocity( self ):Length(), 0, 800, 20000, 1000 ) end

concommand.Add( "+drop", function() end )
concommand.Add( "-drop", function( ply ) ply:DropWeapon() end )

ACCELERATION_NORMAL = 5

HUMAN_RUN_SPEED, HUMAN_PROWL_SPEED, HUMAN_WALK_SPEED, HUMAN_JUMP_HEIGHT = 300, 200, 75, 52

local RunConsoleCommand = RunConsoleCommand
RunConsoleCommand( "sv_accelerate", ACCELERATION_NORMAL )
RunConsoleCommand( "sv_friction", "4" )

HULL_HUMAN_MINS, HULL_HUMAN_MAXS = Vector( -16, -16, 0 ), Vector( 16, 16, 72 )
HULL_HUMAN_DUCK_MINS, HULL_HUMAN_DUCK_MAXS = Vector( -16, -16, 0 ), Vector( 16, 16, 36 )

local bit_band = bit.band
function HasRangeAttack( ent )
	if ent.HAS_RANGE_ATTACK then return true end
	if ent.HAS_NOT_RANGE_ATTACK then return end
	if ent.CapabilitiesGet then
		local c = ent:CapabilitiesGet()
		if bit_band( c, CAP_WEAPON_RANGE_ATTACK1 ) != 0 ||
		bit_band( c, CAP_WEAPON_RANGE_ATTACK2 ) != 0 ||
		bit_band( c, CAP_INNATE_RANGE_ATTACK1 ) != 0 ||
		bit_band( c, CAP_INNATE_RANGE_ATTACK2 ) != 0 then return true end
	end
	if ent.tWeapons then
		for wep in pairs( ent.tWeapons ) do
			if !wep.GetCapabilities then continue end
			local c = wep:GetCapabilities()
			if bit_band( c, CAP_WEAPON_RANGE_ATTACK1 ) != 0 ||
			bit_band( c, CAP_WEAPON_RANGE_ATTACK2 ) != 0 ||
			bit_band( c, CAP_INNATE_RANGE_ATTACK1 ) != 0 ||
			bit_band( c, CAP_INNATE_RANGE_ATTACK2 ) != 0 then return true end
		end
	elseif ent.GetWeapons then
		for _, wep in ipairs( ent:GetWeapons() ) do
			if !wep.GetCapabilities then continue end
			local c = wep:GetCapabilities()
			if bit_band( c, CAP_WEAPON_RANGE_ATTACK1 ) != 0 ||
			bit_band( c, CAP_WEAPON_RANGE_ATTACK2 ) != 0 ||
			bit_band( c, CAP_INNATE_RANGE_ATTACK1 ) != 0 ||
			bit_band( c, CAP_INNATE_RANGE_ATTACK2 ) != 0 then return true end
		end
	end
end
function HasMeleeAttack( ent )
	if ent.HAS_MELEE_ATTACK || IsValid( ent.GAME_pVehicle ) then return true end
	if ent.HAS_NOT_MELEE_ATTACK then return end
	if ent.CapabilitiesGet then
		local c = ent:CapabilitiesGet()
		if bit_band( c, CAP_WEAPON_MELEE_ATTACK1 ) != 0 ||
		bit_band( c, CAP_WEAPON_MELEE_ATTACK2 ) != 0 ||
		bit_band( c, CAP_INNATE_MELEE_ATTACK1 ) != 0 ||
		bit_band( c, CAP_INNATE_MELEE_ATTACK2 ) != 0 then return true end
	end
	if ent.tWeapons then
		for wep in pairs( ent.tWeapons ) do
			if !wep.GetCapabilities then continue end
			local c = wep:GetCapabilities()
			if bit_band( c, CAP_WEAPON_MELEE_ATTACK1 ) != 0 ||
			bit_band( c, CAP_WEAPON_MELEE_ATTACK2 ) != 0 ||
			bit_band( c, CAP_INNATE_MELEE_ATTACK1 ) != 0 ||
			bit_band( c, CAP_INNATE_MELEE_ATTACK2 ) != 0 then return true end
		end
	elseif ent.GetWeapons then
		for _, wep in ipairs( ent:GetWeapons() ) do
			if !wep.GetCapabilities then continue end
			local c = wep:GetCapabilities()
			if bit_band( c, CAP_WEAPON_MELEE_ATTACK1 ) != 0 ||
			bit_band( c, CAP_WEAPON_MELEE_ATTACK2 ) != 0 ||
			bit_band( c, CAP_INNATE_MELEE_ATTACK1 ) != 0 ||
			bit_band( c, CAP_INNATE_MELEE_ATTACK2 ) != 0 then return true end
		end
	end
end

// Intentionally generates UUIDs instead of truly unique numbers for extremely rare funni bugs
function EntityUniqueIdentifier( ent )
	if ent.__UNIQUE_IDENTIFIER__ then return ent.__UNIQUE_IDENTIFIER__ end
	local t = {}
	for _ = 1, 16 do
		local i = math.random( 1, 3 )
		if i == 1 then table.insert( t, string.char( math.random( 65, 90 ) ) ) // A-Z
		elseif i == 2 then table.insert( t, string.char( math.random( 97, 122 ) ) ) // a-z
		else table.insert( t, math.random( 0, 9 ) ) end
	end
	ent.__UNIQUE_IDENTIFIER__ = table.concat( t )
	return ent.__UNIQUE_IDENTIFIER__
end

// local tIgnoreRangeAttackDisp = { [ D_NU ] = true, [ D_LI ] = true }
local util_ScreenShake, util_DistanceToLine = util.ScreenShake, util.DistanceToLine
RANGE_ATTACK_SUPPRESSION_BOUND_SIZE = 512
function DispatchRangeAttack( Owner, vStart, vEnd, flDamage )
	local flAmplitude, flFrequency, flDuration = flDamage * .024, flDamage * .0016, math.min( 4, flDamage * .1 )
	local ang = ( vEnd - vStart ):Angle()
	for _, ent in ipairs( ents.FindAlongRay( vStart, vEnd, Vector( -RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, -RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, -RANGE_ATTACK_SUPPRESSION_BOUND_SIZE ), Vector( RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, RANGE_ATTACK_SUPPRESSION_BOUND_SIZE ) ) ) do
		if ent == Owner || Owner.Disposition && Owner:Disposition( ent ) == D_LI || ent.Disposition && ent:Disposition( Owner ) == D_LI then continue end
		if ent.GAME_tSuppressionAmount then
			ent.GAME_tSuppressionAmount[ Owner ] = ( ent.GAME_tSuppressionAmount[ Owner ] || 0 ) + flDamage
		else ent.GAME_tSuppressionAmount = { [ Owner ] = flDamage } end
		local f = ent.GAME_OnRangeAttacked
		if f == nil then if ent.GAME_flSuppression then ent.GAME_flSuppression = ent.GAME_flSuppression + flDamage end else f( ent, Owner, vStart, vEnd, flDamage ) end
		if ent.__ACTOR__ then
			if ent == Owner || Owner.Disposition && Owner:Disposition( ent ) == D_LI || ent.Disposition && ent:Disposition( Owner ) == D_LI then continue end
			local _, v = util_DistanceToLine( vStart, vEnd, ent:EyePos() )
			if ent:CanSee( v ) && ent:WillAttackFirst( Owner ) then ent:SetupBullseye( Owner, vStart, ang ) end
		end
	end
	// Too cheaty - makes silencers almost completely useless
	//	local ang = ( vEnd - vStart ):Angle()
	//	for ent in pairs( __ACTOR_LIST__ ) do
	//		if ent == Owner || Owner.Disposition && tIgnoreRangeAttackDisp[ Owner:Disposition( ent ) ] || ent.Disposition && tIgnoreRangeAttackDisp[ ent:Disposition( Owner ) ] then continue end
	//		local _, v = util_DistanceToLine( vStart, vEnd, ent:EyePos() )
	//		if ent:CanSee( v ) then ent:SetupBullseye( Owner, vStart, ang ) end
	//	end
end

local function fOnKilled( pEntity, pAttacker )
	if pAttacker:IsPlayer() then
		Achievement_Miscellaneous( pAttacker, "Kill" )
		local f = pAttacker:GetNW2Int "CTRL_Peek"
		if f == COVER_BLINDFIRE_LEFT || f == COVER_BLINDFIRE_RIGHT || f == COVER_BLINDFIRE_UP then
			Achievement_Miscellaneous( pAttacker, "CoverBlindFireKill" )
		end
	end
end

hook.Add( "DoPlayerDeath", "GameImprovements", function( ply )
	local pWeapon = ply:GetActiveWeapon()
	if IsValid( pWeapon ) then ply:DropWeapon( pWeapon ) end
	for _, pWeapon in ipairs( ply:GetWeapons() ) do ply:DropWeapon( pWeapon ) end
end )
hook.Add( "PlayerDeath", "GameImprovements", function( ply, _, at )
	if IsValid( ply.GAME_pFlashlight ) then ply.GAME_pFlashlight:Remove() end
	if IsValid( at ) && at:IsPlayer() then
		local v = __PLAYER_MODEL__[ at:GetModel() ]
		if v then
			v = v.OnKilledSomething
			if v then if v( at, ply ) then b = nil end end
		end
	end
	fOnKilled( ply, at )
end )
hook.Add( "PlayerDeathSilent", "GameImprovements", function( ply ) if IsValid( ply.GAME_pFlashlight ) then ply.GAME_pFlashlight:Remove() end end )
hook.Add( "PlayerDeathSound", "GameImprovements", function() return true end )

hook.Add( "OnNPCKilled", "GameImprovements", function( ent, at )
	if IsValid( at ) && at:IsPlayer() then
		local v = __PLAYER_MODEL__[ at:GetModel() ]
		if v then
			v = v.OnKilledSomething
			if v then if v( at, ent ) then b = nil end end
		end
	end
	fOnKilled( ent, at )
end )

hook.Add( "PlayerSwitchFlashlight", "GameImprovements", function( ply )
	if !ply:Alive() then if IsValid( ply.GAME_pFlashlight ) then ply:EmitSound "FlashlightOff" ply.GAME_pFlashlight:Remove() end return end
	if IsValid( ply.GAME_pFlashlight ) then ply:EmitSound "FlashlightOff" ply.GAME_pFlashlight:Remove() else
		local pt = ents.Create "env_projectedtexture"
		pt:SetPos( ply:EyePos() )
		pt:SetAngles( ply:EyeAngles() )
		pt:SetOwner( ply )
		pt:SetParent( ply )
		pt:SetKeyValue( "lightfov", "30" )
		pt:SetKeyValue( "lightcolor", "255 255 255 2048" )
		pt:SetKeyValue( "NearZ", "1" )
		pt:SetKeyValue( "FarZ", "2048" )
		pt:Input( "SpotlightTexture", nil, nil, "effects/flashlight/soft" )
		pt:Spawn()
		ply:EmitSound "FlashlightOn"
		ply.GAME_pFlashlight = pt
	end
	return false
end )

local util_TraceLine = util.TraceLine

hook.Add( "OnEntityCreated", "GameImprovements", function( ent )
	if IsValid( ent ) && ent:IsWeapon() then
		timer.Simple( .01, function() if IsValid( ent ) then ent.GAME_bWeaponPickedUpOnce = true end end )
	end
end )

local function GrantWeaponAchievement( ply, wep )
	local sAchievement = "Acquire_" .. wep:GetClass()
	if __ACHIEVEMENTS__[ sAchievement ] then
		local s = ply:SteamID64()
		local t = __ACHIEVEMENTS_ACQUIRED__[ s ]
		if t then
			if !t[ sAchievement ] then
				ply:SendLua( "Achievement_Acquire(" .. "\"" .. wep:GetClass() .. "\"" .. ")" )
				t[ sAchievement ] = true
			end
		else
			ply:SendLua( "Achievement_Acquire(" .. "\"" .. wep:GetClass() .. "\"" .. ")" )
			__ACHIEVEMENTS_ACQUIRED__[ s ] = { [ sAchievement ] = true }
		end
	end
end

hook.Add( "PlayerCanPickupWeapon", "GameImprovements", function( ply, wep )
	if !wep.GAME_bWeaponPickedUpOnce then
		GrantWeaponAchievement( ply, wep )
		local w = ply:GetWeapon( wep:GetClass() )
		if IsValid( w ) && !w.__GRENADE__ then ply:DropWeapon( w ) end
		wep.GAME_bWeaponPickedUpOnce = true
		return true
	end
	if !ply:KeyDown( IN_USE ) then return false end
	local tr = util_TraceLine {
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:GetAimVector() * 999999,
		filter = ply
	}
	if tr.Entity != wep then return false end
	local c = wep:GetClass()
	local w = ply:GetWeapon( c )
	if w.__GRENADE__ then return true end
	ply:DropObject()
	wep:ForcePlayerDrop()
	// Make them switch to the gun because they CONSCIOUSLY picked it up,
	// not just randomly got it from the floor and accidentally self stunlocked in the deploy animation
	ply.GAME_sRestoreGun = c
	if IsValid( w ) then ply:DropWeapon( w ) end
	GrantWeaponAchievement( ply, wep )
end )
hook.Add( "PlayerCanPickupItem", "GameImprovements", function( ply, item )
	if !ply:KeyDown( IN_USE ) then return false end
	local tr = util_TraceLine {
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:GetAimVector() * 999999,
		filter = ply
	}
	return tr.Entity == item
end )

local math_max = math.max

hook.Add( "PlayerHurt", "GameImprovements", function( ply, pAttacker, flHealth, flDamage )
	ply:SetNW2Float( "GAME_flBleeding", ply:GetNW2Float( "GAME_flBleeding", 0 ) +
	flDamage / ( math_max( ply:Health(), ply:GetMaxHealth() ) * 112 ) )
	local b = true
	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	if v then
		v = v.Hurt
		if v then if v( ply, pAttacker, flHealth, flDamage ) then b = nil end end
	end
	if b then
		b = !ply.GAME_bSecondHurtViewPunch
		ply.GAME_bSecondHurtViewPunch = b
		local f = ply:GetMaxHealth()
		ply:ViewPunch( Angle( 0, 0, flDamage * ( flHealth > f && .01 || math.Remap( flHealth, 0, f, .05, .01 ) ) * ( b && 1 || -1 ) ) )
	end
end )

hook.Add( "PlayerCanHearPlayersVoice", "GameImprovements", function( pListener, pSpeaker )
	if pListener:GetPos():DistToSqr( pSpeaker:GetPos() ) > ( pListener.GAME_flSpeakDistanceSqr || 13249600/*3640*/ ) then return false end
	return true, true
end )

hook.Add( "PlayerCanSeePlayersChat", "GameImprovements", function( _/*sText*/, _/*bTeamOnly*/, pListener, pSpeaker )
	if !IsValid( pSpeaker ) then return end
	return pListener:GetPos():DistToSqr( pSpeaker:GetPos() ) > ( pListener.GAME_flSpeakDistanceSqr || 13249600/*3640*/ )
end )

hook.Add( "GetFallDamage", "GameImprovements", function( ply, flSpeed )
	local flRatio = flSpeed / ( ply:GetJumpPower() * 1.5 )
	if flRatio <= 1 then return 0 end
	Achievement_Miscellaneous( ply, "Fall" )
	return flRatio * 32
end )

hook.Add( "CreateEntityRagdoll", "GameImprovements", function( pOwner, pRagdoll )
	local f = pOwner.OnBulletImpact
	if f then pRagdoll.OnBulletImpact = f end
end )

TRACER_COLOR = {
	Bullet = { 255, 48, 0, 1024 },
	AR2Tracer = { 48, 255, 255, 1024 },
	HelicopterTracer = { 48, 255, 255, 2048 }
}
local TRACER_COLOR = TRACER_COLOR

TRACER_SIZE = { Bullet = 4 }
local TRACER_SIZE = TRACER_SIZE

local IsValid = IsValid

hook.Add( "EntityFireBullets", "GameImprovements", function( ent, Data, _Comp )
	if _Comp then return end
	hook.Run( "EntityFireBullets", ent, Data, true )
	if Data.AmmoType != "" then Data.Damage = game.GetAmmoPlayerDamage( game.GetAmmoID( Data.AmmoType ) ) Data.AmmoType = "" end
	local OldCallBack = Data.Callback || function() return { damage = true, effects = true } end
	local flDamage = Data.Damage
	local col
	local bTracer = Data.Tracer > 0
	// TODO: Find a way to conceal tracers of your own gun in first person,
	// that will make the crosshair disappearing actually matter
	if bTracer then col = TRACER_COLOR[ Data.TracerName || "Bullet" ] || TRACER_COLOR.Bullet end
	if Data.HullSize == 0 then Data.HullSize = TRACER_SIZE[ Data.TracerName || "Bullet" ] || TRACER_SIZE.Bullet end
	local pOwner = GetOwner( ent )
	Data.Callback = function( atk, tr, dmg )
		DispatchRangeAttack( atk, tr.StartPos, tr.HitPos, flDamage )
		local pTarget, vTargetVelocity, dDamage = tr.Entity
		local bTarget = IsValid( pTarget )
		if bTarget then
			vTargetVelocity = ent:GetVelocity()
			dDamage = DamageInfo()
			dDamage:SetAttacker( pOwner )
			// Not setting the inflictor prevents WALK and STEP movetype knockback
			// dDamage:SetInflictor( ent )
			dDamage:SetDamage( dmg:GetDamage() )
			dDamage:SetDamageType( DMG_BULLET )
			dDamage:SetDamagePosition( tr.HitPos )
		end
		local t = OldCallBack( atk, tr, dDamage ) || { damage = true, effects = true }
		if t.damage && bTarget then pTarget:TakeDamageInfo( dDamage ) end
		local b = t.effects
		if !bTracer || !b then return { damage = false, effects = b } end
		t = pTarget.OnBulletImpact
		if t then t( pTarget, dDamage ) end
		local pt = ents.Create "env_projectedtexture"
		pt:SetPos( tr.StartPos )
		pt:SetAngles( ( tr.HitPos - tr.StartPos ):GetNormalized():Angle() )
		pt:SetKeyValue( "lightfov", "110" )
		pt:SetKeyValue( "lightcolor", table.concat( col, " " ) )
		pt:SetKeyValue( "farz", "256" )
		pt:Input( "SpotlightTexture", nil, nil, "effects/flashlight/soft" )
		pt:SetOwner( GetOwner( ent ) )
		pt:Spawn()
		timer.Simple( .1, function() if IsValid( pt ) then pt:Remove() end end )
		net.Start "DynamicLight"
			net.WriteFloat( col[ 4 ] * .008 ) // Brightness
			net.WriteFloat( 32 ) // Size
			net.WriteFloat( 4 ) // Existence length
			net.WriteVector( tr.HitPos ) // Position
			net.WriteUInt( col[ 1 ], 8 ) net.WriteUInt( col[ 2 ], 8 ) net.WriteUInt( col[ 3 ], 8 ) // R, G, B
		net.Broadcast()
		return { damage = false, effects = true }
	end
	return true
end )

local PersistAll = CreateConVar( "PersistAll", 1, FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_ARCHIVE, "Everything persists", 0, 1 )

hook.Add( "PhysgunPickup", "GameImprovements", function() return true end )

local CEntity = FindMetaTable "Entity"
local CEntity_IsOnFire = CEntity.IsOnFire
local CEntity_Ignite = CEntity.Ignite

function PhysicsCollide( ent, Data )
	local pOther = Data.HitEntity
	if CEntity_IsOnFire( ent ) || CEntity_IsOnFire( pOther ) then
		CEntity_Ignite( ent, 10 )
		CEntity_Ignite( pOther, 10 )
	end
end

// local math_max = math.max

hook.Add( "EntityTakeDamage", "GameImprovements", function( ent, dmg )
	// Bloodloss works only on players for now, so see PlayerHurt for bloodloss code
	local at = dmg:GetAttacker()
	if IsValid( at ) then
		if at:IsPlayer() then
			local v = __PLAYER_MODEL__[ at:GetModel() ]
			if v then
				v = v.OnHurtSomething
				if v then if v( at, ent, dmg ) then b = nil end end
			end
		end
		local f = at.GAME_OnHurtSomething
		if f then f( at, ent, dmg ) end
	end
end )

local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_Extinguish = CEntity.Extinguish

file.CreateDir "Covers"
file.CreateDir "Achievements"

local ents = ents
local ents_Iterator = ents.Iterator
local cEvents = CreateConVar(
	"bEvents",
	0, // 1 // Forcing this to 0 so that people who
	// simply play the game to build and have fun
	// don't have their stuff destroyed by destructive events
	FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_CHEAT,
	"Allow random events?",
	0, 1
)
local cEventProbability = CreateConVar(
	"flEventProbability",
	250000, // 1 // Forcing this to 0 so that people who
	// simply play the game to build and have fun
	// don't have their stuff destroyed by destructive events
	FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_CHEAT,
	"The probability of random events if bEvents is on",
	0, 1
)
__EVENTS__ = __EVENTS__ || {}
__EVENTS_LENGTH__ = __EVENTS_LENGTH__ || 0 // Don't forget to do this every time you add a new event!
//	if !__EVENTS__.MyEvent then __EVENTS_LENGTH__ = __EVENTS_LENGTH__ + 1 end
//	__EVENTS__.MyEvent = function()
//	end
DONT_CHANGE_DRAW_SHADOW = {
	viewmodel = true,
	predicted_viewmodel = true,
	gmod_hands = true
}
hook.Add( "EntityKeyValue", "GameImprovements", function( pEntity, sKey, sValue )
	if !SUN_HAS_A_NAME && CurTime() > 2 then hook.Remove( "EntityKeyValue", "GameImprovements" ) return end
	if pEntity:GetClass() == "light_environment" then
		sKey = string.lower( sKey )
		if sKey == "targetname" && sValue != "" then SUN_HAS_A_NAME = true
		elseif sKey == "angles" then SUN_ANGLES = Angle( sValue )
		elseif sKey == "pitch" then SUN_PITCH_OVERRIDE = tonumber( sValue ) || 0
		elseif sKey == "_light" then
			local R, G, B, A = sValue:match "(%d+)%s+(%d+)%s+(%d+)%s+(%d+)"
			R, G, B, A = tonumber( R ) || -1, tonumber( G )|| -1, tonumber( B ) || -1, tonumber( A ) || -1
			SUN_COLOR = Color( R, G, B )
			SUN_BRIGHTNESS = A * .004
		end
	end
end )
hook.Add( "Think", "GameImprovements", function()
	file.Write( "Covers/" .. game.GetMap() .. "_" .. game.GetMapVersion() .. ".json", util.TableToJSON( __COVERS_STATIC__ ) )
	file.Write( "Achievements/" .. engine.ActiveGamemode() .. ".json", util.TableToJSON( __ACHIEVEMENTS_ACQUIRED__ ) )
	if cEvents:GetBool() && __EVENTS_LENGTH__ > 0 && math.Rand( 0, cEventProbability:GetFloat() * FrameTime() ) <= 1 then
		local iRemaining, tEncountered = __EVENTS_LENGTH__, {}
		while iRemaining > 0 do
			local fEvent = table.Random( __EVENTS__ )
			if tEncountered[ fEvent ] then continue end
			tEncountered[ fEvent ] = true
			if ProtectedCall( fEvent ) then break end
			iRemaining = iRemaining - 1
		end
	end
	if IsValid( CascadeShadowMapping ) then
		if SUN_ANGLES then
			CascadeShadowMapping:SetPitch( SUN_ANGLES[ 1 ] )
			CascadeShadowMapping:SetYaw( SUN_ANGLES[ 2 ] )
			CascadeShadowMapping:SetRoll( SUN_ANGLES[ 3 ] )
			SUN_ANGLES = nil
		end
		if SUN_PITCH_OVERRIDE then
			CascadeShadowMapping:SetPitch( SUN_PITCH_OVERRIDE )
			SUN_PITCH_OVERRIDE = nil
		end
		if SUN_BRIGHTNESS then
			CascadeShadowMapping:SetBrightness( SUN_BRIGHTNESS )
			SUN_BRIGHTNESS = nil
		end
		if SUN_COLOR then
			CascadeShadowMapping:SetLightColor( SUN_COLOR:ToVector() )
			SUN_COLOR = nil
		end
	end
	for _, ent in ents_Iterator() do
		if ent:GetClass() == "light_environment" then ent:Fire( IsValid( CascadeShadowMapping ) && "turnoff" || "turnon" ) end
		if !DONT_CHANGE_DRAW_SHADOW[ ent:GetClass() ] then ent:DrawShadow( !IsValid( CascadeShadowMapping ) ) end
		if ent.GAME_Think then ent:GAME_Think() end
		if !ent.GAME_bPhysCollideHook then ent:AddCallback( "PhysicsCollide", function( ... ) PhysicsCollide( ... ) end ) ent.GAME_bPhysCollideHook = true end
		if CEntity_WaterLevel( ent ) > 0 || ent.GAME_bDontIgnite then CEntity_Extinguish( ent ) elseif CEntity_IsOnFire( ent ) then CEntity_Ignite( ent, 999999 ) end
		if !ent.GAME_bDontIgnite && CEntity_IsOnFire( ent ) && math.random( ( ent.GAME_bFireBall && 200000 || ( 400000 / ent:BoundingRadius() ) ) * FrameTime() ) == 1 then
			for _ = 0, 3 do
				local dir = VectorRand()
				local tr = util_TraceLine {
					start = ent:GetPos() + ent:OBBCenter(),
					endpos = ent:GetPos() + ent:OBBCenter() + VectorRand() * math.Rand( 0, ent:BoundingRadius() ),
					mask = MASK_SOLID,
					filter = ent
				}
				if tr.Entity == ent then continue end
				local p = ents.Create "prop_physics"
				p:SetPos( tr.HitPos )
				p:SetModel "models/combine_helicopter/helicopter_bomb01.mdl"
				p:SetNoDraw( true )
				p:Spawn()
				p.GAME_bFireBall = true
				local f = ents.Create "env_fire_trail"
				f:SetPos( p:GetPos() )
				f:SetParent( p )
				f:Spawn()
				p:GetPhysicsObject():AddVelocity( VectorRand() * math.Rand( 0, ent:BoundingRadius() * 24 ) )
				AddThinkToEntity( p, function( ent ) CEntity_Ignite( ent, 999999 ) if math.random( GetFlameStopChance( ent ) * FrameTime() ) == 1 || ent:WaterLevel() != 0 then ent:Remove() return true end end )
				break
			end
		end
		if PersistAll:GetBool() && ent:MapCreationID() == -1 && !ent:IsPlayer() && ( !ent:IsWeapon() || ent:IsWeapon() && ( !IsValid( ent:GetOwner() ) || IsValid( ent:GetOwner() ) && !ent:GetOwner():IsPlayer() ) ) then ent:SetPersistent( true ) end
		local tSuppressionAmount = {}
		if ent.GAME_tSuppressionAmount then
			for pSuppressor, am in pairs( ent.GAME_tSuppressionAmount ) do
				if IsValid( pSuppressor ) then
					am = math.Approach( am, 0, math.max( ent:Health() * 2, am * .33 ) * FrameTime() )
					if am <= 0 then continue end
					tSuppressionAmount[ pSuppressor ] = am
				end
			end
		end
		ent.GAME_tSuppressionAmount = tSuppressionAmount
		if ent:IsPlayer() then
			ent:SetNW2Float( "GAME_flSuppressionEffects", math.Clamp( ( ent.GAME_flSuppression || 0 ) / ( ent:Health() * 6 ), 0, 1 ) )
		end
	end
end )

COVER_BOUND_SIZE = 3

// IF YOU EDIT THIS, BE SURE TO EDIT ControlsPrediction.lua TOO!
local CEntity_IsOnGround = CEntity.IsOnGround
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_Remove = CEntity.Remove
local CPlayer = FindMetaTable "Player"
local CPlayer_GetRunSpeed = CPlayer.GetRunSpeed
local CPlayer_Give = CPlayer.Give
local ents_Create = ents.Create
local util_TraceHull = util.TraceHull
local function BloodlossStuff( ply, cmd )
	local flBlood = ply:GetNW2Float( "GAME_flBlood", 1 )
	if flBlood <= .8 then
		cmd:RemoveKey( IN_SPEED )
		ply.CTRL_bSprintBlockUnTilUnPressed = true
		ply.CTRL_bHeldSprint = nil
	end
	if flBlood <= .6 then cmd:AddKey( IN_DUCK ) cmd:AddKey( IN_WALK ) end // Crawling (no proper animation, but that's what I'm trying to simulate)
end
hook.Add( "StartCommand", "GameImprovements", function( ply, cmd )
	if !ply:Alive() then return end

	local veh = ply.GAME_pVehicle
	if IsValid( veh ) then
		if !ply.GAME_sRestoreGun then
			local w = ply:GetActiveWeapon()
			if IsValid( w ) then ply.GAME_sRestoreGun = w:GetClass() end
		end
		if veh.bDriverHoldingUse then
			if !cmd:KeyDown( IN_USE ) then
				veh.bDriverHoldingUse = nil
			end
		else
			if ply:KeyDown( IN_USE ) && veh:ExitVehicle( ply ) then return end
		end
		veh:PlayerControls( ply, cmd )
		cmd:AddKey( IN_DUCK )
		local p = ply:GetWeapon "Hands"
		if !IsValid( p ) then p = ply:Give "Hands" end
		if IsValid( p ) then cmd:SelectWeapon( p ) end
		local p = ply:GetWeapon "HandsSwimInternal"
		if IsValid( p ) then p:Remove() end
		return
	end

	local c = ply:GetModel()
	local v = __PLAYER_MODEL__[ c ]
	if v then
		v = v.StartCommand
		if v && v( ply, cmd ) then return end
	end

	BloodlossStuff( ply, cmd )

	ply:SetLadderClimbSpeed( ply:IsSprinting() && ply:GetRunSpeed() || ply:IsWalking() && ply:GetSlowWalkSpeed() || ply:GetWalkSpeed() )

	local bGround = CEntity_IsOnGround( ply )
	if !bGround && CEntity_WaterLevel( ply ) > 0 then
		if !ply.GAME_sRestoreGun then
			local w = ply:GetActiveWeapon()
			if IsValid( w ) then ply.GAME_sRestoreGun = w:GetClass() end
		end
		local p = ply:GetWeapon "Hands"
		if IsValid( p ) then p:Remove() end
		local p = ply:GetWeapon "HandsSwimInternal"
		if !IsValid( p ) then p = ply:Give "HandsSwimInternal" end
		if IsValid( p ) then cmd:SelectWeapon( p ) end
		ply:SetNW2Bool( "CTRL_bSliding", false )
		return
	else
		local p = ply:GetWeapon "Hands"
		if !IsValid( p ) then
			local sRestoreGun = ply.GAME_sRestoreGun
			p = ply:Give "Hands"
			ply.GAME_sRestoreGun = sRestoreGun
		end
		if IsValid( p ) && !IsValid( ply:GetActiveWeapon() ) then
			local sRestoreGun = ply.GAME_sRestoreGun
			cmd:SelectWeapon( p )
			ply.GAME_sRestoreGun = sRestoreGun
		end
		local p = ply:GetWeapon "HandsSwimInternal"
		if IsValid( p ) then p:Remove() end
	end

	local s = ply.GAME_sRestoreGun
	if s then
		local w = ply:GetWeapon( s )
		if IsValid( w ) then cmd:SelectWeapon( w ) end
		ply.GAME_sRestoreGun = nil
	end

	if ply:GetNW2Bool "CTRL_bSliding" then cmd:RemoveKey( IN_ATTACK ) cmd:RemoveKey( IN_ATTACK2 ) end

	if cmd:KeyDown( IN_ZOOM ) then cmd:AddKey( IN_WALK )
	elseif !cmd:KeyDown( IN_SPEED ) then
		local b = cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 )
		if b then cmd:AddKey( IN_WALK ) else
			local p = ply:GetActiveWeapon()
			if IsValid( p ) && ( CurTime() <= p:GetNextPrimaryFire() || CurTime() <= p:GetNextSecondaryFire() ) then cmd:AddKey( IN_WALK ) end
		end
	end

	if ply.CTRL_bSprintBlockUnTilUnPressed then
		if !cmd:KeyDown( IN_SPEED ) then ply.CTRL_bSprintBlockUnTilUnPressed = nil end
		cmd:RemoveKey( IN_SPEED )
	end

	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	local bAllDirectionalSprint = Either( v, v && v.bAllDirectionalSprint, ply.CTRL_bAllDirectionalSprint ) || ( ( Either( ply.CTRL_bCantSlide == nil, __PLAYER_MODEL__[ ply:GetModel() ] && __PLAYER_MODEL__[ ply:GetModel() ].bCantSlide, ply.CTRL_bCantSlide ) && GetVelocity( ply ):Length() >= ply:GetRunSpeed() ) || ply:Crouching() )
	if bAllDirectionalSprint then
		ply:SetNW2Bool( "CTRL_bSprinting", false )
		ply:SetCrouchedWalkSpeed( 1 )
	else
		local bGroundCrouchingAndNotSliding = ply:Crouching() && !ply:GetNW2Bool "CTRL_bSliding"
		if bGroundCrouchingAndNotSliding || cmd:KeyDown( IN_ZOOM ) || !( cmd:KeyDown( IN_FORWARD ) || cmd:KeyDown( IN_BACK ) || cmd:KeyDown( IN_MOVELEFT ) || cmd:KeyDown( IN_MOVERIGHT ) ) then ply.CTRL_bHeldSprint = nil cmd:RemoveKey( IN_SPEED ) end
		if !bGroundCrouchingAndNotSliding && cmd:KeyDown( IN_SPEED ) || ply.CTRL_bHeldSprint then
			ply.CTRL_bHeldSprint = true
			cmd:AddKey( IN_SPEED )
			local p = ply:GetActiveWeapon()
			if cmd:GetForwardMove() <= 0 || IsValid( p ) && ( CurTime() <= p:GetNextPrimaryFire() || CurTime() <= p:GetNextSecondaryFire() ) then
				// ply.CTRL_bSprintBlockUnTilUnPressed = true
				if bGround then ply.CTRL_bHeldSprint = nil end
				cmd:RemoveKey( IN_SPEED )
				ply:SetNW2Bool( "CTRL_bSprinting", false )
			else
				cmd:SetForwardMove( CPlayer_GetRunSpeed( ply ) )
				cmd:SetSideMove( math.Clamp( cmd:GetSideMove(), -cmd:GetForwardMove(), cmd:GetForwardMove() ) )
				local b = ply:GetVelocity():Length() > ply:GetWalkSpeed()
				ply:SetNW2Bool( "CTRL_bSprinting", b )
				if b then
					if cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) || cmd:KeyDown( IN_ZOOM ) then
						ply.CTRL_bSprintBlockUnTilUnPressed = true
						ply.CTRL_bHeldSprint = nil
						cmd:RemoveKey( IN_SPEED )
						ply:SetNW2Bool( "CTRL_bSprinting", false )
					end
				end
			end
		else
			ply:SetNW2Bool( "CTRL_bSprinting", false )
		end
	end
	//	if !ply:IsOnGround() then
	//		local v = __PLAYER_MODEL__[ ply:GetModel() ]
	//		if CEntity_WaterLevel( ply ) <= 0 && !Either( v == nil, ply.CTRL_bAllowMovingWhileInAir, v && v.bAllowMovingWhileInAir ) && ply:GetMoveType() == MOVETYPE_WALK then
	//			// cmd:SetForwardMove( 0 )
	//			cmd:SetSideMove( 0 )
	//		end
	//		// ply:SetNW2Bool( "CTRL_bSprinting", false )
	//	end

	local s = ply.GAME_sCoverState
	if s then
		if s == "DUCK" then
			if cmd:KeyDown( IN_ZOOM ) then
				ply.GAME_flPeekFireTime = nil
			elseif cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) then
				ply.GAME_flPeekFireTime = CurTime() + .2
			elseif CurTime() > ( ply.GAME_flPeekFireTime || 0 ) then
				ply.GAME_sCoverState = nil
				ply.GAME_flPeekUpMinimumTime = nil
				return
			end
			if !ply.GAME_flPeekUpMinimumTime then ply.GAME_flPeekUpMinimumTime = CurTime() + .25 end
			if CurTime() <= ply.GAME_flPeekUpMinimumTime then
				ply:SetNW2Bool( "CTRL_bPredictedCantShoot", true )
				cmd:RemoveKey( IN_ATTACK )
				cmd:RemoveKey( IN_ATTACK2 )
			else ply:SetNW2Bool "CTRL_bPredictedCantShoot" end
			ply:SetNW2Bool "CTRL_bInCover"
			ply.CTRL_bInCover = nil
			ply:SetNW2Int( "CTRL_Peek", cmd:KeyDown( IN_ZOOM ) && COVER_FIRE_UP || COVER_BLINDFIRE_UP )
			cmd:RemoveKey( IN_DUCK )
			local aEye = ply:EyeAngles()
			local bInCover
			local EyeVector = aEye:Forward()
			local EyeVectorFlat = aEye:Forward()
			EyeVectorFlat.z = 0
			EyeVectorFlat:Normalize()
			local vView = ply:GetPos() + ply:GetViewOffset()
			local trStand = util_TraceLine {
				start = vView,
				endpos = vView + EyeVectorFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = ply
			}
			local vViewDucked = ply:GetPos() + ply:GetViewOffsetDucked()
			local trDuck = util_TraceLine {
				start = vViewDucked,
				endpos = vViewDucked + EyeVectorFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = ply
			}
			if !trDuck.Hit || trStand.Hit then
				ply.GAME_sCoverState = nil
				ply.GAME_flPeekUpMinimumTime = nil
				return
			end
		elseif s == "MOVE" then
			if cmd:KeyDown( IN_FORWARD ) || cmd:KeyDown( IN_BACK ) || cmd:KeyDown( IN_MOVELEFT ) || cmd:KeyDown( IN_MOVERIGHT ) then ply.GAME_sCoverState = nil return end
			if cmd:KeyDown( IN_ZOOM ) then
				ply.GAME_flPeekFireTime = nil
			elseif cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) then
				ply.GAME_flPeekFireTime = CurTime() + .2
			elseif CurTime() > ( ply.GAME_flPeekFireTime || 0 ) then
				ply.GAME_sCoverState = "FROM"
				ply.GAME_flPeekUpMinimumTime = nil
				return
			end
			ply:SetNW2Bool "CTRL_bInCover"
			ply.CTRL_bInCover = nil
			ply:SetNW2Int( "CTRL_Peek", cmd:KeyDown( IN_ZOOM ) && ply.GAME_EPeek || ply.GAME_EPeekBlind )
			if !ply.GAME_flPeekUpMinimumTime then ply.GAME_flPeekUpMinimumTime = CurTime() + .25 end
			if CurTime() <= ply.GAME_flPeekUpMinimumTime then
				ply:SetNW2Bool( "CTRL_bPredictedCantShoot", true )
				cmd:RemoveKey( IN_ATTACK )
				cmd:RemoveKey( IN_ATTACK2 )
			else ply:SetNW2Bool "CTRL_bPredictedCantShoot" end
			local d = ply.GAME_vPeekTarget - ply:GetPos()
			d[ 3 ] = 0
			d:Normalize()
			local dEyeFlat = -ply.GAME_vPeekSourceHitNormal
			dEyeFlat:Normalize()
			local bMove
			local s = ply.GAME_bPeekForceCrouch
			if s == false then
				cmd:RemoveKey( IN_DUCK )
				local vMins, vMaxs = ply:OBBMins(), ply:OBBMaxs()
				vMins[ 3 ] = 0
				vMaxs[ 3 ] = 0
				bMove = util_TraceHull( {
					start = ply:GetPos() + ply:GetViewOffsetDucked(),
					endpos = ply:GetPos() + ply:GetViewOffset(),
					mask = MASK_SOLID,
					mins = vMins,
					maxs = vMaxs,
					filter = ply
				} ).Hit || util_TraceLine( {
					start = ply:GetPos() + ply:GetViewOffset(),
					endpos = ply:GetPos() + ply:GetViewOffset() + dEyeFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				} ).Hit
			elseif s then
				cmd:AddKey( IN_DUCK )
				bMove = util_TraceLine( {
					start = ply:GetPos() + ply:GetViewOffsetDucked(),
					endpos = ply:GetPos() + ply:GetViewOffsetDucked() + dEyeFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				} ).Hit
			elseif ply.GAME_bPeekUnCrouchIfCan then
				bMove = util_TraceLine( {
					start = ply:GetPos() + ply:GetViewOffsetDucked(),
					endpos = ply:GetPos() + ply:GetViewOffsetDucked() + dEyeFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				} ).Hit
				cmd:RemoveKey( IN_DUCK )
			else
				local v = ply:GetPos() + ( cmd:KeyDown( IN_DUCK ) && ply:GetViewOffsetDucked() || ply:GetViewOffset() )
				bMove = util_TraceLine( {
					start = v,
					endpos = v + dEyeFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				} ).Hit
			end
			if bMove then
				ply:SetNW2Bool( "CTRL_bPredictedCantShoot", true )
				cmd:RemoveKey( IN_ATTACK )
				cmd:RemoveKey( IN_ATTACK2 )
				cmd:SetForwardMove( ply:GetRunSpeed() * d:Dot( ply:GetForward() ) )
				cmd:SetSideMove( ply:GetRunSpeed() * d:Dot( ply:GetRight() ) )
			else ply:SetNW2Bool "CTRL_bPredictedCantShoot" end
		else//if s == "FROM" then
			ply:SetNW2Bool "CTRL_bPredictedCantShoot"
			if cmd:KeyDown( IN_FORWARD ) || cmd:KeyDown( IN_BACK ) || cmd:KeyDown( IN_MOVELEFT ) || cmd:KeyDown( IN_MOVERIGHT ) then ply.GAME_sCoverState = nil return end
			local bInCover
			local dEyeFlat = -ply.GAME_vPeekSourceHitNormal
			dEyeFlat.z = 0
			dEyeFlat:Normalize()
			local v = ply.GAME_vPeekSource
			local trOriginalStand, trOriginalDuck = util_TraceLine {
				start = v + ply:GetViewOffset(),
				endpos = v + ply:GetViewOffset() + dEyeFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = ply
			}, util_TraceLine {
				start = v + ply:GetViewOffsetDucked(),
				endpos = v + ply:GetViewOffsetDucked() + dEyeFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = ply
			}
			if !trOriginalStand.Hit then cmd:AddKey( IN_DUCK ) end
			if !trOriginalDuck.Hit then ply.GAME_sCoverState = nil return end
			local vView = ply:GetPos() + ply:GetViewOffset()
			local trStand = util_TraceLine {
				start = vView,
				endpos = vView + dEyeFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = ply
			}
			local vViewDucked = ply:GetPos() + ply:GetViewOffsetDucked()
			local trDuck = util_TraceLine {
				start = vViewDucked,
				endpos = vViewDucked + dEyeFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
				mask = MASK_SOLID,
				filter = ply
			}
			local bDuck, tr
			if ply:IsOnGround() then
				if cmd:KeyDown( IN_DUCK ) then
					if trDuck.Hit then
						bDuck = true
						bInCover = true
						tr = trDuck
					end
				else
					if trDuck.Hit && trStand.Hit then
						bInCover = true
						tr = trStand
					end
				end
			end
			if bInCover then
				ply.GAME_sCoverState = nil
				return
			else
				local d = ply.GAME_vPeekSource - ply:GetPos()
				d[ 3 ] = 0
				d:Normalize()
				local dEyeFlat = ply:GetAimVector()
				dEyeFlat[ 3 ] = 0
				dEyeFlat:Normalize()
				cmd:SetForwardMove( ply:GetRunSpeed() * d:Dot( ply:GetForward() ) )
				cmd:SetSideMove( ply:GetRunSpeed() * d:Dot( ply:GetRight() ) )
			end
		end
	else
		local wep = ply:GetActiveWeapon()
		if IsValid( wep ) && !cmd:KeyDown( IN_ZOOM ) then
			local cap = wep.GetCapabilities
			if cap then
				cap = cap( wep )
				if bit.band( cap, CAP_INNATE_MELEE_ATTACK1 ) != 0 || bit.band( cap, CAP_WEAPON_MELEE_ATTACK1 ) != 0 then
					ply:SetNW2Bool "CTRL_bInCover"
					ply.CTRL_bInCover = nil
					ply:SetNW2Int( "CTRL_Peek", COVER_PEEK_NONE )
					return
				end
			end
		end
		local aEye = ply:EyeAngles()
		local bInCover
		local EyeVector = aEye:Forward()
		local EyeVectorFlat = aEye:Forward()
		EyeVectorFlat.z = 0
		EyeVectorFlat:Normalize()
		local vView = ply:GetPos() + ply:GetViewOffset()
		local trStand = util_TraceLine {
			start = vView,
			endpos = vView + EyeVectorFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
			mask = MASK_SOLID,
			filter = ply
		}
		local vViewDucked = ply:GetPos() + ply:GetViewOffsetDucked()
		local trDuck = util_TraceLine {
			start = vViewDucked,
			endpos = vViewDucked + EyeVectorFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
			mask = MASK_SOLID,
			filter = ply
		}
		local bDuck, tr
		if ply:IsOnGround() then
			if cmd:KeyDown( IN_DUCK ) then
				if trDuck.Hit then
					bDuck = true
					bInCover = true
					tr = trDuck
				end
			else
				if trDuck.Hit && trStand.Hit then
					bInCover = true
					tr = trStand
				end
			end
		end
		ply:SetNW2Bool "CTRL_bPredictedCantShoot"
		if bInCover then
			if !Achievement_Has( ply, "Miscellaneous_CoverGrate" ) && bit.band( tr.Contents, CONTENTS_GRATE ) != 0 then Achievement_Miscellaneous_Grant( ply, "CoverGrate" ) end
			// NOTE: Force variables will do nothing when `nil`. This is intended so that
			// covers who allow being both crouched and uncrouched during peeks work!
			local vMins, vMaxs = ply:OBBMins(), ply:OBBMaxs()
			vMins[ 3 ] = 0
			vMaxs[ 3 ] = 0
			local bUp, bLeft, bRight, bLeftForceCrouch, bRightForceCrouch = bDuck && !trStand.Hit && !util_TraceHull( {
				start = ply:GetPos() + ply:GetViewOffsetDucked(),
				endpos = ply:GetPos() + ply:GetViewOffset(),
				mask = MASK_SOLID,
				mins = vMins,
				maxs = vMaxs,
				filter = ply
			} ).Hit
			local vLeft, vRight = ply:GetPos() + tr.HitNormal:Angle():Right() * ply:OBBMaxs().y * 2, ply:GetPos() - tr.HitNormal:Angle():Right() * ply:OBBMaxs().y * 2
			if !util_TraceLine( {
				start = ply:GetPos() + ply:GetViewOffsetDucked(),
				endpos = vLeft + ply:GetViewOffsetDucked(),
				filter = ply,
				mask = MASK_SOLID
			} ).Hit && util_TraceLine( {
				start = vLeft,
				endpos = vLeft - Vector( 0, 0, ply:GetStepSize() ),
				filter = ply,
				mask = MASK_SOLID
			} ).Hit then
				local trDuck = util_TraceLine {
					start = vLeft + ply:GetViewOffsetDucked(),
					endpos = vLeft + ply:GetViewOffsetDucked() + EyeVectorFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				}
				local trStand = util_TraceLine {
					start = vLeft + ply:GetViewOffset(),
					endpos = vLeft + ply:GetViewOffset() + EyeVectorFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				}
				if !trDuck.Hit && !trStand.Hit then bLeft = true
				elseif !trStand.Hit && trDuck.Hit then bLeft = true bLeftForceCrouch = false
				elseif !trDuck.Hit && trStand.Hit then bLeft = true bLeftForceCrouch = true end
			end
			if !util_TraceLine( {
				start = ply:GetPos() + ply:GetViewOffsetDucked(),
				endpos = vRight + ply:GetViewOffsetDucked(),
				filter = ply,
				mask = MASK_SOLID
			} ).Hit && util_TraceLine( {
				start = vRight,
				endpos = vRight - Vector( 0, 0, ply:GetStepSize() ),
				filter = ply,
				mask = MASK_SOLID
			} ).Hit then
				local trDuck = util_TraceLine {
					start = vRight + ply:GetViewOffsetDucked(),
					endpos = vRight + ply:GetViewOffsetDucked() + EyeVectorFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				}
				local trStand = util_TraceLine {
					start = vRight + ply:GetViewOffset(),
					endpos = vRight + ply:GetViewOffset() + EyeVectorFlat * ply:OBBMaxs().x * COVER_BOUND_SIZE,
					mask = MASK_SOLID,
					filter = ply
				}
				if !trDuck.Hit && !trStand.Hit then bRight = true
				elseif !trStand.Hit && trDuck.Hit then bRight = true bRightForceCrouch = false
				elseif !trDuck.Hit && trStand.Hit then bRight = true bRightForceCrouch = true end
			end
			if bUp then
				local f = math.NormalizeAngle( math.AngleDifference( ( -trDuck.HitNormal ):Angle()[ 2 ], aEye[ 2 ] ) )
				if bLeft && f < -11.25 then
					VARIANTS = COVER_VARIANTS_LEFT
				elseif bRight && f > 11.25 then
					VARIANTS = COVER_VARIANTS_RIGHT
				else
					VARIANTS = COVER_VARIANTS_BOTH
				end
			else
				if bLeft && bRight then
					local f = math.NormalizeAngle( math.AngleDifference( ( -trDuck.HitNormal ):Angle()[ 2 ], aEye[ 2 ] ) )
					if f < -11.25 then
						VARIANTS = COVER_VARIANTS_LEFT
					elseif f > 11.25 then
						VARIANTS = COVER_VARIANTS_RIGHT
					end
				elseif bLeft then
					VARIANTS = COVER_VARIANTS_LEFT
				elseif bRight then
					VARIANTS = COVER_VARIANTS_RIGHT
				else VARIANTS = COVER_VARIANTS_BOTH end
			end
			if cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) || cmd:KeyDown( IN_ZOOM ) then
				if VARIANTS == COVER_VARIANTS_BOTH && bUp then
					Achievement_Miscellaneous( ply, cmd:KeyDown( IN_ZOOM ) && "CoverPeek" || "CoverBlindFire" )
					ply.GAME_sCoverState = "DUCK"
					return
				elseif VARIANTS == COVER_VARIANTS_LEFT then
					Achievement_Miscellaneous( ply, cmd:KeyDown( IN_ZOOM ) && "CoverPeek" || "CoverBlindFire" )
					ply.GAME_sCoverState = "MOVE"
					ply.GAME_bPeekForceCrouch = bLeftForceCrouch
					ply.GAME_vPeekTarget = vLeft
					ply.GAME_bPeekUnCrouchIfCan = aEye[ 1 ] < -5
					ply.GAME_vPeekSource = ply:GetPos()
					ply.GAME_vPeekSourceHitNormal = tr.HitNormal
					ply.GAME_EPeek = COVER_FIRE_LEFT
					ply.GAME_EPeekBlind = COVER_BLINDFIRE_LEFT
					return
				elseif VARIANTS == COVER_VARIANTS_RIGHT then
					Achievement_Miscellaneous( ply, cmd:KeyDown( IN_ZOOM ) && "CoverPeek" || "CoverBlindFire" )
					ply.GAME_sCoverState = "MOVE"
					ply.GAME_bPeekForceCrouch = bRightForceCrouch
					ply.GAME_vPeekTarget = vRight
					ply.GAME_bPeekUnCrouchIfCan = aEye[ 1 ] < -5
					ply.GAME_vPeekSource = ply:GetPos()
					ply.GAME_vPeekSourceHitNormal = tr.HitNormal
					ply.GAME_EPeek = COVER_FIRE_RIGHT
					ply.GAME_EPeekBlind = COVER_BLINDFIRE_RIGHT
					return
				end
			end
			ply:SetNW2Bool( "CTRL_bInCover", true )
			ply.CTRL_bInCover = true
			ply:SetNW2Int( "CTRL_Variants", VARIANTS )
			ply:SetNW2Int( "CTRL_Peek", COVER_PEEK_NONE )
		else
			ply:SetNW2Bool "CTRL_bInCover"
			ply.CTRL_bInCover = nil
			ply:SetNW2Int( "CTRL_Peek", COVER_PEEK_NONE )
		end
	end
	BloodlossStuff( ply, cmd ) // Run it twice so that we neutralize RemoveKey( IN_DUCK )
end )

local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local CEntity_GetTable = CEntity.GetTable

local CPlayer_KeyDown = CPlayer.KeyDown

function QuickSlide_Can( ply, t ) if t == nil then t = CEntity_GetTable( ply ) end return !CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) && !Either( t.CTRL_bCantSlide == nil, __PLAYER_MODEL__[ ply:GetModel() ] && __PLAYER_MODEL__[ ply:GetModel() ].bCantSlide, t.CTRL_bCantSlide ) && CEntity_IsOnGround( ply ) && GetVelocity( ply ):Length() >= ( ply:GetRunSpeed() * .9 ) end
local CEntity_SetNW2Bool = CEntity.SetNW2Bool
local CEntity_SetNW2Float = CEntity.SetNW2Float
local CEntity_GetNW2Float = CEntity.GetNW2Float
function QuickSlide_Handle( ply )
	local vel = GetVelocity( ply )
	local f = CEntity_GetNW2Float( ply, "CTRL_flSlideSpeed", 0 )
	if CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) && ( !ply.Alive || ply.Alive && ply:Alive() ) && vel:Length() > 8 && CEntity_IsOnGround( ply ) && f > 8 && ( !ply:IsPlayer() || ply:IsPlayer() && CPlayer_KeyDown( ply, IN_DUCK ) && CPlayer_KeyDown( ply, IN_SPEED ) ) then
		local v = ply:GetAimVector()
		v.z = 0
		v:Normalize()
		local flRunSpeed = ply:GetRunSpeed()
		local t = CEntity_GetTable( ply )
		f = f - ( ply.GAME_flSlideSpeed || flRunSpeed * 1.5 ) * ( t.CTRL_flSlideSpeedDecay || .4 ) * FrameTime()
		CEntity_SetNW2Float( ply, "CTRL_flSlideSpeed", f )
		local s = t.CTRL_pSlideLoop
		if s then
			s:ChangeVolume( vel:Length() / flRunSpeed )
			local p = vel:Length() / flRunSpeed
			s:ChangeVolume( p )
			s:ChangePitch( math.Remap( p, 0, 1, 80, 100 ) )
		end
		return v * f
	else
		local t = CEntity_GetTable( ply )
		local v = t.CTRL_pSlideLoop
		if v then
			v:Stop()
			t.CTRL_pSlideLoop = nil
		end
		CEntity_SetNW2Bool( ply, "CTRL_bSliding", false )
	end
end
function QuickSlide_Start( ply, t )
	if ply:IsPlayer() then Achievement_Miscellaneous( ply, "Slide" ) end
	CEntity_SetNW2Bool( ply, "CTRL_bSliding", true )
	local t = t || CEntity_GetTable( ply )
	local f = t.GAME_flSlideSpeed || ply:GetRunSpeed() * 1.5
	CEntity_SetNW2Float( ply, "CTRL_flSlideSpeed", f )
	local s = CreateSound( ply, t.CTRL_sSlideLoop || "HumanSlideLoop" )
	t.CTRL_pSlideLoop = s
	s:Play()
end
function QuickSlide_CalcLength( ply )
	local v = ply.GAME_flSlideSpeed || ply:GetRunSpeed() * 1.5
	local d = v * ( CEntity_GetTable( ply ).CTRL_flSlideSpeedDecay || .4 )
	return ( v * v ) / ( 2 * d )
end
hook.Add( "Move", "GameImprovements", function( ply, mv )
	if ply:Alive() then
		if !CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) && QuickSlide_Can( ply ) then
			local t = CEntity_GetTable( ply )
			if CPlayer_KeyDown( ply, IN_SPEED ) && CPlayer_KeyDown( ply, IN_DUCK ) && QuickSlide_Can( ply, t ) then QuickSlide_Start( ply, t ) end
		end
		local v = QuickSlide_Handle( ply ) if v then mv:SetVelocity( v ) end
	end
end )

NOT_A_VOICELINE = NOT_A_VOICELINE || {}
NOT_A_VOICELINE[ "npc/antlion_guard/growl_idle.wav" ] = true
NOT_A_VOICELINE[ "npc/antlion_guard/growl_high.wav" ] = true
NOT_A_VOICELINE[ "npc/antlion_guard/confused1.wav" ] = true
NOT_A_VOICELINE[ "npc/antlion/fly1.wav" ] = true
NOT_A_VOICELINE[ "npc/attack_helicopter/aheli_rotor_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/attack_helicopter/aheli_wash_loop3.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/dropship_engine_near_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/dropship_engine_distant_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/dropship_dropping_pod_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/dropship_onground_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/engine_rotor_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/engine_whine_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/combine_gunship/gunship_engine_loop3.wav" ] = true
NOT_A_VOICELINE[ "AirRaidSirenOscillatorLoop.wav" ] = true
NOT_A_VOICELINE[ "npc/stalker/laser_burn.wav" ] = true
NOT_A_VOICELINE[ "npc/stalker/laser_flesh.wav" ] = true
NOT_A_VOICELINE[ "npc/fast_zombie/breathe_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/fast_zombie/gurgle_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/manhack/mh_blade_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/manhack/mh_engine_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/manhack/mh_engine_loop2.wav" ] = true
NOT_A_VOICELINE[ "npc/roller/mine/combine_mine_active_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/roller/mine/rmine_movefast_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/roller/mine/rmine_moveslow_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/roller/mine/rmine_seek_loop2.wav" ] = true
NOT_A_VOICELINE[ "npc/zombie/moan_loop1.wav" ] = true
NOT_A_VOICELINE[ "npc/zombie/moan_loop2.wav" ] = true
NOT_A_VOICELINE[ "npc/zombie/moan_loop3.wav" ] = true
NOT_A_VOICELINE[ "npc/zombie/moan_loop4.wav" ] = true

util.AddNetworkString "EmitSound"

local player_Iterator = player.Iterator
hook.Add( "EntityEmitSound", "GameImprovements", function( Data, _Comp )
	if _Comp then
		if _Comp.KM_CMs_Addon then
			return
		else _Comp.KM_CMs_Addon = true end
	end
	hook.Run( "EntityEmitSound", Data, { KM_CMs_Addon = true } )
	local ent = Data.Entity
	local dent = GetOwner( ent )
	if Data.Volume <= .05 then return true end
	local dt = math.Clamp( Data.SoundLevel ^ ( Data.SoundLevel >= 100 && 2 || 1.5 ), 5, 18000 )
	local vPos = Data.Pos || ( ent:GetPos() + ent:OBBCenter() )
	for act in pairs( __ACTOR_LIST__ ) do
		if act == ent || act == dent then continue end
		if act.flHearDistanceMultiplier > 0 && act:GetPos():Distance( vPos ) <= ( dt * act.flHearDistanceMultiplier ) then
			act:OnHeardSomething( dent, Data )
		end
	end
	local sColor
	if dent.GAME_sCaptionColor then
		sColor = Format( "%q", dent.GAME_sCaptionColor )
	elseif dent.GetPlayerColor then
		local c = dent:GetPlayerColor() * 255
		sColor = Format( "%q", Format( "<clr:%d,%d,%d>", c[ 1 ], c[ 2 ], c[ 3 ] ) )
	else sColor = "\"\"" end
	local sCaption = Format( "%q", Data.SoundName )
	local dts = dt * dt
	for _, ply in player_Iterator() do
		if ply:EyePos():DistToSqr( vPos ) > dts then continue end
		ply:SendLua( "CaptionSound(" .. sColor .. "," .. sCaption .. ")" )
		if NOT_A_VOICELINE[ Data.SoundName ] || ply.DR_EThreat == DIRECTOR_THREAT_MAGIC then continue end
		if Director_GetThreat( ply, ent ) < DIRECTOR_THREAT_HOLD_FIRE || Director_GetThreat( ply, dent ) < DIRECTOR_THREAT_HOLD_FIRE then continue end
		if RealTime() > ( ply.DR_flVoWait || 0 ) && ply.DR_EThreat == DIRECTOR_THREAT_HOLD_FIRE || RealTime() <= ( ply.DR_flVoDangerousWait || math.huge ) then
			local f = ply.DR_flVoWait
			if !f || RealTime() > ( f + DIRECTOR_MUSIC_VO_WAIT * 2 ) then
				local t = ply.DR_tMusicEntities
				if t then t[ dent ] = true end
				ply.DR_EThreat = DIRECTOR_THREAT_COMBAT
				ply:SendLua( "Director_VoiceLineHookToCombat(\"" .. Data.SoundName .. "\")" )
				ply.DR_flVoDangerousWait = RealTime() + math.min( SoundDuration( Data.SoundName ), 8 )
			end
			continue
		end
		// If it's a voice line, wait until it is over
		if ply.DR_EThreat < DIRECTOR_THREAT_HOLD_FIRE || RealTime() <= ( ply.DR_flVoWait || 0 ) then
			local t = ply.DR_tMusicEntities
			if t then t[ dent ] = true end
			ply.DR_EThreat = DIRECTOR_THREAT_HOLD_FIRE
			ply:SendLua( "Director_VoiceLineHook(\"" .. Data.SoundName .. "\")" )
			ply.DR_flVoWait = RealTime() + math.min( SoundDuration( Data.SoundName ), 8 ) + DIRECTOR_MUSIC_VO_WAIT
			continue
		end
	end
	return true
end )

if !CLASS_HUMAN then Add_NPC_Class "CLASS_HUMAN" end

function CPlayer:GetNPCClass() return self.m_iClass || CLASS_HUMAN end
function CPlayer:Classify() return self:GetNPCClass() end
function CPlayer:SetNPCClass( i ) self.m_iClass = i end
