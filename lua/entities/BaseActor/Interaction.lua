// Interactions are used for multi-actor actions, e.g. one suppresses, other moves cover to cover.

local __INTERACTION__ = __INTERACTION__

local _r = debug.getregistry()
local CActorInteraction = _r.ActorInteraction || {}
_r.ActorInteraction = CActorInteraction

// Contains all currently running Interactions
__ACTOR_INTERACTIONS__ = __ACTOR_INTERACTIONS__ || {}
local __ACTOR_INTERACTIONS__ = __ACTOR_INTERACTIONS__

function ENT:CreateInteraction( c )
	local pInteraction = setmetatable( { m_tParticipants = {} }, { __index = function( self, Key )
		local v = rawget( self, Key )
		if v == nil then
			v = rawget( __Interaction__[ c ], Key )
			if v == nil then return CActorInteraction[ Key ] else return v end
		else return v end
	end } )
	__INTERACTION__[ pInteraction ] = true
	return pInteraction
end

function CActorInteraction:Initialize() end

function CActorInteraction:GatherParticipants() end

// Don't return anything to let the entity's default behaviour run
// Return true to completely halt their behaviour
function CActorInteraction:SelectSchedule( self, pEntity, EntTable, Prev, Ret ) return end

function CActorInteraction:Remove()
	for pParticipant in pairs( self.m_tParticipants ) do
		if IsValid( pParticipant ) then
			pParticipant.Schedule = nil
			pParticipant.GAME_pInteraction = nil
		end
	end

	__ACTOR_INTERACTIONS__[ self ] = nil
end

function CActorInteraction:Finish()
	for pParticipant in pairs( self.m_tParticipants ) do
		if IsValid( pParticipant ) then
			pParticipant.GAME_pInteraction = nil
		end
	end

	__ACTOR_INTERACTIONS__[ self ] = nil
end

function CActorInteraction:AddParticipant( pParticipant )
	pParticipant.Schedule = nil
	pParticipant.GAME_pInteraction = self
	self.m_tParticipants[ pParticipant ] = true
end

function CActorInteraction:RemoveParticipant( pParticipant )
	pParticipant.GAME_pInteraction = nil
	self.m_tParticipants[ pParticipant ] = nil
end

function CActorInteraction:IsValidParticipant( pParticipant ) return !pParticipant.GAME_pInteraction end

function CActorInteraction:Tick() end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

function ENT:TryCallInteraction( MyTable, sFunction, ... )
	MyTable = MyTable || CEntity_GetTable( self )

	local pInteraction = MyTable.GAME_pInteraction
	if pInteraction then
		local fFunction = pInteraction[ sFunction ]
		if fFunction then return fFunction( pInteraction, self, MyTable, ... ) end
	end
end

hook.Add( "Think", "ActorInteraction", function()
	for pInteraction in pairs( __ACTOR_INTERACTIONS__ ) do pInteraction:Tick() end
end )

hook.Add( "PostCleanupMap", "ActorInteraction", function()
	for pInteraction in pairs( __ACTOR_INTERACTIONS__ ) do pInteraction:Remove() end
end )
