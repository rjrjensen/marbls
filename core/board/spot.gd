class_name Spot
extends RefCounted
## Where a single marble is. A value object: compare with [method equals].
##
## [member index] is the Main Track index for [constant MAIN_TRACK], the slot
## (0 = entrance end) for [constant HOME_BASE], and 0 otherwise.

enum Kind { STARTING_BLOCK, MAIN_TRACK, HOME_BASE, BULLS_EYE }

var kind: Kind
var index: int


func _init(p_kind: Kind, p_index: int = 0) -> void:
	kind = p_kind
	index = p_index


static func starting_block() -> Spot:
	return Spot.new(Kind.STARTING_BLOCK)


static func track(track_index: int) -> Spot:
	return Spot.new(Kind.MAIN_TRACK, track_index)


static func home(slot: int) -> Spot:
	return Spot.new(Kind.HOME_BASE, slot)


static func bulls_eye() -> Spot:
	return Spot.new(Kind.BULLS_EYE)


func is_starting_block() -> bool:
	return kind == Kind.STARTING_BLOCK


func is_track() -> bool:
	return kind == Kind.MAIN_TRACK


func is_home() -> bool:
	return kind == Kind.HOME_BASE


func equals(other: Spot) -> bool:
	return other != null and kind == other.kind and index == other.index


func to_dict() -> Dictionary:
	return {"kind": kind, "index": index}


static func from_dict(data: Dictionary) -> Spot:
	return Spot.new(int(data["kind"]) as Kind, int(data["index"]))


func _to_string() -> String:
	match kind:
		Kind.STARTING_BLOCK:
			return "start-block"
		Kind.MAIN_TRACK:
			return "track:%d" % index
		Kind.HOME_BASE:
			return "home:%d" % index
		_:
			return "bulls-eye"
