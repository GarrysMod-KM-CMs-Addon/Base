// ENT.vAim = nil

function ENT:SetAimVector( v ) self.vAim = v end
function ENT:GetAimVector() return self.vAim || self:GetForward() end

ENT.flTurnRate = 128
ENT.flBodyTensity = 1 // 1 means as fast as possible, lower values make us turn slower to face smaller angles

function ENT:EyeAngles() return self:GetAimVector():Angle() end
function ENT:SetEyeAngles( a ) self.vAim = a:Forward() end
