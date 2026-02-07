local __BEHAVIOUR__ = __BEHAVIOUR__

local _r = debug.getregistry()
local CActorBehaviour = _r.ActorBehaviour || {}
_r.ActorBehaviour = CActorBehaviour

// Contains All Currently Running Behaviours
__ACTOR_BEHAVIOURS__ = __ACTOR_BEHAVIOURS__ || {}
local __ACTOR_BEHAVIOURS__ = __ACTOR_BEHAVIOURS__

function ENT:CreateBehaviour( c )
	p = setmetatable( { m_tParticipants = {} }, { __index = function( self, Key )
		local v = rawget( self, Key )
		if v == nil then
			v = rawget( __BEHAVIOUR__[ c ], Key )
			if v == nil then return CActorBehaviour[ Key ] else return v end
		else return v end
	end } )
	__ACTOR_BEHAVIOURS__[ p ] = true
	return p
end

function CActorBehaviour:Initialize() end

function CActorBehaviour:GatherParticipants() end

// Don't return anything to let the entity's default behaviour run
// Return `true` to completely halt their behaviour
function CActorBehaviour:SelectSchedule( self, ent, EntTable, prev, ret ) return end

function CActorBehaviour:Remove()
	for ent in pairs( self.m_tParticipants ) do
		if IsValid( ent ) then
			ent.Schedule = nil
			ent.GAME_pBehaviour = nil
		end
	end
	__ACTOR_BEHAVIOURS__[ self ] = nil
end

function CActorBehaviour:Finish()
	for ent in pairs( self.m_tParticipants ) do
		if IsValid( ent ) then
			ent.GAME_pBehaviour = nil
		end
	end
	__ACTOR_BEHAVIOURS__[ self ] = nil
end

function CActorBehaviour:AddParticipant( ent )
	ent.Schedule = nil
	ent.GAME_pBehaviour = self
	self.m_tParticipants[ ent ] = true
end

function CActorBehaviour:RemoveParticipant( ent )
	ent.GAME_pBehaviour = nil
	self.m_tParticipants[ ent ] = nil
end

function CActorBehaviour:IsValidParticipant( ent ) return !ent.GAME_pBehaviour end

function CActorBehaviour:Tick() end

hook.Add( "Think", "ActorBehaviour", function() for beh in pairs( __ACTOR_BEHAVIOURS__ ) do beh:Tick() end end )
hook.Add( "PostCleanupMap", "ActorBehaviour", function() for beh in pairs( __ACTOR_BEHAVIOURS__ ) do beh:Remove() end end )
