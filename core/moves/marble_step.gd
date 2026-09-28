class_name MarbleStep
extends RefCounted
## One marble's part of a [Move]: where it goes, the spaces it passes through,
## and any marbles it kills by landing on them.

var marble: MarbleRef
var from: Spot
var to: Spot
## Every spot entered on the way, ending with [member to].
var path: Array[Spot] = []
var kills: Array[MarbleRef] = []


func _init(p_marble: MarbleRef, p_from: Spot, p_to: Spot, p_path: Array[Spot], p_kills: Array[MarbleRef]) -> void:
	marble = p_marble
	from = p_from
	to = p_to
	path = p_path
	kills = p_kills


func _to_string() -> String:
	var text := "%s %s->%s" % [marble, from, to]
	if not kills.is_empty():
		text += " kills %s" % [kills]
	return text
