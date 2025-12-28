__SCHEDULE__ = __SCHEDULE__ || {}
local __SCHEDULE__ = __SCHEDULE__

function Actor_RegisterSchedule( Name, Func ) __SCHEDULE__[ Name ] = Func end
function Actor_RegisterScheduleSpecial( Name, Fall ) __SCHEDULE__[ Name ] = function( self, sched ) return ( self.__SCHEDULE__[ Fall ] || __SCHEDULE__[ Fall ] )( self, sched ) end end

__BEHAVIOUR__ = __BEHAVIOUR__ || {}
local __BEHAVIOUR__ = __BEHAVIOUR__

function Actor_RegisterBehaviour( Name, Data ) __BEHAVIOUR__[ Name ] = Data end

__ALARMS__ = __ALARMS__ || {}
__ALARMS_ACTIVE__ = __ALARMS_ACTIVE__ || {}

__ALARM_REINFORCEMENTS__ = __ALARM_REINFORCEMENTS__ || {}
for _, sPath in ipairs( file.Find( "Reinforcements/*.lua", "LUA" ) ) do ProtectedCall( function() include( "Reinforcements/" .. sPath ) end ) end

function Alarm_IsClouded( vOrigin, vPos, pAlarm )
	local tr = util.TraceLine {
		start = vPos,
		endpos = vOrigin,
		filter = pAlarm,
		mask = MASK_VISIBLE_AND_NPCS
	}
	return tr.Fraction <= .33 && tr.HitPos:DistToSqr( vPos ) > ( RANGE_ATTACK_SUPPRESSION_BOUND_SIZE * RANGE_ATTACK_SUPPRESSION_BOUND_SIZE )
end

// Cover: ( Vector vStart, Vector vEnd, Boolean bRightSide, Table tConnections )
// CNavArea:GetID() -> SequentialTable[ Cover ]
__COVERS_STATIC__ = __COVERS_STATIC__ || util.JSONToTable( file.Read( "Covers/" .. game.GetMap() .. "_" .. game.GetMapVersion() .. ".json" ) || "[]", true )
__COVERS_DYNAMIC__ = __COVERS_DYNAMIC__ || {} // CNavArea:GetID() -> { Any -> Cover }

local FLAGS = FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_ARCHIVE

CreateConVar(
	"bThirst",
	0,
	FLAGS,
	"Does thirst exist? Disabled by default so maps that don't have water work properly",
	0, 1
)
CreateConVar(
	"bHunger",
	1,
	FLAGS,
	"Does hunger exist? Some entities cannot be hungry even if this at 1.",
	0, 1
)
