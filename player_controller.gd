extends "actor_controller.gd"

# Consts
const player_camera_controller_const = preload("player_camera_controller.gd")
const vr_manager_const = preload("res://addons/vr_manager/vr_manager.gd")

export (NodePath) var _target_node_path: NodePath = NodePath()
onready var _target_node: Spatial = get_node_or_null(_target_node_path)

export (NodePath) var _target_smooth_node_path: NodePath = NodePath()
onready var _target_smooth_node: Spatial = get_node_or_null(_target_smooth_node_path)

export (NodePath) var _camera_controller_node_path: NodePath = NodePath()
onready var _camera_controller_node: Spatial = get_node_or_null(_camera_controller_node_path)

export (NodePath) var _player_input_path: NodePath = NodePath()
onready var _player_input: Node = get_node_or_null(_player_input_path)

export (NodePath) var _player_pickup_controller_path: NodePath = NodePath()
var _player_pickup_controller: Node = null

export (int, LAYERS_3D_PHYSICS) var local_player_collision: int = 1
export (int, LAYERS_3D_PHYSICS) var other_player_collision: int = 1

onready var physics_fps: int = ProjectSettings.get("physics/common/physics_fps")

var _ik_space: Spatial = null
var _avatar_display: Spatial = null

# The offset between the camera position and ARVROrigin center (none transformed)
var frame_offset: Vector3 = Vector3()
var origin_offset: Vector3 = Vector3()

# Movement / Interpolation
var desired_direction: Basis = Vector3()
var current_origin: Vector3 = Vector3()
var movement_lock_count: int = 0

# Teleport
var teleport_flag: bool = false
var teleport_transform: Transform = Transform()


func lock_movement() -> void:
	movement_lock_count += 1

	
func unlock_movement() -> void:
	movement_lock_count -= 1
	if movement_lock_count < 0:
		printerr("Player lock underflow!")


func movement_is_locked() -> bool:
	return movement_lock_count > 0


func master_movement(p_delta: float) -> void:
	if is_entity_master():
		_player_input.update_movement_input(desired_direction)

	if _state_machine:
		_state_machine.set_input_magnitude(_player_input.input_magnitude)
		
		if !movement_is_locked():
			_state_machine.set_input_direction(_player_input.input_direction)
		else:
			_state_machine.set_input_direction(Vector3())
		
		_state_machine.update(p_delta)


func move(p_target_velocity: Vector3) -> Vector3:
	var transformed_frame_offset: Vector3 = Vector3()
	if _player_input:
		# Get any potential offset (head-position, VR for this frame)
		frame_offset = _player_input.get_head_accumulator()
		transformed_frame_offset = _player_input.transform_origin_offset(frame_offset)
		_player_input.clear_head_accumulator()

		# Compensate for the offset
		origin_offset += frame_offset

	var move_ret: Vector3 = .move(p_target_velocity + (transformed_frame_offset * physics_fps))
	#set_global_transform(Transform(entity_node.global_transform.basis, _extended_kinematic_body.global_transform.origin))
	return move_ret


func preprocess_master_or_puppet_state() -> void:
	if is_entity_master():
		if _extended_kinematic_body:
			_extended_kinematic_body.collision_layer = local_player_collision
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		if _extended_kinematic_body:
			_extended_kinematic_body.queue_free()
		_camera_controller_node.queue_free()
		_camera_controller_node.get_parent().remove_child(_camera_controller_node)
		_camera_controller_node = null

	#update_network_player_name()


func _on_target_smooth_transform_complete(p_delta) -> void:
	if _ik_space:
		_ik_space.transform_update(p_delta)


func cache_nodes() -> void:
	.cache_nodes()

	# Node caching
	_player_pickup_controller = get_node_or_null(_player_pickup_controller_path)
	_player_pickup_controller.player_controller = self

	_ik_space = _render_node.get_node_or_null("IKSpace")

	_avatar_display = _render_node.get_node_or_null("AvatarDisplay")
	_avatar_display.simulation_logic = self


func _on_transform_changed() -> void:
	._on_transform_changed()

	# Update the camera
	if _camera_controller_node:
		_camera_controller_node.rotation_yaw = get_transform().basis.get_euler().y


func _on_camera_internal_rotation_updated(p_camera_type: int) -> void:
	if (
		_camera_controller_node
		and p_camera_type == player_camera_controller_const.CAMERA_FIRST_PERSON
	):
		var camera_controller_yaw_basis = Basis().rotated(
			Vector3(0, 1, 0), _camera_controller_node.rotation_yaw
		)

		var basis: Basis

		if _camera_controller_node.camera:
			# Movement directions are relative to this. (TODO: refactor)
			match VRManager.vr_user_preferences.movement_orientation:
				VRManager.vr_user_preferences.movement_orientation_enum.HEAD_ORIENTED_MOVEMENT:
					basis = _camera_controller_node.camera.global_transform.basis
				VRManager.vr_user_preferences.movement_orientation_enum.PLAYSPACE_ORIENTED_MOVEMENT:
					basis = _camera_controller_node.global_transform.basis
				VRManager.vr_user_preferences.movement_orientation_enum.HAND_ORIENTED_MOVEMENT:
					basis = _player_input.vr_locomotion_component.get_controller_direction()
				_:
					basis = _camera_controller_node.transform.basis
		
		desired_direction = Basis(\
			Vector3(cos(basis.get_euler().y), 0.0, -sin(basis.get_euler().y)),\
			Vector3(),\
			Vector3(-sin(basis.get_euler().y), 0.0, -cos(basis.get_euler().y))\
			)
		
		# Overall entity rotation
		set_transform(Transform(camera_controller_yaw_basis, get_origin()))


