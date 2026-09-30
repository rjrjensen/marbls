class_name MoveChoice
extends RefCounted
## One thing the player can tap: "move this marble to that spot".

var marble: MarbleRef
var to: Spot
## Shown on the ghost: spaces used ("3"), or "out", "swap", "exit".
var label: String
## A Jack swap is its own choice even when a plain move ends on the same
## spot (one space behind an opponent: kill them, or swap with them).
var is_swap: bool


func _init(p_marble: MarbleRef, p_to: Spot, p_label: String = "", p_is_swap: bool = false) -> void:
	marble = p_marble
	to = p_to
	label = p_label
	is_swap = p_is_swap


func matches(move: Move, step: MarbleStep) -> bool:
	return step.marble.equals(marble) and step.to.equals(to) and (move.kind == Move.Kind.SWAP) == is_swap
