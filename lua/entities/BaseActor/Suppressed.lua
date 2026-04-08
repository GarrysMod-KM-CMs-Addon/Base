ENT.flShootTimeMin = 2
ENT.flShootTimeMax = 12

ENT.GAME_flSuppression = 0
ENT.flSuppressionMax = 8
ENT.flSuppressionRec = 8
ENT.flSuppressionHide = .1

function ENT:CanExpose( MyTable ) return self.GAME_flSuppression <= self:Health() * self.flSuppressionHide end
