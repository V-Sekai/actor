extends "actor_state.gd"

func enter() -> void:
	if state_machine.is_attempting_movement() == false:
		change_state("Idle")
	else:
		change_state("Locomotion")

func update(p_delta : float) -> void:
	if p_delta > 0.0:
		pass
	
func exit() -> void:
	pass
