// Player-specific shit goes here

ENT.tGestureSlotToLayer = {}
function ENT:AnimRestartGesture( slot, activity, autokill ) self.tGestureSlotToLayer[ slot ] = self:RestartGesture( activity, autokill ) end
function ENT:AnimRestartMainSequence() end

function ENT:SetActivity( act ) end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
function ENT:GetRunSpeed() return CEntity_GetTable( self ).flTopSpeed end
function ENT:GetWalkSpeed() return CEntity_GetTable( self ).flRunSpeed end
function ENT:GetSlowWalkSpeed() return CEntity_GetTable( self ).flWalkSpeed end

local FL = FL_DUCKING + FL_ANIMDUCKING
function ENT:Crouching() return self:IsFlagSet( FL ) end
function ENT:GetCrouchTarget() return self:Crouching() && 0 || 1 end
function ENT:SetCrouchTarget( flHeight )
	if flHeight < .5 || self:GetNW2Bool "CTRL_bSliding" then self:AddFlags( FL ) else self:RemoveFlags( FL ) end
end

ENT.flDefaultJumpHeight = HUMAN_JUMP_HEIGHT
function ENT:GetJumpPower() return self.flJumpPower || ( 2 * GetConVarNumber "sv_gravity" * self.flDefaultJumpHeight ) ^ .5 end
function ENT:SetJumpPower( p ) self.flJumpPower = p end
function ENT:CalcJumpHeight() return self.flJumpPower && ( self.flJumpPower ^ 2 / ( 2 * self.loco:GetGravity() ) ) || self.flDefaultJumpHeight end
/*
local sv_gravity = GetConVar "sv_gravity"
function ENT:CalcJumpHeight() return self:GetJumpPower() ^ 2 / ( 2 * sv_gravity:GetFloat() ) end
*/
