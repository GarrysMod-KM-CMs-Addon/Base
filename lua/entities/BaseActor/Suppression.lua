ENT.flShootTimeMin = 2
ENT.flShootTimeMax = 12

ENT.GAME_flSuppression = 0

ENT.flSuppressionHide = .2

function ENT:CanExpose( MyTable ) return self.GAME_flSuppression <= self:Health() * self.flSuppressionHide end

// TODO: Implement functions:
// 1. slowly find HQ suppress target (and validate it)
// 2. quicky find suppress target (and validate it)
// 3. lightweight check if the enemy can be suppressed from behind a cover candidate,
// so we can take it even if it's not along the path, which is useful for when we have to
// loop around for the path to face the enemy, but have an elevated position for example
