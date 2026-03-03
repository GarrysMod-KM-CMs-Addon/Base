// ENT.vAim = nil

function ENT:SetAimVector( v ) self.vAim = v end
function ENT:GetAimVector() return self.vAim || self:GetForward() end

ENT.flTurnRate = 128
ENT.flBodyTensity = 1 // 1 means as fast as possible, lower values make us turn slower to face smaller angles

local math_AngleDifference = math.AngleDifference
local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetAngles = CEntity.GetAngles
local CEntity_LookupPoseParameter = CEntity.LookupPoseParameter
local CEntity_SetPoseParameter = CEntity.SetPoseParameter
local CEntity_GetPoseParameter = CEntity.GetPoseParameter

function ENT:EyeAngles() return self:GetAimVector():Angle() end
function ENT:SetEyeAngles( a, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	local sPitch = MyTable.m_sPitchPoseParameter
	local sYaw = MyTable.m_sYawPoseParameter
	local ppAimPitch = CEntity_LookupPoseParameter( self, sPitch )
	local Angles = CEntity_GetAngles( self )
	local aAim = Angle( Angles )
	local aDesAim = a
	if ppAimPitch != -1 then
		local p = CEntity_GetPoseParameter( self, sPitch )
		CEntity_SetPoseParameter( self, sPitch, p + math_AngleDifference( aDesAim.p, Angles.p + p ) )
		aAim.p = aAim.p + CEntity_GetPoseParameter( self, sPitch )
	end
	local ppAimYaw = CEntity_LookupPoseParameter( self, sYaw )
	if ppAimYaw != -1 then
		local p = CEntity_GetPoseParameter( self, sYaw )
		CEntity_SetPoseParameter( self, sYaw, p + math_AngleDifference( aDesAim.y, Angles.y + p ) )
		aAim.y = aAim.y + CEntity_GetPoseParameter( self, sYaw )
	end
	MyTable.aAim = aAim
	MyTable.vAim = aAim:Forward()
	// TODO: Turn the body if it's out of our pose parameters?
	// if MyTable.bCantTurnBody then return end
end
