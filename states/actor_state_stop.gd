extends "actor_state.gd"

func enter():
	if state_machine.is_attempting_movement() == false:
		change_state("Idle")
	else:
		change_state("Locomotion")

func update(p_delta):
	pass
	
func exit():
	pass