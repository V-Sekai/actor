extends "res://addons/entity_manager/mt_spatial_entity.gd"
tool

const MAX_SLIDE_ATTEMPTS = 4
const extended_kinematic_body_const = preload("res://addons/extended_kinematic_body/extended_kinematic_body.gd")

export(NodePath) var extended_kinematic_body_path = NodePath()
var extended_kinematic_body = null

var target_velocity = Vector3(0.0, 0.0, 0.0)
var velocity = Vector3(0.0, 0.0, 0.0)
var euler = Vector2(0.0, 0.0) setget set_euler, get_euler # radians

static func get_direction(p_start, p_end):
	var dir = p_end - p_start
	dir = dir.normalized()
	return dir
	
# Is this nessecary?
static func get_direction_advanced(p_start, p_end, p_up = Vector3(0.0, 1.0, 0.0)):
	return -Transform(Basis(), p_start).looking_at(Vector3(p_end.x, p_start.y, p_end.z), p_up).basis[2].normalized()

static func convert_euler_to_normal(p_euler):
	return Vector3(cos(p_euler.x) * sin(p_euler.y), -sin(p_euler.x), cos(p_euler.y) * cos(p_euler.x))
	
static func convert_normal_to_euler(p_normal):
	return Vector2(asin(p_normal.y), atan2(p_normal.x, p_normal.z))

static func interpolate_angle(p_current_angle, p_target_angle):
	return p_target_angle

func set_euler(p_euler):
	euler = p_euler
	
func get_euler():
	return euler
	
func set_direction_normal(p_normal):
	set_euler(convert_normal_to_euler(p_normal))
	
func get_direction_normal():
	return convert_euler_to_normal(get_euler())
	
func get_kinematic_body():
	return extended_kinematic_body
	
func move(p_target_velocity):
	extended_kinematic_body.extended_move(p_target_velocity, MAX_SLIDE_ATTEMPTS)
	set_global_transform(extended_kinematic_body.global_transform)
	
func is_grounded():
	return extended_kinematic_body.is_grounded

func process_movement(p_delta, p_move_direction, p_speed):
	# Calculate direction based on the decoded input vector
	var is_moving = (p_move_direction.length() > 0)
	
	var direction = Vector3(0.0, 0.0, 0.0)
	if is_moving:
		euler.y = convert_normal_to_euler(p_move_direction).y
		direction = convert_euler_to_normal(euler)
			
	# Perform different physics depending on whether the character is grounded or not
	if is_moving:
		target_velocity = direction * p_speed
	else:
		target_velocity = Vector3(0.0, 0.0, 0.0)
		velocity = Vector3(0.0, 0.0, 0.0)
	
	if(target_velocity.length() > 0.0):
		velocity = move(target_velocity)
	
func teleport_to(p_origin):
	pass
	
func _ready():
	if has_node(extended_kinematic_body_path):
		extended_kinematic_body = get_node(extended_kinematic_body_path)
	
		if extended_kinematic_body == self or extended_kinematic_body is extended_kinematic_body_const == false:
			extended_kinematic_body = null
		else:
			# By default, kinematic body is not affected by its parent's movement
			extended_kinematic_body.set_as_toplevel(true)
		
	
	if is_inside_tree():
		var spatial_global_transform = get_global_transform()
		euler = Vector2(spatial_global_transform.basis.get_euler().x, spatial_global_transform.basis.get_euler().y)
		set_global_transform(Transform(Basis(), spatial_global_transform.origin))