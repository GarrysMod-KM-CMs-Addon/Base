__SCHEDULE__ = __SCHEDULE__ || {}
local __SCHEDULE__ = __SCHEDULE__

function Actor_RegisterSchedule( Name, Func ) __SCHEDULE__[ Name ] = Func end
function Actor_RegisterScheduleSpecial( Name, Fall ) __SCHEDULE__[ Name ] = function( self, sched ) return ( self.__SCHEDULE__[ Fall ] || __SCHEDULE__[ Fall ] )( self, sched ) end end

__BEHAVIOUR__ = __BEHAVIOUR__ || {}
local __BEHAVIOUR__ = __BEHAVIOUR__

function Actor_RegisterBehaviour( Name, Data ) __BEHAVIOUR__[ Name ] = Data end

__ALARMS__ = __ALARMS__ || {}
__ALARMS_ACTIVE__ = __ALARMS_ACTIVE__ || {}

// Cover: ( Vector vStart, Vector vEnd, Boolean bRightSide )
// CNavArea:GetID() -> SequentialTable[ Cover ]
__COVERS_STATIC__ = __COVERS_STATIC__ || util.JSONToTable( file.Read( "Covers/" .. engine.ActiveGamemode() .. ".json" ) || "[]", true )
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
