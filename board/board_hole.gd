class_name BoardHole
extends Node3D
## One hole in the board. Its [member role] and [member number] say which
## part of the board graph it stands for; [BoardView] reads them to map
## [Spot]s to places on screen.

enum Role { TRACK, HOME_BASE, STARTING_BLOCK, BULLS_EYE }

## How much white the thin ring inside a filled hole mixes in.
const INSET_WHITENESS := 0.35

@export var role: Role = Role.TRACK
## TRACK: offset from its arm's Starting Exit (-8..5).
## HOME_BASE and STARTING_BLOCK: slot 0..3. BULLS_EYE: unused.
@export var number: int = 0

@onready var _pit: MeshInstance3D = $Pit
@onready var _ring: MeshInstance3D = $Ring
@onready var _inset: MeshInstance3D = $Inset


## Shows a colored ring around the hole (Starting Block holes).
func set_ring_color(color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.4
	_ring.material_override = material
	_ring.visible = true


## Paints the hole itself in a seat color, with a thin pale ring just inside
## its edge (Home Base, Starting Exit, own Fast Track corner).
func set_fill_color(color: Color) -> void:
	var pit_material := StandardMaterial3D.new()
	pit_material.albedo_color = color
	pit_material.roughness = 0.3
	_pit.material_override = pit_material
	var inset_material := StandardMaterial3D.new()
	inset_material.albedo_color = color.lerp(Color.WHITE, INSET_WHITENESS)
	inset_material.roughness = 0.3
	_inset.material_override = inset_material
	_inset.visible = true
