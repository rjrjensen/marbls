class_name MarbleRef
extends RefCounted
## Identifies one marble: which seat owns it and which of their marbles it is.

var seat: int
var marble: int


func _init(p_seat: int, p_marble: int) -> void:
	seat = p_seat
	marble = p_marble


func equals(other: MarbleRef) -> bool:
	return other != null and seat == other.seat and marble == other.marble


func to_dict() -> Dictionary:
	return {"seat": seat, "marble": marble}


static func from_dict(data: Dictionary) -> MarbleRef:
	return MarbleRef.new(int(data["seat"]), int(data["marble"]))


func _to_string() -> String:
	return "seat%d/m%d" % [seat, marble]
