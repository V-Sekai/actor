extends Reference

enum {
	AI_MOVE_TYPE_ANIMATION
}

enum {
	AI_MOVE_NONE,
	AI_MOVE_SPATIAL,
	AI_FACE_SPATIAL,
	AI_WANDER
}

var move_type = AI_MOVE_TYPE_ANIMATION
var move_state = AI_MOVE_NONE
var move_destination = Vector3() # Final position