extends "res://addons/entity_manager/component_node.gd"

const immediate_shapes_const = preload("res://addons/gdutil/immediate_shape_util.gd")
const camera_matrix_const = preload("res://addons/gdutil/camera_matrix_util.gd")
const geometry_util_const = preload("res://addons/gdutil/geometry_util.gd")

# Virtual camera info
var camera_matrix : camera_matrix_const = null
var camera_planes : Array = []

func get_actor_eye_transform() -> Transform:
	return Transform()
	#if camera_controller != null:
	#	return camera_controller.global_transform
	#else:
	#	return get_global_origin() + Transform(Basis(), extended_kinematic_body.up * eye_height)
	
func can_see_collider_point(p_point : Vector3, p_exclusion_array : Array = [], p_collision_bits : int = 1) -> bool:
	var dss : PhysicsDirectSpaceState = entity_node.PhysicsServer.space_get_direct_state(entity_node.get_world().get_space())
	if dss:
		camera_planes = camera_matrix.get_projection_planes(get_actor_eye_transform())
		
		if geometry_util_const.test_point_with_planes(p_point, camera_planes):
			var ray_exclusion_array = p_exclusion_array
			ray_exclusion_array.push_front(self)
			var result = dss.intersect_ray(get_actor_eye_transform().origin, p_point, ray_exclusion_array, p_collision_bits)
			if result.empty():
				return true
			
	return false
	
func can_see_collider_aabb(p_aabb : AABB, p_exclusion_array : Array = [], p_collision_bits : int = 1) -> bool:
	var dss = entity_node.PhysicsServer.space_get_direct_state(entity_node.get_world().get_space())
	if dss:
		camera_planes = camera_matrix.get_projection_planes(get_actor_eye_transform())
		
		if geometry_util_const.test_aabb_with_planes(p_aabb, camera_planes):
			var ray_exclusion_array = p_exclusion_array
			ray_exclusion_array.push_front(self)
			var result = dss.intersect_ray(get_actor_eye_transform().origin, p_aabb.position + (p_aabb.size * 0.5), ray_exclusion_array, p_collision_bits, PhysicsDirectSpaceState.TYPE_MASK_COLLISION)
			if result.empty():
				return true
			
	return false

func setup_camera_matrix(p_fovy_degrees : float, p_aspect : float, p_z_near : float, p_z_far : float, p_flip_fov : float) -> void:
	camera_matrix = camera_matrix_const.new()
	camera_matrix.set_perspective(p_fovy_degrees, p_aspect, p_z_near, p_z_far, p_flip_fov)
