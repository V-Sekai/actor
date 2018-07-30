extends "actor_state.gd"

func enter():
	pass

func update(p_delta):
	if state_machine.is_grounded() == false:
		change_state("Falling")
		return
		
	var input_direction = state_machine.get_input_direction()
	
	state_machine.set_direction_vector((Vector3(input_direction.x, 0.0, input_direction.y)))
	state_machine.set_move_vector(state_machine.get_direction_vector() * state_machine.actor_controller.walk_speed * state_machine.get_input_magnitude())
	
	state_machine.move(state_machine.get_move_vector())
	
	if state_machine.is_attempting_movement() == false:
		change_state("Stop")
		return
	else:
		pass
	
func exit():
	pass