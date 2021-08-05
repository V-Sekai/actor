extends "res://addons/actor/states/actor_state.gd" # actor_state.gd


func enter() -> void:
	if state_machine.is_noclipping():
		change_state("Noclip")
	else:
		if ! state_machine.is_attempting_movement():
			change_state("Idle")
		else:
			change_state("Locomotion")


func update(_delta: float) -> void:
	pass


func exit() -> void:
	pass
