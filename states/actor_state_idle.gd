extends "actor_state.gd"

const actor_state_locomotion_const = preload("actor_state_locomotion.gd")

static func enter(p_actor_state_machine):
	pass

static func update(p_actor_state_machine, p_delta):
	if p_actor_state_machine.is_attempting_movement():
		p_actor_state_machine.set_current_state(actor_state_locomotion_const)
		return
	else:
		pass
	
static func exit(p_actor_state_machine):
	pass