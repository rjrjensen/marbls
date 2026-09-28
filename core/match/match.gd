class_name Match
extends RefCounted
## One game, run authoritatively: intents in, events out.
##
## The same class runs offline (inside [LocalMatchHost]) and on the online
## server. All randomness comes from one seeded RNG, and the whole match
## round-trips through [method to_dict] / [method from_dict], so games can be
## replayed, resumed after a server restart, and reproduced from bug reports.

var rules: RuleSet
var state: GameState
var _rng := RandomNumberGenerator.new()
var _generator: MoveGenerator
var _resolver := MoveResolver.new()
var _legal_moves: Array[Move] = []
## Whose marbles the card in play can move (see MoveGenerator.controlled_seats).
var _movers: Array[int] = []


## [param seat_arms] lists the board arm each seat sits at, in clockwise
## turn order (e.g. [code][0, 2][/code] for two players on the classic board).
func _init(p_rules: RuleSet, arm_count: int, seat_arms: Array[int], seed_value: int) -> void:
	rules = p_rules
	_generator = MoveGenerator.new(rules)
	_rng.seed = seed_value
	state = GameState.new(BoardTopology.new(arm_count))
	for seat: int in seat_arms.size():
		var deck := Deck.standard(rules.jokers_per_deck)
		state.players.append(PlayerState.new(seat, seat_arms[seat], deck, rules.marbles_per_player))


## The classic game: [param seat_count] players on a board with one arm each
## (two players sit opposite each other on the classic 4-arm board).
static func create_standard(p_rules: RuleSet, seat_count: int, seed_value: int) -> Match:
	var seat_arms: Array[int] = []
	if seat_count == 2:
		seat_arms = [0, 2]
		return Match.new(p_rules, 4, seat_arms, seed_value)
	for seat: int in seat_count:
		seat_arms.append(seat)
	return Match.new(p_rules, seat_count, seat_arms, seed_value)


## Shuffles every deck, picks who goes first and starts the first turn.
func start() -> Array[MatchEvent]:
	assert(state.phase == GameState.Phase.NOT_STARTED, "Match already started.")
	var events: Array[MatchEvent] = [MatchEvent.new(MatchEvent.Kind.GAME_STARTED)]
	for player: PlayerState in state.players:
		player.deck.shuffle(_rng)
	state.current_seat = _cut_for_first_seat(events) if rules.cut_for_first_seat else 0
	_begin_turn(events)
	return events


## The legal moves for the card in play (empty unless awaiting a move).
func legal_moves() -> Array[Move]:
	return _legal_moves


func submit(intent: MatchIntent) -> Array[MatchEvent]:
	var events: Array[MatchEvent] = []
	if state.phase == GameState.Phase.GAME_OVER:
		events.append(MatchEvent.rejected(intent.seat, "The game is over."))
	elif state.phase == GameState.Phase.NOT_STARTED:
		events.append(MatchEvent.rejected(intent.seat, "The game hasn't started."))
	elif intent.seat != state.current_seat:
		events.append(MatchEvent.rejected(intent.seat, "It's not your turn."))
	else:
		match intent.kind:
			MatchIntent.Kind.DRAW_CARD:
				_draw(events)
			MatchIntent.Kind.CHOOSE_MOVE:
				_choose(intent.move_index, events)
	return events


func _draw(events: Array[MatchEvent]) -> void:
	if state.phase != GameState.Phase.AWAITING_DRAW:
		events.append(MatchEvent.rejected(state.current_seat, "Play the card you already drew first."))
		return
	var seat: int = state.current_seat
	var deck: Deck = state.player(seat).deck
	if deck.is_draw_pile_empty():
		deck.reshuffle(_rng)
		events.append(MatchEvent.new(MatchEvent.Kind.DECK_RESHUFFLED, seat))
	var card: Card = deck.draw()
	state.current_card = card
	events.append(MatchEvent.with_card(MatchEvent.Kind.CARD_DRAWN, seat, card))
	_movers = _generator.controlled_seats(state, seat)
	_legal_moves = _generator.legal_moves(state, seat, card)
	if _legal_moves.is_empty():
		events.append(MatchEvent.with_card(MatchEvent.Kind.NO_LEGAL_MOVE, seat, card))
		_finish_card(null, events)
	else:
		state.phase = GameState.Phase.AWAITING_MOVE


func _choose(move_index: int, events: Array[MatchEvent]) -> void:
	if state.phase != GameState.Phase.AWAITING_MOVE:
		events.append(MatchEvent.rejected(state.current_seat, "Draw a card first."))
		return
	if move_index < 0 or move_index >= _legal_moves.size():
		events.append(MatchEvent.rejected(state.current_seat, "That move isn't legal."))
		return
	var move: Move = _legal_moves[move_index]
	events.append_array(_resolver.apply(state, move))
	_finish_card(move, events)


