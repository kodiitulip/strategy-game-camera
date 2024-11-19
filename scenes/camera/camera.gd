class_name CameraController
extends Node3D

@export var movement_time: float = 5.0
@export var speed_normal: float = 0.5
@export var speed_fast: float = 3.0
@export var rotation_amount: float = 2.0
@export var zoom_amount: Vector3 = Vector3(0, -10, 10)

var movement_speed: float
var new_position: Vector3
var new_rotation: Quaternion
var new_zoom: Vector3:
	set(value):
		new_zoom = Vector3(
			value.x,
			clampf(value.y, 80, 2500),
			clampf(value.z, -2500, -80)
			)
var drag_start_pos: Vector3
var drag_current_pos: Vector3

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	new_position = global_position
	new_rotation = Quaternion(transform.basis)
	new_zoom = camera.position


func _process(delta: float) -> void:
	_handle_movement_input()
	_handle_movement_mouse_input()
	_handle_rotation_input()
	_handle_zoom_input()

	global_position = global_position.lerp(new_position, delta * movement_time)
	transform.basis = transform.basis.slerp(Basis(new_rotation.normalized()),
		delta * movement_time)
	camera.position = camera.position.lerp(new_zoom, delta * movement_time)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"mouse_zoom_in"):
		new_zoom += zoom_amount
	if event.is_action_pressed(&"mouse_zoom_out"):
		new_zoom -= zoom_amount

	if event is InputEventMouseMotion:
		_handle_rotation_mouse_input(event as InputEventMouseMotion)


func _handle_rotation_mouse_input(event: InputEventMouseMotion) -> void:
	if not Input.is_action_pressed(&"rotate_cam_mouse"):
		return
	var axis: float = clampf(event.relative.x, -2.5, 2.5)
	new_rotation *= Quaternion(Vector3.UP, deg_to_rad(axis * rotation_amount))


func _handle_movement_mouse_input() -> void:
	if Input.is_action_just_pressed(&"move_cam_mouse"):
		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var origin: Vector3 = camera.project_ray_origin(mouse_pos)
		var end: Vector3 = origin + camera.project_ray_normal(mouse_pos) * 2500
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			origin, end)
		var result: Dictionary = space_state.intersect_ray(query)
		drag_start_pos = result["position"] \
			if not result.is_empty() \
			else Vector3.ZERO

	if Input.is_action_pressed(&"move_cam_mouse"):
		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var origin: Vector3 = camera.project_ray_origin(mouse_pos)
		var end: Vector3 = origin + camera.project_ray_normal(mouse_pos) * 2500
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			origin, end)
		var result: Dictionary = space_state.intersect_ray(query)
		drag_current_pos = result["position"] \
			if not result.is_empty() \
			else Vector3.ZERO
		new_position = global_position + drag_start_pos - drag_current_pos


func _handle_zoom_input() -> void:
	var axis: float = Input.get_axis(&"zoom_out",&"zoom_in")
	new_zoom += axis * zoom_amount


func _handle_rotation_input() -> void:
	var axis: float = Input.get_axis(&"rotate_cam_right", &"rotate_cam_left")
	new_rotation *= Quaternion(Vector3.UP, deg_to_rad(axis * rotation_amount))


func _handle_movement_input() -> void:
	movement_speed = speed_fast \
		if Input.is_action_pressed(&"fast_cam_moviment") \
		else speed_normal
	var dir: Vector2 = Input.get_vector(
		&"move_cam_left",
		&"move_cam_right",
		&"move_cam_forward",
		&"move_cam_backward"
		)
	var new_transform: Vector3 = (transform.basis * -Vector3(dir.x, 0.0, dir.y))
	new_position += new_transform.normalized() * movement_speed
