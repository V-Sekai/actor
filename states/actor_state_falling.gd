extends "actor_state.gd"


func enter() -> void:
	pass


func update(p_delta: float) -> void:
	var gravity_delta: float = state_machine.get_actor_controller().get_gravity_speed() * p_delta
	var gravity_direction: Vector3 = state_machine.get_actor_controller().get_gravity_direction()

	state_machine.set_velocity(
		state_machine.get_velocity() + gravity_direction * gravity_delta
	)
	state_machine.move(state_machine.get_velocity())

	if state_machine.is_grounded():
		change_state("Landed")


func exit() -> void:
	pass
