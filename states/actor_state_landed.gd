extends "res://addons/actor/states/actor_state.gd" # actor_state.gd


func enter() -> void:
	if state_machine.is_noclipping():
		change_state("Noclip")
	else:
		state_machine.set_velocity(
			(
				state_machine.get_velocity() * Vector3(1.0, 0.0, 1.0)
			)
		)
		state_machine.set_movement_vector(state_machine.get_velocity())
		
		if state_machine.is_attempting_movement():
			change_state("Locomotion")
			return
		elif state_machine.is_attempting_jumping():
			change_state("Pre-Jump")
			return
		else:
			change_state("Idle")


func update(_delta: float) -> void:
	pass


func exit() -> void:
	pass
