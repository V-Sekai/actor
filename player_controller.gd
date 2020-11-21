extends "actor_controller.gd"
tool

# Consts
const vr_manager_const = preload("res://addons/vr_manager/vr_manager.gd")

export (NodePath) var _target_node_path: NodePath = NodePath()
onready var _target_node: Spatial = get_node_or_null(_target_node_path)

export (NodePath) var _target_smooth_node_path: NodePath = NodePath()
onready var _target_smooth_node: Spatial = get_node_or_null(_target_smooth_node_path)

export (NodePath) var _camera_controller_node_path: NodePath = NodePath()
onready var _camera_controller_node: Spatial = get_node_or_null(_camera_controller_node_path)

export (NodePath) var _player_input_path: NodePath = NodePath()
onready var _player_input: Node = get_node_or_null(_player_input_path)

export (NodePath) var _player_interaction_controller_path: NodePath = NodePath()
var _player_interaction_controller: Node = null

export (NodePath) var _player_pickup_controller_path: NodePath = NodePath()
var _player_pickup_controller: Node = null

export (NodePath) var _player_teleport_controller_path: NodePath = NodePath()
var _player_teleport_controller: Node = null

export (NodePath) var _player_nametag_path: NodePath = NodePath()
var _player_nametag: Node = null

export (int, LAYERS_3D_PHYSICS) var local_player_collision: int = 1
export (int, LAYERS_3D_PHYSICS) var other_player_collision: int = 1

onready var physics_fps: int = ProjectSettings.get("physics/common/physics_fps")

var _ik_space: Spatial = null
var _avatar_display: Spatial = null

# The offset between the camera position and ARVROrigin center (none transformed)
var frame_offset: Vector3 = Vector3()
var origin_offset: Vector3 = Vector3()

# Movement / Interpolation
var current_origin: Vector3 = Vector3()
var movement_lock_count: int = 0


func _player_display_name_updated(p_network_id: int, p_name: String) -> void:
	if p_network_id == get_network_master():
		if _player_nametag:
			_player_nametag.set_nametag(p_name)
			if p_name != "":
				_player_nametag.show()
			else:
				_player_nametag.hide()


func _player_avatar_path_updated(p_network_id: int, p_path: String) -> void:
	if get_network_master() == p_network_id:
		_avatar_display.set_avatar_model_path(p_path)
		_avatar_display.load_model()


func lock_movement() -> void:
	movement_lock_count += 1


func unlock_movement() -> void:
	movement_lock_count -= 1
	if movement_lock_count < 0:
		printerr("Player lock underflow!")


func movement_is_locked() -> bool:
	return movement_lock_count > 0


func _master_movement(p_delta: float) -> void:
	_player_input.update_movement_input(_get_desired_direction())
	
	if _state_machine:
		_state_machine.set_input_magnitude(_player_input.input_magnitude)
		
		if !movement_is_locked():
			_state_machine.set_input_direction(_player_input.input_direction)
		else:
			_state_machine.set_input_direction(Vector3())
		
		_state_machine.update(p_delta)


func update_origin() -> void:
	# There is a slight delay in the movement, but this allows framerate independent movement
	if entity_node.get_entity_parent():
		current_origin = entity_node.global_transform.origin
	else:
		current_origin = entity_node.transform.origin


func set_movement_vector(p_target_velocity: Vector3) -> void:
	.set_movement_vector(p_target_velocity)
	var transformed_frame_offset: Vector3 = Vector3()
	if _player_input:
		# Get any potential offset (head-position, VR for this frame)
		frame_offset = _player_input.get_head_accumulator()
		transformed_frame_offset = _player_input.transform_origin_offset(frame_offset)
		_player_input.clear_head_accumulator()

		# Compensate for the offset
		origin_offset += frame_offset

	movement_vector += (transformed_frame_offset * physics_fps)
	

func move(p_movement_vector: Vector3) -> void:
	.move(p_movement_vector)


