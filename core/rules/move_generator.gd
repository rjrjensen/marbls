class_name MoveGenerator
extends RefCounted
## Lists every legal way a seat can play a card. Pure: never changes state.
##
## Moves come back in a deterministic order so a server and its clients agree
## on move indices without sending the moves themselves. Two moves with the
## same result (e.g. reaching a hole by Fast Track or by Main Track) are
## listed once.

var rules: RuleSet


func _init(p_rules: RuleSet) -> void:
	rules = p_rules


func legal_moves(state: GameState, seat: int, card: Card) -> Array[Move]:
	var moves: Array[Move] = []
	var seen: Dictionary[String, bool] = {}
	var movers: Array[int] = controlled_seats(state, seat)

	if rules.can_start(card.rank):
		for owner: int in movers:
			_add(moves, seen, _start_move(state, owner, card))

	if rules.bulls_eye_enabled and rules.can_exit_bulls_eye(card.rank):
		for ref: MarbleRef in _marbles_of(state, movers):
			if state.spot_of(ref).kind == Spot.Kind.BULLS_EYE:
				_add(moves, seen, _bulls_eye_exit(state, ref, card))

	var backward: bool = rules.moves_backward(card.rank)
	var kind: Move.Kind = Move.Kind.BACKWARD if backward else Move.Kind.FORWARD
	for ref: MarbleRef in _marbles_of(state, movers):
		for step: MarbleStep in marble_steps(state, ref, rules.steps_for(card.rank), backward):
			var steps: Array[MarbleStep] = [step]
			_add(moves, seen, Move.new(kind, card, steps))

	if rules.can_swap(card.rank):
		_add_swaps(moves, seen, state, movers, card)
	if rules.can_split(card.rank):
		_add_splits(moves, seen, state, seat, movers, card)
	return moves


## Whose marbles [param seat]'s cards move: their own, or, once they've
## finished in a team game, their unfinished teammates'.
func controlled_seats(state: GameState, seat: int) -> Array[int]:
	var seats: Array[int] = []
	if not rules.is_team_game() or not state.player(seat).is_finished():
		seats.append(seat)
		return seats
	for member: int in rules.team_members(seat):
		if not state.player(member).is_finished():
			seats.append(member)
	return seats


## Every way one marble can travel exactly [param count] spaces: the plain
## walk, dropping into the Bull's Eye, and riding the Fast Track.
func marble_steps(state: GameState, ref: MarbleRef, count: int, backward: bool) -> Array[MarbleStep]:
	var out: Array[MarbleStep] = []
	var from: Spot = state.spot_of(ref)
	if not (from.is_track() or from.is_home()):
		return out
	var arm: int = state.player(ref.seat).arm
	var topology: BoardTopology = state.topology

	# The plain walk. A Main Track marble standing on a corner with one step
	# left (it arrived there, or it's sitting there and the card moves one
	# space) may take that step into the Bull's Eye instead, except from its
	# own color's corner, the one right before its Home Base.
	var path: Array[Spot] = []
	var current: Spot = from
	var blocked: bool = false
	for i: int in count:
		if rules.bulls_eye_enabled and i == count - 1 and current.is_track() \
				and topology.is_fast_track_corner(current.index) \
				and current.index != topology.own_fast_track_corner(arm):
			var dive: Array[Spot] = path.duplicate()
			dive.append(Spot.bulls_eye())
			_append_if_legal(out, state, ref, from, dive)
		var next: Spot = topology.next_backward(arm, current) if backward else topology.next_forward(arm, current)
		if next == null or _own_marble_at(state, ref, next):
			blocked = true
			break
		path.append(next)
		current = next
	if not blocked:
		_append_if_legal(out, state, ref, from, path)

	if not backward:
		out.append_array(_fast_track_steps(state, ref, count))
	return out


## Riding the Fast Track: each point of the card either hops to the next
## corner or (from then on) walks the Main Track. Hops stop at the marble's own
## color's corner, and before any corner holding one of its own marbles.
func _fast_track_steps(state: GameState, ref: MarbleRef, count: int) -> Array[MarbleStep]:
	var out: Array[MarbleStep] = []
	var from: Spot = state.spot_of(ref)
	var player: PlayerState = state.player(ref.seat)
	var topology: BoardTopology = state.topology
	if not rules.fast_track_enabled or not player.fast_track_ready[ref.marble]:
		return out
	if not from.is_track() or not topology.is_fast_track_corner(from.index):
		return out
	var own_corner: int = topology.own_fast_track_corner(player.arm)
	var corner: int = from.index
	var hops: Array[Spot] = []
	for hop_count: int in range(1, count + 1):
		if corner == own_corner:
			break
		corner = topology.wrap_index(corner + BoardTopology.SEGMENT_LENGTH)
		var corner_spot := Spot.track(corner)
		if _own_marble_at(state, ref, corner_spot):
			break
		hops.append(corner_spot)
		var path: Array[Spot] = hops.duplicate()
		var current: Spot = corner_spot
		var walked_all: bool = true
		for i: int in count - hop_count:
			var next: Spot = topology.next_forward(player.arm, current)
			if next == null or _own_marble_at(state, ref, next):
				walked_all = false
				break
			path.append(next)
			current = next
		if walked_all:
			_append_if_legal(out, state, ref, from, path)
	return out


