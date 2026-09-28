class_name MatchIntent
extends RefCounted
## A request from a player (human, AI or remote) to act. The [Match] decides
## whether it's allowed; nothing else changes game state.

enum Kind { DRAW_CARD, CHOOSE_MOVE }

var kind: Kind
var seat: int
## CHOOSE_MOVE: index into the current legal move list.
var move_index: int = -1


func _init(p_kind: Kind, p_seat: int, p_move_index: int = -1) -> void:
	kind = p_kind
	seat = p_seat
	move_index = p_move_index


static func draw_card(p_seat: int) -> MatchIntent:
	return MatchIntent.new(Kind.DRAW_CARD, p_seat)


static func choose_move(p_seat: int, p_move_index: int) -> MatchIntent:
	return MatchIntent.new(Kind.CHOOSE_MOVE, p_seat, p_move_index)


func to_dict() -> Dictionary:
	return {"kind": kind, "seat": seat, "move_index": move_index}


static func from_dict(data: Dictionary) -> MatchIntent:
	return MatchIntent.new(int(data["kind"]) as Kind, int(data["seat"]), int(data["move_index"]))
