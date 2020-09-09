extends Spatial
tool

const player_origin_const = preload("player_origin.tscn")

var origin: Spatial = null
var camera: Camera = null

export (bool) var is_active: bool = true

enum { CAMERA_FIRST_PERSON, CAMERA_THIRD_PERSON }

# Height
var camera_height: float = 0

# Rotation
var rotation_yaw: float = 0.0 # radians
var rotation_pitch: float = 0.0 # radians

var rotation_pitch_min: float = deg2rad(-89.5)
var rotation_pitch_max: float = deg2rad(89.5)

var origin_offset: Vector3 = Vector3()

signal internal_rotation_updated(p_camera_type)

func update(p_delta: float) -> void:
	if is_active and p_delta > 0.0:
		rotation_pitch = clamp(rotation_pitch, rotation_pitch_min, rotation_pitch_max)

	transform.basis = Basis.rotated(Vector3(0.0, 1.0, 0.0), rotation_yaw - PI)

	if camera and ! VRManager.is_xr_active():
		camera.transform.origin = Vector3(0.0, 1.0, 0.0) * camera_height
		camera.transform.basis = Basis.rotated(Vector3(-1.0, 0.0, 0.0), rotation_pitch)
		
	emit_signal("internal_rotation_updated", CAMERA_FIRST_PERSON)


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
