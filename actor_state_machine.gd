extends "res://addons/state_machine/state_machine.gd"
tool

export(NodePath) var actor_controller_path = NodePath()
var actor_controller = null

func _change_state(state_name):
	"""
	The base state_machine interface this node extends does most of the work
	"""
	if not _active:
		return
	._change_state(state_name)
	
# Input actions
var input_direction = Vector3() setget set_input_direction
var input_magnitude = 0.0 setget set_input_magnitude
var action_pressed = false

func set_input_direction(p_input_direction):
	input_direction = p_input_direction
	
func set_input_magnitude(p_input_magnitude):
	input_magnitude = p_input_magnitude
	
func get_input_direction():
	return input_direction
	
func get_input_magnitude():
	return input_magnitude
	
func is_attempting_movement():
	return input_direction.length() > 0.0 and input_magnitude > 0.0
	
func get_actor_controller():
	return actor_controller
		
func is_grounded():
	return get_actor_controller().is_grounded()
	
func get_move_vector():
	get_actor_controller().get_move_vector()
		
func set_move_vector(p_move_vector):
	get_actor_controller().set_move_vector(p_move_vector)
	
func get_direction_vector():
	return get_actor_controller().get_direction_vector()
	
func set_direction_vector(p_normal):
	get_actor_controller().set_direction_vector(p_normal)
	
func get_euler():
	return get_actor_controller().get_euler()
	
func set_euler(p_euler):
	actor_controller.set_euler(p_euler)
	
func _ready():
	states_map = {
		"Spawned": $Spawned,
		"Idle": $Idle,
		"Locomotion": $Locomotion,
		"Falling": $Falling,
		"Stop": $Stop
	}
	
	actor_controller = get_node(actor_controller_path)