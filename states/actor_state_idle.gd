extends "actor_state.gd"

func enter():
	if state_machine.is_attempting_movement():
		change_state("Locomotion")
		return
	else:
		pass

func update(p_delta):
	if state_machine.is_attempting_movement():
		change_state("Locomotion")
		return
	else:
		pass
	
func exit():
	pass