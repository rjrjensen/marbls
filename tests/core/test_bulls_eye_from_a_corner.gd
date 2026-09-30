extends RulesTestCase
## Dropping into the Bull's Eye from a Fast Track corner and killing whoever is
## there, as described in docs/RULES.md ("Bull's Eye").


func test_sitting_on_a_corner_with_a_one_space_card_can_drop_into_the_bulls_eye() -> void:
	place(0, 0, Spot.track(5))
	assert_eq(destinations_of(moves_for(0, Card.Rank.ACE), MarbleRef.new(0, 0)),
			sorted(["bulls-eye", "track:6"] as Array[String]))


func test_every_one_space_card_can_drop_in_from_a_corner() -> void:
	for rank: Card.Rank in [Card.Rank.JACK, Card.Rank.QUEEN, Card.Rank.KING, Card.Rank.JOKER]:
		place(0, 0, Spot.track(19))
		assert_true("bulls-eye" in destinations_of(moves_for(0, rank), MarbleRef.new(0, 0)), str(rank))


func test_a_marble_with_a_fast_track_chance_can_also_drop_in_with_a_one_space_card() -> void:
	place(0, 0, Spot.track(5))
	state.player(0).fast_track_ready[0] = true
	assert_eq(destinations_of(moves_for(0, Card.Rank.ACE), MarbleRef.new(0, 0)),
			sorted(["bulls-eye", "track:6", "track:19"] as Array[String]))


func test_sitting_on_a_corner_with_a_longer_card_does_not_drop_in() -> void:
	place(0, 0, Spot.track(5))
	assert_eq(destinations_of(moves_for(0, Card.Rank.TWO), MarbleRef.new(0, 0)), ["track:7"] as Array[String])


func test_sitting_on_your_own_corner_with_a_one_space_card_walks_on() -> void:
	place(0, 0, Spot.track(47))
	assert_eq(destinations_of(moves_for(0, Card.Rank.ACE), MarbleRef.new(0, 0)), ["track:48"] as Array[String])


func test_a_marble_off_the_corner_does_not_drop_in_with_a_one_space_card() -> void:
	place(0, 0, Spot.track(4))
	assert_eq(destinations_of(moves_for(0, Card.Rank.ACE), MarbleRef.new(0, 0)), ["track:5"] as Array[String])


func test_dropping_in_from_a_corner_kills_whoever_is_in_the_bulls_eye() -> void:
	place(0, 0, Spot.track(5))
	place(2, 0, Spot.bulls_eye())
	var victims: Array[String] = []
	for move: Move in moves_for(0, Card.Rank.ACE):
		if move.steps[0].to.kind == Spot.Kind.BULLS_EYE:
			for victim: MarbleRef in move.kills():
				victims.append(str(victim))
	assert_eq(victims.size(), 1, "one kill")
	assert_eq(victims[0], str(MarbleRef.new(2, 0)))


func test_a_teammate_in_the_bulls_eye_is_killed_too() -> void:
	var team_rules := RuleSet.new()
	team_rules.team_of_seat = PackedInt32Array([0, 1, 0, 1])
	var team_generator := MoveGenerator.new(team_rules)
	place(0, 0, Spot.track(5))
	place(2, 0, Spot.bulls_eye())
	var found: bool = false
	for move: Move in team_generator.legal_moves(state, 0, Card.new(Card.Rank.ACE, Card.Suit.SPADES)):
		if move.steps[0].to.kind == Spot.Kind.BULLS_EYE:
			found = true
			assert_eq(move.kills().size(), 1)
	assert_true(found)


func test_a_match_lets_a_marble_on_a_corner_drop_in_and_kill() -> void:
	var game := _match_with_top_cards([Card.Rank.ACE])
	game.state.player(0).marbles[0] = Spot.track(5)
	game.state.player(2).marbles[1] = Spot.bulls_eye()
	game.submit(MatchIntent.draw_card(0))
	var index: int = _index_to(game, Spot.bulls_eye())
	assert_true(index >= 0, "the Bull's Eye is offered")
	game.submit(MatchIntent.choose_move(0, index))
	assert_true(game.state.player(0).marbles[0].kind == Spot.Kind.BULLS_EYE)
	assert_true(game.state.player(2).marbles[1].is_starting_block(), "the victim went back to its Starting Block")
