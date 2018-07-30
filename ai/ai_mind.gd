extends Reference

const ai_memory_const = preload("ai_memory.gd")

var owner = null

var memory = ai_memory_const.new()

func think():
	pass

func _init(p_owner):
	owner = p_owner