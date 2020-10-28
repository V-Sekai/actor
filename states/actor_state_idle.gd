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
	if state_machine.is_attempting_movement():
		change_state("Locomotion")
		return
	elif state_machine.is_attempting_jumping():
		change_state("Pre-Jump")
		return
		
	state_machine.set_movement_vector(state_machine.get_velocity())


func exit() -> void:
	pass
