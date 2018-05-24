extends Node
tool

export(NodePath) var actor_controller_path = NodePath()
var actor_controller = null
var current_state = null

# Input actions
var input_direction = Vector3() setget set_input_direction
var input_magnitude = 0.0 setget set_input_magnitude
var action_pressed = false

# Settings
export(bool) var instant_turning = false

func set_input_direction(p_input_direction):
	input_direction = p_input_direction
	
func set_input_magnitude(p_input_magnitude):
	input_magnitude = p_input_magnitude

func set_current_state(p_state):
	if current_state == p_state:
		return
		
	if current_state != null:
		current_state.exit(self)
	
	current_state = p_state
	current_state.enter(self)
	
func update_current_state(p_delta):
	if current_state != null:
		current_state.update(self, p_delta)
		
func is_attempting_movement():
	return input_direction.length() > 0.0 and input_magnitude > 0.0
	
func get_actor_controller():
	return actor_controller
		
func is_grounded():
	return get_actor_controller().is_grounded()
		
func set_move_vector(p_move_vector):
	get_actor_controller().move_vector = p_move_vector
	
func get_direction_normal():
	return get_actor_controller().get_direction_normal()
	
func set_direction_normal(p_normal):
	get_actor_controller().set_direction_normal(p_normal)
	
func get_euler():
	return get_actor_controller().get_euler()
	
func set_euler(p_euler):
	actor_controller.set_euler(p_euler)
	
func _ready():
	if !Engine.is_editor_hint():
		if has_node(actor_controller_path):
			actor_controller = get_node(actor_controller_path)