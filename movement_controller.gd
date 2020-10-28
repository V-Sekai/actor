extends "res://addons/entity_manager/node_3d_simulation_logic.gd"
tool

const MAX_SLIDE_ATTEMPTS = 4

const controller_helpers_const = preload("controller_helpers.gd")

const extended_kinematic_body_const = preload("res://addons/extended_kinematic_body/extended_kinematic_body.gd")
export (NodePath) var _extended_kinematic_body_path: NodePath = NodePath()
var _extended_kinematic_body: extended_kinematic_body_const = null setget set_kinematic_body, get_kinematic_body

var motion_vector: Vector3 = Vector3()
var movement_vector: Vector3 = Vector3() # Movement for this frame

func set_global_origin(p_origin: Vector3, _p_update_physics: bool = false) -> void:
	.set_global_origin(p_origin, _p_update_physics)
	if _p_update_physics:
		if _extended_kinematic_body:
			_extended_kinematic_body.set_global_transform(Transform(Basis(), get_global_origin()))


func set_transform(p_transform: Transform, _p_update_physics: bool = false) -> void:
	.set_transform(p_transform, _p_update_physics)
	if _p_update_physics:
		if _extended_kinematic_body:
			_extended_kinematic_body.set_global_transform(Transform(Basis(), get_global_origin()))


func set_global_transform(p_global_transform: Transform, _p_update_physics: bool = false) -> void:
	.set_global_transform(p_global_transform, _p_update_physics)
	if _p_update_physics:
		if _extended_kinematic_body:
			_extended_kinematic_body.set_global_transform(Transform(Basis(), get_global_origin()))


func set_kinematic_body(p_extended_kinematic_body: extended_kinematic_body_const) -> void:
	_extended_kinematic_body = p_extended_kinematic_body


func get_kinematic_body() -> extended_kinematic_body_const:
	return _extended_kinematic_body


func set_direction_normal(p_normal: Vector3) -> void:
	if p_normal == Vector3():
		return
	set_global_transform(
		get_global_transform().looking_at(get_global_origin() + p_normal, Vector3(0, 1, 0))
	)


func get_direction_normal() -> Vector3:
	return get_global_transform().basis.z


func move(p_target_velocity: Vector3) -> void:
	if _extended_kinematic_body:
		if p_target_velocity.length() > 0.0:
			motion_vector = _extended_kinematic_body.extended_move(p_target_velocity, MAX_SLIDE_ATTEMPTS)
			set_global_transform(
				Transform(
					get_global_transform().basis, _extended_kinematic_body.global_transform.origin
				)
			)


func set_movement_vector(p_target_velocity: Vector3) -> void:
	movement_vector = p_target_velocity
	
	
func is_grounded() -> bool:
	if _extended_kinematic_body:
		return _extended_kinematic_body.is_grounded
	else:
		return false


func set_grounded(p_is_grounded: bool) -> void:
	if _extended_kinematic_body:
		_extended_kinematic_body.is_grounded = p_is_grounded


func get_gravity_speed() -> float:
	return 9.8 * 3


func get_gravity_direction() -> Vector3:
	return Vector3(0.0, -1.0, 0.0)


func teleport_to(p_transform: Transform) -> void:
	set_global_transform(p_transform, true)
	

func cache_nodes() -> void:
	.cache_nodes()

	if has_node(_extended_kinematic_body_path):
		_extended_kinematic_body = get_node_or_null(_extended_kinematic_body_path)

		if (
			_extended_kinematic_body == self
			or not _extended_kinematic_body is extended_kinematic_body_const
		):
			_extended_kinematic_body = null

func _ready() -> void:
	if _extended_kinematic_body:
		_extended_kinematic_body.set_as_toplevel(true)
		_extended_kinematic_body.global_transform = Transform(
			Basis(), get_global_transform().origin
		)
