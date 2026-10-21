include "Player.lua"

ENT.vHullMins = HULL_HUMAN_MINS
ENT.vHullMaxs = HULL_HUMAN_MAXS

ENT.vHullDuckMins = HULL_HUMAN_DUCK_MINS
ENT.vHullDuckMaxs = HULL_HUMAN_DUCK_MAXS

ENT.bCanSlide = true

ENT.bFootSoldier = true

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local FL_DUCKING = FL_DUCKING
function ENT:GetShootPos()
	local vPos = self:GetPos()
	if self:IsFlagSet( FL_DUCKING ) then
		vPos:Add( self:GetViewOffsetDucked() )
	else vPos:Add( self:GetViewOffset() ) end
	return vPos
end

function ENT:GetSlideLength() return QuickSlide_CalcLength( self ) end

ENT.tPreScheduleResetVariables = {}
ENT.tPreScheduleResetVariables.WEAPON_STANCE = false

function ENT:PreScheduleResetVariables( MyTable )
	self:SetNW2Int( "WEAPON_STANCE", MyTable.WEAPON_STANCE || WEAPON_STANCE_DEFAULT )
end

function ENT:MoveAlongPathToCover( pPath, tFilter, flTolerance )
	local flDistSqr = flTolerance && ( flTolerance * 3 ) || self.flPathTolerance
	if pPath:GetEnd():DistToSqr( self:GetPos() ) <= flDistSqr * flDistSqr then
		self:MoveAlongPath( pPath, self.flWalkSpeed, 1, tFilter, nil, flTolerance )
		return
	end

	local pLocomotion = self.loco
	if self:GetNW2Bool "CTRL_bSliding" then
		pLocomotion:SetDesiredSpeed( 0 )
		pLocomotion:SetAcceleration( 0 )
		pLocomotion:SetDeceleration( 0 )
		self:GroundMovement( pPath, self.flTopSpeed, tFilter )
		return
	end

	if self.bCanSlide && QuickSlide_Can( self ) then
		pPath:MoveCursorToClosestPosition( self:GetPos() )
		local f, n = math.abs( pPath:GetLength() - pPath:GetCursorPosition() ), self:GetSlideLength()
		if f > n * .2 && f <= n then
			QuickSlide_Start( self )
			pLocomotion:SetDesiredSpeed( 0 )
			pLocomotion:SetAcceleration( 0 )
			pLocomotion:SetDeceleration( 0 )
			pPath:Update( self )
			return
		end
	end

	self:MoveAlongPath( pPath, self.flTopSpeed, 1, tFilter, true )
end

ENT.flTopSpeed = HUMAN_SPRINT_SPEED
ENT.flJogSpeed = HUMAN_JOG_SPEED
ENT.flWalkSpeed = HUMAN_WALK_SPEED

function ENT:BodyUpdate() self:BodyMoveXY() end

DEFINE_BASECLASS "BaseActor"
function ENT:Initialize()
	BaseClass.Initialize( self )
	if self:PhysicsInitShadow( false, false ) then self:GetPhysicsObject():SetMass( 85 ) end
end

function ENT:TranslateActivity( n ) return hook.Run( "TranslateActivity", self, n ) end

ENT.flJumpHeight = HUMAN_JUMP_HEIGHT

