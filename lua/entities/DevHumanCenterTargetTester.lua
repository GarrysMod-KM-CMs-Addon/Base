AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayer"

scripted_ents.Register( ENT, "DevHumanCenterTargetTester" )

list.Set( "NPC", "DevHumanCenterTargetTester", {
	Name = "#DevHumanCenterTargetTester",
	Class = "DevHumanCenterTargetTester",
	Category = "Developer",
	Weapons = { "AK47" }
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
	MyTable.SetSchedule( self, "DevHumanCenterTargetTester", MyTable )
end

ENT.flDefaultJumpHeight = 99999

RegisterSchedule( "DevHumanCenterTargetTester", { Execute = function( self, sched, MyTable )
	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return end
	local pPath = sched.pPath
	if !pPath then pPath = Path "Follow" end
	sched.pPath = pPath
	//	MyTable.ComputePath( self, pPath, vector_origin, MyTable )
	MyTable.ComputeFlankPath( self, pPath, pEnemy, MyTable )
	MyTable.CenterTarget( self, pEnemy:GetPos() + pEnemy:OBBCenter(), MyTable )
	MyTable.MoveAlongPath( self, pPath, MyTable.flJogSpeed, 1 )
	MyTable.WEAPON_STANCE = WEAPON_STANCE_HIP
end } )
