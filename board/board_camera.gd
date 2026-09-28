class_name BoardCamera
extends Node3D
## The tilted camera: orbits the board so the player whose turn it is sits at
## the bottom of the screen, like leaning over the real table.

@export_range(20.0, 89.0) var tilt_degrees: float = 62.0
@export var field_of_view: float = 42.0
@export var turn_seconds: float = 0.6

var _board_radius: float = 10.0

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	get_viewport().size_changed.connect(_place_camera)
	_place_camera()


## Pulls back far enough to fit a board of this radius on screen.
func frame(board_radius: float) -> void:
	_board_radius = board_radius
	_place_camera()


## Turns so [param direction] (an arm's outward direction) points at the viewer.
func face(direction: Vector3, animate: bool) -> void:
	var target: float = atan2(direction.x, direction.z)
	if not animate:
		rotation.y = target
		return
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation:y", rotation.y + angle_difference(rotation.y, target), turn_seconds)
	await tween.finished


## A short jolt, for kills.
func shake() -> void:
	var tween := create_tween()
	for i: int in 4:
		tween.tween_property(_camera, "h_offset", 0.12 * (1 if i % 2 == 0 else -1), 0.04)
	tween.tween_property(_camera, "h_offset", 0.0, 0.04)


func _place_camera() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	var portrait: bool = size.y > size.x
	# In portrait the field of view is horizontal, so the board's width fits.
	_camera.keep_aspect = Camera3D.KEEP_WIDTH if portrait else Camera3D.KEEP_HEIGHT
	_camera.fov = field_of_view
	var distance: float = _board_radius * 0.98 / tan(deg_to_rad(field_of_view) / 2.0)
	var tilt: float = deg_to_rad(tilt_degrees)
	var eye: Vector3 = Vector3(0.0, sin(tilt), cos(tilt)) * distance
	var focus := Vector3(0.0, 0.0, _board_radius * 0.12)
	_camera.transform = Transform3D(Basis(), eye).looking_at(focus, Vector3.UP)
