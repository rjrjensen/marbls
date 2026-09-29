class_name MoveChoice
extends RefCounted
## One thing the player can tap: "move this marble to that spot".

var marble: MarbleRef
var to: Spot
## Shown on the ghost: spaces used ("3"), or "out", "swap", "exit".
var label: String


func _init(p_marble: MarbleRef, p_to: Spot, p_label: String = "") -> void:
	marble = p_marble
	to = p_to
	label = p_label


func matches(step: MarbleStep) -> bool:
	return step.marble.equals(marble) and step.to.equals(to)
