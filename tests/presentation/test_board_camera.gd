extends TestCase
## The camera frames the whole board inside the screen area it's given, and
## comes close enough that the board fills that area.

const CAMERA_SCRIPT := preload("res://board/board_camera.gd")


func make_camera() -> BoardCamera:
	var rig := Node3D.new()
	rig.set_script(CAMERA_SCRIPT)
	var lens := Camera3D.new()
	lens.name = "Camera"
	rig.add_child(lens)
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	return rig as BoardCamera


func free_camera(rig: BoardCamera) -> void:
	rig.get_parent().remove_child(rig)
	rig.free()


func screen_bounds(rig: BoardCamera, footprint: Rect2) -> Rect2:
	var lens := rig.get_node("Camera") as Camera3D
	var bounds := Rect2(lens.unproject_position(Vector3(footprint.position.x, 0.0, footprint.position.y)), Vector2.ZERO)
	var others: Array[Vector2] = [
		footprint.end, Vector2(footprint.position.x, footprint.end.y), Vector2(footprint.end.x, footprint.position.y),
	]
	for corner: Vector2 in others:
		bounds = bounds.expand(lens.unproject_position(Vector3(corner.x, 0.0, corner.y)))
	return bounds


func test_the_board_fills_the_area_it_is_given() -> void:
	var rig := make_camera()
	var screen: Vector2 = rig.get_viewport().get_visible_rect().size
	var area := Rect2(0.0, screen.y * 0.1, screen.x, screen.y * 0.75)
	var footprint := Rect2(-9.0, -10.0, 18.0, 20.0)
	rig.fit_inside(area)
	for facing: Vector3 in [Vector3.FORWARD, Vector3.RIGHT, Vector3(1.0, 0.0, 1.0).normalized()]:
		rig.frame(footprint)
		rig.face(facing, false)
		var bounds: Rect2 = screen_bounds(rig, footprint)
		var inner: Rect2 = area.grow(-rig.screen_margin)
		var label: String = "facing %s: board %s, area %s" % [facing, bounds, inner]
		assert_true(inner.grow(1.0).encloses(bounds), label)
		var snug: bool = bounds.size.x > inner.size.x - 4.0 or bounds.size.y > inner.size.y - 4.0
		assert_true(snug, label)
		assert_true(absf(bounds.get_center().y - inner.get_center().y) < 4.0, "not centred: " + label)
	free_camera(rig)
