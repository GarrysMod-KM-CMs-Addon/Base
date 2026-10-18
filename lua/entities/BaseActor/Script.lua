local __KEY_VALUES__ = {
	Weapon = function( self, _, sWeapons )
		// if sWeaponClass != nil && sWeaponClass != '' then self:Give( sWeaponClass ) end
		for t in string.gmatch( sWeapons, "[^,]+" ) do self:Give( t ) end
	end,

	ActorClass = function( self, _, sClass )
		sClass = "CLASS_" .. sClass
		local v = _G[ sClass ]
		if v == nil then
			Add_NPC_Class( sClass )
			local v = _G[ sClass ]
			if v then self:SetNPCClass( v ) end
		else self:SetNPCClass( v ) end
	end,

	Scripting = function( self, _, v )
		if v == "1" then
			self.m_bScript = true
		else self.m_bScript = nil end
	end,

	OnSpawn = function( self, _, v )
		ACTOR = self
		RunString( v )
		ACTOR = nil
	end
}

__KEY_VALUES__.additionalequipment = __KEY_VALUES__.Weapon

function ENT:KeyValue( k, v )
	local f = __KEY_VALUES__[ k ]
	if f then f( self, k, v ) return end
	self:HandleKeyValue( k, v )
end
