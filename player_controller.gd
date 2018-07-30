extends "actor_controller.gd"

const head_bob_const = preload("head_bob.gd")

var input_direction : Vector2 = Vector2()
var input_magnitude : float = 0.0
var is_moving : bool = false
var head_bob : head_bob_const = null

# Camera
const player_camera_controller_const = preload("res://addons/actor/player_camera_controller.gd")

export(NodePath) var camera_target_node_path : NodePath = NodePath()
onready var camera_target_node : Spatial = get_node(camera_target_node_path)

export(NodePath) var camera_height_node_path : NodePath = NodePath()
onready var camera_height_node : Spatial = get_node(camera_height_node_path)

export(NodePath) var camera_controller_node_path : NodePath = NodePath()
onready var camera_controller_node : Spatial = get_node(camera_controller_node_path)

# Movement
var can_move : bool = true

export(float) var camera_height : float = 1.6
export(float) var run_step_lengthen : float = 0.7
export(float) var step_interval : float = 5.0

# Interaction
export(NodePath) var interactable_controller_path : NodePath = NodePath()
var interactable_controller : Node = null

# Input
sync var synced_input_direction : Array = [0x00, 0x00]
sync var synced_input_magnitude : int = 0x00

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
	
func get_relative_movement_velocity(p_input_direction : Vector2):
	return get_spatial_relative_movement_velocity(entity_node, p_input_direction)
	
func update_movement_input() -> void:
	if is_entity_master():
		var vertical_movement : float = clamp(InputManager.axes_values["move_vertical"], -1.0, 1.0)
		var horizontal_movement : float = clamp(InputManager.axes_values["move_horizontal"], -1.0, 1.0)
	
		var input_direction_vec3 : Vector3 = get_relative_movement_velocity(Vector2(vertical_movement, horizontal_movement))
		
		input_direction = Vector2(input_direction_vec3.x, input_direction_vec3.z)
		input_magnitude = clamp(input_direction.length_squared(), 0.0, 1.0)
		input_direction = input_direction.normalized()
	
func client_movement(p_delta : float) -> void:
	update_movement_input()
	
	state_machine.set_input_direction(Vector2())
	if(can_move):
		state_machine.set_input_direction(input_direction)
	
	synced_input_direction = [int(input_direction.x * 0xff), int(input_direction.y * 0xff)] # Encode new input velocity
	synced_input_magnitude = int(input_magnitude * 0xff)
	
func server_movement(p_delta : float) -> void:
	# Perform movement command on server
	input_magnitude = float(synced_input_magnitude) / 0xff
	state_machine.set_input_direction(Vector2(float(synced_input_direction[0]) / 0xff, float(synced_input_direction[1]) / 0xff).normalized())
	state_machine.set_input_magnitude(input_magnitude)
	if state_machine:
		state_machine.update(p_delta)
		
func client_update(p_delta : float) -> void:
	#set_global_transform(Transform(Basis(), slave_origin))
	
	#progress_step_cycle(velocity, input_magnitude * walk_speed, p_delta)
	if head_bob:
		head_bob.step(p_delta)
	#if bob_controller:
	#	bob_controller.set_translation(head_bob.offset)
	
func _physics_process(p_delta : float) -> void:
	if !Engine.is_editor_hint():
		if camera_controller_node:
			camera_controller_node.update(p_delta)
		
		input_direction = Vector2(0.0, 0.0)
		input_magnitude = 0.0
		
		if (is_entity_master()):
			if camera_height_node:
				camera_height_node.translation = Vector3(0.0, 1.0, 0.0) * camera_height
			client_movement(p_delta)
			
		if (NetworkManager.is_server()):
			server_movement(p_delta)
			
		if interactable_controller:
			interactable_controller.process(p_delta)
			
		client_update(p_delta)

func _ready() -> void:
	if !Engine.is_editor_hint():
		
		if has_node(camera_target_node_path):
			camera_target_node = get_node(camera_target_node_path)
		
			if camera_target_node == self or not camera_target_node is Spatial:
				camera_target_node = null
			else:
				# By default, kinematic body is not affected by its parent's movement
				camera_target_node.set_as_toplevel(true)
				camera_target_node.global_transform = Transform(Basis(), get_global_transform().origin)
		
		# Assign the interactable controller
		if has_node(interactable_controller_path):
			interactable_controller = get_node(interactable_controller_path)
			if interactable_controller == self:
				interactable_controller = null
			else:
				interactable_controller.player_controller = self
		
func _entity_ready() -> void:
	._entity_ready()
	
	if is_entity_master():
		pass
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		camera_controller_node.queue_free()
		camera_controller_node.get_parent().remove_child(camera_controller_node)
		camera_controller_node = null

func _on_transform_changed() -> void:
	._on_transform_changed()
	
	# Update the camera
	if camera_controller_node:
		if camera_controller_node.camera_type == player_camera_controller_const.CAMERA_FIRST_PERSON:
			var m : Basis = get_absoloute_basis(get_global_transform().basis)
			camera_controller_node.rotation_yaw = rad2deg(-m.get_euler().y)
	
func _on_camera_internal_rotation_updated(p_camera_type : int) -> void:
	if p_camera_type == player_camera_controller_const.CAMERA_FIRST_PERSON:
		var entity_basis : Basis = Basis().rotated(Vector3(0, 1, 0), deg2rad(-camera_controller_node.rotation_yaw))
		
		set_global_transform(Transform(entity_basis, get_global_origin()))