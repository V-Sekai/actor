extends "actor_state.gd"

const actor_state_idle_const = preload("actor_state_idle.gd")

static func enter(p_actor_state_machine):
	p_actor_state_machine.set_current_state(actor_state_idle_const)

static func update(p_actor_state_machine, p_delta):
	pass
	
static func exit(p_actor_state_machine):
	pass