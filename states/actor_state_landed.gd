extends "actor_state.gd"


func enter() -> void:
	change_state("Idle")


func update(p_delta: float) -> void:
	if p_delta > 0.0:
		pass


func exit() -> void:
	pass
