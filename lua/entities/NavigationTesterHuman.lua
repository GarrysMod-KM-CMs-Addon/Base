AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayerHuman"

scripted_ents.Register( ENT, "NavigationTesterHuman" )

ENT.CATEGORIZE = { Terrorist = true }

list.Set( "NPC", "NavigationTesterHuman", {
	Name = "#NavigationTesterHuman",
	Class = "NavigationTesterHuman",
	Category = "Developer"
} )

if !SERVER then return end

ENT.iDefaultClass = CLASS_COMBINE

function ENT:Initialize()
	self:SetModel "models/player/arctic.mdl"
	self:SetHealth( 100 )
	self:SetMaxHealth( 100 )
	BaseClass.Initialize( self )
end

function ENT:SelectSchedule( MyTable )
	MyTable.SetNPCState( self, NPC_STATE_COMBAT )
	MyTable.SetSchedule( self, "NavigationTesterHuman", MyTable )
end

ENT.flDefaultJumpHeight = 99999

Actor_RegisterSchedule( "NavigationTesterHuman", function( self, sched )
	local pEnemy = self.Enemy
	if !IsValid( pEnemy ) then return end
	local pPath = sched.pPath
	if !pPath then pPath = Path "Follow" end
	sched.pPath = pPath
	self:ComputeFlankPath( pPath, pEnemy )
	self:MoveAlongPath( pPath, self.flTopSpeed, 1 )
	local goal = pPath:GetCurrentGoal()
	if goal then
		self.vaAimTargetBody = ( goal.pos - self:GetPos() ):Angle()
		self.vaAimTargetPose = self.vaAimTargetBody
	end
end )
