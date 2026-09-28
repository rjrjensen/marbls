class_name PlayerState
extends RefCounted
## One seat at the table: which arm it sits at, its deck and its marbles.

var seat: int
var arm: int
var deck: Deck
var marbles: Array[Spot] = []
## Per marble: its last move ended on a Fast Track corner, so this seat's
## next card may ride the Fast Track with it.
var fast_track_ready: Array[bool] = []


func _init(p_seat: int, p_arm: int, p_deck: Deck, marble_count: int) -> void:
	seat = p_seat
	arm = p_arm
	deck = p_deck
	for i: int in marble_count:
		marbles.append(Spot.starting_block())
		fast_track_ready.append(false)


func is_finished() -> bool:
	for spot: Spot in marbles:
		if not spot.is_home():
			return false
	return true


## Index of the first marble still in the Starting Block, or -1.
func first_marble_in_starting_block() -> int:
	for i: int in marbles.size():
		if marbles[i].is_starting_block():
			return i
	return -1


func to_dict() -> Dictionary:
	var marble_data: Array[Dictionary] = []
	for spot: Spot in marbles:
		marble_data.append(spot.to_dict())
	return {
		"seat": seat,
		"arm": arm,
		"deck": deck.to_dict(),
		"marbles": marble_data,
		"fast_track_ready": fast_track_ready.duplicate(),
	}


static func from_dict(data: Dictionary) -> PlayerState:
	var marble_data: Array = data["marbles"]
	var player := PlayerState.new(int(data["seat"]), int(data["arm"]), Deck.from_dict(data["deck"]), 0)
	var ready_data: Array = data.get("fast_track_ready", [])
	for i: int in marble_data.size():
		player.marbles.append(Spot.from_dict(marble_data[i]))
		player.fast_track_ready.append(bool(ready_data[i]) if i < ready_data.size() else false)
	return player


## A copy with its own marble positions (sharing the deck), for trying moves
## out without touching the real state.
func copy_for_simulation() -> PlayerState:
	var copy := PlayerState.new(seat, arm, deck, 0)
	copy.marbles = marbles.duplicate()
	copy.fast_track_ready = fast_track_ready.duplicate()
	return copy
