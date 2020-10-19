extends "movement_controller.gd"
tool

const state_machine_const = preload("actor_state_machine.gd")

export (NodePath) var _state_machine_path: NodePath = NodePath()
var _state_machine: state_machine_const = null

# Render
export (NodePath) var _third_person_render_node_path: NodePath = NodePath()
onready var _third_person_render_node: Node = get_node_or_null(_third_person_render_node_path)

# Vector fed into the kinematic movement
var velocity: Vector3 = Vector3() setget set_velocity, get_velocity


func set_velocity(p_velocity: Vector3) -> void:
	velocity = p_velocity


func get_velocity() -> Vector3:
	return velocity


#
var direction_vector: Vector3 = Vector3() setget set_direction_vector, get_direction_vector


func set_direction_vector(p_direction_vector: Vector3) -> void:
	direction_vector = p_direction_vector


func get_direction_vector() -> Vector3:
	return direction_vector


# Movement stats
export (float) var sprint_speed: float = 10.0 setget set_sprint_speed, get_sprint_speed
export (float) var walk_speed: float = 5.0 setget set_walk_speed, get_walk_speed


func set_sprint_speed(p_speed: float) -> void:
	sprint_speed = p_speed


func get_sprint_speed() -> float:
	return sprint_speed


func set_walk_speed(p_speed: float) -> void:
	walk_speed = p_speed


func get_walk_speed() -> float:
	return walk_speed


# Render
export (NodePath) var _render_node_path: NodePath = NodePath()
var _render_node: Spatial = null

#var skeleton = null : Spatial


func cache_nodes() -> void:
	.cache_nodes()
	
	# Render node
	_render_node = get_node_or_null(_render_node_path)
	if _render_node == self or not _render_node is Spatial:
		_render_node = null

	# State machine node
	_state_machine = get_node_or_null(_state_machine_path)
	if _state_machine == self:
		_state_machine = null


func _entity_ready() -> void:
	._entity_ready()

	_third_person_render_node.show()


func _on_transform_changed() -> void:
	._on_transform_changed()
