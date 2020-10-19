extends Spatial
tool

const player_origin_const = preload("player_origin.tscn")

var origin: Spatial = null
var camera: Camera = null

export (bool) var is_active: bool = true

# Camera mode
enum { CAMERA_FIRST_PERSON, CAMERA_THIRD_PERSON }
var camera_mode: int = CAMERA_FIRST_PERSON

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

func update(p_delta: float) -> void:
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
		translate(Vector3(1.0, 0.0, 0.0) * side_offset)
		translate(Vector3(0.0, 0.0, 1.0) * cos(corrected_pitch))
		translate(Vector3(0.0, 1.0, 0.0) * sin(corrected_pitch))
	else:
		transform.origin = Vector3()
		
	rotation_pitch = corrected_pitch


func update_origin(p_origin_offset: Vector3) -> void:
	origin_offset = p_origin_offset
	if origin:
		origin.transform = Transform(Basis(), -origin_offset)


func setup_origin() -> void:
	if is_network_master():
		if ! origin:
			origin = player_origin_const.instance()
			add_child(origin)
			update_origin(origin_offset)

			camera = origin.get_node_or_null("ARVRCamera")
			if camera:
				camera.set_current(true)

func _input(p_event: InputEvent) -> void:
	if p_event.is_action_pressed("toggle_camera_mode"):
		camera_mode = CAMERA_THIRD_PERSON if camera_mode == CAMERA_FIRST_PERSON else CAMERA_FIRST_PERSON

func _enter_tree() -> void:
	add_to_group("camera_controllers")
	setup_origin()

func _exit_tree() -> void:
	camera = null

	if origin:
		origin.queue_free()
		origin.get_parent().remove_child(origin)

	if is_in_group("camera_controllers"):
		remove_from_group("camera_controllers")
