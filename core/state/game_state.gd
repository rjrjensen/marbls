class_name GameState
extends RefCounted
## Everything needed to describe a game in progress. Plain data plus queries.
##
## Only [Match] (through [MoveResolver]) changes a GameState. UI, AI and the
## network layer read it and send intents instead (see CLAUDE.md).

enum Phase { NOT_STARTED, AWAITING_DRAW, AWAITING_MOVE, GAME_OVER }

var topology: BoardTopology
var players: Array[PlayerState] = []
var phase: Phase = Phase.NOT_STARTED
var current_seat: int = 0
## The card the current seat drew and still has to play, or null.
var current_card: Card = null
var turn_number: int = 0
var winners: Array[int] = []


func _init(p_topology: BoardTopology) -> void:
	topology = p_topology


func seat_count() -> int:
	return players.size()


func player(seat: int) -> PlayerState:
	return players[seat]


func spot_of(ref: MarbleRef) -> Spot:
	return players[ref.seat].marbles[ref.marble]


## The marble on this Main Track space, or null.
func marble_on_track(track_index: int) -> MarbleRef:
	for p: PlayerState in players:
		for i: int in p.marbles.size():
			var spot: Spot = p.marbles[i]
			if spot.is_track() and spot.index == track_index:
				return MarbleRef.new(p.seat, i)
	return null


## The marble in this seat's Home Base slot, or null.
func marble_in_home(seat: int, slot: int) -> MarbleRef:
	var p: PlayerState = players[seat]
	for i: int in p.marbles.size():
		var spot: Spot = p.marbles[i]
		if spot.is_home() and spot.index == slot:
			return MarbleRef.new(seat, i)
	return null


func marble_in_bulls_eye() -> MarbleRef:
	for p: PlayerState in players:
		for i: int in p.marbles.size():
			if p.marbles[i].kind == Spot.Kind.BULLS_EYE:
				return MarbleRef.new(p.seat, i)
	return null


## Whoever occupies [param spot] from the point of view of [param seat]'s
## marble (Home Base spots belong to that seat), or null. Starting Blocks are
## never "occupied" in this sense.
func occupant(spot: Spot, seat: int) -> MarbleRef:
	match spot.kind:
		Spot.Kind.MAIN_TRACK:
			return marble_on_track(spot.index)
		Spot.Kind.HOME_BASE:
			return marble_in_home(seat, spot.index)
		Spot.Kind.BULLS_EYE:
			return marble_in_bulls_eye()
		_:
			return null


func to_dict() -> Dictionary:
	var player_data: Array[Dictionary] = []
	for p: PlayerState in players:
		player_data.append(p.to_dict())
	return {
		"arm_count": topology.arm_count,
		"home_length": topology.home_length,
		"players": player_data,
		"phase": phase,
		"current_seat": current_seat,
		"current_card": current_card.to_dict() if current_card != null else null,
		"turn_number": turn_number,
		"winners": winners.duplicate(),
	}


static func from_dict(data: Dictionary) -> GameState:
	var state := GameState.new(BoardTopology.new(int(data["arm_count"]), int(data["home_length"])))
	var player_data: Array = data["players"]
	for item: Dictionary in player_data:
		state.players.append(PlayerState.from_dict(item))
	state.phase = int(data["phase"]) as Phase
	state.current_seat = int(data["current_seat"])
	var card_data: Variant = data["current_card"]
	state.current_card = Card.from_dict(card_data) if card_data is Dictionary else null
	state.turn_number = int(data["turn_number"])
	var winner_data: Array = data["winners"]
	for seat: Variant in winner_data:
		state.winners.append(int(seat))
	return state
