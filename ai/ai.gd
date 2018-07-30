extends Node

const ai_mind_const = preload("ai_mind.gd")
var mind = ai_mind_const.new(self)

var current_think_time = 0
var next_think_time = 0

var actor_location = null
var actor = null setget set_actor, get_actor # Overworld representation.

var script = null

static func direction_to_target(p_origin, p_target, p_up = Vector3(0.0, 1.0, 0.0)):
	return -Transform(Basis(), p_origin).looking_at(Vector3(p_target.x, p_origin.y, p_target.z), p_up).basis[2].normalized()
#
func is_in_current_location():
	for location in get_tree().get_nodes_in_group("current_location"):
		if actor_location == location:
			return true
	return false

func set_actor(p_actor):
	actor = p_actor

func get_actor():
	return actor

func is_actor_active():
	return get_actor() != null

func animation_move():
	pass
	
func _think(p_delta):
	current_think_time += p_delta
	
	if current_think_time < next_think_time:
		next_think_time += 0.2 ## ??
		return
	
	mind.think()
		
	if(actor):
		actor.think(p_delta)
	
func _process(p_delta):
	_think(p_delta)
	
func _ready():
	set_process(true)