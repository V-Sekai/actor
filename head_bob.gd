extends Resource

#const curve_controlled_bob_const = preload("res://addons/headbob/curve_controlled_bob.gd")

var offset = Vector3(0.0, 0.0, 0.0)

#var motion_bob = curve_controlled_bob_const.new()
var first_person_controller = null
export(float, 0.0, 1.0) var running_stride_lengthen = 0.0

func _init(p_first_person_controller):
	first_person_controller = p_first_person_controller

func step(p_delta):
	var local_position = Vector3()
	var velocity_length = first_person_controller.velocity.length()
	#if (velocity_length > 0.0):
	#	offset = motion_bob.do_head_bob(velocity_length, p_delta) * 0.1