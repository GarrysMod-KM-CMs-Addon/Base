__SCHEDULE__ = __SCHEDULE__ || {}
local __SCHEDULE__ = __SCHEDULE__

function RegisterSchedule( Name, Func ) __SCHEDULE__[ Name ] = Func end

__INTERACTION__ = __INTERACTION__ || {}
local __INTERACTION__ = __INTERACTION__

function RegisterInteraction( Name, Data ) __INTERACTION__[ Name ] = Data end

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

// ACTOR_QUEUE_LAST

local coroutine_create = coroutine.create
function ACTOR_QUEUE( fFunction )
	if ACTOR_QUEUE_LAST then
		local pNew = { coThread = coroutine_create( fFunction ) }
		local pHead = ACTOR_QUEUE_LAST.pNext
		pNew.pPrev = ACTOR_QUEUE_LAST
		pNew.pNext = pHead
		ACTOR_QUEUE_LAST.pNext = pNew
		pHead.pPrev = pNew
		ACTOR_QUEUE_LAST = pNew
	else
		ACTOR_QUEUE_LAST = { coThread = coroutine_create( fFunction ) }
		ACTOR_QUEUE_LAST.pPrev = ACTOR_QUEUE_LAST
		ACTOR_QUEUE_LAST.pNext = ACTOR_QUEUE_LAST
	end
end

// Cover: ( Vector vStart, Vector vEnd, Boolean bLeftSide, Table tConnections )
// CNavArea:GetID() -> SequentialTable[ Cover ]
__COVERS_STATIC__ = __COVERS_STATIC__ || util.JSONToTable( file.Read( "Covers/" .. game.GetMap() .. "_" .. game.GetMapVersion() .. ".json" ) || "[]", true )
// Cover -> { Entity -> { Any -> CNavArea:GetID() } }
__COVER_DYNAMIC_CONNECTIONS__ = {}
__COVERS_DYNAMIC__ = __COVERS_DYNAMIC__ || {} // CNavArea:GetID() -> { Entity -> { Any -> Cover } }

local FLAGS = FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_ARCHIVE + FCVAR_CHEAT

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
	"Does hunger exist? Some entities cannot be hungry even with this enabled.",
	0, 1
)
