extends "actor_controller.gd"

const actor_spawned_state_const = preload("states/actor_state_spawned.gd")
const head_bob_const = preload("head_bob.gd")

var input_direction = Vector2()
var input_magnitude = 0.0
var is_moving = false
var head_bob = null

# Camera
export(NodePath) var camera_controller_path = NodePath()
onready var camera_controller = get_node(camera_controller_path)

# Movement
var can_move = true

export(float) var eye_height = 1.6
export(float) var run_step_lengthen = 0.7
export(float) var step_interval = 5.0

# Interaction
export(NodePath) var interactable_controller_path = NodePath()
var interactable_controller = null

# VR
var vr_forwards_backwards = 0.0
var vr_left_right = 0.0

##############
# Networking #
##############

func network_set_unreliable(p_property, p_value):
	if (get_tree().has_network_peer()):
		rset_unreliable(p_property, p_value)
	else:
		set(p_property, p_value)

# Input
sync var synced_input_direction = [0x00, 0x00]
sync var synced_input_magnitude = 0x00
# Movement
slave var slave_origin = Vector3()
slave var slave_euler = Vector2()

###

static func get_camera_relative_velocity(p_camera, p_input_direction):
	var new_direction = Vector3()
	if(p_camera):
		# Get the camera rotation
		var m = p_camera.global_transform.basis.orthonormalized()
		var det = m.determinant()
		if (det < 0):
			m = m.scaled(Vector3(-1, -1, -1));
		
		var camera_yaw = m.get_euler().y # Radians
		var camera_normal = convert_euler_to_normal(Vector3(0.0, camera_yaw, 0.0))
		
		new_direction += Vector3(-camera_normal.x, 0.0, -camera_normal.z) * p_input_direction.x
		new_direction += Vector3(camera_normal.z, 0.0, -camera_normal.x) * p_input_direction.y
		
	return new_direction
		
func turn(p_rot):
	camera_controller.rotation_yaw += p_rot
	camera_controller.rotation_yaw_smooth = camera_controller.rotation_yaw
	camera_controller.rotation_yaw_velocity = 0.0
	
func update_movement_input():
	var vertical_movement = clamp(InputManager.axes_values["move_vertical"] + vr_forwards_backwards, -1.0, 1.0)
	var horizontal_movement = clamp(InputManager.axes_values["move_horizontal"] + vr_left_right, -1.0, 1.0)
	
	var vertical_movement_test = float(Input.get_action_strength("move_forwards")) - float(Input.get_action_strength("move_backwards"))
	var horizontal_movement_test = float(Input.get_action_strength("move_right")) - float(Input.get_action_strength("move_left"))
	
	#vertical_movement = vertical_movement_test
	#horizontal_movement = horizontal_movement_test
	
	get_node("../Label").set_text("vertical_movement: " + str(vertical_movement) + " / " + "horizontal_movement: " + str(horizontal_movement))

	if VRManager.is_vr_mode_enabled():
		input_direction = get_camera_relative_velocity(VRManager.arvr_origin.get_node("ARVRCamera"), Vector2(vertical_movement, horizontal_movement))
		input_magnitude = clamp(input_direction.length_squared(), 0.0, 1.0)
		input_direction = input_direction.normalized()
	else:
		input_direction = get_camera_relative_velocity(camera_controller, Vector2(vertical_movement, horizontal_movement))
		input_magnitude = clamp(input_direction.length_squared(), 0.0, 1.0)
		input_direction = input_direction.normalized()
	
func client_movement(p_delta):
	update_movement_input()
	
	state_machine.set_input_direction(Vector3())
	if(can_move):
		state_machine.set_input_direction(input_direction)
	
	if (get_tree().has_network_peer()):
		if(!get_tree().is_network_server()):
			# Process the state machine on the client first to avoid any user input lag.
			if state_machine:
				state_machine.update_current_state(p_delta)
				move(state_machine.move_direction)
			
			# Save client spatial information
			slave_euler = euler
			slave_origin = get_global_origin()
		
	synced_input_direction = [int(input_direction.x * 0xff), int(input_direction.z * 0xff)] # Encode new input velocity
	network_set_unreliable("synced_input_direction", synced_input_direction)
	synced_input_magnitude = int(input_magnitude * 0xff)
	network_set_unreliable("synced_input_magnitude", synced_input_magnitude)
	
