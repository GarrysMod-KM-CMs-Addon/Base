local _reg = debug.getregistry()
local CActorSchedule = _reg.ActorSchedule || {}
_reg.ActorSchedule = CActorSchedule

CActorSchedule.__index = CActorSchedule

// ENT.Schedule = nil

// See Mind.lua for the new default implementation as of version 0.20.0
// local ErrorNoHaltWithStack = ErrorNoHaltWithStack
// function ENT:SelectSchedule( MyTable, Previous, PrevName, PrevReturn ) ErrorNoHaltWithStack "SelectSchedule Not Overriden" end

local rawget = rawget

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

function ENT:IsCurrentSchedule( sName )
	local pSchedule = CEntity_GetTable( self ).Schedule
	return pSchedule && pSchedule.m_sName == sName
end

function ENT:SetSchedule( Name, MyTable )
	local sched = setmetatable( { m_pOwner = self, m_sName = Name }, { __index = function( self, Key, Value )
		local v = rawget( self, Key )
		if v == nil then return rawget( CActorSchedule, Key )
		else return v end
	end } )
	if MyTable then MyTable.Schedule = sched else CEntity_GetTable( self ).Schedule = sched end
	return sched
end

local __SCHEDULE__ = __SCHEDULE__
ENT.__SCHEDULE__ = {}

ENT.tPreScheduleResetVariables = {}

function ENT:SelectScheduleInternal( MyTable, ... )
	if MyTable.m_bScript then return end
	MyTable.Schedule = nil
	local p = MyTable.GAME_pBehaviour
	if p then if p:SelectSchedule( self, MyTable, ... ) then return end end
	local veh = MyTable.GAME_pVehicle
	if IsValid( veh ) then MyTable.SetSchedule( self, "Vehicle_Base", MyTable )
	else MyTable.SelectSchedule( self, MyTable, ... ) end
end

local pairs = pairs
local Either = Either

function ENT:RunMind()
	local MyTable = CEntity_GetTable( self )
	for k, v in pairs( MyTable.tPreScheduleResetVariables ) do MyTable[ k ] = Either( v == false, nil, v ) end
	local v = MyTable.Schedule
	if !v then MyTable.SelectScheduleInternal( self, MyTable ) return end
	local s = v.m_sName || ""
	local f = MyTable.__SCHEDULE__[ s ] || __SCHEDULE__[ s ]
	local b = IsValid( MyTable.GAME_pVehicle )
	if !f || ( b && !s:match "^Vehicle_" || !b && s:match "^Vehicle_" ) then MyTable.Schedule = nil MyTable.SelectScheduleInternal( self, MyTable, v, s ) return end
	local r = f( self, v, MyTable )
	if r != nil then MyTable.SelectScheduleInternal( self, MyTable, v, s, r ) end
end

------ Include Default Schedules ------

include "Schedules/Vehicle/Base.lua"

include "Schedules/Idle.lua"
include "Schedules/Combat.lua"
include "Schedules/Cover.lua"
include "Schedules/PullAlarm.lua"
include "Schedules/Startle.lua"
