// ENT.Schedule = nil

// See Mind.lua for the new default implementation as of version 0.20.0
// local ErrorNoHaltWithStack = ErrorNoHaltWithStack
// function ENT:SelectSchedule( MyTable, Previous, PrevName, PrevReturn ) ErrorNoHaltWithStack "SelectSchedule Not Overriden" end

// EDIT: 0.20.0?! Holy shit, this is OLD! (writing this as of developing commit 532)

local rawget = rawget

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

function ENT:IsCurrentSchedule( sName )
	local pSchedule = CEntity_GetTable( self ).Schedule
	return pSchedule && pSchedule.m_sName == sName
end

function ENT:SetSchedule( Name, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )

	local pSchedule = MyTable.Schedule
	if pSchedule then
		local sClassName = pSchedule.m_sName || ""
		local pScheduleClass = __SCHEDULE__[ sClassName ]
		if pScheduleClass then
			local fOnLeave = pScheduleClass.OnLeave
			if fOnLeave then fOnLeave( self, pSchedule, MyTable ) end
		end
	end

	local sched = { m_pOwner = self, m_sName = Name }
	MyTable.Schedule = sched
	return sched
end

local __SCHEDULE__ = __SCHEDULE__

ENT.tPreScheduleResetVariables = {}
ENT.tPreScheduleResetVariables.bCharging = false
ENT.tPreScheduleResetVariables.bTaunting = false
ENT.tPreScheduleResetVariables.bAttacking = false

function ENT:SelectScheduleInternal( MyTable, ... )
	if MyTable.m_bScript then return end
	MyTable.Schedule = nil
	local p = MyTable.GAME_pBehaviour
	if p then if p:SelectSchedule( self, MyTable, ... ) then return end end
	local veh = MyTable.GAME_pVehicle
	if IsValid( veh ) then MyTable.SetSchedule( self, "VehicleBase", MyTable )
	else MyTable.SelectSchedule( self, MyTable, ... ) end
end

local pairs = pairs
local Either = Either

function ENT:PreScheduleResetVariables() end

local function PreScheduleResetVariables( MyTable, t )
	for k, v in pairs( t ) do
		if k == "BaseClass" then
			PreScheduleResetVariables( MyTable, v )
			continue
		end
		MyTable[ k ] = Either( v == false, nil, v )
	end
end

function ENT:RunMind()
	local MyTable = CEntity_GetTable( self )
	MyTable.PreScheduleResetVariables( self, MyTable )
	PreScheduleResetVariables( MyTable, MyTable.tPreScheduleResetVariables )
	local pSchedule = MyTable.Schedule
	if !pSchedule then MyTable.SelectScheduleInternal( self, MyTable ) return end
	local sClassName = pSchedule.m_sName || ""
	if IsValid( MyTable.GAME_pVehicle ) then
		if !sClassName:match "^Vehicle" then MyTable.Schedule = nil MyTable.SelectScheduleInternal( self, MyTable, pSchedule, sClassName ) return end
	elseif sClassName:match "^Vehicle" then MyTable.Schedule = nil MyTable.SelectScheduleInternal( self, MyTable, pSchedule, sClassName ) return end
	local pScheduleClass = __SCHEDULE__[ sClassName ]
	if !pScheduleClass then MyTable.SelectScheduleInternal( self, MyTable, pSchedule, sClassName ) return end
	local fExecute = pScheduleClass.Execute
	if !fExecute then
		ErrorNoHaltWithStack( "Schedule class " .. sClassName .. "missing Execute!" )
		MyTable.SelectScheduleInternal( self, MyTable, pSchedule, sClassName )
		return
	end
	local Return = fExecute( self, pSchedule, MyTable )
	if Return != nil then
		local fOnLeave = pScheduleClass.OnLeave
		if fOnLeave then fOnLeave( self, pSchedule, MyTable ) end
		MyTable.SelectScheduleInternal( self, MyTable, pSchedule, sClassName, Return )
	end
end

------ Include Default Schedules ------

include "Schedules/Vehicle/Base.lua"
include "Schedules/CombatHeavy/Main.lua"

include "Schedules/Idle.lua"
include "Schedules/Cover.lua"
include "Schedules/Peek.lua"
include "Schedules/TakeCover.lua"
include "Schedules/TakeCoverMove.lua"
include "Schedules/PullAlarm.lua"
include "Schedules/Startle.lua"
include "Schedules/PickUpGun.lua"
include "Schedules/FreeMovement.lua"
