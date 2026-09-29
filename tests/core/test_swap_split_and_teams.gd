extends RulesTestCase
## Jack swap, Seven split and teams, as decided in docs/DESIGN.md.


# --- Jack swap -----------------------------------------------------------------

func test_jack_swaps_with_track_and_bulls_eye_marbles_only() -> void:
	place(0, 0, Spot.track(10))
	place(1, 0, Spot.track(30))
	place(2, 0, Spot.bulls_eye())
	place(3, 0, Spot.home(2))  # safe in Home Base
	var swaps: Array[String] = []
	for move: Move in moves_for(0, Card.Rank.JACK):
		if move.kind == Move.Kind.SWAP:
			swaps.append("%s<->%s" % [move.steps[0].marble, move.steps[1].marble])
			assert_true(move.kills().is_empty())
	assert_eq(sorted(swaps), sorted(["seat0/m0<->seat1/m0", "seat0/m0<->seat2/m0"] as Array[String]))


func test_a_swap_onto_a_corner_puts_the_marble_on_the_fast_track() -> void:
	var game := _match_with_top_cards([Card.Rank.JACK])
	game.state.player(0).marbles[0] = Spot.track(10)
	game.state.player(1).marbles[0] = Spot.track(33)
	game.submit(MatchIntent.draw_card(0))
	for index: int in game.legal_moves().size():
		if game.legal_moves()[index].kind == Move.Kind.SWAP:
			game.submit(MatchIntent.choose_move(0, index))
			break
	assert_true(game.state.player(0).fast_track_ready[0])


func test_a_swap_trades_places() -> void:
	var game := _match_with_top_cards([Card.Rank.JACK])
	game.state.player(0).marbles[0] = Spot.track(10)
	game.state.player(1).marbles[0] = Spot.track(30)
	game.submit(MatchIntent.draw_card(0))
	for index: int in game.legal_moves().size():
		if game.legal_moves()[index].kind == Move.Kind.SWAP:
			game.submit(MatchIntent.choose_move(0, index))
			break
	assert_true(game.state.player(0).marbles[0].equals(Spot.track(30)))
	assert_true(game.state.player(1).marbles[0].equals(Spot.track(10)))


# --- Seven split ---------------------------------------------------------------

func test_seven_splits_between_two_marbles_and_both_halves_can_kill() -> void:
	place(0, 0, Spot.track(10))
	place(0, 1, Spot.track(20))
	place(1, 0, Spot.track(13))
	place(1, 1, Spot.track(24))
	var found: bool = false
	for move: Move in moves_for(0, Card.Rank.SEVEN):
		if move.kind == Move.Kind.SPLIT and move.kills().size() == 2:
			found = true
	assert_true(found, "3 + 4 kills both blue marbles")


func test_both_halves_can_go_into_home_base() -> void:
	place(0, 0, Spot.track(53))
	place(0, 1, Spot.track(54))
	var found: bool = false
	for move: Move in moves_for(0, Card.Rank.SEVEN):
		if move.kind == Move.Kind.SPLIT and move.steps[0].to.is_home() and move.steps[1].to.is_home():
			found = true
	assert_true(found)


func test_split_uses_exactly_seven_and_never_two_opponents() -> void:
	place(0, 0, Spot.track(10))
	place(1, 0, Spot.track(30))
	for move: Move in moves_for(0, Card.Rank.SEVEN):
		if move.kind == Move.Kind.SPLIT:
			fail("only one of my marbles is out, and blue isn't my teammate")


func test_split_with_a_teammate() -> void:
	rules.team_of_seat = RuleSet.opposite_partners(4)
	place(0, 0, Spot.track(10))
	place(2, 0, Spot.track(40))  # yellow is red's partner
	place(1, 0, Spot.track(30))
	var partners: int = 0
	for move: Move in moves_for(0, Card.Rank.SEVEN):
		if move.kind == Move.Kind.SPLIT:
			var seats: Array[int] = [move.steps[0].marble.seat, move.steps[1].marble.seat]
			assert_false(seats.has(1), "blue is an opponent")
			partners += 1
	assert_eq(partners, 6, "1+6 .. 6+1 (the same split in the other order is the same choice)")


# --- Teams ---------------------------------------------------------------------

func test_a_finished_player_moves_their_partners_marbles() -> void:
	rules.team_of_seat = RuleSet.opposite_partners(4)
	for i: int in 4:
		place(0, i, Spot.home(i))
	assert_eq(generator.controlled_seats(state, 0), [2] as Array[int])
	var moves := moves_for(0, Card.Rank.ACE)
	assert_eq(moves.size(), 1)
	assert_eq(moves[0].steps[0].marble.seat, 2, "starts yellow's marble")


func test_a_team_wins_only_when_every_partner_is_home() -> void:
	var team_rules := RuleSet.new()
	team_rules.cut_for_first_seat = false
	team_rules.team_of_seat = RuleSet.opposite_partners(4)
	var game := Match.create_standard(team_rules, 4, 5)
	game.start()
	var red: PlayerState = game.state.player(0)
	for i: int in 3:
		red.marbles[i] = Spot.home(i + 1)
	red.marbles[3] = Spot.track(53)
	red.deck.draw_pile.append(Card.new(Card.Rank.TWO, Card.Suit.CLUBS))
	game.submit(MatchIntent.draw_card(0))
	game.submit(MatchIntent.choose_move(0, _index_to(game, Spot.home(0))))
	assert_eq(game.state.finished_seats, [0] as Array[int])
	assert_true(game.state.phase != GameState.Phase.GAME_OVER, "yellow isn't home yet")


func test_random_games_with_every_rule_and_teams_finish() -> void:
	for seat_count: int in [4, 6]:
		for seed_value: int in [1, 2]:
			var team_rules := RuleSet.new()
			team_rules.team_of_seat = RuleSet.opposite_partners(seat_count)
			var game := Match.create_standard(team_rules, seat_count, seed_value)
			game.start()
			var driver := RandomNumberGenerator.new()
			driver.seed = seed_value
			var steps: int = 0
			while game.state.phase != GameState.Phase.GAME_OVER and steps < 60000:
				var seat: int = game.state.current_seat
				if game.state.phase == GameState.Phase.AWAITING_MOVE:
					game.submit(MatchIntent.choose_move(seat, driver.randi_range(0, game.legal_moves().size() - 1)))
				else:
					game.submit(MatchIntent.draw_card(seat))
				steps += 1
			assert_eq(game.state.phase, GameState.Phase.GAME_OVER, "%d seats, seed %d" % [seat_count, seed_value])
			assert_eq(game.state.winners.size(), 2 if seat_count > 0 else 0)
			for winner: int in game.state.winners:
				assert_true(game.state.player(winner).is_finished())
