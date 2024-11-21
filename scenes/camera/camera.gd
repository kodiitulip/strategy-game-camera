class_name CameraController
extends Node3D

@export_group("Speed", "speed_")
@export var speed_normal: float = 0.5
@export var speed_fast: float = 3.0
@export_group("Zoom", "zoom_")
@export var zoom_amount: float = 10.0
@export var zoom_max: float = 200.0
@export var zoom_min: float = 50.0
@export_group("Rotation","rotation_")
@export var rotation_amount: float = 2.0
@export_range(-180,180,0.001,"degrees") var rotation_vertical_max: float = -5
@export_range(-180,180,0.001,"degrees") var rotation_vertical_min: float = -80
@export_group("Inverted","inverted_")
@export var inverted_y_axis: bool = false
@export var inverted_x_axis: bool = false
@export var movement_time: float = 5.0
@export var ray_length: float = 3000.0

var new_position: Vector3
var new_rotation: Quaternion
var new_v_rotation: float
var new_zoom: float
var drag_start_pos: Vector3
var drag_current_pos: Vector3

@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var camera_arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	new_position = global_position
	new_rotation = Quaternion(transform.basis)
	new_v_rotation = camera_arm.rotation_degrees.x
	new_zoom = camera_arm.spring_length


func _process(delta: float) -> void:
	_handle_movement_input()
	_handle_rotation_input()
	_handle_zoom_input()
	_handle_movement_mouse_input()

	new_zoom = clampf(new_zoom, zoom_min, zoom_max)

	global_position = global_position.lerp(new_position, delta * movement_time)
	transform.basis = transform.basis.slerp(Basis(new_rotation.normalized()),
		delta * movement_time)
	camera_arm.spring_length = lerpf(camera_arm.spring_length,
		new_zoom, delta * movement_time)
	camera_arm.rotation_degrees.x = lerpf(
		camera_arm.rotation_degrees.x, new_v_rotation, delta * movement_time)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"mouse_zoom_in"):
		new_zoom -= zoom_amount
	if event.is_action_pressed(&"mouse_zoom_out"):
		new_zoom += zoom_amount

	if event is InputEventMouseMotion:
		_handle_rotation_mouse_input(event as InputEventMouseMotion)


func _cast_ray_from_cam(cam: Camera3D, ray_len: float) -> Variant:
	var plane: Plane = Plane(Vector3.UP).normalized()
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = cam.project_ray_origin(mouse_pos)
	var end: Vector3 = origin + cam.project_ray_normal(mouse_pos) * ray_len
	return plane.intersects_segment(origin, end)


func _handle_rotation_mouse_input(event: InputEventMouseMotion) -> void:
	if not Input.is_action_pressed(&"rotate_cam_mouse"):
		return
	var axis: float = event.relative.x * 0.3
	var axis_x: float = -event.relative.y * 0.3
	if inverted_x_axis:
		axis = -axis
	if inverted_y_axis:
		axis_x = -axis_x
	new_rotation *= Quaternion(Vector3.UP, deg_to_rad(axis))
	new_v_rotation = clampf(new_v_rotation + axis_x,
		rotation_vertical_min, rotation_vertical_max)


func _handle_movement_mouse_input() -> void:
	if Input.is_action_just_pressed(&"move_cam_mouse"):
		var pos: Variant = _cast_ray_from_cam(camera, ray_length)
		if pos:
			drag_start_pos = pos
	if Input.is_action_pressed(&"move_cam_mouse"):
		var pos: Variant = _cast_ray_from_cam(camera, ray_length)
		if pos:
			drag_current_pos = pos
		new_position = global_position + drag_start_pos - drag_current_pos


func _handle_zoom_input() -> void:
	var axis: float = Input.get_axis(&"zoom_in",&"zoom_out")
	new_zoom += axis * zoom_amount


func _handle_rotation_input() -> void:
	var axis: float = Input.get_axis(&"rotate_cam_left", &"rotate_cam_right")
	var axis_x: float = Input.get_axis(&"rotate_cam_up", &"rotate_cam_down")
	new_rotation *= Quaternion(Vector3.UP, deg_to_rad(axis * rotation_amount))
	new_v_rotation = clampf(new_v_rotation + axis_x * rotation_amount,
		rotation_vertical_min, rotation_vertical_max)


func _handle_movement_input() -> void:
	var movement_speed: float = speed_fast \
			if Input.is_action_pressed(&"fast_cam_moviment") \
			else speed_normal

	var dir: Vector2 = Input.get_vector(
			&"move_cam_left", &"move_cam_right",
			&"move_cam_forward", &"move_cam_backward")

	var new_transform: Vector3 = (transform.basis * -Vector3(dir.x, 0.0, dir.y))
	var speed_modfier: float = remap(new_zoom, zoom_min, zoom_max,
		1, zoom_max / zoom_min)

	new_position += new_transform.normalized() * movement_speed * speed_modfier
