local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

ENT.m_tSkills = {}

// If you don't want to localize CEntity_GetTable,
// and most likely you don't, you can use this as
/*
function ENT:GrantDefaultSkills()
	local MyTable = self:GrantDefaultSkills()
	if !MyTable then return end
end
*/

function ENT:GrantDefaultSkills( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	if MyTable.m_bGrantedDefaultSkills then return end
	MyTable.m_bGrantedDefaultSkills = true
	return MyTable
end

function ENT:RegrantDefaultSkills( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	MyTable.m_bGrantedDefaultSkills = nil
	MyTable.GrantDefaultSkills( self, MyTable )
end

function ENT:HasSkill( sSkill, MyTable )
	if MyTable then return MyTable.m_tSkills[ sSkill ] end
	return CEntity_GetTable( self ).m_tSkills[ sSkill ]
end

function ENT:GrantSkill( sSkill, MyTable )
	if MyTable then MyTable.m_tSkills[ sSkill ] = true return end
	CEntity_GetTable( self ).m_tSkills[ sSkill ] = true
end

function ENT:RevokeSkill( sSkill, MyTable )
	if MyTable then MyTable.m_tSkills[ sSkill ] = nil return end
	CEntity_GetTable( self ).m_tSkills[ sSkill ] = nil
end