function ENT:Behaviour( MyTable )
	local EActivity, iSequence = hook.Run( "CalcMainActivity", self, self.loco:GetVelocity() )

	local ECalcIdeal = MyTable.CalcIdeal
	if !ECalcIdeal then
		ECalcIdeal = -1
		MyTable.CalcIdeal = ECalcIdeal
	end

	local EActivity = self:TranslateActivity( ECalcIdeal )

	if EActivity == -1 then EActivity = ECalcIdeal end

	if iSequence == nil || iSequence == -1 then self.CalcSeqOverride = self:SelectWeightedSequence( EActivity ) end

	local pLocomotion = MyTable.loco

	hook.Run( "UpdateAnimation", self, pLocomotion:GetVelocity(), self:GetSequenceGroundSpeed( MyTable.CalcSeqOverride ) )

	MyTable.PromoteSequence( self, self:GetSequenceName( MyTable.CalcSeqOverride ), self:GetPlaybackRate() )
	MyTable.AnimationSystemTick( self, MyTable )
	pLocomotion:SetJumpHeight( MyTable.flJumpHeight )

	if ECalcIdeal == ACT_MP_CROUCH_IDLE || ECalcIdeal == ACT_MP_CROUCHWALK then
		local hm, hn, cm, cn = MyTable.vHullDuckMins, MyTable.vHullDuckMaxs, self:GetCollisionBounds()
		if hm != cm || hn != cn then
			self:SetCollisionBounds( hm, hn )
			if !IsValid( self:GetParent() ) && self:PhysicsInitShadow( false, false ) then
				local p = self:GetPhysicsObject()
				if IsValid( p ) then p:SetMass( 85 ) end
			end
		end
	else
		local hm, hn, cm, cn = MyTable.vHullMins, MyTable.vHullMaxs, self:GetCollisionBounds()
		if hm != cm || hn != cn then
			self:SetCollisionBounds( hm, hn )
			if !IsValid( self:GetParent() ) && self:PhysicsInitShadow( false, false ) then
				local p = self:GetPhysicsObject()
				if IsValid( p ) then p:SetMass( 85 ) end
			end
		end
	end

	MyTable.RunMind( self, MyTable )

	local vSlideVelocity = QuickSlide_Handle( self )
	if vSlideVelocity then
		pLocomotion:Approach( vector_origin, 1 )
		pLocomotion:SetVelocity( vSlideVelocity )
		pLocomotion:SetDesiredSpeed( 0 )
		pLocomotion:SetAcceleration( 0 )
		pLocomotion:SetDeceleration( 0 )
	end
end

function ENT:OnKilled( dmg )
	if BaseClass.OnKilled( self, dmg ) then return end

	local v = self.CTRL_pSlideLoop
	if v then v:Stop() end

	// Shows [Death] in subtitles, and that gives it out.
	// I prefer having to check if I killed them myself.
	//	self:EmitSound( dmg:IsDamageType( DMG_FALL ) && "Player.FallGib" || "Player.Death" )

	self:BecomeRagdoll( dmg )
end

function ENT:MoveAlongPath( pPath, flSpeed, flHeight, tFilter, bAllowSliding, flToleranceOverride )
	if flHeight == nil then flHeight = 1 end

	if !bAllowSliding then
		self:SetNW2Bool( "CTRL_bSliding", false )
		self:SetNW2Float( "CTRL_flSlideSpeed", 0 )
	end

	self:SetCrouchTarget( flHeight )

	if flHeight > .5 then flSpeed = math.min( self.flTopSpeed, flSpeed )
	else flSpeed = math.min( self.flWalkSpeed, flSpeed ) end

	if self.flTopSpeed > self.flJogSpeed && flSpeed >= self.flTopSpeed then
		self:SetNW2Bool( "CTRL_bSprinting", true )
	else self:SetNW2Bool "CTRL_bSprinting" end

	local pLocomotion = self.loco
	pLocomotion:SetDesiredSpeed( flSpeed )
	local f = flSpeed * ACCELERATION_NORMAL
	pLocomotion:SetAcceleration( f )
	pLocomotion:SetDeceleration( f )

	self:GroundMovement( pPath, flSpeed, tFilter, flToleranceOverride )
end

function ENT:Stand( flHeight )
	if flHeight == nil then flHeight = 1 end
	self:SetCrouchTarget( flHeight )
	self:SetNW2Bool "CTRL_bSliding"
	self:SetNW2Bool "CTRL_bSprinting"
	BaseClass.Stand( self )
end
