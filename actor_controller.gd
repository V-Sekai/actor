extends "movement_controller.gd"
tool

export(NodePath) var state_machine_path = NodePath()
var state_machine = null

# Render
export(NodePath) var third_person_render_node_path = NodePath()
onready var third_person_render_node = get_node(third_person_render_node_path)

# Vector fed into the kinematic movement
var move_vector = Vector3() setget set_move_vector, get_move_vector

func set_move_vector(p_move_vector):
	move_vector = p_move_vector
	
func get_move_vector():
	return move_vector
	
#
var direction_vector = Vector3() setget set_direction_vector, get_direction_vector

func set_direction_vector(p_direction_vector):
	direction_vector = p_direction_vector
	
func get_direction_vector():
	return direction_vector

# Movement stats
export(float) var rotation_speed = 0.0
export(float) var sprint_speed = 10.0
export(float) var walk_speed = 5.0

# Render
export(NodePath) var render_node_path = NodePath()
var render_node = null

# Animation
export(NodePath) var animation_graph_player_node_path = NodePath()
var animation_graph_player = null

var skeleton = null

func _ready():
	if !Engine.is_editor_hint():
		# Render node
		if has_node(render_node_path):
			render_node = get_node(render_node_path)
			if render_node == self or not render_node is Spatial:
				render_node = null
			else:
				render_node.set_as_toplevel(true)
				render_node.global_transform = Transform(Basis(), get_global_origin())
				
		# Animation node
		if has_node(animation_graph_player_node_path):
			animation_graph_player_node_path = get_node(animation_graph_player_node_path)
			if animation_graph_player_node_path == self:
				animation_graph_player_node_path = null
			
		# State machine node
		if has_node(state_machine_path):
			state_machine = get_node(state_machine_path)
			if state_machine == self:
				state_machine = null
	else:
		set_process(false)
		set_process_internal(false)
		set_physics_process(false)
		set_physics_process_internal(false)
		set_process_input(false)
		set_process_unhandled_key_input(false)
		set_process_unhandled_input(false)
		
func get_gravity():
	return (-9.8 * 3)
		
func _entity_ready():
	._entity_ready()
	
	if is_entity_master():
		third_person_render_node.hide()
	else:
		third_person_render_node.show()
		
func _on_transform_changed():
	._on_transform_changed()