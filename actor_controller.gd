extends "movement_controller.gd"
tool

# Finite state machine
const actor_state_machine_const = preload("actor_state_machine.gd")

export(NodePath) var state_machine_path = NodePath()
var state_machine = null

# Vector fed into the kinematic movement
var move_vector = Vector3()

# Movement stats
export(float) var rotation_speed = 0.0
export(float) var sprint_speed = 10.0
export(float) var walk_speed = 5.0

var render_node = null
var skeleton = null
		
func set_render_transform(p_transform):
	if render_node:
		render_node.set_transform()
		
func get_render_transform():
	if render_node:
		return render_node.get_transform()
		
func _ready():
	if !Engine.is_editor_hint():
		if spatial_node.has_node("Render"):
			render_node = spatial_node.get_node("Render")
		if has_node(state_machine_path):
			state_machine = get_node(state_machine_path)

	else:
		set_process(false)
		set_process_internal(false)
		set_physics_process(false)
		set_physics_process_internal(false)
		set_process_input(false)
		set_process_unhandled_key_input(false)
		set_process_unhandled_input(false)