func _on_touched_by_body(p_body) -> void:
	if p_body.has_method("touched_by_body_with_network_id"):
		p_body.touched_by_body_with_network_id(get_network_master())


func entity_child_pre_remove(p_entity_child: Node) -> void:
	if _player_pickup_controller:
		_player_pickup_controller.clear_hand_entity_references_for_entity(p_entity_child)


func get_attachment_node(p_attachment_id: int) -> Node:
	match p_attachment_id:
		_player_pickup_controller.LEFT_HAND_ID:
			return _avatar_display.left_hand_bone_attachment
		_player_pickup_controller.RIGHT_HAND_ID:
			return _avatar_display.right_hand_bone_attachment
		_:
			return _render_node


func _can_teleport() -> bool:
	return true

func _schedule_teleport(p_transform: Transform) -> void:
	teleport_transform = p_transform
	teleport_flag = true


func teleport_to(p_transform: Transform) -> void:
	.teleport_to(p_transform)


func get_player_pickup_controller() -> Node:
	return _player_pickup_controller


func _threaded_instance_post_setup() -> void:
	_avatar_display.load_model()


func _entity_physics_process(p_delta: float) -> void:
	._entity_physics_process(p_delta)
	
	if is_entity_master():
		if teleport_flag:
			teleport_to(teleport_transform)

		_player_input.update_head_accumulation()
		_player_input.update_input(p_delta)

	_player_input.input_direction = Vector3(0.0, 0.0, 0.0)
	_player_input.input_magnitude = 0.0

	if is_entity_master():
		master_movement(p_delta)

	# There is a slight delay in the movement, but this allows framerate independent movement
	if entity_node.get_entity_parent():
		current_origin = entity_node.global_transform.origin
	else:
		current_origin = entity_node.global_transform.origin

	if _target_node:
		_target_node.transform.origin = current_origin

	#if ! is_entity_master():
	#	_extended_kinematic_body.global_transform.origin = get_global_origin()

	if teleport_flag:
		_target_smooth_node.teleport()
		teleport_flag = false
		
	if _ik_space:
		_ik_space.update_physics(p_delta)

func _entity_process(p_delta: float) -> void:
	._entity_process(p_delta)
	
	if is_entity_master():
		_player_input.update_input(p_delta)
		_player_input.update_origin(
			origin_offset + Vector3(0.0, -_avatar_display.height_offset, 0.0)
		)

		if _render_node:
			var camera_offset: Vector3 = _player_input.transform_origin_offset(
				_player_input.get_head_accumulator()
			)
			_render_node.transform.basis = get_transform().basis
	else:
		_render_node.transform.basis = get_transform().basis

	if _avatar_display:
		_avatar_display.update(p_delta)

	entity_node.network_logic_node.set_dirty(true)

func _entity_ready() -> void:
	._entity_ready()
	
	# Callback for when the first packet is received. If this entity is not
	# owned by the player, wait for the first packet to be received
	if ! is_entity_master():
		_render_node.hide()
		if get_entity_node().network_logic_node:
			_ik_space.connect("external_trackers_changed", _render_node, "show", [], CONNECT_ONESHOT)
		
	# State machine
	if ! is_entity_master():
		_state_machine.start_state = NodePath("Networked")
	else:
		_player_input.setup_xr_camera()
		
		# Teleport callback
		var teleport:Spatial = VRManager.xr_origin.get_component_by_name("TeleportComponent")
		if teleport:
			teleport.assign_can_teleport_funcref(self, "_can_teleport")
			teleport.assign_teleport_callback_funcref(self, "_schedule_teleport")
			
		_state_machine.start_state = NodePath("Spawned")
	_state_machine.start()
	
	_avatar_display._entity_ready()
	_ik_space._entity_ready()

	preprocess_master_or_puppet_state()
	_target_node = get_node_or_null(_target_node_path)
	if _target_node:
		if _target_node == self or not _target_node is Spatial:
			_target_node = null
		else:
			# By default, kinematic body is not affected by its parent's movement
			_target_node.set_as_toplevel(true)
			_target_smooth_node.set_as_toplevel(true)

			current_origin = get_global_transform().origin
			_target_node.global_transform = Transform(Basis(), current_origin)
			#_target_smooth_node.global_transform = _target_node.global_transform
		_target_smooth_node.teleport()
		
	# Set the camera controller's initial rotation to be that of entity's rotation
	_on_transform_changed()
