extends RulesTestCase
## Fast Track and Bull's Eye, as decided in docs/DESIGN.md.


# --- Fast Track -------------------------------------------------------------

func test_a_ready_marble_can_hop_corners_then_walk() -> void:
	place(0, 0, Spot.track(5))
	state.player(0).fast_track_ready[0] = true
	# Five points: walk 5 (10), hop once then walk 4 (23), hop twice then 3 (36),
	# hop three times to its own corner 47 then walk 2 (49). No hop past 47.
	assert_eq(destinations_of(moves_for(0, Card.Rank.FIVE), MarbleRef.new(0, 0)),
			sorted(["track:10", "track:23", "track:36", "track:49"] as Array[String]))


func test_without_the_chance_there_is_no_fast_track() -> void:
	place(0, 0, Spot.track(5))
	assert_eq(destinations_of(moves_for(0, Card.Rank.FIVE), MarbleRef.new(0, 0)), ["track:10"] as Array[String])


func test_own_marble_on_a_corner_forces_an_early_exit() -> void:
	place(0, 0, Spot.track(5))
	place(0, 1, Spot.track(33))
	state.player(0).fast_track_ready[0] = true
	assert_eq(destinations_of(moves_for(0, Card.Rank.FIVE), MarbleRef.new(0, 0)),
			sorted(["track:10", "track:23"] as Array[String]))


func test_landing_on_a_corner_kills_but_hopping_past_does_not() -> void:
	place(0, 0, Spot.track(5))
	place(1, 0, Spot.track(19))
	state.player(0).fast_track_ready[0] = true
	var kills_on_19: int = 0
	for move: Move in moves_for(0, Card.Rank.TWO):
		if move.steps[0].to.equals(Spot.track(19)):
			kills_on_19 += 1
			assert_eq(move.kills().size(), 1)
		if move.steps[0].to.equals(Spot.track(33)):
			assert_eq(move.kills().size(), 0, "hopped over the blue marble")
	assert_eq(destinations_of(moves_for(0, Card.Rank.ACE), MarbleRef.new(0, 0)),
			sorted(["track:19", "track:6"] as Array[String]))


func test_the_chance_is_granted_by_ending_on_a_corner_and_lost_after_the_next_card() -> void:
	var game := _match_with_top_cards([Card.Rank.FIVE, Card.Rank.TWO])
	var me: PlayerState = game.state.player(0)
	me.marbles[0] = Spot.track(0)
	game.submit(MatchIntent.draw_card(0))  # the Five
	game.submit(MatchIntent.choose_move(0, _index_to(game, Spot.track(5))))
	assert_true(me.fast_track_ready[0], "ended on a corner")
	_pass_to_seat_zero(game)
	game.submit(MatchIntent.draw_card(0))  # the Two
	assert_true(_index_to(game, Spot.track(33)) >= 0, "can hop two corners")
	game.submit(MatchIntent.choose_move(0, _index_to(game, Spot.track(7))))
	assert_false(me.fast_track_ready[0], "walked off instead: the chance is gone")


func test_own_color_corner_gives_no_chance() -> void:
	var game := _match_with_top_cards([Card.Rank.TWO])
	game.state.player(0).marbles[0] = Spot.track(45)
	game.submit(MatchIntent.draw_card(0))
	game.submit(MatchIntent.choose_move(0, _index_to(game, Spot.track(47))))
	assert_false(game.state.player(0).fast_track_ready[0])


func test_a_four_backward_onto_a_corner_gives_a_chance() -> void:
	var game := _match_with_top_cards([Card.Rank.FOUR])
	game.state.player(0).marbles[0] = Spot.track(9)
	game.submit(MatchIntent.draw_card(0))
	game.submit(MatchIntent.choose_move(0, _index_to(game, Spot.track(5))))
	assert_true(game.state.player(0).fast_track_ready[0])


# --- Bull's Eye --------------------------------------------------------------

func test_arriving_at_a_corner_with_one_step_left_can_drop_into_the_bulls_eye() -> void:
	place(0, 0, Spot.track(1))
	assert_eq(destinations_of(moves_for(0, Card.Rank.FIVE), MarbleRef.new(0, 0)),
			sorted(["bulls-eye", "track:6"] as Array[String]))


func test_starting_on_a_corner_is_not_arriving() -> void:
	place(0, 0, Spot.track(5))
	assert_eq(destinations_of(moves_for(0, Card.Rank.ACE), MarbleRef.new(0, 0)), ["track:6"] as Array[String])


func test_a_four_can_back_into_the_bulls_eye() -> void:
	place(0, 0, Spot.track(8))
	assert_eq(destinations_of(moves_for(0, Card.Rank.FOUR), MarbleRef.new(0, 0)),
			sorted(["bulls-eye", "track:4"] as Array[String]))


func test_diving_into_an_occupied_bulls_eye_kills() -> void:
	place(0, 0, Spot.track(1))
	place(2, 0, Spot.bulls_eye())
	for move: Move in moves_for(0, Card.Rank.FIVE):
		if move.steps[0].to.kind == Spot.Kind.BULLS_EYE:
			assert_eq(move.kills().size(), 1)
			return
	fail("no Bull's Eye move")


func test_only_jack_queen_or_king_leave_the_bulls_eye_for_the_own_corner() -> void:
	place(0, 0, Spot.bulls_eye())
	assert_eq(destinations_of(moves_for(0, Card.Rank.ACE), MarbleRef.new(0, 0)), [] as Array[String])
	for rank: Card.Rank in [Card.Rank.JACK, Card.Rank.QUEEN, Card.Rank.KING]:
		assert_eq(destinations_of(moves_for(0, rank), MarbleRef.new(0, 0)), ["track:47"] as Array[String])
