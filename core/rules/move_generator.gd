class_name MoveGenerator
extends RefCounted
## Lists every legal way a seat can play a card. Pure: never changes state.
##
## Moves come back in a deterministic order so a server and its clients agree
## on move indices without sending the moves themselves.

var rules: RuleSet


func _init(p_rules: RuleSet) -> void:
	rules = p_rules


func legal_moves(state: GameState, seat: int, card: Card) -> Array[Move]:
	var moves: Array[Move] = []
	if rules.can_start(card.rank):
		var start_move: Move = _start_move(state, seat, card)
		if start_move != null:
			moves.append(start_move)

	var backward: bool = rules.moves_backward(card.rank)
	var kind: Move.Kind = Move.Kind.BACKWARD if backward else Move.Kind.FORWARD
	var player: PlayerState = state.player(seat)
	for marble: int in player.marbles.size():
		var step: MarbleStep = walk(state, MarbleRef.new(seat, marble), rules.steps_for(card.rank), backward)
		if step != null:
			var steps: Array[MarbleStep] = [step]
			moves.append(Move.new(kind, card, steps))
	return moves


## Moving the first Starting Block marble onto the Starting Exit, or null.
func _start_move(state: GameState, seat: int, card: Card) -> Move:
	var player: PlayerState = state.player(seat)
	var marble: int = player.first_marble_in_starting_block()
	if marble < 0:
		return null
	var exit := Spot.track(state.topology.starting_exit(player.arm))
	var kills: Array[MarbleRef] = []
	var blocker: MarbleRef = state.occupant(exit, seat)
	if blocker != null:
		if blocker.seat == seat or rules.starting_exit_must_be_empty:
			return null
		kills.append(blocker)
	var path: Array[Spot] = [exit]
	var steps: Array[MarbleStep] = [MarbleStep.new(MarbleRef.new(seat, marble), Spot.starting_block(), exit, path, kills)]
	return Move.new(Move.Kind.START, card, steps)


## Walks one marble [param count] spaces, or returns null if that's illegal:
## it runs off the end of the Home Base, or would land on or hop over a marble
## of its own color. Landing on another color kills it.
func walk(state: GameState, ref: MarbleRef, count: int, backward: bool) -> MarbleStep:
	var from: Spot = state.spot_of(ref)
	if not (from.is_track() or from.is_home()):
		return null
	var arm: int = state.player(ref.seat).arm
	var path: Array[Spot] = []
	var current: Spot = from
	for i: int in count:
		var next: Spot = state.topology.next_backward(arm, current) if backward \
				else state.topology.next_forward(arm, current)
		if next == null:
			return null
		var blocker: MarbleRef = state.occupant(next, ref.seat)
		if blocker != null and blocker.seat == ref.seat:
			return null
		path.append(next)
		current = next
	var kills: Array[MarbleRef] = []
	var victim: MarbleRef = state.occupant(current, ref.seat)
	if victim != null:
		kills.append(victim)
	return MarbleStep.new(ref, from, current, path, kills)
