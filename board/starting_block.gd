class_name StartingBlock
extends Node3D
## One seat's four Starting Block holes, sitting in a pill-shaped groove.

@onready var _groove: MeshInstance3D = $Groove


## Tints the groove with the seat's colour.
func set_color(color: Color) -> void:
	var material := (_groove.mesh.surface_get_material(0) as ShaderMaterial).duplicate() as ShaderMaterial
	material.set_shader_parameter("color", color)
	_groove.material_override = material
