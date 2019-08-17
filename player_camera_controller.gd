extends Spatial
tool

const MAX_ANGLE = 360.0

var arvr_origin : ARVROrigin = null
var arvr_camera : ARVRCamera = null

export(NodePath) var target_path : NodePath = NodePath()
onready var target : Spatial = null setget set_target
export(Vector3) var target_offset : Vector3 = Vector3()

export(NodePath) var kinematic_player_controller_path : NodePath = NodePath()
onready var kinematic_player_controller : Node = null setget set_kinematic_player_controller

export(bool) var is_active : bool = true
export(bool) var lock_pitch : bool = false

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
export(float) var interpolation_factor : float = 0.1
export(float) var rotation_speed : float = 10

var interpolation_quat : Quat = Quat()

var rotation_yaw : float = 0.0
var rotation_pitch : float = 0.0

var rotation_pitch_min : float = -89.5
var rotation_pitch_max : float = 89.5

var exclusion_array : Array = []

var collision_mask : int = 1

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
	var start_offset = p_start + p_offset
	
	var result = p_ds.intersect_ray(start_offset, p_end + p_offset, exclusion_array, collision_mask)
	if(result.empty() == false):
		var new_distance : float = start_offset.distance_to(result.position)
		if(new_distance < p_distance):
			return new_distance
			
	return p_distance

func calculate_final_transform(p_delta : float) -> void:
	var ds : PhysicsDirectSpaceState = PhysicsServer.space_get_direct_state(get_world().get_space())
	if(ds):
		set_rotation(interpolation_quat.get_euler())
		#set_rotation_degrees(Vector3((-rotation_pitch_smooth), (-rotation_yaw_smooth), 0.0))
			
		if camera_type == CAMERA_THIRD_PERSON:
			var smooth_damp_return : Dictionary = GodotMathExtension.smooth_damp_scaler(distance, target_distance, distance_velocity, distance_speed, INF, p_delta)
			distance = smooth_damp_return.interpolation
			distance_velocity = smooth_damp_return.velocity

			var collision_distance : float = distance
			var start : Vector3 = get_parent().global_transform.origin
			if target:
				start = target.global_transform.origin + target_offset
			var xform = Transform(global_transform.basis, start).xform(Vector3(0.0, 0.0, collision_distance))
			if !typeof(xform) == TYPE_VECTOR3:
				printerr("calculate_final_transform: invalid type!")
			
			var end : Vector3 = xform

			var gt : Transform = global_transform
			gt.origin = end
			set_global_transform(gt)
			
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
			set_global_transform(gt)

func calculate_internal_rotation(p_delta : float) -> void:
	if is_active and p_delta > 0.0:
		var x_direction : float = 1.0
		var y_direction : float = 1.0
	
		if(ProjectSettings.get("gameplay/invert_look_x") == true):
			x_direction = -1.0
		else:
			x_direction = 1.0
		if(ProjectSettings.get("gameplay/invert_look_y") == true):
			y_direction = -1.0
		else:
			y_direction = 1.0
			
		# TODO: clean up and unify this with regular player controller
		var vr_turning_vector : Vector2 = Vector2()
		if arvr_origin:
			vr_turning_vector = arvr_origin.get_controller_turning_vector()

		var input_x : float = (clamp((InputManager.axes_values["mouse_x"] + InputManager.axes_values["look_horizontal"] + vr_turning_vector.x), -1.0, 1.0) * rotation_speed) * x_direction
		var input_y : float = (clamp((InputManager.axes_values["mouse_y"] + InputManager.axes_values["look_vertical"] + vr_turning_vector.y), -1.0, 1.0) * rotation_speed) * y_direction
	
		rotation_yaw += input_x
		
		if lock_pitch == false:
			rotation_pitch -= input_y
			rotation_pitch = clamp(rotation_pitch, rotation_pitch_min, rotation_pitch_max)
		else:
			rotation_pitch = 0.0
		
		# Calculate smooth rotation
		var final_quat : Quat = Quat()
		final_quat.set_euler(Vector3(deg2rad(-rotation_pitch), deg2rad(-rotation_yaw), 0.0))
		if interpolation_factor < 1.0:
			interpolation_quat = interpolation_quat.slerp(final_quat, interpolation_factor)
		else:
			interpolation_quat = final_quat
			
		emit_signal("internal_rotation_updated", camera_type)
		
func _get_property_list() -> Array:
	var property_list = []
	
	property_list.push_back({"name":"collision_mask", "type":TYPE_INT, "hint":PROPERTY_HINT_LAYERS_3D_PHYSICS})
		
	return property_list
	
func _set(p_property : String, p_value : int) -> bool:
	var split_property = p_property.split("/", -1)
	if split_property.size() > 0:
		if split_property.size() == 1:
			if split_property[0] == "collision_mask":
				collision_mask = p_value
				return true
				
	return false
		
func _get(p_property : String):
	var split_property = p_property.split("/", -1)
	if split_property.size() > 0:
		if split_property.size() == 1:
			if split_property[0] == "collision_mask":
				return collision_mask

func update(p_delta : float) -> void:
	calculate_internal_rotation(p_delta)
	calculate_final_transform(p_delta)

func _process(p_delta):
	if p_delta > 0.0:
		arvr_origin.transform = global_transform

func _ready() -> void:
	if Engine.is_editor_hint() == false:
		if has_node(target_path):
			set_target(get_node(target_path))
		if has_node(kinematic_player_controller_path):
			set_kinematic_player_controller(get_node(kinematic_player_controller_path))
	
		add_to_group("camera_controllers")
	
		if(!ProjectSettings.has_setting("gameplay/invert_look_x")):
			ProjectSettings.set_setting("gameplay/invert_look_x", false)
	
		if(!ProjectSettings.has_setting("gameplay/invert_look_y")):
			ProjectSettings.set_setting("gameplay/invert_look_y", false)
		
		# TODO: Clean this up
		arvr_origin = $ARVROrigin
		arvr_camera = $ARVROrigin/ARVRCamera
		arvr_origin.set_as_toplevel(true)
	else:
		set_process(false)
		set_physics_process(false)
