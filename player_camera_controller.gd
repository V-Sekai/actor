extends Spatial

const MAX_ANGLE = 360

export(NodePath) var target_path = NodePath()
onready var target = null setget set_target
export(Vector3) var target_offset = Vector3()

export(NodePath) var player_controller_path = NodePath()
onready var player_controller = null setget set_player_controller

export(bool) var is_active = true
export(bool) var lock_pitch = false

enum {CAMERA_FIRST_PERSON, CAMERA_THIRD_PERSON}

var listener = null
export(int, "First-Person", "Third-Person") var camera_type = CAMERA_FIRST_PERSON

# Distance
export(float) var distance = 2.5
export(float) var distance_min = 1.333333
export(float) var distance_max = 2.5
export(float) var distance_speed = 0.7
var distance_velocity = 0.0
var target_distance = distance

# Rotation
export(float) var interpolation_factor = 0.1
export(float) var rotation_speed = 10
export(float) var rotation_smoothing_factor = 0.08

var interpolation_quat = Quat()

var rotation_yaw = 0.0
var rotation_pitch = 0.0

var rotation_pitch_min = -89.5
var rotation_pitch_max = 89.5

var exclusion_array = []

export(int, FLAGS) var layer_mask = 1

signal internal_rotation_updated(p_camera_type)

static func normalize_angle(p_angle):
	while (p_angle < 0):
		p_angle += MAX_ANGLE
	while (p_angle >= MAX_ANGLE):
		p_angle -= MAX_ANGLE
		
	return p_angle

func set_target(p_target):
	if p_target != null and p_target is Spatial and p_target != self:
		target = p_target
	else:
		target = null
		
func set_player_controller(p_player_controller):
	if p_player_controller != null and p_player_controller is Spatial and p_player_controller != self:
		player_controller = p_player_controller
	else:
		player_controller = null
	exclusion_array = [player_controller]

func _enter_tree():
	listener = Listener.new()
	add_child(listener)
	add_to_group("Listeners")

func _exit_tree():
	if(listener.is_inside_tree()):
		listener.queue_free()

func _input(p_event):
	if(p_event is InputEventMouseButton):
		if (p_event.button_index == BUTTON_WHEEL_UP):
			target_distance -= 0.1

		if (p_event.button_index == BUTTON_WHEEL_DOWN):
			target_distance += 0.1

		if(target_distance > distance_max):
			target_distance = distance_max
		elif(target_distance < distance_min):
			target_distance = distance_min

func test_collision_point(p_ds, p_distance, p_start, p_end, p_offset):
	var start_offset = p_start + p_offset
	
	var result = p_ds.intersect_ray(start_offset, p_end + p_offset, exclusion_array, layer_mask, PhysicsDirectSpaceState.TYPE_MASK_COLLISION)
	if(result.empty() == false):
		var new_distance = start_offset.distance_to(result.position)
		if(new_distance < p_distance):
			return new_distance
			
	return p_distance

func calculate_final_transform(p_delta):
	var ds = PhysicsServer.space_get_direct_state(get_world().get_space())
	if(ds):
		set_rotation(interpolation_quat.get_euler())
		#set_rotation_degrees(Vector3((-rotation_pitch_smooth), (-rotation_yaw_smooth), 0.0))
			
		if camera_type == CAMERA_THIRD_PERSON:
			var smooth_damp_return = GodotMathExtension.smooth_damp_scaler(distance, target_distance, distance_velocity, distance_speed, INF, p_delta)
			distance = smooth_damp_return.interpolation
			distance_velocity = smooth_damp_return.velocity

			var collision_distance = distance
			var start = get_parent().get_global_transform()
			if target:
				start = target.get_global_transform().origin + target_offset
			var end = Transform(get_global_transform().basis, start).xform(Vector3(0.0, 0.0, collision_distance))

			var gt = get_global_transform()
			gt.origin = end
			set_global_transform(gt)
			
			"""
			var main_camera = CameraManager.get_main_camera()
			if main_camera:
				var upper_left = end - main_camera.project_position(Vector2(0.0, 0.0))
				var upper_right = end - main_camera.project_position(Vector2(OS.get_window_size().x, 0.0))
				var bottom_left = end - main_camera.project_position(Vector2(0.0, OS.get_window_size().y))
				var bottom_right = end - main_camera.project_position(Vector2(OS.get_window_size().x, OS.get_window_size().y))
				collision_distance = test_collision_point(ds, collision_distance, start, end, Vector3(0.0, 0.0, 0.0))
				collision_distance = test_collision_point(ds, collision_distance, start, end, upper_left)
				collision_distance = test_collision_point(ds, collision_distance, start, end, upper_right)
				collision_distance = test_collision_point(ds, collision_distance, start, end, bottom_left)
				collision_distance = test_collision_point(ds, collision_distance, start, end, bottom_right)
			"""

			end = Transform(get_global_transform().basis, start).xform(Vector3(0.0, 0.0, collision_distance))

			gt = get_global_transform()
			gt.origin = end
			set_global_transform(gt)
		else:
			var gt = get_global_transform()
			gt.origin = get_parent().get_global_transform().origin
			if target:
				gt.origin = target.get_global_transform().origin
			set_global_transform(gt)

func calculate_internal_rotation(p_delta):
	if is_active:
		var x_direction = 1.0
		var y_direction = 1.0
	
		if(ProjectSettings.get("gameplay/invert_look_x") == true):
			x_direction = -1.0
		else:
			x_direction = 1.0
		if(ProjectSettings.get("gameplay/invert_look_y") == true):
			y_direction = -1.0
		else:
			y_direction = 1.0
	
		var input_x = (clamp((InputManager.axes_values["mouse_x"] + InputManager.axes_values["look_horizontal"]), -1.0, 1.0) * rotation_speed) * x_direction
		var input_y = (clamp((InputManager.axes_values["mouse_y"] + InputManager.axes_values["look_vertical"]), -1.0, 1.0) * rotation_speed) * y_direction
	
		rotation_yaw += input_x
		
		if lock_pitch == false:
			rotation_pitch -= input_y
			rotation_pitch = clamp(rotation_pitch, rotation_pitch_min, rotation_pitch_max)
		else:
			rotation_pitch = 0.0
		
		# Calculate smooth rotation
		var final_quat = Quat()
		final_quat.set_euler(Vector3(deg2rad(-rotation_pitch), deg2rad(-rotation_yaw), 0.0))
		if interpolation_factor < 1.0:
			interpolation_quat = interpolation_quat.slerp(final_quat, interpolation_factor)
		else:
			interpolation_quat = final_quat
			
		emit_signal("internal_rotation_updated", camera_type)

func update(p_delta):
	calculate_internal_rotation(p_delta)
	calculate_final_transform(p_delta)

func _ready():
	if has_node(target_path):
		set_target(get_node(target_path))
	if has_node(player_controller_path):
		set_player_controller(get_node(player_controller_path))

	add_to_group("camera_controllers")

	if(!ProjectSettings.has_setting("gameplay/invert_look_x")):
		ProjectSettings.set_setting("gameplay/invert_look_x", false)

	if(!ProjectSettings.has_setting("gameplay/invert_look_y")):
		ProjectSettings.set_setting("gameplay/invert_look_y", false)
