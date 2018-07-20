extends "res://addons/entity_manager/spatial_logic_node.gd"
tool

const MAX_SLIDE_ATTEMPTS = 4

const extended_kinematic_body_const = preload("res://addons/extended_kinematic_body/extended_kinematic_body.gd")
export(NodePath) var extended_kinematic_body_path = NodePath()
var extended_kinematic_body = null setget set_kinematic_body, get_kinematic_body

func set_kinematic_body(p_extended_kinematic_body):
	extended_kinematic_body = p_extended_kinematic_body
	
func get_kinematic_body():
	return extended_kinematic_body

var target_velocity = Vector3(0.0, 0.0, 0.0)
var velocity = Vector3(0.0, 0.0, 0.0)
	
static func convert_euler_to_normal(p_euler):
	return Vector3(cos(p_euler.x) * sin(p_euler.y), -sin(p_euler.x), cos(p_euler.y) * cos(p_euler.x))
	
static func convert_normal_to_euler(p_normal):
	return Vector2(asin(p_normal.y), atan2(p_normal.x, p_normal.z))

static func interpolate_angle(p_current_angle, p_target_angle):
	return p_target_angle
	
func set_direction_normal(p_normal):
	if p_normal == Vector3():
		return
	set_global_transform(get_global_transform().looking_at(get_global_origin() + p_normal, Vector3(0,1,0)))
	
func get_direction_normal():
	return get_global_transform().basis.z
	
func move(p_target_velocity):
	extended_kinematic_body.extended_move(p_target_velocity, MAX_SLIDE_ATTEMPTS)
	set_global_transform(Transform(get_global_transform().basis, extended_kinematic_body.global_transform.origin))
	
func is_grounded():
	return extended_kinematic_body.is_grounded

func _on_transform_changed():
	._on_transform_changed()
	
func _ready():
	if has_node(extended_kinematic_body_path):
		extended_kinematic_body = get_node(extended_kinematic_body_path)
	
		if extended_kinematic_body == self or not extended_kinematic_body is extended_kinematic_body_const:
			extended_kinematic_body = null
		else:
			# By default, kinematic body is not affected by its parent's movement
			extended_kinematic_body.set_as_toplevel(true)
			extended_kinematic_body.global_transform = Transform(Basis(), get_global_transform().origin)