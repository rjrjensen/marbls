extends TestCase
## Turn flow: intents in, events out.


func new_match(seat_count: int = 4, seed_value: int = 7) -> Match:
	var rules := RuleSet.new()
	rules.cut_for_first_seat = false
	var game := Match.create_standard(rules, seat_count, seed_value)
	game.start()
	return game


## Puts [param rank] on top of [param seat]'s draw pile.
func stack(game: Match, seat: int, rank: Card.Rank) -> void:
	game.state.player(seat).deck.draw_pile.append(Card.new(rank, Card.Suit.HEARTS))


func kinds(events: Array[MatchEvent]) -> Array[MatchEvent.Kind]:
	var out: Array[MatchEvent.Kind] = []
	for event: MatchEvent in events:
		out.append(event.kind)
	return out


func test_start_shuffles_and_begins_the_first_turn() -> void:
	var rules := RuleSet.new()
	var game := Match.create_standard(rules, 4, 3)
	var events: Array[MatchEvent] = game.start()
	assert_eq(events[0].kind, MatchEvent.Kind.GAME_STARTED)
	assert_eq(events[-1].kind, MatchEvent.Kind.TURN_STARTED)
	assert_eq(events[-1].seat, game.state.current_seat)
	assert_true(kinds(events).has(MatchEvent.Kind.CARD_CUT))
	assert_eq(game.state.phase, GameState.Phase.AWAITING_DRAW)


func test_the_cut_winner_had_the_highest_card() -> void:
	var rules := RuleSet.new()
	var game := Match.create_standard(rules, 4, 11)
	var events: Array[MatchEvent] = game.start()
	var last_round: Dictionary[int, int] = {}
	for event: MatchEvent in events:
		if event.kind == MatchEvent.Kind.CARD_CUT:
			last_round[event.seat] = rules.cut_value(event.card.rank)
	var winner: int = game.state.current_seat
	for seat: int in last_round:
		assert_true(last_round[winner] >= last_round[seat], "seat %d cut higher than the winner" % seat)


func test_two_players_sit_opposite_on_the_classic_board() -> void:
	var game := new_match(2)
	assert_eq(game.state.topology.arm_count, 4)
	assert_eq(game.state.player(1).arm, 2)


func test_out_of_turn_intents_are_rejected() -> void:
	var game := new_match()
	var events: Array[MatchEvent] = game.submit(MatchIntent.draw_card(2))
	assert_eq(kinds(events), [MatchEvent.Kind.INTENT_REJECTED] as Array[MatchEvent.Kind])
	assert_eq(game.state.current_seat, 0)


func test_no_legal_move_passes_the_turn() -> void:
	var game := new_match()
	stack(game, 0, Card.Rank.TWO)
	var events: Array[MatchEvent] = game.submit(MatchIntent.draw_card(0))
	assert_eq(kinds(events), [
		MatchEvent.Kind.CARD_DRAWN, MatchEvent.Kind.NO_LEGAL_MOVE, MatchEvent.Kind.TURN_STARTED,
	] as Array[MatchEvent.Kind])
	assert_eq(game.state.current_seat, 1)
	assert_eq(game.state.player(0).deck.discard_pile.size(), 1)


func test_play_again_card_keeps_the_turn() -> void:
	var game := new_match()
	stack(game, 0, Card.Rank.ACE)
	game.submit(MatchIntent.draw_card(0))
	assert_eq(game.state.phase, GameState.Phase.AWAITING_MOVE)
	assert_eq(game.legal_moves().size(), 1)
	var events: Array[MatchEvent] = game.submit(MatchIntent.choose_move(0, 0))
	assert_eq(kinds(events), [MatchEvent.Kind.MARBLE_MOVED, MatchEvent.Kind.PLAY_AGAIN] as Array[MatchEvent.Kind])
	assert_eq(game.state.current_seat, 0)
	assert_eq(game.state.phase, GameState.Phase.AWAITING_DRAW)


func test_play_again_without_a_move_is_a_rule_option() -> void:
	for allowed: bool in [true, false]:
		var game := new_match()
		game.rules.play_again_without_move = allowed
		var me: PlayerState = game.state.player(0)
		me.marbles[0] = Spot.home(3)
		me.marbles[1] = Spot.home(2)
		me.marbles[2] = Spot.home(1)
		game.state.player(1).marbles[0] = Spot.track(0)  # blocks my Starting Exit
		stack(game, 0, Card.Rank.ACE)
		var events: Array[MatchEvent] = game.submit(MatchIntent.draw_card(0))
		assert_eq(events[1].kind, MatchEvent.Kind.NO_LEGAL_MOVE)
		assert_eq(game.state.current_seat, 0 if allowed else 1, "allowed=%s" % allowed)


