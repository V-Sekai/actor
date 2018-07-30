extends Reference

var navigation = null

class PathWaypoint:
	var position = Vector3(0.0, 0.0, 0.0)
	var yaw = 0.0

func generate_simple_path(p_target, p_optimize = true):
	var current_path = Array()
		
	if(navigation):
		var p = navigation.get_simple_path(get_global_transform().origin, p_target, p_optimize)
		current_path = Array(p)
		current_path.invert()
	else:
	#	# Navigation not found, but attempt navigation anyway
		current_path = [p_target, get_global_transform().origin]
		
	return current_path