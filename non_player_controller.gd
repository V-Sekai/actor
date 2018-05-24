extends "actor_controller.gd"
tool

const ai_pathfinder_const = preload("ai/ai_pathfinder.gd")
var pathfinder = ai_pathfinder_const.new()
const ai_move_const = preload("ai/ai_move.gd")
var move = ai_move_const.new() # Current movement info

const actor_spawned_state_const = preload("states/actor_state_spawned.gd")


var ai = null
var ai_manager_singleton = null

func debug_update():
	pass
	
func get_goal_origin():
	if move:
		return move.move_destination
	
	return global_transform.origin
	
func animation_move():
	var origin = global_transform.origin
	var goal = get_goal_origin()
	
	var dir = get_direction(origin, goal)
	
	state_machine.set_input_direction(dir)
	state_machine.set_input_magnitude(1.0)

func think(p_delta):
	if move.move_type == ai_move_const.AI_MOVE_TYPE_ANIMATION:
		animation_move()

func _physics_process(p_delta):
	if !Engine.is_editor_hint():
		var player_controller = get_tree().get_nodes_in_group("player_controller")[0]
		
		state_machine.update_current_state(p_delta)
		if move_vector.length() > 0:
			move(move_vector)

func _ready():
	if !Engine.is_editor_hint():
		if get_tree().get_root().has_node("ai_manager"):
			ai_manager_singleton = get_tree().get_root().get_node("ai_manager")
		else:
			printerr("Could not load ai_manager!")
			
		if ai == null:
			ai = ai_manager_singleton.create_ai()
			ai.set_actor(self)
		
		state_machine.set_current_state(actor_spawned_state_const)