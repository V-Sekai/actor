extends "actor_state.gd"

const DEFAULT_JUMP_VELOCITY = 7.5

func enter() -> void:
	var jump_velocity : float = DEFAULT_JUMP_VELOCITY
	var jump_direction: Vector3 = Vector3.UP * jump_velocity
	
	state_machine.set_move_vector(
		(
			state_machine.get_move_vector() + jump_direction
		)
	)
	
	state_machine.set_grounded(false)
	change_state("Falling")


func update(_delta: float) -> void:
	pass


func exit() -> void:
	pass
