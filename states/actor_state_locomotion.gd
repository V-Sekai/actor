extends "actor_state.gd"

const movement_controller_const = preload("../movement_controller.gd")
const actor_state_falling_const = preload("actor_state_falling.gd")
const actor_state_stop_const = preload("actor_state_stop.gd")

static func enter(p_actor_state_machine):
	pass

static func update(p_actor_state_machine, p_delta):
	if p_actor_state_machine.is_grounded() == false:
		p_actor_state_machine.set_current_state(actor_state_falling_const)
		return
	
	p_actor_state_machine.set_direction_normal((Vector3(p_actor_state_machine.input_direction.x, 0.0, p_actor_state_machine.input_direction.z)))
	p_actor_state_machine.set_move_vector(p_actor_state_machine.get_direction_normal() * p_actor_state_machine.actor_controller.walk_speed * p_actor_state_machine.input_magnitude)
		
	if p_actor_state_machine.is_attempting_movement() == false:
		p_actor_state_machine.set_current_state(actor_state_stop_const)
		return
	else:
		pass
	
static func exit(p_actor_state_machine):
	pass