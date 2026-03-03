include "Aim.lua"
include "Disposition.lua"
include "Vehicles.lua"
include "Weapons.lua"
include "Senses.lua"
include "Schedule.lua"
include "Path.lua"
include "Suppressed.lua"
include "CombatState.lua"
include "Script.lua"
include "Search.lua"
include "Behaviour.lua"
include "Animation.lua"
include "Mind.lua"

local CEntity = FindMetaTable "Entity"

local CEntity_GetTable = CEntity.GetTable

local coroutine_create = coroutine.create
local coroutine_status = coroutine.status
local coroutine_resume = coroutine.resume
function ENT:BehaveStart()
	local MyTable = CEntity_GetTable( self )
	MyTable.RunBehaviour( self, MyTable )
end
function ENT:BehaveUpdate( flInterval )
	local MyTable = CEntity_GetTable( self )
	local coBehaveThread = MyTable.m_coBehaveThread
	if !coBehaveThread then return end
	if coroutine_status( coBehaveThread ) == "dead" then
		MyTable.m_coBehaveThread = nil
		MyTable.RunBehaviour( self, MyTable )
		ErrorNoHalt( self, "MY COROUTINE DIED!\n" )
		return
	end
	local bOk, sMessage = coroutine_resume( coBehaveThread, MyTable )
	if bOk == false then
		MyTable.m_coBehaveThread = nil
		ErrorNoHalt( self, "Error: ", sMessage, "\n" )
		MyTable.RunBehaviour( self, MyTable )
	end
end

ENT.vHullMins = HULL_HUMAN_MINS
ENT.vHullMaxs = HULL_HUMAN_MAXS
ENT.vHullDuckMins = HULL_HUMAN_MINS // HULL_HUMAN_DUCK_MINS
ENT.vHullDuckMaxs = HULL_HUMAN_MAXS // HULL_HUMAN_DUCK_MAXS

ENT.GAME_flReach = 64

ENT.flHungerDepletion = -1
ENT.flHunger = -1
ENT.flHungerLimit = -1

ENT.flThirstDepletion = -1
ENT.flThirst = -1
ENT.flThirstLimit = -1

ENT.flBoldness = -1

local math = math
local math_max = math.max
local math_ceil = math.ceil

local ents_Create = ents.Create
local CEntity_SetOwner = CEntity.SetOwner
function ENT:CreateProjectile( sClass )
	local pProjectile = ents_Create( sClass )
	if !IsValid( pProjectile ) then return end
	CEntity_GetTable( pProjectile ).iClass = CEntity_GetTable( self ).iClass
	CEntity_SetOwner( pProjectile, self )
	return pProjectile
end
function ENT:CreateActor( sClass )
	local pActor = ents_Create( sClass )
	if !IsValid( pActor ) then return end
	CEntity_GetTable( pActor ).iClass = CEntity_GetTable( self ).iClass
	// TODO: Copy our enemies to them
	return pActor
end

function ENT:SelectAim( pEnemy, vShoot, flSpeed, flRadius, flBound )
	local vPos = pEnemy:GetPos()
	local v = ( vShoot - vPos ):GetNormalized()
	v[ 3 ] = 0
	local tr = util.TraceLine {
		start = vPos,
		endpos = vPos - Vector( 0, 0, flRadius ) + v * flBound,
		mask = MASK_SOLID,
		filter = pEnemy
	}
	if tr.Hit then
		v = tr.HitPos
		if self:VisibleVec( v ) then
			self.vaAimTargetBody = v + GetVelocity( pEnemy ) * v:Distance( vShoot ) / flSpeed
			self.vaAimTargetPose = self.vaAimTargetBody
		else
			local vTarget = pEnemy:GetPos() + pEnemy:OBBCenter()
			local vOffset = GetVelocity( pEnemy ) * vTarget:Distance( vShoot ) / flSpeed
			vTarget = vTarget + vOffset
			self.vaAimTargetBody = vTarget
			self.vaAimTargetPose = self.vaAimTargetBody
		end
	else
		local vTarget = pEnemy:GetPos() + pEnemy:OBBCenter()
		local vOffset = GetVelocity( pEnemy ) * vTarget:Distance( vShoot ) / flSpeed
		self.vaAimTargetBody = vTarget
		self.vaAimTargetPose = self.vaAimTargetBody
	end
end

