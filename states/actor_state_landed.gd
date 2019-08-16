extends "actor_state.gd"

func enter():
	change_state("Idle")

func update(p_delta):
	if p_delta > 0.0:
		pass
	
func exit():
	pass