func _on_target_smooth_transform_complete(p_delta) -> void:
	if _ik_space:
		_ik_space.transform_update(p_delta)


func cache_nodes() -> void:
	.cache_nodes()

	# Node caching
	_player_pickup_controller = get_node_or_null(_player_pickup_controller_path)
	_player_pickup_controller.player_controller = self
	
	_player_teleport_controller = get_node_or_null(_player_teleport_controller_path)
	
	_player_interaction_controller = get_node_or_null(_player_interaction_controller_path)

	_ik_space = _render_node.get_node_or_null("IKSpace")

	_avatar_display = _render_node.get_node_or_null("AvatarDisplay")
	_avatar_display.simulation_logic = self
	
	_player_nametag = get_node_or_null(_player_nametag_path)


func _on_transform_changed() -> void:
	._on_transform_changed()


func _get_desired_direction() -> Basis:
	var camera_controller_yaw_basis = Basis().rotated(
		Vector3(0, 1, 0), _camera_controller_node.rotation_yaw
	)
	
	var basis: Basis = camera_controller_yaw_basis
	
	if _camera_controller_node.camera:
		# Movement directions are relative to this. (TODO: refactor)
		match VRManager.vr_user_preferences.movement_orientation:
			VRManager.vr_user_preferences.movement_orientation_enum.HEAD_ORIENTED_MOVEMENT:
				basis = camera_controller_yaw_basis * _camera_controller_node.camera.transform.basis
			VRManager.vr_user_preferences.movement_orientation_enum.PLAYSPACE_ORIENTED_MOVEMENT:
				basis = camera_controller_yaw_basis
			VRManager.vr_user_preferences.movement_orientation_enum.HAND_ORIENTED_MOVEMENT:
				basis = camera_controller_yaw_basis * _player_input.vr_locomotion_component.get_controller_direction()
				
	return Basis(\
		Vector3(-cos(basis.get_euler().y), 0.0, sin(basis.get_euler().y)),\
		Vector3(),\
		Vector3(sin(basis.get_euler().y), 0.0, cos(basis.get_euler().y))\
		)


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


func get_player_pickup_controller() -> Node:
	return _player_pickup_controller


func _threaded_instance_post_setup() -> void:
	._threaded_instance_post_setup()

func _setup_target() -> void:
	_target_node = get_node_or_null(_target_node_path)
	if _target_node:
		if _target_node == self or not _target_node is Spatial:
			_target_node = null
		else:
			# By default, kinematic body is not affected by its parent's movement
			_target_node.set_as_toplevel(true)
			_target_smooth_node.set_as_toplevel(true)
			_target_smooth_node.process_priority = EntityManager.process_priority + 1

			current_origin = get_global_transform().origin
			_target_node.global_transform = Transform(Basis(), current_origin)
			#_target_smooth_node.global_transform = _target_node.global_transform
		_target_smooth_node.teleport()


func _update_master_transform() -> void:
	var camera_controller_yaw_basis = Basis().rotated(
		Vector3(0, 1, 0), _camera_controller_node.rotation_yaw
	)
	
	set_transform(Transform(camera_controller_yaw_basis, get_origin()))

func _master_kinematic_integration_update(p_delta: float) -> void:
	move(movement_vector)

func _master_physics_update(p_delta: float) -> void:
	_player_input.update_physics_input(p_delta)

	_player_input.input_direction = Vector3(0.0, 0.0, 0.0)
	_player_input.input_magnitude = 0.0
		
	if _player_teleport_controller:
		_player_teleport_controller.check_respawn_bounds()
		_player_teleport_controller.check_teleport()
		
	_player_interaction_controller.update(get_entity_node(), p_delta)
	
	_master_movement(p_delta)
	_update_master_transform()