function ENT:Stand() self.loco:SetDesiredSpeed( 0 ) self.loco:Approach( self:GetPos(), 1 ) end

function ENT:OnKilled( dmg )
	if self.bDead then return true end
	self.bDead = true
	for wep in pairs( self.tWeapons ) do self:DropWeapon( wep ) end
	local pAttacker = dmg:GetAttacker()
	if IsValid( pAttacker ) then
		local fAddFrags = pAttacker.AddFrags
		if fAddFrags then fAddFrags( pAttacker, math_max( 1, math_ceil( self:GetMaxHealth() / 100 ) ) ) end
	end
	timer.Simple( .1, function()
		for pActor in pairs( __ACTOR_LIST__ ) do
			if !pActor:CanSee( self ) then continue end
			local pSchedule = pActor.Schedule
			if !pSchedule || pSchedule.m_sName != "StartleNoise" then continue end
			local sSound = pSchedule.tData.SoundName
			pActor.tSoundHarmless[ sSound ] = nil
			pActor.tSoundHarmful[ sSound ] = ( pActor.tSoundHarmful[ sSound ] || 0 ) + 1
		end
	end )
	hook.Run( "OnNPCKilled", self, dmg:GetAttacker(), dmg:GetInflictor() )
end

function ENT:ModifyMoveAimVector( ang, flSpeed, flDuck )
	if flDuck && flDuck < .5 then return end
	ang[ 1 ] = ang[ 1 ] + 35
end

function ENT:OnAcquireEnemy() end

