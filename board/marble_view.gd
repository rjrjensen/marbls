class_name MarbleView
extends Node3D
## A marble on the board, or a translucent "ghost" showing where a legal move
## would put one. Emits [signal tapped] up to [BoardView].

signal tapped(marble: MarbleView)

## Resting height above the board surface (the marble sits a little in its hole).
const REST_HEIGHT := 0.24

## Which marble this is. Null for ghosts.
var ref: MarbleRef = null
## Ghosts only: the index of the legal move this ghost stands for.
var move_index: int = -1

var _material := StandardMaterial3D.new()
var _base_color := Color.WHITE
var _pulse: Tween = null

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	_mesh.material_override = _material


func setup(color: Color, is_ghost: bool) -> void:
	_base_color = color
	_material.albedo_color = color
	_material.metallic = 0.1
	_material.roughness = 0.12
	_material.rim_enabled = true
	_material.rim = 0.4
	if is_ghost:
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.albedo_color = Color(color.lightened(0.35), 0.6)
		set_glow(true)


## Makes the marble glow and pulse to show it can be tapped.
func set_glow(on: bool) -> void:
	_material.emission_enabled = on
	_material.emission = _base_color.lightened(0.3)
	_material.emission_energy_multiplier = 1.4 if on else 0.0
	if _pulse != null:
		_pulse.kill()
		_pulse = null
	_mesh.scale = Vector3.ONE
	if on and is_inside_tree():
		_pulse = create_tween().set_loops()
		_pulse.tween_property(_mesh, "scale", Vector3.ONE * 1.2, 0.45).set_trans(Tween.TRANS_SINE)
		_pulse.tween_property(_mesh, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_SINE)


func _on_area_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape: int) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(self)
