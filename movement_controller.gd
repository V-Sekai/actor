extends "res://addons/entity_manager/spatial_simulation_logic.gd"
tool

const MAX_SLIDE_ATTEMPTS = 4

const controller_helpers_const = preload("res://addons/actor/controller_helpers.gd")

const extended_kinematic_body_const = preload("res://addons/extended_kinematic_body/extended_kinematic_body.gd")
export(NodePath) var _extended_kinematic_body_path : NodePath = NodePath()
var _extended_kinematic_body : extended_kinematic_body_const = null setget set_kinematic_body, get_kinematic_body

export(NodePath) var _internal_rotation_path : NodePath = NodePath()
var _internal_rotation : Spatial = null

func set_kinematic_body(p_extended_kinematic_body : extended_kinematic_body_const) -> void:
	_extended_kinematic_body = p_extended_kinematic_body
	
func get_kinematic_body() -> extended_kinematic_body_const:
	return _extended_kinematic_body

func set_direction_normal(p_normal : Vector3) -> void:
	if p_normal == Vector3():
		return
	set_global_transform(get_global_transform().looking_at(get_global_origin() + p_normal, Vector3(0,1,0)))
	
func get_direction_normal() -> Vector3:
	return get_global_transform().basis.z
	
func move(p_target_velocity : Vector3) -> Vector3:
	var motion : Vector3 = Vector3()
	
	if p_target_velocity.length() > 0.0:
		motion = _extended_kinematic_body.extended_move(p_target_velocity, MAX_SLIDE_ATTEMPTS)
		set_global_transform(Transform(get_global_transform().basis, _extended_kinematic_body.global_transform.origin))
	
	return motion
	
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
			
	if has_node(_internal_rotation_path):
		_internal_rotation = get_node(_internal_rotation_path)
	
		if _internal_rotation == self or not _internal_rotation is Spatial:
			_internal_rotation = get_entity_node()
		else:
			_internal_rotation.set_as_toplevel(true)
			_internal_rotation.global_transform = Transform(Basis(), get_global_transform().origin)
