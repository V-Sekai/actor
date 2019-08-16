extends "actor_state.gd"

func enter():
	pass

func update(p_delta):
	if p_delta > 0.0:
		var gravity = state_machine.get_actor_controller().get_gravity()
		
		state_machine.set_move_vector(state_machine.get_move_vector() + Vector3(0.0, gravity * p_delta, 0.0))
		state_machine.move(state_machine.get_move_vector())
		
		if state_machine.is_grounded():
			change_state("Landed")

func exit():
	pass
