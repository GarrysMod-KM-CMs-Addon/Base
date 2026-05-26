// ENT.vAim = nil

function ENT:SetAimVector( v ) self.vAim = v end
function ENT:GetAimVector() return self.vAim || self:GetForward() end

ENT.flTurnRate = 128
ENT.flBodyTensity = 1 // 1 means as fast as possible, lower values make us turn slower to face smaller angles

local math_AngleDifference = math.AngleDifference
local math_Clamp = math.Clamp
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
	local aAngles = CEntity_GetAngles( self )
	if !MyTable.bPhysics then a[ 1 ] = math_Clamp( a[ 1 ], -89, 89 ) end
	local aAim = Angle( Angles )
	local ppAimPitch = CEntity_LookupPoseParameter( self, sPitch )
	if ppAimPitch != -1 then
		local p = CEntity_GetPoseParameter( self, sPitch )
		CEntity_SetPoseParameter( self, sPitch, math_AngleDifference( a[ 1 ], aAngles[ 1 ] - p ) )
		aAim[ 1 ] = aAim[ 1 ] + CEntity_GetPoseParameter( self, sPitch )
	end
	local ppAimYaw = CEntity_LookupPoseParameter( self, sYaw )
	if ppAimYaw != -1 then
		local p = CEntity_GetPoseParameter( self, sYaw )
		CEntity_SetPoseParameter( self, sYaw, math_AngleDifference( a[ 2 ], aAngles[ 2 ] - p ) )
		aAim[ 2 ] = aAim[ 2 ] + CEntity_GetPoseParameter( self, sYaw )
	end
	MyTable.aAim = aAim
	MyTable.vAim = aAim:Forward()
	// TODO: Turn the body if it's out of our pose parameters?
	// if MyTable.bCantTurnBody then return end
end
