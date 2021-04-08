extends "actor_state.gd"


func enter() -> void:
	pass


func update(_delta: float) -> void:
	state_machine.set_movement_vector(Vector3())

	if state_machine.is_noclipping():
		change_state("Noclip")
	else:
		if state_machine.is_grounded():
			change_state("Idle")
		else:
			change_state("Falling")


func exit() -> void:
	pass