func server_movement(p_delta):
	# Perform movement command on server
	input_magnitude = float(synced_input_magnitude) / 0xff
	state_machine.set_input_direction(Vector3(float(synced_input_direction[0]) / 0xff, 0.0, float(synced_input_direction[1]) / 0xff).normalized())
	state_machine.set_input_magnitude(input_magnitude)
	if state_machine:
		state_machine.update_current_state(p_delta)
		move(move_vector)
		
	# Send updated information to the clients
	slave_euler = euler
	slave_origin = get_global_origin()
	network_set_unreliable("slave_euler", slave_euler)
	network_set_unreliable("slave_origin", get_global_origin())
	
	# Send input information to the clients
	network_set_unreliable("synced_input_direction", synced_input_direction)
	network_set_unreliable("synced_input_magnitude", synced_input_magnitude)

func client_update(p_delta):
	euler = slave_euler
	
	#adjust_render_rotation(direction, get_node("Render"))
	#set_global_transform(Transform(Basis(), slave_origin))
	
	#progress_step_cycle(velocity, input_magnitude * walk_speed, p_delta)
	if head_bob:
		head_bob.step(p_delta)
	#if bob_controller:
	#	bob_controller.set_translation(head_bob.offset)
	
func _process(delta):
	if VRManager.arvr_active == true:
		if VRManager.arvr_origin:
			VRManager.arvr_origin.global_transform = get_global_origin()
			VRManager.arvr_origin.set_rotation(Vector3(0.0, camera_controller.get_rotation().y, 0.0))
		

func _physics_process(p_delta):
	if !Engine.is_editor_hint():
		input_direction = Vector2(0.0, 0.0)
		input_magnitude = 0.0
		
		if (get_tree().has_network_peer()):
			if (is_network_master()):
				client_movement(p_delta)
		else:
			client_movement(p_delta)
			
		if (get_tree().has_network_peer()):
			if (get_tree().is_network_server()):
				server_movement(p_delta)
		else:
			server_movement(p_delta)
			
		if interactable_controller:
			interactable_controller.process(p_delta)
			
		client_update(p_delta)
		
func get_actor_eye_transform():
	if camera_controller != null:
		return camera_controller.global_transform
	else:
		return get_global_origin() + Transform(Basis(), extended_kinematic_body.up * eye_height)

func _ready():
	if !Engine.is_editor_hint():
		state_machine.set_current_state(actor_spawned_state_const)
		
		# Assign the state machine
		
		# Assign the interactable controller
		if has_node(interactable_controller_path):
			interactable_controller = get_node(interactable_controller_path)
			if interactable_controller == self:
				interactable_controller = null
			else:
				interactable_controller.player_controller = self
		
		#if is_inside_tree() and global_game_manager_singleton:
		#	if (get_tree().has_network_peer()):
		#		if (is_network_master()):
		#			global_game_manager_singleton.register_active_player_controller(self)
		#	else:
		#		global_game_manager_singleton.register_active_player_controller(self)
			
		#	if VRManager.is_vr_mode() == false:
		#		if !global_game_manager_singleton.is_gameplay_camera_active():
		#			bob_controller.add_child(global_game_manager_singleton.get_gameplay_camera())
		
		#head_bob = head_bob_const.new(self)
		#get_tree().set_network_peer(NetworkedMultiplayerPeer.new())
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
func _exit_tree():
	pass
	#if !Engine.is_editor_hint():
	#	if global_game_manager_singleton:
	#		if (get_tree().has_network_peer()):
	#			if (is_network_master()):
	#				global_game_manager_singleton.unregister_active_player_controller()
	#		else:
	#			global_game_manager_singleton.unregister_active_player_controller()