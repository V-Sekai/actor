extends "actor_state.gd"


func enter() -> void:
	pass


func update(_delta: float) -> void:
	if ! state_machine.is_grounded():
		change_state("Falling")
		return

	var input_direction: Vector3 = state_machine.get_input_direction()

	state_machine.set_direction_vector(input_direction)
	state_machine.set_move_vector(
		(
			state_machine.get_direction_vector()
			* state_machine.actor_controller.walk_speed
			* state_machine.get_input_magnitude()
		)
	)
	
	if state_machine.is_attempting_jumping():
		change_state("Pre-Jump")
	
	state_machine.move(state_machine.get_move_vector())

	if ! state_machine.is_attempting_movement():
		change_state("Stop")
		return
	else:
		pass


func exit() -> void:
	pass