local select = select
function ENT:ClearThreatToClass( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	local t = MyTable.tThreatToClass
	if !t then return end
	local n = {}
	for ent in pairs( MyTable.tEnemies ) do
		if ent.__ACTOR_BULLSEYE__ then
			local _, p = self:SetupEnemy( ent )
			ent = p
		end
		local f = ent.Classify
		if !f then continue end
		n[ f( ent ) ] = true
	end
	MyTable.tThreatToClass = n
end

function ENT:MoveAlongPath() end
function ENT:MoveAlongPathToCover( pPath, tFilter ) self:MoveAlongPath( pPath, math.abs( pPath:GetLength() - pPath:GetCursorPosition() ) <= self.flWalkSpeed && self.flWalkSpeed || self.flTopSpeed, 1, tFilter ) end

ENT.bHoldFire = true

function ENT:OnTakeDamage() CEntity_GetTable( self ).bHoldFire = nil end

ENT.flHearDistanceMultiplier = 1

ENT.iState = NPC_STATE_NONE
function ENT:GetNPCState() return self.iState end
function ENT:SetNPCState( i ) self.iState = i end

function ENT:GetShootPos() return self:GetPos() + Vector( 0, 0, self:OBBMaxs().z * .77777777777778 ) end
function ENT:EyePos() return self:GetShootPos() end

function ENT:GetHull() return self.vHullMins, self.vHullMaxs end
function ENT:GetHullDuck() return self.vHullDuckMins, self.vHullDuckMaxs end

function ENT:TranslateActivity( n ) return n end

__ACTOR_LIST__ = __ACTOR_LIST__ || {}
local __ACTOR_LIST__ = __ACTOR_LIST__

local SafeRemoveEntity = SafeRemoveEntity

function ENT:OnRemove()
	__ACTOR_LIST__[ self ] = nil
	local MyTable = CEntity_GetTable( self )
	for _, d in pairs( MyTable.tBullseyes ) do SafeRemoveEntity( d[ 1 ] ) end
	local iClass = MyTable.GetNPCClass( self )
	if iClass != CLASS_NONE then
		local t = MyTable.GetActorTableByClass()[ iClass ]
		if t then t[ self ] = true end
	end
end

function ENT:Tick( MyTable ) end

local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local CEntity_GetParent = CEntity.GetParent
local CEntity_PhysicsDestroy = CEntity.PhysicsDestroy
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_GetPos = CEntity.GetPos
local CEntity_GetAngles = CEntity.GetAngles

local IsValid = IsValid

function ENT:DoPhysicsStuff( phys, MyTable ) end

// Does the physics object take the lead, or the locomotion?
// Do note that if the physics object takes the lead, the
// locomotion will not work, but if the locomotion takes
// the lead, the physics will, albeit only somewhat, work.
ENT.bPhysics = false
local sv_gravity = GetConVar "sv_gravity"
function ENT:Think()
	local MyTable = CEntity_GetTable( self )
	local phys = CEntity_GetPhysicsObject( self )
	if IsValid( phys ) then
		MyTable.DoPhysicsStuff( self, phys, MyTable )
		if MyTable.bPhysics then
			MyTable.loco:SetGravity( 0 )
			phys:Wake()
			local loco = MyTable.loco
			loco:SetStepHeight( 0 )
			loco:SetJumpHeight( 0 )
		else
			MyTable.loco:SetGravity( sv_gravity:GetFloat() )
			if IsValid( CEntity_GetParent( self ) ) then CEntity_PhysicsDestroy( self ) else
				if CEntity_WaterLevel( self ) == 0 then
					phys:SetPos( CEntity_GetPos( self ) )
					phys:SetAngles( CEntity_GetAngles( self ) )
				else
					phys:UpdateShadow( CEntity_GetPos( self ), CEntity_GetAngles( self ), 0 )
				end
			end
		end
	else MyTable.loco:SetGravity( sv_gravity:GetFloat() ) end
	if IsValid( MyTable.GAME_pVehicle ) then
		self:SetActiveWeapon( NULL )
		if self:GetCollisionGroup() != COLLISION_GROUP_WORLD then self:SetCollisionGroup( COLLISION_GROUP_WORLD ) end
	else if self:GetCollisionGroup() != COLLISION_GROUP_NPC then self:SetCollisionGroup( COLLISION_GROUP_NPC ) end end
	MyTable.Tick( self, MyTable )
end

local FL_OBJECT = FL_OBJECT
function ENT:Initialize()
	self:AddFlags( FL_OBJECT )
	__ACTOR_LIST__[ self ] = true
	self:SetNPCClass( self:GetNPCClass() ) // Required for ally searches to work
	self:AddCallback( "PhysicsCollide", function( self, Data )
		local ent = Data.HitEntity
		if !IsValid( ent ) then return end
		local class = ent:GetClass()
		local phys = Data.HitObject
		if !ent:IsPlayerHolding() then
			local d = math.floor( ( Data.TheirOldVelocity:Length() * Data.HitObject:GetMass() ) * .001 )
			if d > 10 then
				local dmg = DamageInfo()
				if ent:IsVehicle() && IsValid( ent:GetDriver() ) then
					dmg:SetAttacker( ent:GetDriver() )
				elseif IsValid( ent:GetPhysicsAttacker() ) then
					dmg:SetAttacker( ent:GetPhysicsAttacker() )
				else dmg:SetAttacker( ent ) end
				dmg:SetInflictor( ent )
				dmg:SetDamage( d )
				if ent:IsVehicle() then dmg:SetDamageType( DMG_VEHICLE )
				else dmg:SetDamageType( DMG_CRUSH ) end
				dmg:SetDamageForce( phys:GetVelocity() )
				self:TakeDamageInfo( dmg )
			end
		end
	end )
end

function ENT:HandleKeyValue( Key, Value ) end

ENT.GAME_flSuppression = 0
ENT.flSuppressionMax = 4
ENT.flSuppressionRec = 1
ENT.flSuppressionHide = .1

function ENT:GAME_OnRangeAttacked( _, _, _, flDamage )
	local MyTable = CEntity_GetTable( self )
	MyTable.GAME_flSuppression = MyTable.GAME_flSuppression + flDamage
	MyTable.flCombatStateSuppression = MyTable.flCombatStateSuppression + flDamage
end

local ProtectedCall = ProtectedCall
local ai_disabled, developer = GetConVar "ai_disabled", GetConVar "developer"
local coroutine_yield = coroutine.yield
local math_Approach = math.Approach
local math_Clamp = math.Clamp
local math_abs = math.abs
local math_AngleDifference = math.AngleDifference
local FrameTime = FrameTime
local CEntity_Health = CEntity.Health
local CEntity_GetPoseParameter = CEntity.GetPoseParameter
local CEntity_SetPoseParameter = CEntity.SetPoseParameter
local CEntity_LookupPoseParameter = CEntity.LookupPoseParameter
local Angle = Angle
ENT.m_sPitchPoseParameter = "aim_pitch"
ENT.m_sYawPoseParameter = "aim_yaw"
function ENT:HandleTurning( MyTable )
	local sPitch = MyTable.m_sPitchPoseParameter
	local sYaw = MyTable.m_sYawPoseParameter
	local ppAimPitch = CEntity_LookupPoseParameter( self, sPitch )
	local Angles = CEntity_GetAngles( self )
	local aAim = Angle( Angles )
	local v = MyTable.vaAimTargetPose
	local aDesAim
	if v then
		if isangle( v ) then aDesAim = v
		else aDesAim = ( v - MyTable.GetShootPos( self, MyTable ) ):Angle() end
	else aDesAim = Angles end
	local flTurnRate = MyTable.flTurnRate
	local f = MyTable.flOverrideTurnRateThisTick
	if f then flTurnRate = f MyTable.flOverrideTurnRateThisTick = nil end
	if ppAimPitch != -1 then
		local p = CEntity_GetPoseParameter( self, sPitch )
		local des = math_AngleDifference( aDesAim.p, Angles.p + p )
		local t = MyTable.flBodyTensity
		local f = flTurnRate / t * FrameTime()
		CEntity_SetPoseParameter( self, sPitch, p + math_Clamp( des * t, -f, f ) )
		aAim.p = aAim.p + CEntity_GetPoseParameter( self, sPitch )
	end
	local ppAimYaw = CEntity_LookupPoseParameter( self, sYaw )
	if ppAimYaw != -1 then
		local p = CEntity_GetPoseParameter( self, sYaw )
		local des = math_AngleDifference( aDesAim.y, Angles.y + p )
		local t = MyTable.flBodyTensity
		local f = flTurnRate / t * FrameTime()
		CEntity_SetPoseParameter( self, sYaw, p + math_Clamp( des * t, -f, f ) )
		aAim.y = aAim.y + CEntity_GetPoseParameter( self, sYaw )
	end
	MyTable.aAim = aAim
	MyTable.vAim = aAim:Forward()
	if MyTable.bCantTurnBody then return end
	local loco = MyTable.loco
	loco:SetMaxYawRate( flTurnRate * math_Clamp( math_abs( math_AngleDifference( aDesAim.y, Angles.y ) ), 0, 90 ) * .01111111111 )
	local v = MyTable.vaAimTargetBody || CEntity_GetAngles( self )
	if isangle( v ) then v = v:Forward() else v = ( v - self:GetShootPos() ):GetNormalized() end
	v = CEntity_GetPos( self ) + v
	for _ = 1, 8 do loco:FaceTowards( v ) end
end

function ENT:RunBehaviour( MyTable )
	MyTable.m_coBehaveThread = coroutine_create( function( MyTable )
		while true do
			if ai_disabled:GetInt() == 1 then coroutine_yield() continue end
			local f = MyTable.fCallMeInRunBehaviour
			if f && f( self, MyTable ) then MyTable.fCallMeInRunBehaviour = nil MyTable.sCallMeInRunBehaviour = nil end
			local f = CEntity_Health( self )
			MyTable.GAME_flSuppression = math_Approach( math_Clamp( MyTable.GAME_flSuppression, 0, f * MyTable.flSuppressionMax ), 0, f * MyTable.flSuppressionRec * FrameTime() )
			MyTable.flCombatStateSuppression = math_Approach( math_Clamp( MyTable.flCombatStateSuppression, 0, f * MyTable.flCombatStateSuppressionMax ), 0, f * MyTable.flCombatStateSuppressionRec * FrameTime() )
			MyTable.HandleTurning( self, MyTable )
			MyTable.Look( self, MyTable )
			MyTable.CalcCombatState( self, MyTable )
			MyTable.Behaviour( self, MyTable )
			coroutine_yield()
		end
	end )
end

/*
ENT.bCanClimbLadders = false
// Note that this is NOT climbing ladders, it's climbing ANYTHING, like Left 4 Dead 2 infected
ENT.bCanClimb = false

ENT.bSimpleDuck = false // Can only duck very simply as the name suggests - either ducked, or not ducked
ENT.bCanMove = false
ENT.bCanMoveShoot = false
ENT.bCanDuck = false
ENT.bCanDuckShoot = false
ENT.bCanDuckMove = false
ENT.bCanDuckMoveShoot = false
*/

function ENT:Crouching() return self:GetCrouchTarget() < .5 end
function ENT:SetCrouchTarget( flTarget ) end
function ENT:GetCrouchTarget() return 1 end
