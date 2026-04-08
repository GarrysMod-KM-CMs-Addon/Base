// Interactions are used for multi-actor actions, e.g. one suppresses, other moves cover to cover.

local __INTERACTION__ = __INTERACTION__

local _r = debug.getregistry()
local CActorInteraction = _r.ActorInteraction || {}
_r.ActorInteraction = CActorInteraction

// Contains all currently running Interactions
__ACTOR_INTERACTIONS__ = __ACTOR_INTERACTIONS__ || {}
local __ACTOR_INTERACTIONS__ = __ACTOR_INTERACTIONS__

function ENT:CreateInteraction( c )
	p = setmetatable( { m_tParticipants = {} }, { __index = function( self, Key )
		local v = rawget( self, Key )
		if v == nil then
			v = rawget( __Interaction__[ c ], Key )
			if v == nil then return CActorInteraction[ Key ] else return v end
		else return v end
	end } )
	__INTERACTION__[ p ] = true
	return p
end

function CActorInteraction:Initialize() end

function CActorInteraction:GatherParticipants() end

// Don't return anything to let the entity's default behaviour run
// Return `true` to completely halt their behaviour
function CActorInteraction:SelectSchedule( self, ent, EntTable, prev, ret ) return end

function CActorInteraction:Remove()
	for ent in pairs( self.m_tParticipants ) do
		if IsValid( ent ) then
			ent.Schedule = nil
			ent.GAME_pInteraction = nil
		end
	end
	__ACTOR_INTERACTIONS__[ self ] = nil
end

function CActorInteraction:Finish()
	for ent in pairs( self.m_tParticipants ) do
		if IsValid( ent ) then
			ent.GAME_pInteraction = nil
		end
	end
	__ACTOR_INTERACTIONS__[ self ] = nil
end

function CActorInteraction:AddParticipant( ent )
	ent.Schedule = nil
	ent.GAME_pInteraction = self
	self.m_tParticipants[ ent ] = true
end

function CActorInteraction:RemoveParticipant( ent )
	ent.GAME_pInteraction = nil
	self.m_tParticipants[ ent ] = nil
end

function CActorInteraction:IsValidParticipant( ent ) return !ent.GAME_pInteraction end

function CActorInteraction:Tick() end

hook.Add( "Think", "ActorInteraction", function() for beh in pairs( __ACTOR_INTERACTIONS__ ) do beh:Tick() end end )
hook.Add( "PostCleanupMap", "ActorInteraction", function() for beh in pairs( __ACTOR_INTERACTIONS__ ) do beh:Remove() end end )
