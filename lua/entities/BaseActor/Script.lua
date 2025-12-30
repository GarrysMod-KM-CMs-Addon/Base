function ENT:CustomInput( Input, Param, Activator, Caller ) end

local __INPUTS__ = {
	updateenemymemory = function( self, sName )
		local tPositions
		local c = string.find( sName, "," )
		if c then
			local bef = string.sub( sName, 1, c - 1 )
			local aft = string.sub( sName, c + 1 )
			tPositions = {}
			local bNotFound = true
			for _, ent in ipairs( ents.FindByName( aft ) ) do
				table.insert( tPositions, { ent:GetPos(), ent:GetAngles() } )
				bNotFound = nil
			end
			if bNotFound then
				for _, ent in ipairs( ents.FindByClass( aft ) ) do
					table.insert( tPositions, { ent:GetPos(), ent:GetAngles() } )
				end
			end
			sName = bef
			if table.IsEmpty( tPositions ) then tPositions = nil end
		end
		if tPositions then
			local l = #tPositions
			local bNotFound = true
			for _, ent in ipairs( ents.FindByName( sName ) ) do
				if self:IsHateDisposition( ent ) then
					self:SetupBullseye( ent, unpack( tPositions[ math.random( l ) ] ) )
					bNotFound = nil
				end
			end
			if bNotFound then
				for _, ent in ipairs( ents.FindByClass( sName ) ) do
					if self:IsHateDisposition( ent ) then
						self:SetupBullseye( ent, unpack( tPositions[ math.random( l ) ] ) )
					end
				end
			end
		else
			local bNotFound = true
			for _, ent in ipairs( ents.FindByName( sName ) ) do
				if self:IsHateDisposition( ent ) then
					self:SetupBullseye( ent, ent:GetPos(), ent:GetAngles() )
					bNotFound = nil
				end
			end
			if bNotFound then
				for _, ent in ipairs( ents.FindByClass( sName ) ) do
					if self:IsHateDisposition( ent ) then
						self:SetupBullseye( ent, ent:GetPos(), ent:GetAngles() )
					end
				end
			end
		end
	end,
	setrelationship = function( self, s ) self:AddRelationship( s ) end
}
function ENT:AcceptInput( Input, Activator, Caller, Param )
	local v = __INPUTS__[ string.lower( Input ) ]
	if v == nil then self:CustomInput( Input, Param, Activator, Caller ) else v( self, Param ) end
end

local __KEY_VALUES__ = {
	cweapon = function( self, _, sWeapons )
		// if sWeaponClass != nil && sWeaponClass != '' then self:Give( sWeaponClass ) end
		for t in string.gmatch( sWeapons, "[^,]+" ) do self:Give( t ) end
	end,
	eclass = function( self, _, sClass )
		sClass = "CLASS_" .. sClass
		local v = _G[ sClass ]
		if v == nil then
			Add_NPC_Class( sClass )
			local v = _G[ sClass ]
			if v then self:SetNPCClass( v ) end
		else self:SetNPCClass( v ) end
	end,
	bscripting = function( self, _, v )
		if v == "1" then
			self.m_bScript = true
		else self.m_bScript = nil end
	end
}
__KEY_VALUES__.additionalequipment = __KEY_VALUES__.cweapon
function ENT:KeyValue( k, v )
	local f = __KEY_VALUES__[ string.lower( k ) ]
	if f then f( self, k, v ) return end
	self:HandleKeyValue( k, v )
end
