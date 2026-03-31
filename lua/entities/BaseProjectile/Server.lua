ENT.__PROJECTILE__ = true

function ENT:Initialize() end

ENT.iDefaultClass = CLASS_NONE
function ENT:GetNPCClass() return self.iClass || self.iDefaultClass end
function ENT:Classify() return self:GetNPCClass() end
function ENT:SetNPCClass( iClass ) self.iClass = iClass end