## Discards the card in play, then ends the game, plays again, or passes the turn.
## [param move] is what the card did, or null if it couldn't move anything.
func _finish_card(move: Move, events: Array[MatchEvent]) -> void:
	var seat: int = state.current_seat
	var card: Card = state.current_card
	state.player(seat).deck.discard(card)
	state.current_card = null
	_legal_moves = []
	_update_fast_track(move)
	_movers = []

	if move != null:
		for step: MarbleStep in move.steps:
			var owner: int = step.marble.seat
			if state.player(owner).is_finished() and not state.finished_seats.has(owner):
				state.finished_seats.append(owner)
				events.append(MatchEvent.new(MatchEvent.Kind.PLAYER_FINISHED, owner))
		var winners: Array[int] = _winners()
		if not winners.is_empty():
			state.winners = winners
			state.phase = GameState.Phase.GAME_OVER
			events.append(MatchEvent.game_over(winners))
			return

	var moved: bool = move != null
	if rules.plays_again(card.rank) and (moved or rules.play_again_without_move):
		state.phase = GameState.Phase.AWAITING_DRAW
		events.append(MatchEvent.with_card(MatchEvent.Kind.PLAY_AGAIN, seat, card))
		return

	state.current_seat = (seat + 1) % state.seat_count()
	_begin_turn(events)


## The card in play was this seat's "next card" for every marble it could
## have moved, so their Fast Track chances are used up. Marbles whose move
## ended on a corner (other than their own color's) get a new chance.
func _update_fast_track(move: Move) -> void:
	for owner: int in _movers:
		var player: PlayerState = state.player(owner)
		for i: int in player.fast_track_ready.size():
			player.fast_track_ready[i] = false
	if move == null or not rules.fast_track_enabled:
		return
	if move.kind == Move.Kind.SWAP and not rules.swap_grants_fast_track:
		return
	for step: MarbleStep in move.steps:
		var player: PlayerState = state.player(step.marble.seat)
		var on_corner: bool = step.to.is_track() and state.topology.is_fast_track_corner(step.to.index)
		var own_corner: bool = step.to.index == state.topology.own_fast_track_corner(player.arm)
		player.fast_track_ready[step.marble.marble] = on_corner and not own_corner


## The first player home wins; in a team game, the first team with everyone home.
func _winners() -> Array[int]:
	var winners: Array[int] = []
	for seat: int in state.finished_seats:
		var team: Array[int] = rules.team_members(seat)
		var all_home: bool = true
		for member: int in team:
			if not state.finished_seats.has(member):
				all_home = false
		if all_home:
			return team
	return winners


func _begin_turn(events: Array[MatchEvent]) -> void:
	state.phase = GameState.Phase.AWAITING_DRAW
	state.turn_number += 1
	events.append(MatchEvent.new(MatchEvent.Kind.TURN_STARTED, state.current_seat))


## Everyone cuts their deck; the highest card goes first. Ties cut again.
func _cut_for_first_seat(events: Array[MatchEvent]) -> int:
	var contenders: Array[int] = []
	for seat: int in state.seat_count():
		contenders.append(seat)
	while contenders.size() > 1:
		var best_value: int = -1
		var best: Array[int] = []
		for seat: int in contenders:
			var card: Card = state.player(seat).deck.peek_random(_rng)
			events.append(MatchEvent.with_card(MatchEvent.Kind.CARD_CUT, seat, card))
			var value: int = rules.cut_value(card.rank)
			if value > best_value:
				best_value = value
				best = [seat]
			elif value == best_value:
				best.append(seat)
		contenders = best
	return contenders[0]


func to_dict() -> Dictionary:
	return {
		"rules": rules.to_dict(),
		"state": state.to_dict(),
		# RNG state is a 64-bit int; kept as a string so JSON can't round it.
		"rng_seed": str(_rng.seed),
		"rng_state": str(_rng.state),
	}


static func from_dict(data: Dictionary) -> Match:
	var rules := RuleSet.from_dict(data["rules"])
	var no_seats: Array[int] = []
	var restored := Match.new(rules, 4, no_seats, 0)
	restored.state = GameState.from_dict(data["state"])
	restored._rng.seed = String(data["rng_seed"]).to_int()
	restored._rng.state = String(data["rng_state"]).to_int()
	if restored.state.phase == GameState.Phase.AWAITING_MOVE:
		var seat: int = restored.state.current_seat
		restored._movers = restored._generator.controlled_seats(restored.state, seat)
		restored._legal_moves = restored._generator.legal_moves(restored.state, seat, restored.state.current_card)
	return restored
