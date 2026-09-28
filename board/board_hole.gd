class_name BoardHole
extends Node3D
## One hole in the board. Its [member role] and [member number] say which
## part of the board graph it stands for; [BoardView] reads them to map
## [Spot]s to places on screen.

enum Role { TRACK, HOME_BASE, STARTING_BLOCK, BULLS_EYE }

@export var role: Role = Role.TRACK
## TRACK: offset from its arm's Starting Exit (-8..5).
## HOME_BASE and STARTING_BLOCK: slot 0..3. BULLS_EYE: unused.
@export var number: int = 0

@onready var _ring: MeshInstance3D = $Ring


## Shows a colored ring around the hole (Starting Exits, Home Base, corners).
func set_ring_color(color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.4
	_ring.material_override = material
	_ring.visible = true
