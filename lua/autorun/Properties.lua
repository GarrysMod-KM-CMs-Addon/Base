// Entities cannot be on fire, for now, until maybe I implement a Far Cry 3 like propagation system. Maybe.
properties.Remove( "ignite" )
properties.Remove( "extinguish" )

local PROPERTY = 90001

PROPERTY = PROPERTY + 1
properties.Add( "Properties_Kill", {
	MenuLabel = "#Properties_Kill",
	Order = PROPERTY,
	MenuIcon = "icon16/stop.png",
	PrependSpacer = true,

	Filter = function( self, pEntity, pPlayer )
		if !gamemode.Call( "CanProperty", pPlayer, "Properties_Kill", pEntity ) then return false end

		local fAlive = pEntity.Alive
		if fAlive && !fAlive( pEntity ) then return false end

		return pEntity:Health() > 0
	end,

	Action = function( self, pEntity )
		self:MsgStart()
			net.WriteEntity( pEntity )
		self:MsgEnd()
	end,

	Receive = function( self, flLength, pPlayer )
		local pEntity = net.ReadEntity()
		if !properties.CanBeTargeted( pEntity, pPlayer ) then return end
		if !self:Filter( pEntity, pPlayer ) then return end

		local pDamage = DamageInfo()

		local flMax = pEntity:GetMaxHealth()
		if flMax > 0 then
			pDamage:SetDamage( flMax * .4 )
		else
			pDamage:SetDamage( pEntity:Health() * .4 )
		end

		// Just for show
		pDamage:SetDamageForce( ( pEntity:GetPos() + pEntity:OBBCenter() - pPlayer:EyePos() ):GetNormalized() * 128 * 85 )

		pDamage:SetAttacker( pPlayer )

		pEntity:SetHealth( 0 )
		pEntity:TakeDamageInfo( pDamage )
	end
} )

PROPERTY = PROPERTY + 1
properties.Add( "Properties_KillViolently", {
	MenuLabel = "#Properties_KillViolently",
	Order = PROPERTY,
	MenuIcon = "icon16/cancel.png",

	Filter = function( self, pEntity, pPlayer )
		if !gamemode.Call( "CanProperty", pPlayer, "Properties_KillViolently", pEntity ) then return false end

		local fAlive = pEntity.Alive
		if fAlive && !fAlive( pEntity ) then return false end

		return pEntity:Health() > 0
	end,

	Action = function( self, pEntity )
		self:MsgStart()
			net.WriteEntity( pEntity )
		self:MsgEnd()
	end,

	Receive = function( self, flLength, pPlayer )
		local pEntity = net.ReadEntity()
		if !properties.CanBeTargeted( pEntity, pPlayer ) then return end
		if !self:Filter( pEntity, pPlayer ) then return end

		local pDamage = DamageInfo()

		local flMax = pEntity:GetMaxHealth()
		if flMax > 0 then
			pDamage:SetDamage( flMax * 2 )
		else
			pDamage:SetDamage( pEntity:Health() * 2 )
		end

		pDamage:SetDamageForce( ( pEntity:GetPos() + pEntity:OBBCenter() - pPlayer:EyePos() ):GetNormalized() * 4096 * 85 )

		pDamage:SetAttacker( pPlayer )

		pEntity:SetHealth( 0 )
		pEntity:TakeDamageInfo( pDamage )
	end
} )

PROPERTY = PROPERTY + 1
properties.Add( "Properties_HealUp", {
	MenuLabel = "#Properties_HealUp",
	Order = PROPERTY,
	MenuIcon = "icon16/heart_add.png",

	Filter = function( self, pEntity, pPlayer )
		if !gamemode.Call( "CanProperty", pPlayer, "Properties_HealUp", pEntity ) then return false end

		local fAlive = pEntity.Alive
		if fAlive && !fAlive( pEntity ) then return false end

		local flHealth, flMax = pEntity:Health(), pEntity:GetMaxHealth()
		return flHealth > 0 && flMax > 0 && flHealth < flMax
	end,

	Action = function( self, pEntity )
		self:MsgStart()
			net.WriteEntity( pEntity )
		self:MsgEnd()
	end,

	Receive = function( self, flLength, pPlayer )
		local pEntity = net.ReadEntity()
		if !properties.CanBeTargeted( pEntity, pPlayer ) then return end
		if !self:Filter( pEntity, pPlayer ) then return end
		pEntity:SetHealth( pEntity:GetMaxHealth() )
	end
} )

PROPERTY = PROPERTY + 1
properties.Add( "Properties_HealDown", {
	MenuLabel = "#Properties_HealDown",
	Order = PROPERTY,
	MenuIcon = "icon16/heart_delete.png",

	Filter = function( self, pEntity, pPlayer )
		if !gamemode.Call( "CanProperty", pPlayer, "Properties_HealDown", pEntity ) then return false end

		local fAlive = pEntity.Alive
		if fAlive && !fAlive( pEntity ) then return false end

		local flHealth, flMax = pEntity:Health(), pEntity:GetMaxHealth()
		return flHealth > 0 && flMax > 0 && flHealth > flMax
	end,

	Action = function( self, pEntity )
		self:MsgStart()
			net.WriteEntity( pEntity )
		self:MsgEnd()
	end,

	Receive = function( self, flLength, pPlayer )
		local pEntity = net.ReadEntity()
		if !properties.CanBeTargeted( pEntity, pPlayer ) then return end
		if !self:Filter( pEntity, pPlayer ) then return end
		pEntity:SetHealth( pEntity:GetMaxHealth() )
	end
} )

PROPERTY = PROPERTY + 1
properties.Add( "Properties_TakeControl", {
	MenuLabel = "#Properties_TakeControl",
	Order = PROPERTY,
	MenuIcon = "icon16/controller.png",

	Filter = function( self, pEntity, pPlayer )
		if !gamemode.Call( "CanProperty", pPlayer, "Properties_TakeControl", pEntity ) then return false end

		if !pEntity.__ACTOR__ || !pEntity.__CONTROLLABLE__ then return false end

		return true
	end,

	Action = function( self, pEntity )
		self:MsgStart()
			net.WriteEntity( pEntity )
		self:MsgEnd()
	end,

	Receive = function( self, flLength, pPlayer )
		local pEntity = net.ReadEntity()
		if !properties.CanBeTargeted( pEntity, pPlayer ) then return end

		if !self:Filter( pEntity, pPlayer ) then return end

		ACTOR_TAKE_CONTROL( pEntity, pPlayer )
	end
} )
