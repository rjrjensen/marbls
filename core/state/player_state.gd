class_name PlayerState
extends RefCounted
## One seat at the table: which arm it sits at, its deck and its marbles.

var seat: int
var arm: int
var deck: Deck
var marbles: Array[Spot] = []


func _init(p_seat: int, p_arm: int, p_deck: Deck, marble_count: int) -> void:
	seat = p_seat
	arm = p_arm
	deck = p_deck
	for i: int in marble_count:
		marbles.append(Spot.starting_block())


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
	return {"seat": seat, "arm": arm, "deck": deck.to_dict(), "marbles": marble_data}


static func from_dict(data: Dictionary) -> PlayerState:
	var marble_data: Array = data["marbles"]
	var player := PlayerState.new(int(data["seat"]), int(data["arm"]), Deck.from_dict(data["deck"]), 0)
	for item: Dictionary in marble_data:
		player.marbles.append(Spot.from_dict(item))
	return player