func test_choosing_an_illegal_move_is_rejected() -> void:
	var game := new_match()
	stack(game, 0, Card.Rank.ACE)
	game.submit(MatchIntent.draw_card(0))
	var events: Array[MatchEvent] = game.submit(MatchIntent.choose_move(0, 5))
	assert_eq(events[0].kind, MatchEvent.Kind.INTENT_REJECTED)
	assert_eq(game.state.phase, GameState.Phase.AWAITING_MOVE)


func test_last_marble_home_wins_the_game() -> void:
	var game := new_match()
	var me: PlayerState = game.state.player(0)
	me.marbles[0] = Spot.home(1)
	me.marbles[1] = Spot.home(2)
	me.marbles[2] = Spot.home(3)
	me.marbles[3] = Spot.track(53)
	stack(game, 0, Card.Rank.TWO)
	game.submit(MatchIntent.draw_card(0))
	var events: Array[MatchEvent] = game.submit(MatchIntent.choose_move(0, 0))
	assert_eq(kinds(events), [
		MatchEvent.Kind.MARBLE_MOVED, MatchEvent.Kind.PLAYER_FINISHED, MatchEvent.Kind.GAME_OVER,
	] as Array[MatchEvent.Kind])
	assert_eq(game.state.winners, [0] as Array[int])
	assert_eq(game.submit(MatchIntent.draw_card(1))[0].kind, MatchEvent.Kind.INTENT_REJECTED)


func test_an_empty_draw_pile_is_reshuffled() -> void:
	var game := new_match()
	var deck: Deck = game.state.player(0).deck
	deck.discard_pile.append_array(deck.draw_pile)
	deck.draw_pile.clear()
	var events: Array[MatchEvent] = game.submit(MatchIntent.draw_card(0))
	assert_eq(events[0].kind, MatchEvent.Kind.DECK_RESHUFFLED)
	assert_eq(deck.total_cards(), 54)


func test_a_saved_match_continues_exactly_like_the_original() -> void:
	var original := new_match(4, 99)
	var driver := RandomNumberGenerator.new()
	driver.seed = 5
	for i: int in 150:
		original.submit(_random_intent(original, driver))

	var restored := Match.from_dict(JSON.parse_string(JSON.stringify(original.to_dict())))
	var driver_copy := RandomNumberGenerator.new()
	driver_copy.seed = driver.seed
	driver_copy.state = driver.state
	for i: int in 300:
		var a: Array[MatchEvent] = original.submit(_random_intent(original, driver))
		var b: Array[MatchEvent] = restored.submit(_random_intent(restored, driver_copy))
		assert_eq(str(b), str(a), "diverged at step %d" % i)
		if not a.is_empty() and a[-1].kind == MatchEvent.Kind.GAME_OVER:
			break
	assert_eq(JSON.stringify(restored.to_dict()), JSON.stringify(original.to_dict()))


func test_random_games_always_finish_with_legal_boards() -> void:
	for seat_count: int in [2, 3, 4, 6]:
		for seed_value: int in [1, 2, 3]:
			var game := new_match(seat_count, seed_value)
			var driver := RandomNumberGenerator.new()
			driver.seed = seed_value
			var steps: int = 0
			while game.state.phase != GameState.Phase.GAME_OVER and steps < 50000:
				game.submit(_random_intent(game, driver))
				steps += 1
				if steps % 50 == 0 and not _board_is_legal(game.state):
					fail("illegal board: %d seats, seed %d, step %d" % [seat_count, seed_value, steps])
					return
			assert_eq(game.state.phase, GameState.Phase.GAME_OVER, "%d seats, seed %d" % [seat_count, seed_value])
			assert_true(game.state.player(game.state.winners[0]).is_finished())


## Draws when it's time to draw, otherwise picks a random legal move.
func _random_intent(game: Match, driver: RandomNumberGenerator) -> MatchIntent:
	var seat: int = game.state.current_seat
	if game.state.phase == GameState.Phase.AWAITING_MOVE:
		return MatchIntent.choose_move(seat, driver.randi_range(0, game.legal_moves().size() - 1))
	return MatchIntent.draw_card(seat)


func _board_is_legal(state: GameState) -> bool:
	var track_seen: Dictionary[int, bool] = {}
	for p: PlayerState in state.players:
		if p.deck.total_cards() != 54 - (1 if state.current_card != null and p.seat == state.current_seat else 0):
			return false
		var home_seen: Dictionary[int, bool] = {}
		for spot: Spot in p.marbles:
			if spot.is_track():
				if track_seen.has(spot.index):
					return false
				track_seen[spot.index] = true
			elif spot.is_home():
				if home_seen.has(spot.index):
					return false
				home_seen[spot.index] = true
	return true
