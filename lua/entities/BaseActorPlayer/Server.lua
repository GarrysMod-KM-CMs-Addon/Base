ENT.vHullMins = HULL_HUMAN_MINS
ENT.vHullMaxs = HULL_HUMAN_MAXS
ENT.vHullDuckMins = HULL_HUMAN_DUCK_MINS
ENT.vHullDuckMaxs = HULL_HUMAN_DUCK_MAXS

ENT.bSimpleDuck = true
ENT.bCanMove = true
ENT.bCanMoveShoot = true
ENT.bCanDuck = true
ENT.bCanDuckShoot = true
ENT.bCanDuckMove = true
ENT.bCanDuckMoveShoot = true
ENT.bCanSlide = true

function ENT:OnBulletImpact( dDamage )
	local ed = EffectData()
	ed:SetOrigin( dDamage:GetDamagePosition() )
	util.Effect( "BloodImpact", ed )
end

function ENT:GetSlideLength() return QuickSlide_CalcLength( self ) end

function ENT:MoveAlongPathToCover( Path, tFilter )
	if self:GetNW2Bool "CTRL_bSliding" then
		// HACK: Rapidly decelerate
		local f = self.flPathTolerance
		f = f * f
		if self:GetPos():DistToSqr( Path:GetEnd() ) <= ( self:GetSlideLength() * .2 ) then
			f = self:GetNW2Float( "CTRL_flSlideSpeed", 0 )
			self:SetNW2Float( "CTRL_flSlideSpeed", f - ( self.GAME_flSlideSpeed || self:GetRunSpeed() * 1.5 ) * ( self.CTRL_flSlideSpeedDecay || .8 ) * FrameTime() )
		end
		self.loco:SetDesiredSpeed( 0 )
		self.loco:SetAcceleration( 0 )
		self.loco:SetDeceleration( 0 )
		Path:Update( self )
		return
	end
	if self.bCanSlide && QuickSlide_Can( self ) then
		Path:MoveCursorToClosestPosition( self:GetPos() )
		local f, n = math.abs( Path:GetLength() - Path:GetCursorPosition() ), self:GetSlideLength()
		if f > n * .2 && f <= n then
			QuickSlide_Start( self )
			self.loco:SetDesiredSpeed( 0 )
			self.loco:SetAcceleration( 0 )
			self.loco:SetDeceleration( 0 )
			Path:Update( self )
			return
		end
	end
	self:MoveAlongPath( Path, self.flTopSpeed, 1, tFilter, true )
end

ENT.flTopSpeed = HUMAN_RUN_SPEED
ENT.flRunSpeed = HUMAN_PROWL_SPEED
ENT.flWalkSpeed = HUMAN_WALK_SPEED

function ENT:BodyUpdate() self:BodyMoveXY() end

DEFINE_BASECLASS "BaseActor"
function ENT:Initialize()
	BaseClass.Initialize( self )
	if self:PhysicsInitShadow( false, false ) then self:GetPhysicsObject():SetMass( 85 ) end
end

function ENT:TranslateActivity( n ) return hook.Run( "TranslateActivity", self, n ) end

local sv_gravity = GetConVar "sv_gravity"
function ENT:Behaviour()
	local act, seq = hook.Run( "CalcMainActivity", self, self.loco:GetVelocity() )
	if !self.CalcIdeal then self.CalcIdeal = -1 end
	local act = self:TranslateActivity( self.CalcIdeal )
	if seq == nil || seq == -1 then self.CalcSeqOverride = self:SelectWeightedSequence( act ) end
	hook.Run( "UpdateAnimation", self, self.loco:GetVelocity(), self:GetSequenceGroundSpeed( self.CalcSeqOverride ) )
	self:PromoteSequence( self.CalcSeqOverride, self:GetPlaybackRate() )
	self:AnimationSystemTick()
	self.loco:SetGravity( sv_gravity:GetFloat() )
	self.loco:SetJumpHeight( self:CalcJumpHeight() )
	if self.CalcIdeal == ACT_MP_CROUCH_IDLE || self.CalcIdeal == ACT_MP_CROUCHWALK then
		local hm, hn, cm, cn = self.vHullDuckMins, self.vHullDuckMaxs, self:GetCollisionBounds()
		if hm != cm || hn != cn then
			self:SetCollisionBounds( hm, hn )
			if !IsValid( self:GetParent() ) && self:PhysicsInitShadow( false, false ) then
				local p = self:GetPhysicsObject()
				if IsValid( p ) then p:SetMass( 85 ) end
			end
		end
	else
		local hm, hn, cm, cn = self.vHullMins, self.vHullMaxs, self:GetCollisionBounds()
		if hm != cm || hn != cn then
			self:SetCollisionBounds( hm, hn )
			if !IsValid( self:GetParent() ) && self:PhysicsInitShadow( false, false ) then
				local p = self:GetPhysicsObject()
				if IsValid( p ) then p:SetMass( 85 ) end
			end
		end
	end
	self:RunMind()
	local v = QuickSlide_Handle( self )
	if v then
		self.loco:Approach( Vector( 0, 0, 0 ), 1 )
		self.loco:SetVelocity( v )
		self.loco:Approach( Vector( 0, 0, 0 ), 1 )
		self.loco:SetDesiredSpeed( 0 )
		self.loco:SetAcceleration( 0 )
		self.loco:SetDeceleration( 0 )
		self.loco:Approach( Vector( 0, 0, 0 ), 1 )
	end
end

function ENT:OnKilled( dmg )
	if BaseClass.OnKilled( self, dmg ) then return end
	local v = self.CTRL_pSlideLoop
	if v then v:Stop() end
	self:EmitSound( dmg:IsDamageType( DMG_FALL ) && "Player.FallGib" || "Player.Death" )
	dmg:SetDamage( 0 )
	self:BecomeRagdoll( dmg )
end
