extends "actor_state.gd"

func enter():
	pass

func update(p_delta):
	if state_machine.is_grounded():
		change_state("Idle")
	else:
		change_state("Falling")
	
func exit():
	pass