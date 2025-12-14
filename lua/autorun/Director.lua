// Director API, shared endpoints

DIRECTOR_THREAT_NULL = -1
DIRECTOR_THREAT_HEAT = 0
DIRECTOR_THREAT_ALERT = 1
DIRECTOR_THREAT_HOLD_FIRE = 2
DIRECTOR_THREAT_COMBAT = 3
// A special trance-like state when there's a lot of alerted enemies.
// This state is higher than literally every other state in the game.
// For example, in Far Cry 3, when an alarm was pulled and a dozen,
// if not more, of all types of hostiles in the game are coming.
// Getting out of this situation will be extremely hard.
DIRECTOR_THREAT_MAGIC = 4

DIRECTOR_MUSIC_VO_WAIT = 1

SOUND_PATCH_ABSOLUTE_MINIMUM = .04 // Trust me, I've tried to go lower than this

// Not used on the server. Leaving it here just for you! :3
DIRECTOR_LAYER_TABLE = {
	DIRECTOR_THREAT_NULL,
	DIRECTOR_THREAT_HEAT,
	DIRECTOR_THREAT_ALERT,
	DIRECTOR_THREAT_HOLD_FIRE,
	DIRECTOR_THREAT_COMBAT,
	DIRECTOR_THREAT_MAGIC
}
