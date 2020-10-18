extends "actor_state.gd"


func enter() -> void:
	state_machine.set_velocity(
		(
			Vector3()
		)
	)
	
	if state_machine.is_attempting_movement():
		change_state("Locomotion")
		return
	elif state_machine.is_attempting_jumping():
		change_state("Pre-Jump")
		return


func update(_delta: float) -> void:
	state_machine.move(state_machine.get_velocity())

	if state_machine.is_attempting_movement():
		change_state("Locomotion")
		return
	elif state_machine.is_attempting_jumping():
		change_state("Pre-Jump")
		return


func exit() -> void:
	pass
