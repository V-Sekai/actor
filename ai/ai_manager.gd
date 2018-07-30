extends Node

const ai_const = preload("ai.gd")

func create_ai():
	var ai = ai_const.new()
	add_child(ai)
	
	return ai