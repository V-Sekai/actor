extends "movement_controller.gd"
tool

const state_machine_const = preload("./actor_state_machine.gd")

export(NodePath) var _state_machine_path : NodePath = NodePath()
var _state_machine : state_machine_const = null

# Render
export(NodePath) var _third_person_render_node_path : NodePath = NodePath()
onready var _third_person_render_node : Node = get_node(_third_person_render_node_path)

# Vector fed into the kinematic movement
var move_vector : Vector3 = Vector3() setget set_move_vector, get_move_vector

func set_move_vector(p_move_vector : Vector3) -> void:
	move_vector = p_move_vector
	
func get_move_vector() -> Vector3:
	return move_vector
	
#
var direction_vector : Vector3 = Vector3() setget set_direction_vector, get_direction_vector

func set_direction_vector(p_direction_vector : Vector3) -> void:
	direction_vector = p_direction_vector
	
func get_direction_vector() -> Vector3:
	return direction_vector

# Movement stats
export(float) var sprint_speed : float = 10.0 setget set_sprint_speed, get_sprint_speed
export(float) var walk_speed : float = 5.0 setget set_walk_speed, get_walk_speed

func set_sprint_speed(p_speed : float) -> void:
	sprint_speed = p_speed
	
func get_sprint_speed() -> float:
	return sprint_speed

func set_walk_speed(p_speed : float) -> void:
	walk_speed = p_speed
	
func get_walk_speed() -> float:
	return walk_speed

# Render
export(NodePath) var _render_node_path : NodePath = NodePath()
var _render_node : Spatial = null

#var skeleton = null : Spatial

func _ready() -> void:
	if !Engine.is_editor_hint():
		# Render node
		if has_node(_render_node_path):
			_render_node = get_node(_render_node_path)
			if _render_node == self or not _render_node is Spatial:
				_render_node = null
			else:
				_render_node.set_as_toplevel(true)
				_render_node.global_transform = Transform(Basis(), get_global_origin())
			
		# State machine node
		if has_node(_state_machine_path):
			_state_machine = get_node(_state_machine_path)
			if _state_machine == self:
				_state_machine = null
	else:
		set_process(false)
		set_process_internal(false)
		set_physics_process(false)
		set_physics_process_internal(false)
		set_process_input(false)
		set_process_unhandled_key_input(false)
		set_process_unhandled_input(false)
		
func get_gravity() -> float:
	return (-9.8 * 3)
		
func _entity_ready() -> void:
	._entity_ready()
	
	"""if is_entity_master():
		_third_person_render_node.hide()
	else:
		_third_person_render_node.show()"""
		
	_third_person_render_node.show()
		
func _on_transform_changed():
	._on_transform_changed()
