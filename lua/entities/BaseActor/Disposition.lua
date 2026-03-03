ENT.iDefaultClass = CLASS_NONE
// ENT.iClass = nil

// The reason we don't do ENT.__ACTOR_TABLE_BY_CLASS__ = {} is because
// Garry's Mod Lua internally does magic that makes the table NOT mutable.
// Usually, this is extremely useful, but here, it's a very small problem.
// local __ACTOR_TABLE_BY_CLASS__ = {}
__ACTOR_TABLE_BY_CLASS__ = __ACTOR_TABLE_BY_CLASS__ || {}
local __ACTOR_TABLE_BY_CLASS_LOCAL__ = __ACTOR_TABLE_BY_CLASS__
function ENT.GetActorTableByClass() return __ACTOR_TABLE_BY_CLASS_LOCAL__ end
local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
local CLASS_NONE = CLASS_NONE
function ENT:GetAlliesByClass() local f = CEntity_GetTable( self ) f = f.iClass || f.iDefaultClass if f == CLASS_NONE then return end return __ACTOR_TABLE_BY_CLASS_LOCAL__[ f ] end

local isentity, IsValid = isentity, IsValid
hook.Add( "Think", "BaseActorDisposition", function()
	local t = {}
	for cls, tbl in pairs( __ACTOR_TABLE_BY_CLASS_LOCAL__ ) do
		for ent in pairs( tbl ) do
			if !isentity( ent ) || !IsValid( ent ) then continue end
			local v = t[ cls ]
			if v then v[ ent ] = true else t[ cls ] = { [ ent ] = true } end
		end
	end
	__ACTOR_TABLE_BY_CLASS__ = t
	__ACTOR_TABLE_BY_CLASS_LOCAL__ = t
end )

// Getters exist for a reason. Use them.
function ENT:GetNPCClass() return self.m_iClass || self.iDefaultClass end
function ENT:Classify() return self.m_iClass || self.iDefaultClass end
// Setters also exist for a reason. Use them too.
function ENT:SetNPCClass( iClass )
	self.m_iClass = iClass
	local iPreviousClass = self:GetNPCClass()
	if iPreviousClass != CLASS_NONE then
		local t = __ACTOR_TABLE_BY_CLASS__[ iPreviousClass ]
		if t then t[ self ] = nil end
	end
	iClass = iClass || CLASS_NONE
	if iClass != CLASS_NONE then
		local t = __ACTOR_TABLE_BY_CLASS__[ iClass ]
		if t then t[ self ] = true
		else __ACTOR_TABLE_BY_CLASS__[ iClass ] = { [ self ] = true } end
	end
end

ENT.tSpecialRelationships = {}
function ENT:AddEntityRelationship( ent, disp ) self.tSpecialRelationships[ ent ] = disp end

local D_ENUM = { D_ER = 0, D_HT = 1, D_FR = 2, D_LI = 3, D_NU = 4 }
function ENT:AddRelationship( sRelationship )
	local sPart1, sPart2 = sRelationship:find( " " ), sRelationship:find( " ", sRelationship:find( " " ) + 1 )
	local sClass = sRelationship:sub( 1, sPart1 - 1 )
	local Relationship = D_ENUM[ sRelationship:sub( sPart1 + 1, sPart2 - 1 ) ] || 0
	local bNotFound = true
	for _, ent in ipairs( ents.FindByName( sClass ) ) do
		self.tSpecialRelationships[ ent ] = Relationship
		bNotFound = nil
	end
	// Classname-based relationships are only semi-supported since we're using a completely new relationship system to VALVe's
	if bNotFound then for _, ent in ipairs( ents.FindByClass( sClass ) ) do self.tSpecialRelationships[ ent ] = Relationship end end
end

local ai_ignoreplayers = GetConVar "ai_ignoreplayers"
function ENT:Disposition( ent )
	if !IsValid( ent ) || ent.__ALARM__ || ent.__PROJECTILE__ then return D_NU end
	if ent.__ACTOR_BULLSEYE__ then return ent.Owner == self && D_HT || D_NU end
	if !ent.Classify || ent:IsPlayer() && ai_ignoreplayers:GetInt() == 1 then return D_NU end
	local v = self.tSpecialRelationships[ ent ]
	if v then return v end
	if ent.Classify then
		if self:GetNPCClass() == CLASS_NONE then return D_HT end
		return ent:Classify() == self:Classify() && D_LI || D_HT
	end
	return D_NU
end

function ENT:GetRelationship( ent ) return self:Disposition( ent ) end

function ENT:WillAttackFirst( ent )
	// Only attack first if both of us are consciously hostile beings or we are a threat to eachother
	local t = ent.tThreatToClass
	if t then return t[ self:Classify() ] end
	local t = self.tThreatToClass
	if t then
		local f = ent.Classify
		if f then
			f = f( ent )
			return t[ f ]
		end
	end
	return true
end

function ENT:IsHateDisposition( ent ) local d = self:Disposition( ent ) return d == D_HT || d == D_FR end
