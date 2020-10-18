extends "actor_state.gd"


func enter() -> void:
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
