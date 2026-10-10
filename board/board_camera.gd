class_name BoardCamera
extends Node3D
## The tilted camera: orbits the board so the player whose turn it is sits at
## the bottom of the screen, like leaning over the real table.

@export_range(20.0, 89.0) var tilt_degrees: float = 62.0
@export var field_of_view: float = 42.0
@export var turn_seconds: float = 0.6
## Gap kept between the board and the edge of the screen, in pixels.
@export var screen_margin: float = 16.0

## The board's outline on the table, including its rim.
var _footprint := Rect2(-10.0, -10.0, 20.0, 20.0)
## The part of the screen the board must fit in; empty means the whole screen.
var _screen_area := Rect2()

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	get_viewport().size_changed.connect(_place_camera)
	_place_camera()


## Comes as close as it can while the whole board (its outline on the
## table, [param footprint]) stays on screen.
func frame(footprint: Rect2) -> void:
	_footprint = footprint
	_place_camera()


## Keeps the board inside [param area] of the screen (say, between the HUD's
## bars). An empty rectangle means the whole screen.
func fit_inside(area: Rect2) -> void:
	_screen_area = area
	_place_camera()


## Turns so [param direction] (an arm's outward direction) points at the viewer.
func face(direction: Vector3, animate: bool) -> void:
	var target: float = atan2(direction.x, direction.z)
	if not animate:
		_turn_to(target)
		return
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_turn_to, rotation.y, rotation.y + angle_difference(rotation.y, target), turn_seconds)
	await tween.finished


## A short jolt, for kills.
func shake() -> void:
	var tween := create_tween()
	for i: int in 4:
		tween.tween_property(_camera, "h_offset", 0.12 * (1 if i % 2 == 0 else -1), 0.04)
	tween.tween_property(_camera, "h_offset", 0.0, 0.04)


## A rectangular board looks wider from some sides, so the camera refits as
## it turns.
func _turn_to(angle: float) -> void:
	rotation.y = angle
	_place_camera()


## Finds the closest distance at which every corner of the board is on screen,
## then nudges the aim so the board sits in the middle.
func _place_camera() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	var area: Rect2 = _screen_area if _screen_area.has_area() else Rect2(Vector2.ZERO, size)
	area = area.grow(-screen_margin)
	var portrait: bool = size.y > size.x
	_camera.keep_aspect = Camera3D.KEEP_WIDTH if portrait else Camera3D.KEEP_HEIGHT
	_camera.fov = field_of_view
	var focus := Vector3(_footprint.get_center().x, 0.0, _footprint.get_center().y)
	var distance: float = _fit_distance(focus, area)
	for attempt: int in 8:
		var off_center: float = _board_on_screen_bounds().get_center().y - area.get_center().y
		if absf(off_center) < 1.0:
			break
		# Aim nearer the viewer to move the board up the screen, farther to move it down.
		var toward_viewer: Vector3 = global_transform.basis.z
		toward_viewer.y = 0.0
		focus += toward_viewer.normalized() * off_center / size.y * distance * 0.5
		distance = _fit_distance(focus, area)


## The closest distance (aiming at [param focus]) at which the board fits in
## [param area]. Leaves the camera there.
func _fit_distance(focus: Vector3, area: Rect2) -> float:
	var near: float = 0.1
	var far: float = _footprint.size.length() * 6.0
	for step: int in 24:
		var distance: float = (near + far) / 2.0
		_aim(focus, distance)
		if area.encloses(_board_on_screen_bounds()):
			far = distance
		else:
			near = distance
	_aim(focus, far)
	return far


func _aim(focus: Vector3, distance: float) -> void:
	var tilt: float = deg_to_rad(tilt_degrees)
	var eye: Vector3 = Vector3(0.0, sin(tilt), cos(tilt)) * distance
	var local_focus: Vector3 = global_transform.affine_inverse() * focus
	_camera.transform = Transform3D(Basis(), local_focus + eye).looking_at(local_focus, Vector3.UP)


func _board_on_screen_bounds() -> Rect2:
	var bounds := Rect2(_camera.unproject_position(_corner(0)), Vector2.ZERO)
	for i: int in range(1, 4):
		bounds = bounds.expand(_camera.unproject_position(_corner(i)))
	return bounds


func _corner(index: int) -> Vector3:
	var x: float = _footprint.position.x if index % 2 == 0 else _footprint.end.x
	var z: float = _footprint.position.y if index < 2 else _footprint.end.y
	return Vector3(x, 0.0, z)
