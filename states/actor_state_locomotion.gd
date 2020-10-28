extends "actor_state.gd"

func locomotion() -> void:
	if ! state_machine.is_attempting_movement():
		change_state("Stop")
		return
	else:
		pass
	
	if ! state_machine.is_grounded():
		change_state("Falling")
		return

	var input_direction: Vector3 = state_machine.get_input_direction()

	state_machine.set_direction_vector(input_direction)
	state_machine.set_velocity(
		(
			state_machine.get_direction_vector()
			* state_machine.actor_controller.walk_speed
			* state_machine.get_input_magnitude()
		)
	)
	
	if state_machine.is_attempting_jumping():
		change_state("Pre-Jump")
	
	state_machine.set_movement_vector(state_machine.get_velocity())


func enter() -> void:
	locomotion()


func update(_delta: float) -> void:
	locomotion()


func exit() -> void:
	pass
