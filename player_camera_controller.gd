extends Spatial
tool

const MAX_ANGLE : float = 360.0

const player_origin_const = preload("res://assets/scenes/player_origin.tscn")

var origin : Spatial = null
var camera : Camera = null

export(NodePath) var target_path : NodePath = NodePath()
onready var target : Spatial = null setget set_target
export(Vector3) var target_offset : Vector3 = Vector3()

export(NodePath) var kinematic_player_controller_path : NodePath = NodePath()
onready var kinematic_player_controller : Node = null setget set_kinematic_player_controller

export(bool) var is_active : bool = true

enum {CAMERA_FIRST_PERSON, CAMERA_THIRD_PERSON}

export(int, "First-Person", "Third-Person") var camera_type : int = CAMERA_FIRST_PERSON

# Distance
export(float) var distance : float = 2.5
export(float) var distance_min : float = 1.333333
export(float) var distance_max : float = 2.5
export(float) var distance_speed : float = 0.7
var distance_velocity : float = 0.0
var target_distance : float = distance

# Rotation
export(float) var interpolation_factor : float = 1.0

var interpolation_quat : Quat = Quat()

var rotation_yaw : float = 0.0
var rotation_pitch : float = 0.0

var rotation_pitch_min : float = -89.5
var rotation_pitch_max : float = 89.5

var exclusion_array : Array = []

var origin_offset : Vector3 = Vector3()

export(int, LAYERS_3D_PHYSICS) var collision_mask : int = 1

signal internal_rotation_updated(p_camera_type)

static func normalize_angle(p_angle : float) -> float:
	while (p_angle < 0):
		p_angle += MAX_ANGLE
	while (p_angle >= MAX_ANGLE):
		p_angle -= MAX_ANGLE
		
	return p_angle

func set_target(p_target : Spatial) -> void:
	if p_target != null and p_target is Spatial and p_target != self:
		target = p_target
	else:
		target = null
		
func set_kinematic_player_controller(p_kinematic_player_controller : Node) -> void:
	if p_kinematic_player_controller != null and p_kinematic_player_controller is Spatial and p_kinematic_player_controller != self:
		kinematic_player_controller = p_kinematic_player_controller
	else:
		kinematic_player_controller = null
	exclusion_array = [kinematic_player_controller]

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass

func _input(p_event : InputEvent) -> void:
	if(p_event is InputEventMouseButton):
		if (p_event.button_index == BUTTON_WHEEL_UP):
			target_distance -= 0.1

		if (p_event.button_index == BUTTON_WHEEL_DOWN):
			target_distance += 0.1

		if(target_distance > distance_max):
			target_distance = distance_max
		elif(target_distance < distance_min):
			target_distance = distance_min

func test_collision_point(p_ds : PhysicsDirectSpaceState, p_distance : float, p_start : Vector3, p_end : Vector3, p_offset : Vector3) -> float:
	var start_offset : Vector3 = p_start + p_offset
	
	var result : Dictionary = p_ds.intersect_ray(start_offset, p_end + p_offset, exclusion_array, collision_mask)
	if(result.empty() == false):
		var new_distance : float = start_offset.distance_to(result.position)
		if(new_distance < p_distance):
			return new_distance
			
	return p_distance

func calculate_final_transform(p_delta : float) -> void:
	set_rotation(interpolation_quat.get_euler())
	if camera_type == CAMERA_THIRD_PERSON:
		var ds : PhysicsDirectSpaceState = PhysicsServer.space_get_direct_state(get_world().get_space())
		var smooth_damp_return : Dictionary = GodotMathExtension.smooth_damp_scaler(distance, target_distance, distance_velocity, distance_speed, INF, p_delta)
		distance = smooth_damp_return.interpolation
		distance_velocity = smooth_damp_return.velocity

		var collision_distance : float = distance
		var start : Vector3 = get_parent().global_transform.origin
		if target:
			start = target.global_transform.origin + target_offset
		var xform : Vector3 = Transform(global_transform.basis, start).xform(Vector3(0.0, 0.0, collision_distance))
		if !typeof(xform) == TYPE_VECTOR3:
			printerr("calculate_final_transform: invalid type!")
		
		var end : Vector3 = xform

		var gt : Transform = global_transform
		gt.origin = end
		set_global_transform(gt)
		
		if(ds):
			"""var main_camera = CameraManager.get_main_camera()
			if main_camera:
				var upper_left = end - main_camera.project_position(Vector2(0.0, 0.0))
				var upper_right = end - main_camera.project_position(Vector2(OS.get_window_size().x, 0.0))
				var bottom_left = end - main_camera.project_position(Vector2(0.0, OS.get_window_size().y))
				var bottom_right = end - main_camera.project_position(Vector2(OS.get_window_size().x, OS.get_window_size().y))
				collision_distance = test_collision_point(ds, collision_distance, start, end, Vector3(0.0, 0.0, 0.0))
				collision_distance = test_collision_point(ds, collision_distance, start, end, upper_left)
				collision_distance = test_collision_point(ds, collision_distance, start, end, upper_right)
				collision_distance = test_collision_point(ds, collision_distance, start, end, bottom_left)
				collision_distance = test_collision_point(ds, collision_distance, start, end, bottom_right)"""

		xform = Transform(get_global_transform().basis, start).xform(Vector3(0.0, 0.0, collision_distance))
		end = xform

		gt = get_global_transform()
		gt.origin = end
		set_global_transform(gt)
	else:
		var gt : Transform = get_global_transform()
		gt.origin = get_parent().get_global_transform().origin
		if target:
			gt.origin = target.get_global_transform().origin
		#set_global_transform(gt)

func calculate_internal_rotation(p_delta : float) -> void:
	if is_active and p_delta > 0.0:
		
		rotation_pitch = clamp(rotation_pitch, rotation_pitch_min, rotation_pitch_max)
		
		# Calculate smooth rotation
		var final_quat : Quat = Quat()
		final_quat.set_euler(Vector3(deg2rad(-rotation_pitch), deg2rad(-rotation_yaw), 0.0))
		if interpolation_factor < 1.0:
			interpolation_quat = interpolation_quat.slerp(final_quat, interpolation_factor)
		else:
			interpolation_quat = final_quat
			
		emit_signal("internal_rotation_updated", camera_type)

func update(p_delta : float) -> void:
	calculate_internal_rotation(p_delta)
	calculate_final_transform(p_delta)

func update_origin(p_origin_offset):
	origin_offset = p_origin_offset
	origin.transform = global_transform * Transform(Basis(), -origin_offset)

func _ready() -> void:
	if Engine.is_editor_hint() == false:
		if has_node(target_path):
			set_target(get_node(target_path))
		if has_node(kinematic_player_controller_path):
			set_kinematic_player_controller(get_node(kinematic_player_controller_path))
	
		add_to_group("camera_controllers")
		
		origin = player_origin_const.instance()
		GroupsGameFlowManager.gameroot.add_child(origin)
		origin.set_as_toplevel(true)
		camera = origin.get_node_or_null("ARVRCamera")
		if camera:
			camera.set_current(true)
	else:
		set_process(false)
		set_physics_process(false)
