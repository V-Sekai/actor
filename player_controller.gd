extends "actor_controller.gd"

# Consts
const player_camera_controller_const = preload("res://addons/actor/player_camera_controller.gd")
const vr_manager_const = preload("res://addons/vr_manager/vr_manager.gd")

export(NodePath) var _camera_target_node_path : NodePath = NodePath()
onready var _camera_target_node : Spatial = get_node(_camera_target_node_path)

export(NodePath) var _camera_controller_node_path : NodePath = NodePath()
onready var _camera_controller_node : Spatial = get_node(_camera_controller_node_path)

export(NodePath) var _player_input_path : NodePath = NodePath()
onready var _player_input : Node = get_node(_player_input_path)

export(int, LAYERS_3D_PHYSICS) var local_player_collision : int = 1
export(int, LAYERS_3D_PHYSICS) var other_player_collision : int = 1

onready var physics_fps : int = ProjectSettings.get("physics/common/physics_fps")

# Movement / Interpolation
var previous_origin : Vector3 = Vector3()
var current_origin : Vector3 = Vector3()

var can_move : bool = true
	
func client_movement(p_delta : float) -> void:
	if p_delta > 0.0:
		if is_entity_master():
			_player_input.update_movement_input(_internal_rotation)
		
		_state_machine.set_input_direction(Vector2())
		if(can_move):
			_state_machine.set_input_direction(_player_input.input_direction)
		
		_player_input.synced_input_direction = [int(_player_input.input_direction.x * 0xff), int(_player_input.input_direction.y * 0xff)] # Encode new input velocity
		_player_input.synced_input_magnitude = int(_player_input.input_magnitude * 0xff)
	
func master_movement(p_delta : float) -> void:
	# Perform movement command on server
	_player_input.input_magnitude = float(_player_input.synced_input_magnitude) / 0xff
	_state_machine.set_input_direction(Vector2(float(_player_input.synced_input_direction[0]) / 0xff, float(_player_input.synced_input_direction[1]) / 0xff).normalized())
	_state_machine.set_input_magnitude(_player_input.input_magnitude)
	if _state_machine:
		_state_machine.update(p_delta)
		
func move(p_target_velocity : Vector3) -> Vector3:
	var offset_movement : Vector3 = Vector3()
	if _player_input:
		# Get any potential offset (head-position, VR for this frame)
		var offset : Vector3 = _player_input.get_transformed_offset()
		# Compensate for the offset
		current_origin += offset
		# Scale to the timestep
		offset_movement = offset * physics_fps
		
	return .move(p_target_velocity + offset_movement)
		
# Automatically sets this entity name to correspond with its unique network ID
func update_network_player_name() -> void:
	var entity_node : Node = get_entity_node()
	if entity_node:
		entity_node.set_name("Player_" + str(get_network_master()))
		
func preprocess_master_or_puppet_state() -> void:
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
		
func _process(p_delta : float) -> void:
	if !Engine.is_editor_hint():
		if p_delta > 0.0:
			if is_entity_master():
				_player_input.update(p_delta)
				
			# Do interpolated movement
			if _camera_target_node:
				_camera_target_node.transform.origin = previous_origin.linear_interpolate(
				current_origin, Engine.get_physics_interpolation_fraction()
				)
				
			if _render_node:
				_render_node.transform.origin = previous_origin.linear_interpolate(
				current_origin, Engine.get_physics_interpolation_fraction()
				)
				_render_node.transform.basis = get_global_transform().basis
				
func _physics_process(p_delta : float) -> void:
	if !Engine.is_editor_hint():
		if p_delta > 0.0:
			if is_entity_master():
				_player_input.update(p_delta)
			
			_player_input.input_direction = Vector2(0.0, 0.0)
			_player_input.input_magnitude = 0.0
			
			if is_entity_master():
				client_movement(p_delta)
				master_movement(p_delta) # Restructure this!
				
			# There is a slight delay in the movement, but this allows framerate independent movement
			previous_origin = current_origin
			current_origin = get_entity_node().global_transform.origin
			
			if _camera_target_node:
				_camera_target_node.transform.origin = previous_origin
				
			if !is_entity_master():
				_extended_kinematic_body.global_transform.origin = get_global_origin()

func _ready() -> void:
	if !Engine.is_editor_hint():
		preprocess_master_or_puppet_state()
		if has_node(_camera_target_node_path):
			_camera_target_node = get_node(_camera_target_node_path)
			
			if _camera_target_node == self or not _camera_target_node is Spatial:
				_camera_target_node = null
			else:
				# By default, kinematic body is not affected by its parent's movement
				_camera_target_node.set_as_toplevel(true)
				
				previous_origin = get_global_transform().origin
				current_origin = get_global_transform().origin
				_camera_target_node.global_transform = Transform(Basis(), current_origin)
		
func _entity_ready() -> void:
	._entity_ready()
	
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
		
		# Movement directions are relative to this. (TODO: refactor)
		match VRManager.movement_orientation:
			vr_manager_const.movement_orientation_enum.HEAD_ORIENTED_MOVEMENT:
				_internal_rotation.set_global_transform(Transform(_camera_controller_node.camera.global_transform.basis, get_global_origin()))
			vr_manager_const.movement_orientation_enum.PLAYSPACE_ORIENTED_MOVEMENT:
				_internal_rotation.set_global_transform(Transform(_camera_controller_node.transform.basis, get_global_origin()))
			vr_manager_const.movement_orientation_enum.HAND_ORIENTED_MOVEMENT:
				_internal_rotation.set_global_transform(Transform(_camera_controller_node.origin.get_controller_direction(), get_global_origin()))
			_:
				_internal_rotation.set_global_transform(Transform(_camera_controller_node.transform.basis, get_global_origin()))
		
		# Overall entity rotation
		set_global_transform(Transform(camera_controller_yaw, get_global_origin()))