## Moving the first Starting Block marble onto the Starting Exit, or null.
func _start_move(state: GameState, owner: int, card: Card) -> Move:
	var player: PlayerState = state.player(owner)
	var marble: int = player.first_marble_in_starting_block()
	if marble < 0:
		return null
	var exit := Spot.track(state.topology.starting_exit(player.arm))
	var kills: Array[MarbleRef] = []
	var blocker: MarbleRef = state.occupant(exit, owner)
	if blocker != null:
		if blocker.seat == owner or rules.starting_exit_must_be_empty:
			return null
		kills.append(blocker)
	var path: Array[Spot] = [exit]
	var steps: Array[MarbleStep] = [MarbleStep.new(MarbleRef.new(owner, marble), Spot.starting_block(), exit, path, kills)]
	return Move.new(Move.Kind.START, card, steps)


## Leaving the Bull's Eye for the marble's own color's Fast Track corner.
func _bulls_eye_exit(state: GameState, ref: MarbleRef, card: Card) -> Move:
	var corner := Spot.track(state.topology.own_fast_track_corner(state.player(ref.seat).arm))
	var out: Array[MarbleStep] = []
	var path: Array[Spot] = [corner]
	_append_if_legal(out, state, ref, Spot.bulls_eye(), path)
	if out.is_empty():
		return null
	return Move.new(Move.Kind.BULLS_EYE_EXIT, card, out)


## The Jack: trade places with any other color's marble on the Main Track or
## in the Bull's Eye (not in a Starting Block or Home Base). Teammates count.
func _add_swaps(
	moves: Array[Move], seen: Dictionary[String, bool], state: GameState, movers: Array[int], card: Card
) -> void:
	for mine: MarbleRef in _marbles_of(state, movers):
		var my_spot: Spot = state.spot_of(mine)
		if not _swappable(my_spot):
			continue
		for p: PlayerState in state.players:
			if p.seat == mine.seat:
				continue
			for i: int in p.marbles.size():
				var their_spot: Spot = p.marbles[i]
				if not _swappable(their_spot):
					continue
				var theirs := MarbleRef.new(p.seat, i)
				var no_kills: Array[MarbleRef] = []
				var my_path: Array[Spot] = [their_spot]
				var their_path: Array[Spot] = [my_spot]
				var steps: Array[MarbleStep] = [
					MarbleStep.new(mine, my_spot, their_spot, my_path, no_kills),
					MarbleStep.new(theirs, their_spot, my_spot, their_path, no_kills.duplicate()),
				]
				_add(moves, seen, Move.new(Move.Kind.SWAP, card, steps))


## The Seven: split all 7 between exactly two marbles, which can be your own
## two or one of yours and one of your teammate's. Either half can kill or go
## into Home Base. The second half is worked out after the first has happened.
func _add_splits(
	moves: Array[Move], seen: Dictionary[String, bool], state: GameState, seat: int, movers: Array[int], card: Card
) -> void:
	var total: int = rules.steps_for(card.rank)
	var partner_seats: Array[int] = movers.duplicate()
	for member: int in rules.team_members(seat):
		if not partner_seats.has(member) and not state.player(member).is_finished():
			partner_seats.append(member)
	var candidates: Array[MarbleRef] = []
	for ref: MarbleRef in _marbles_of(state, partner_seats):
		var spot: Spot = state.spot_of(ref)
		if spot.is_track() or spot.is_home():
			candidates.append(ref)
	for first: MarbleRef in candidates:
		for second: MarbleRef in candidates:
			if first.equals(second) or not (movers.has(first.seat) or movers.has(second.seat)):
				continue
			for first_count: int in range(1, total):
				for first_step: MarbleStep in marble_steps(state, first, first_count, false):
					var after := state.copy_for_simulation()
					MoveResolver.apply_step(after, first_step)
					for second_step: MarbleStep in marble_steps(after, second, total - first_count, false):
						var steps: Array[MarbleStep] = [first_step, second_step]
						_add(moves, seen, Move.new(Move.Kind.SPLIT, card, steps))


## Adds a step along [param path] unless it would land on one of the marble's
## own color (landing on another color kills it).
func _append_if_legal(out: Array[MarbleStep], state: GameState, ref: MarbleRef, from: Spot, path: Array[Spot]) -> void:
	var to: Spot = path[-1]
	var kills: Array[MarbleRef] = []
	var occupant: MarbleRef = state.occupant(to, ref.seat)
	if occupant != null:
		if occupant.seat == ref.seat:
			return
		kills.append(occupant)
	out.append(MarbleStep.new(ref, from, to, path, kills))


func _own_marble_at(state: GameState, ref: MarbleRef, spot: Spot) -> bool:
	var occupant: MarbleRef = state.occupant(spot, ref.seat)
	return occupant != null and occupant.seat == ref.seat


func _swappable(spot: Spot) -> bool:
	return spot.is_track() or spot.kind == Spot.Kind.BULLS_EYE


func _marbles_of(state: GameState, seats: Array[int]) -> Array[MarbleRef]:
	var refs: Array[MarbleRef] = []
	for seat: int in seats:
		for i: int in state.player(seat).marbles.size():
			refs.append(MarbleRef.new(seat, i))
	return refs


func _add(moves: Array[Move], seen: Dictionary[String, bool], move: Move) -> void:
	if move == null:
		return
	var key: String = move.signature()
	if seen.has(key):
		return
	seen[key] = true
	moves.append(move)
