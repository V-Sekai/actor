extends "res://addons/entity_manager/spatial_logic_node.gd"
tool

const MAX_SLIDE_ATTEMPTS = 4

const extended_kinematic_body_const = preload("res://addons/extended_kinematic_body/extended_kinematic_body.gd")
export(NodePath) var _extended_kinematic_body_path : NodePath = NodePath()
var _extended_kinematic_body : extended_kinematic_body_const = null setget set_kinematic_body, get_kinematic_body

func set_kinematic_body(p_extended_kinematic_body : extended_kinematic_body_const) -> void:
	_extended_kinematic_body = p_extended_kinematic_body
	
func get_kinematic_body() -> extended_kinematic_body_const:
	return _extended_kinematic_body
	
static func get_direction_to(p_start : Vector3, p_end : Vector3) -> Vector3:
	var dir = p_end - p_start
	dir = dir.normalized()
	return dir
	
static func convert_euler_to_normal(p_euler : Vector3) -> Vector3:
	return Vector3(cos(p_euler.x) * sin(p_euler.y), -sin(p_euler.x), cos(p_euler.y) * cos(p_euler.x))
	
static func convert_normal_to_euler(p_normal : Vector3) -> Vector2:
	return Vector2(asin(p_normal.y), atan2(p_normal.x, p_normal.z))

func set_direction_normal(p_normal : Vector3) -> void:
	if p_normal == Vector3():
		return
	set_global_transform(get_global_transform().looking_at(get_global_origin() + p_normal, Vector3(0,1,0)))
	
func get_direction_normal() -> Vector3:
	return get_global_transform().basis.z
	
func move(p_target_velocity : Vector3) -> void:
	_extended_kinematic_body.extended_move(p_target_velocity, MAX_SLIDE_ATTEMPTS)
	set_global_transform(Transform(get_global_transform().basis, _extended_kinematic_body.global_transform.origin))
	
func is_grounded() -> bool:
	return _extended_kinematic_body.is_grounded

func _on_transform_changed() -> void:
	._on_transform_changed()
	
func _ready() -> void:
	if has_node(_extended_kinematic_body_path):
		_extended_kinematic_body = get_node(_extended_kinematic_body_path)
	
		if _extended_kinematic_body == self or not _extended_kinematic_body is extended_kinematic_body_const:
			_extended_kinematic_body = null
		else:
			# By default, kinematic body is not affected by its parent's movement
			_extended_kinematic_body.set_as_toplevel(true)
			_extended_kinematic_body.global_transform = Transform(Basis(), get_global_transform().origin)