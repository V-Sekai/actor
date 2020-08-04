extends "actor_state.gd"


func enter() -> void:
	pass


func update(p_delta: float) -> void:
	if p_delta > 0.0:
		state_machine.move(Vector3())

		if state_machine.is_grounded():
			change_state("Idle")
		else:
			change_state("Falling")


func exit() -> void:
	pass
