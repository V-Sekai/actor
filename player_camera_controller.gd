extends Spatial
tool

const player_origin_const = preload("player_origin.tscn")

var origin: Spatial = null
var camera: Camera = null

export (bool) var is_active: bool = true
export (int, LAYERS_3D_PHYSICS) var camera_clip_layers: int = 1

# Camera mode
enum { CAMERA_FIRST_PERSON, CAMERA_THIRD_PERSON }
var camera_mode: int = CAMERA_FIRST_PERSON

# Side
var distance: float = 4.0

# Side
var side_offset: float = 0.25

# Height
var camera_height: float = 0

# Rotation
var rotation_yaw: float = 0.0 # radians
var rotation_pitch: float = 0.0 # radians

# Used to provide representation interpolation for snapping
var rotation_yaw_snap_offset: float = 0.0 # radians

var rotation_pitch_min: float = deg2rad(-89.5)
var rotation_pitch_max: float = deg2rad(89.5)

var origin_offset: Vector3 = Vector3()

func test_collision_point(p_ds: PhysicsDirectSpaceState, p_distance: float, p_start: Vector3, p_end: Vector3) -> float:
	var result = p_ds.intersect_ray(p_start, p_end, [get_parent().global_transform.origin], camera_clip_layers, true, false)
	if(!result.empty()):
		var new_distance = p_start.distance_to(result.position)
		if(new_distance < p_distance):
			return new_distance
			
	return p_distance

func translate_third_person_camera(p_distance: float, p_corrected_pitch: float) -> void:
	translate(Vector3(1.0, 0.0, 0.0) * side_offset)
	translate(Vector3(0.0, 0.0, 1.0) * p_distance * cos(p_corrected_pitch))
	translate(Vector3(0.0, 1.0, 0.0) * p_distance * sin(p_corrected_pitch))

func get_camera_clip_distance(_camera) -> float:
	var ds: PhysicsDirectSpaceState = PhysicsServer.space_get_direct_state(get_world().get_space())
	
	var collision_distance = distance
	var start_transform: Transform = get_parent().get_global_transform()
	var end_transform = get_global_transform()
	
	#var upper_left = end_transform.origin - p_camera.project_position(Vector2(0.0, 0.0), 0.0)
	#var upper_right = end_transform.origin - p_camera.project_position(Vector2(OS.get_window_size().x, 0.0), 0.0)
	#var bottom_left = end_transform.origin - p_camera.project_position(Vector2(0.0, OS.get_window_size().y), 0.0)
	#var bottom_right = end_transform.origin - p_camera.project_position(Vector2(OS.get_window_size().x, OS.get_window_size().y), 0.0)
	
	collision_distance = test_collision_point(ds, collision_distance, start_transform.origin, end_transform.origin)
	
	return collision_distance

func update() -> void:
	if InputManager.is_ingame_action_just_pressed("toggle_camera_mode"):
		camera_mode = CAMERA_THIRD_PERSON if camera_mode == CAMERA_FIRST_PERSON else CAMERA_FIRST_PERSON
	
	var corrected_pitch: float = 0.0
	if is_active and ! VRManager.is_xr_active():
		corrected_pitch = clamp(rotation_pitch, rotation_pitch_min, rotation_pitch_max)

	var pitch_basis:Basis = Basis.rotated(Vector3(-1.0, 0.0, 0.0), corrected_pitch)
	var yaw_basis:Basis = Basis.rotated(Vector3(0.0, 1.0, 0.0), rotation_yaw + rotation_yaw_snap_offset - PI)

	transform.origin = Vector3()
	transform.basis = yaw_basis

	if camera and ! VRManager.is_xr_active():
		camera.transform = Transform(pitch_basis, Vector3(0.0, 1.0, 0.0) * camera_height)
		
	# Third-person camera
	if camera_mode == CAMERA_THIRD_PERSON:
		translate_third_person_camera(distance, corrected_pitch)
	
		var new_distance: float = get_camera_clip_distance(camera)
		transform.origin = Vector3()
		
		translate_third_person_camera(new_distance, corrected_pitch)
	else:
		transform.origin = Vector3()
		
	rotation_pitch = corrected_pitch


func update_origin(p_origin_offset: Vector3) -> void:
	origin_offset = p_origin_offset
	if origin:
		origin.transform = Transform(Basis(), -origin_offset)


func setup_origin() -> void:
	if get_tree().has_network_peer() and is_network_master():
		if ! origin:
			origin = player_origin_const.instance()
			add_child(origin)
			update_origin(origin_offset)

			camera = origin.get_node_or_null("ARVRCamera")
			if camera:
				camera.set_current(true)

func _enter_tree() -> void:
	if !Engine.is_editor_hint():
		add_to_group("camera_controllers")
		setup_origin()

func _exit_tree() -> void:
	if !Engine.is_editor_hint():
		camera = null

		if origin:
			origin.queue_free()
			origin.get_parent().remove_child(origin)

		if is_in_group("camera_controllers"):
			remove_from_group("camera_controllers")
