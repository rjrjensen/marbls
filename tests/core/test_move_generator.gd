extends TestCase
## Movement rules from the README. Classic 4-player board: seat N sits at arm
## N, so seat 0 exits at track 0 and turns into Home Base after track 54.

var rules := RuleSet.new()
var state: GameState = Match.create_standard(rules, 4, 1).state
var generator := MoveGenerator.new(rules)


func place(seat: int, marble: int, spot: Spot) -> void:
	state.player(seat).marbles[marble] = spot


func moves_for(seat: int, rank: Card.Rank) -> Array[Move]:
	return generator.legal_moves(state, seat, Card.new(rank, Card.Suit.SPADES))


func destinations(moves: Array[Move]) -> Array[String]:
	var out: Array[String] = []
	for move: Move in moves:
		out.append(str(move.steps[0].to))
	return out


func test_ace_starts_one_marble() -> void:
	var moves := moves_for(0, Card.Rank.ACE)
	assert_eq(moves.size(), 1)
	assert_eq(moves[0].kind, Move.Kind.START)
	assert_true(moves[0].steps[0].to.equals(Spot.track(0)))


func test_two_cannot_start() -> void:
	assert_eq(moves_for(0, Card.Rank.TWO).size(), 0)


func test_own_marble_on_the_exit_blocks_starting() -> void:
	place(0, 0, Spot.track(0))
	var moves := moves_for(0, Card.Rank.ACE)
	assert_eq(destinations(moves), ["track:1"] as Array[String], "only the forward move remains")


func test_opponent_on_the_exit_blocks_starting_under_the_strict_rule() -> void:
	rules.starting_exit_must_be_empty = true
	place(1, 0, Spot.track(0))
	assert_eq(moves_for(0, Card.Rank.SIX).size(), 0)


func test_starting_kills_an_opponent_on_the_exit() -> void:
	place(1, 0, Spot.track(0))
	var moves := moves_for(0, Card.Rank.JOKER)
	assert_eq(moves.size(), 1)
	assert_eq(moves[0].kills().size(), 1)
	assert_true(moves[0].kills()[0].equals(MarbleRef.new(1, 0)))


func test_cannot_land_on_or_hop_own_marble() -> void:
	place(0, 0, Spot.track(3))
	place(0, 1, Spot.track(1))
	assert_eq(destinations(moves_for(0, Card.Rank.TWO)), ["track:5"] as Array[String], "m1 would land on m0")
	assert_eq(destinations(moves_for(0, Card.Rank.FIVE)), ["track:8"] as Array[String], "m1 would hop m0")


func test_landing_on_another_color_kills_but_passing_does_not() -> void:
	place(0, 0, Spot.track(2))
	place(1, 0, Spot.track(5))
	var kill := moves_for(0, Card.Rank.THREE)
	assert_eq(kill[0].kills().size(), 1)
	var passing := moves_for(0, Card.Rank.FIVE)
	assert_true(passing[0].steps[0].to.equals(Spot.track(7)))
	assert_eq(passing[0].kills().size(), 0)


func test_teammates_can_be_killed_too() -> void:
	place(0, 0, Spot.track(20))
	place(2, 0, Spot.track(22))
	assert_eq(moves_for(0, Card.Rank.TWO)[0].kills().size(), 1)


func test_entering_home_base_needs_an_exact_fit() -> void:
	place(0, 0, Spot.track(53))
	assert_eq(destinations(moves_for(0, Card.Rank.FIVE)), ["home:3"] as Array[String])
	assert_eq(moves_for(0, Card.Rank.SEVEN).size(), 0, "past the end of Home Base")


func test_cannot_hop_own_marble_inside_home_base() -> void:
	place(0, 0, Spot.track(54))
	place(0, 1, Spot.home(1))
	assert_eq(destinations(moves_for(0, Card.Rank.THREE)), [] as Array[String])
	assert_eq(destinations(moves_for(0, Card.Rank.TWO)), ["home:3"] as Array[String], "only m1 can move 2")


func test_opponents_pass_by_a_home_entrance() -> void:
	place(1, 0, Spot.track(53))
	assert_eq(destinations(moves_for(1, Card.Rank.TWO)), ["track:55"] as Array[String])


func test_home_base_marbles_never_move_backward() -> void:
	place(0, 0, Spot.home(2))
	assert_eq(moves_for(0, Card.Rank.FOUR).size(), 0)


func test_four_backward_past_the_exit_then_forward_into_home() -> void:
	place(0, 0, Spot.track(1))
	var back := moves_for(0, Card.Rank.FOUR)
	assert_eq(back[0].kind, Move.Kind.BACKWARD)
	assert_true(back[0].steps[0].to.equals(Spot.track(53)))
	place(0, 0, Spot.track(53))
	assert_eq(destinations(moves_for(0, Card.Rank.TWO)), ["home:0"] as Array[String], "no full lap needed")


func test_four_backward_can_kill() -> void:
	place(0, 0, Spot.track(10))
	place(2, 0, Spot.track(6))
	assert_eq(moves_for(0, Card.Rank.FOUR)[0].kills().size(), 1)


func test_resolver_sends_the_victim_home_to_its_starting_block() -> void:
	place(0, 0, Spot.track(2))
	place(1, 0, Spot.track(5))
	var events: Array[MatchEvent] = MoveResolver.new().apply(state, moves_for(0, Card.Rank.THREE)[0])
	assert_true(state.spot_of(MarbleRef.new(0, 0)).equals(Spot.track(5)))
	assert_true(state.spot_of(MarbleRef.new(1, 0)).is_starting_block())
	assert_eq(events.size(), 2)
	assert_eq(events[1].kind, MatchEvent.Kind.MARBLE_KILLED)
	assert_true(events[1].victim_from.equals(Spot.track(5)))
