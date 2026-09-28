class_name Move
extends RefCounted
## A complete legal play of one card: one or more [MarbleStep]s.
##
## Special cards compose several steps (a split 7, a Jack swap) instead of
## needing their own Move subclasses.

enum Kind { START, FORWARD, BACKWARD }

var kind: Kind
var card: Card
var steps: Array[MarbleStep] = []


func _init(p_kind: Kind, p_card: Card, p_steps: Array[MarbleStep]) -> void:
	kind = p_kind
	card = p_card
	steps = p_steps


func kills() -> Array[MarbleRef]:
	var out: Array[MarbleRef] = []
	for step: MarbleStep in steps:
		out.append_array(step.kills)
	return out


func _to_string() -> String:
	return "%s(%s) %s" % [Kind.keys()[kind], card, steps]
