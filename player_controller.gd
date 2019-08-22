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

export(NodePath) var _vr_player_node_path : NodePath = NodePath()
onready var _vr_player_node : ARVROrigin = get_node(_vr_player_node_path)

export(int, LAYERS_3D_PHYSICS) var local_player_collision : int = 1
export(int, LAYERS_3D_PHYSICS) var other_player_collision : int = 1

# Movement
var can_move : bool = true

export(float) var camera_height : float = 1.8

# Input
var synced_input_direction : Array = [0x00, 0x00]
var synced_input_magnitude : int = 0x00

# VR
const vr_manager_const = preload("res://addons/vr_manager/vr_manager.gd")

# Automatically sets this entity name to correspond with its unique network ID
func update_network_player_name() -> void:
	if _entity_node:
		_entity_node.set_name("Player_" + str(get_network_master()))
	
func get_relative_movement_velocity(p_input_direction : Vector2) -> Vector3:
	return controller_helpers_const.get_spatial_relative_movement_velocity(_internal_rotation, p_input_direction)
	
func update_movement_input() -> void:
	if is_entity_master():
		# Depends on the presence of the VR Player node
		var vr_movement_input : Vector2 = Vector2()
		if _vr_player_node != null:
			vr_movement_input = _vr_player_node.get_controller_movement_vector()
		###
		
		var horizontal_movement : float = clamp(InputManager.axes_values["move_horizontal"] + vr_movement_input.x, -1.0, 1.0)
		var vertical_movement : float = clamp(InputManager.axes_values["move_vertical"] + vr_movement_input.y, -1.0, 1.0)
	
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
	
func update_vr_camera_state():
	if _camera_height_node:
		if VRManager.is_arvr_active():
			_camera_height_node.translation = Vector3(0.0, 0.0, 0.0)
			_camera_controller_node.lock_pitch = true
		else:
			_camera_height_node.translation = Vector3(0.0, 1.0, 0.0) * camera_height
			_camera_controller_node.lock_pitch = false
	
func _process(p_delta : float) -> void:
	if !Engine.is_editor_hint():
		if p_delta > 0.0:
			if is_entity_master():
				update_vr_camera_state()
				
func _physics_process(p_delta : float) -> void:
	if !Engine.is_editor_hint():
		if p_delta > 0.0:
			input_direction = Vector2(0.0, 0.0)
			input_magnitude = 0.0
			
			if _camera_controller_node:
				_camera_controller_node.update(p_delta)
			
			if is_entity_master():
				client_movement(p_delta)
				master_movement(p_delta) # Restructure this!

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
		
func _entity_ready() -> void:
	._entity_ready()
	
	if is_entity_master():
		if _extended_kinematic_body:
			_extended_kinematic_body.collision_layer = local_player_collision
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		if _extended_kinematic_body:
			_extended_kinematic_body.collision_layer = other_player_collision
		_camera_controller_node.queue_free()
		_camera_controller_node.get_parent().remove_child(_camera_controller_node)
		_camera_controller_node = null
		
	update_network_player_name()

func _on_transform_changed() -> void:
	._on_transform_changed()
	
	# Update the camera
	if _camera_controller_node:
		if _camera_controller_node.camera_type == player_camera_controller_const.CAMERA_FIRST_PERSON:
			var m : Basis = controller_helpers_const.get_absolute_basis(get_global_transform().basis)
			_camera_controller_node.rotation_yaw = rad2deg(-m.get_euler().y)
	
func _on_camera_internal_rotation_updated(p_camera_type : int) -> void:
	if p_camera_type == player_camera_controller_const.CAMERA_FIRST_PERSON:
		var camera_controller_yaw = Basis().rotated(Vector3(0, 1, 0), deg2rad(-_camera_controller_node.rotation_yaw))
		
		# Movement directions are relative to this
		match VRManager.movement_orientation:
			vr_manager_const.movement_orientation_enum.HEAD_ORIENTED_MOVEMENT:
				_internal_rotation.set_global_transform(Transform(_camera_controller_node.arvr_camera.global_transform.basis, get_global_origin()))
			vr_manager_const.movement_orientation_enum.PLAYSPACE_ORIENTED_MOVEMENT:
				_internal_rotation.set_global_transform(Transform(_camera_controller_node.transform.basis, get_global_origin()))
			vr_manager_const.movement_orientation_enum.HAND_ORIENTED_MOVEMENT:
				_internal_rotation.set_global_transform(Transform(_camera_controller_node.arvr_origin.get_controller_direction(), get_global_origin()))
			_:
				_internal_rotation.set_global_transform(Transform(_camera_controller_node.transform.basis, get_global_origin()))
		
		# Overall entity rotation
		set_global_transform(Transform(camera_controller_yaw, get_global_origin()))
