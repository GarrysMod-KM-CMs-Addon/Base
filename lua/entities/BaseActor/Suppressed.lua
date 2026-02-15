ENT.flShootTimeMin = 2
ENT.flShootTimeMax = 12

function ENT:CanExpose( MyTable, f ) return self.GAME_flSuppression <= self:Health() * self.flSuppressionHide end
function ENT:IsSuppressed() return self.GAME_flSuppression > self:Health() * self.flSuppressionHide end
function ENT:GetExposedWeight() return self.GAME_flSuppression end