func _entity_physics_process(p_delta: float) -> void:
	._entity_physics_process(p_delta)
	
	if _ik_space:
		_ik_space.update_physics(p_delta)
	
	if is_entity_master():
		_master_physics_update(p_delta)
	
	update_origin()

	# There is a slight delay in the movement, but this allows framerate independent movement
	if entity_node.get_entity_parent():
		current_origin = entity_node.global_transform.origin
	else:
		current_origin = entity_node.transform.origin

	if _target_node:
		_target_node.transform.origin = current_origin
		

func _entity_kinematic_integration_callback(p_delta: float) -> void:
	_master_kinematic_integration_update(p_delta)
	

func _entity_physics_post_process(p_delta: float) -> void:
	._entity_physics_post_process(p_delta)


func _master_representation_process(p_delta: float) -> void:
	_player_input.update_representation_input(p_delta)
	_player_input.update_origin(
		origin_offset + Vector3(0.0, -_avatar_display.height_offset, 0.0)
	)

	if _render_node:
		var camera_offset: Vector3 = _player_input.transform_origin_offset(
			_player_input.get_head_accumulator()
		)
		_render_node.transform.basis = get_transform().basis

func _puppet_representation_process(p_delta) -> void:
	_render_node.transform.basis = get_transform().basis

func _master_ready() -> void:
	get_entity_node().register_kinematic_integration_callback()
	
	### Avatar ###
	_player_avatar_path_updated(get_network_master(), VSKPlayerManager.avatar_path)
	###
	
	_player_input.setup_xr_camera()
	
	_player_teleport_controller.setup(self)
	
	if _extended_kinematic_body:
		_extended_kinematic_body.collision_layer = local_player_collision
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _free_master_nodes() -> void:
	if _extended_kinematic_body:
		_extended_kinematic_body.queue_free()
		_extended_kinematic_body.get_parent().remove_child(_extended_kinematic_body)
		_extended_kinematic_body = null
		
	if _camera_controller_node:
		_camera_controller_node.queue_free()
		_camera_controller_node.get_parent().remove_child(_camera_controller_node)
		_camera_controller_node = null
	
func _puppet_ready() -> void:
	# Callback for when the first packet is received. If this entity is not
	# owned by the player, wait for the first packet to be received
	_render_node.hide()
	
	if get_entity_node().network_logic_node:
		_ik_space.connect("external_trackers_changed", _render_node, "show", [], CONNECT_ONESHOT)
	
	_state_machine.start_state = NodePath("Networked")
	
	### Avatar ###
	if VSKNetworkManager.connect("player_avatar_path_updated", self, "_player_avatar_path_updated") != OK:
		printerr("Could not connect player_avatar_path_updated")
	if VSKNetworkManager.player_avatar_paths.has(get_network_master()):
		_player_avatar_path_updated(get_network_master(), VSKNetworkManager.player_avatar_paths[get_network_master()])
	###
	
	if VSKNetworkManager.connect("player_display_name_updated", self, "_player_display_name_updated") != OK:
		printerr("Could not connect player_display_name_updated")
	
	if VSKNetworkManager.player_display_names.has(get_network_master()):
		_player_display_name_updated(get_network_master(), VSKNetworkManager.player_display_names[get_network_master()])
	
	_free_master_nodes()

func _entity_representation_process(p_delta: float) -> void:
	._entity_representation_process(p_delta)
	
	if is_entity_master():
		_master_representation_process(p_delta)
	else:
		_puppet_representation_process(p_delta)

	entity_node.network_logic_node.set_dirty(true)

func _entity_ready() -> void:
	._entity_ready()
	
	# State machine
	if ! is_entity_master():
		_puppet_ready()
	else:
		_master_ready()
		
	_state_machine.start()
	
	_ik_space._entity_ready()
	_avatar_display._entity_ready()

	_setup_target()
		
	# Set the camera controller's initial rotation to be that of entity's rotation
	if _camera_controller_node:
		_camera_controller_node.rotation_yaw = get_transform().basis.get_euler().y
