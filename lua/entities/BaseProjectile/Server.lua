function ENT:Initialize() end

ENT.m_iDefaultClass = CLASS_NONE
function ENT:GetNPCClass() return self.iClass || self.m_iDefaultClass end
function ENT:Classify() return self:GetNPCClass() end
function ENT:SetNPCClass( iClass ) self.iClass = iClass end
