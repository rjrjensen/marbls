class_name MoveChoice
extends RefCounted
## One thing the player can tap: "move this marble to that spot".

var marble: MarbleRef
var to: Spot


func _init(p_marble: MarbleRef, p_to: Spot) -> void:
	marble = p_marble
	to = p_to


func matches(step: MarbleStep) -> bool:
	return step.marble.equals(marble) and step.to.equals(to)
