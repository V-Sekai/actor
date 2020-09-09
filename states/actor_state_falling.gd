extends "actor_state.gd"


func enter() -> void:
	pass


func update(_delta: float) -> void:
	var gravity = state_machine.get_actor_controller().get_gravity()

	state_machine.set_move_vector(
		state_machine.get_move_vector() + Vector3(0.0, gravity * _delta, 0.0)
	)
	state_machine.move(state_machine.get_move_vector())

	if state_machine.is_grounded():
		change_state("Landed")


func exit() -> void:
	pass
