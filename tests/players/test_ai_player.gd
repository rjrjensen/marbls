extends TestCase
## The personalities should play like the people they're named after.

var rules := RuleSet.new()
var state: GameState = Match.create_standard(rules, 4, 1).state
var generator := MoveGenerator.new(rules)


func place(seat: int, marble: int, spot: Spot) -> void:
	state.player(seat).marbles[marble] = spot


func pick(profile_name: String, rank: Card.Rank) -> Move:
	var moves: Array[Move] = generator.legal_moves(state, 0, Card.new(rank, Card.Suit.SPADES))
	var ai := AIPlayer.new(AIPresets.named(profile_name), rules, 1)
	return moves[ai.choose_move(state, 0, moves)]


func test_every_preset_loads() -> void:
	for profile: AIProfile in AIPresets.PROFILES:
		assert_true(profile.display_name != "", "preset without a name")
	assert_not_null(AIPresets.named("Jordan"))


## Blue's marble just left its Starting Block (worth little). Red can kill it,
## or put a marble safely into Home Base.
func _kill_or_home() -> void:
	place(0, 0, Spot.track(12))
	place(1, 0, Spot.track(14))  # Blue just came out
	place(0, 1, Spot.track(53))  # a Two takes it into Red's Home Base


func test_jordan_goes_for_the_kill_even_when_pointless() -> void:
	_kill_or_home()
	assert_eq(pick("Jordan", Card.Rank.TWO).kills().size(), 1)


func test_kelsey_keeps_the_goal_in_mind() -> void:
	_kill_or_home()
	var move: Move = pick("Kelsey", Card.Rank.TWO)
	assert_true(move.steps[0].to.is_home(), "Kelsey secures the marble in Home Base: %s" % move)


func test_kelsey_takes_a_kill_that_matters() -> void:
	place(0, 0, Spot.track(40))
	place(1, 0, Spot.track(42))  # Blue is almost home (Blue's entrance is 12)
	place(1, 1, Spot.track(0))
	var move: Move = pick("Kelsey", Card.Rank.TWO)
	assert_eq(move.kills().size(), 1)


func test_the_turtle_stays_out_of_reach() -> void:
	# Either marble can move 3. Moving the one at 18 would land it right in
	# front of Blue at 20; moving the one at 40 keeps everything safe.
	place(0, 0, Spot.track(18))
	place(0, 1, Spot.track(40))
	place(1, 0, Spot.track(20))
	assert_eq(pick("The Turtle", Card.Rank.THREE).steps[0].marble.marble, 1)


func test_lookahead_counts_the_cards_it_has_played() -> void:
	var deck := Deck.standard(2)
	# Everything but the Fours has been played.
	for i: int in range(deck.draw_pile.size() - 1, -1, -1):
		if deck.draw_pile[i].rank != Card.Rank.FOUR:
			deck.discard(deck.draw_pile.pop_at(i))
	var perfect := LookaheadEvaluator.new(1.0)
	var odds: Dictionary[int, float] = perfect.expected_next_card_odds(deck, rules)
	assert_true(absf(odds[Card.Rank.FOUR] - 1.0) < 0.001)
	var forgetful := LookaheadEvaluator.new(0.0)
	odds = forgetful.expected_next_card_odds(deck, rules)
	assert_true(absf(odds[Card.Rank.FOUR] - 4.0 / 54.0) < 0.001)


func test_the_grandmaster_saves_the_four_it_knows_is_coming() -> void:
	# Only Fours are left in Red's deck. A marble on its Starting Exit can back
	# up 4 to just short of Home Base, so with a Three the Grandmaster moves the
	# other marble and keeps that shortcut. (Without look-ahead it's a tie.)
	var deck: Deck = state.player(0).deck
	for i: int in range(deck.draw_pile.size() - 1, -1, -1):
		if deck.draw_pile[i].rank != Card.Rank.FOUR:
			deck.discard(deck.draw_pile.pop_at(i))
	place(0, 0, Spot.track(0))
	place(0, 1, Spot.track(31))
	assert_eq(pick("The Grandmaster", Card.Rank.THREE).steps[0].marble.marble, 1)


func test_ai_games_always_finish() -> void:
	for seed_value: int in [1, 2, 3]:
		var result: Dictionary = AISimulation.play(4, seed_value, false)
		assert_true(result["finished"], "seed %d" % seed_value)


func test_jordan_kills_more_than_the_turtle() -> void:
	var jordan_kills: int = 0
	var turtle_kills: int = 0
	for seed_value: int in range(1, 7):
		var result: Dictionary = AISimulation.play(4, seed_value, false, ["Jordan", "The Turtle", "Jordan", "The Turtle"])
		var kills: Array = result["kills_by_seat"]
		jordan_kills += int(kills[0]) + int(kills[2])
		turtle_kills += int(kills[1]) + int(kills[3])
	assert_true(jordan_kills > turtle_kills, "Jordan %d vs Turtle %d" % [jordan_kills, turtle_kills])


func test_sitting_on_an_opponents_starting_exit_is_dangerous() -> void:
	place(0, 0, Spot.track(14))  # Blue's Starting Exit; Blue still has marbles to bring out
	var exposed: float = BoardMetrics.danger(state, 0, rules)
	place(0, 0, Spot.track(16))
	assert_true(exposed > BoardMetrics.danger(state, 0, rules))
