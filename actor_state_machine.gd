extends "res://addons/state_machine/state_machine.gd"
tool

export(NodePath) var actor_controller_path = NodePath()
var actor_controller = null

func _change_state(state_name : String) -> void:
	"""
	The base state_machine interface this node extends does most of the work
	"""
	if not _active:
		return
	._change_state(state_name)
	
# Input actions
var input_direction : Vector2 = Vector2() setget set_input_direction
var input_magnitude : float = 0.0 setget set_input_magnitude
var action_pressed : bool = false

func set_input_direction(p_input_direction : Vector2):
	input_direction = p_input_direction
	
func set_input_magnitude(p_input_magnitude : float):
	input_magnitude = p_input_magnitude
	
func get_input_direction() -> Vector2:
	return input_direction
	
func get_input_magnitude() -> float:
	return input_magnitude
	
func is_attempting_movement() -> bool:
	return input_direction.length() > 0.0 and input_magnitude > 0.0
	
func get_actor_controller() -> Node:
	return actor_controller
		
func is_grounded() -> bool:
	return get_actor_controller().is_grounded()
	
func get_move_vector() -> Vector3:
	return get_actor_controller().get_move_vector()
		
func set_move_vector(p_move_vector : Vector3) -> void:
	get_actor_controller().set_move_vector(p_move_vector)
	
func get_direction_vector() -> Vector3:
	return get_actor_controller().get_direction_vector()
	
func set_direction_vector(p_normal : Vector3) -> void:
	get_actor_controller().set_direction_vector(p_normal)
	
func get_euler() -> Vector3:
	return get_actor_controller().get_euler()
	
func set_euler(p_euler : Vector3) -> void:
	actor_controller.set_euler(p_euler)
	
func move(p_movement : Vector3) -> void:
	actor_controller.move(p_movement)
	
func update(p_delta : float) -> void:
	.update(p_delta)
	
func _ready() -> void:
	if !Engine.is_editor_hint():
		states_map = {
			"Spawned": $Spawned,
			"Idle": $Idle,
			"Locomotion": $Locomotion,
			"Falling": $Falling,
			"Stop": $Stop,
			"Landed": $Landed
		}
		
		actor_controller = get_node(actor_controller_path)