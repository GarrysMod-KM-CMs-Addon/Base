// This is an override/nullifier of Source Engine's shitty default watersplash,
// so that we can make custom FX for props being tossed in water.
// You are most likely looking for FootstepSplash.

function EFFECT:Init() end
function EFFECT:Think() return false end
function EFFECT:Render() end
