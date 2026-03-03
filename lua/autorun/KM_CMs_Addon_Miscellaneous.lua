local CEntity = FindMetaTable "Entity"

CEntity_OBBMinsInternal = CEntity_OBBMinsInternal || CEntity.OBBMins
CEntity_OBBMaxsInternal = CEntity_OBBMaxsInternal || CEntity.OBBMaxs

local CEntity_OBBMinsInternal = CEntity_OBBMinsInternal
local CEntity_OBBMaxsInternal = CEntity_OBBMaxsInternal

local CEntity_GetTable = CEntity.GetTable

function CEntity:OBBMins()
	local v = CEntity_GetTable( self ).GAME_BoundMins
	if v then return v end
	return CEntity_OBBMinsInternal( self )
end
function CEntity:OBBMaxs()
	local v = CEntity_GetTable( self ).GAME_BoundMaxs
	if v then return v end
	return CEntity_OBBMaxsInternal( self )
end
