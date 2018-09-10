extends "actor_controller.gd"

var input_direction : Vector2 = Vector2()
var input_magnitude : float = 0.0

# Camera
const player_camera_controller_const = preload("res://addons/actor/player_camera_controller.gd")

export(NodePath) var _camera_target_node_path : NodePath = NodePath()
onready var _camera_target_node : Spatial = get_node(_camera_target_node_path)

export(NodePath) var _camera_height_node_path : NodePath = NodePath()
onready var _camera_height_node : Spatial = get_node(_camera_height_node_path)

export(NodePath) var _camera_controller_node_path : NodePath = NodePath()
onready var _camera_controller_node : Spatial = get_node(_camera_controller_node_path)

# Movement
var can_move : bool = true

export(float) var camera_height : float = 1.6

# Interaction
export(NodePath) var _interactable_controller_path : NodePath = NodePath()
var _interactable_controller : Node = null

# Input
var synced_input_direction : Array = [0x00, 0x00]
var synced_input_magnitude : int = 0x00

static func get_absoloute_basis(p_basis : Basis) -> Basis:
	var m : Basis = p_basis.orthonormalized()
	var det : float = m.determinant()
	if (det < 0):
		m = m.scaled(Vector3(-1, -1, -1))
		
	return m

static func get_spatial_relative_movement_velocity(p_spatial : Spatial, p_input_direction : Vector2) -> Vector3:
	var new_direction : Vector3 = Vector3()
	
	if(p_spatial):
		# Get the camera rotation
		var m : Basis = get_absoloute_basis(p_spatial.global_transform.basis)
		
		var camera_yaw : float = m.get_euler().y # Radians	
		var spatial_normal : Vector3 = convert_euler_to_normal(Vector3(0.0, camera_yaw, 0.0))
		
		new_direction += Vector3(-spatial_normal.x, 0.0, -spatial_normal.z) * p_input_direction.x
		new_direction += Vector3(spatial_normal.z, 0.0, -spatial_normal.x) * p_input_direction.y
		
	return new_direction

# Automatically sets this entity name to correspond with its unique network ID
func update_network_player_name():
	if _entity_node:
		_entity_node.set_name("Player_" + str(get_network_master()))
	
func get_relative_movement_velocity(p_input_direction : Vector2):
	return get_spatial_relative_movement_velocity(_entity_node, p_input_direction)
	
func update_movement_input() -> void:
	if is_entity_master():
		var vertical_movement : float = clamp(InputManager.axes_values["move_vertical"], -1.0, 1.0)
		var horizontal_movement : float = clamp(InputManager.axes_values["move_horizontal"], -1.0, 1.0)
	
		var input_direction_vec3 : Vector3 = get_relative_movement_velocity(Vector2(vertical_movement, horizontal_movement))
		
		input_direction = Vector2(input_direction_vec3.x, input_direction_vec3.z)
		input_magnitude = clamp(input_direction.length_squared(), 0.0, 1.0)
		input_direction = input_direction.normalized()
	
func client_movement(p_delta : float) -> void:
	if p_delta > 0.0:
		update_movement_input()
		
		_state_machine.set_input_direction(Vector2())
		if(can_move):
			_state_machine.set_input_direction(input_direction)
		
		synced_input_direction = [int(input_direction.x * 0xff), int(input_direction.y * 0xff)] # Encode new input velocity
		synced_input_magnitude = int(input_magnitude * 0xff)
	
func master_movement(p_delta : float) -> void:
	# Perform movement command on server
	input_magnitude = float(synced_input_magnitude) / 0xff
	_state_machine.set_input_direction(Vector2(float(synced_input_direction[0]) / 0xff, float(synced_input_direction[1]) / 0xff).normalized())
	_state_machine.set_input_magnitude(input_magnitude)
	if _state_machine:
		_state_machine.update(p_delta)
		
func client_update(p_delta : float) -> void:
	if(p_delta > 0.0):
		pass
	
func _physics_process(p_delta : float) -> void:
	if !Engine.is_editor_hint():
		if _camera_controller_node:
			_camera_controller_node.update(p_delta)
		
		input_direction = Vector2(0.0, 0.0)
		input_magnitude = 0.0
		
		if (is_entity_master()):
			if _camera_height_node:
				_camera_height_node.translation = Vector3(0.0, 1.0, 0.0) * camera_height
			client_movement(p_delta)
			master_movement(p_delta) # Restructure this!
			
		if _interactable_controller:
			_interactable_controller.process(p_delta)
			
		client_update(p_delta)

func _ready() -> void:
	if !Engine.is_editor_hint():
		
		if has_node(_camera_target_node_path):
			_camera_target_node = get_node(_camera_target_node_path)
		
			if _camera_target_node == self or not _camera_target_node is Spatial:
				_camera_target_node = null
			else:
				# By default, kinematic body is not affected by its parent's movement
				_camera_target_node.set_as_toplevel(true)
				_camera_target_node.global_transform = Transform(Basis(), get_global_transform().origin)
		
		# Assign the interactable controller
		_interactable_controller = cache_node(_interactable_controller_path)
		if _interactable_controller:
			_interactable_controller.player_controller = self
		
func _entity_ready() -> void:
	._entity_ready()
	
	if is_entity_master():
		pass
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		_camera_controller_node.queue_free()
		_camera_controller_node.get_parent().remove_child(_camera_controller_node)
		_camera_controller_node = null
		
	update_network_player_name()

func _on_transform_changed() -> void:
	._on_transform_changed()
	
	# Update the camera
	if _camera_controller_node:
		if _camera_controller_node.camera_type == player_camera_controller_const.CAMERA_FIRST_PERSON:
			var m : Basis = get_absoloute_basis(get_global_transform().basis)
			_camera_controller_node.rotation_yaw = rad2deg(-m.get_euler().y)
	
func _on_camera_internal_rotation_updated(p_camera_type : int) -> void:
	if p_camera_type == player_camera_controller_const.CAMERA_FIRST_PERSON:
		var entity_basis : Basis = Basis().rotated(Vector3(0, 1, 0), deg2rad(-_camera_controller_node.rotation_yaw))
		
		set_global_transform(Transform(entity_basis, get_global_origin()))