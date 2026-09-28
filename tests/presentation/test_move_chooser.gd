extends TestCase
## Picking a move one marble at a time.

var rules := RuleSet.new()
var state: GameState = Match.create_standard(rules, 4, 1).state
var generator := MoveGenerator.new(rules)


func test_a_simple_move_is_one_tap() -> void:
	var moves: Array[Move] = generator.legal_moves(state, 0, Card.new(Card.Rank.ACE))
	var chooser := MoveChooser.new()
	chooser.reset(moves)
	var choices: Array[MoveChoice] = chooser.choices()
	assert_eq(choices.size(), 1)
	assert_eq(chooser.pick(choices[0]), 0)


func test_a_forced_second_half_needs_no_second_tap() -> void:
	state.player(0).marbles[0] = Spot.track(10)
	state.player(0).marbles[1] = Spot.track(40)
	var moves: Array[Move] = generator.legal_moves(state, 0, Card.new(Card.Rank.SEVEN))
	var chooser := MoveChooser.new()
	chooser.reset(moves)
	# Marble 0 moves 3 (to 13); marble 1 can only take the other 4 (to 44).
	var index: int = chooser.pick(_find(chooser.choices(), MarbleRef.new(0, 0), Spot.track(13)))
	assert_true(index >= 0)
	assert_true(moves[index].steps[1].to.equals(Spot.track(44)))


func test_a_split_seven_with_a_real_second_choice_takes_two_taps() -> void:
	state.player(0).marbles[0] = Spot.track(10)
	state.player(0).marbles[1] = Spot.track(30)
	var moves: Array[Move] = generator.legal_moves(state, 0, Card.new(Card.Rank.SEVEN))
	var chooser := MoveChooser.new()
	chooser.reset(moves)
	# Marble 0 moves 3; marble 1's 4 reaches corner 33 with one step left, so
	# it can go on to 34 or drop into the Bull's Eye.
	assert_eq(chooser.pick(_find(chooser.choices(), MarbleRef.new(0, 0), Spot.track(13))), -1)
	assert_eq(chooser.depth(), 1)
	var seconds: Array[MoveChoice] = chooser.choices()
	assert_eq(seconds.size(), 2)
	var index: int = chooser.pick(_find(seconds, MarbleRef.new(0, 1), Spot.bulls_eye()))
	assert_true(index >= 0)
	assert_eq(moves[index].steps[1].to.kind, Spot.Kind.BULLS_EYE)


func test_the_whole_seven_on_one_marble_is_still_one_tap() -> void:
	state.player(0).marbles[0] = Spot.track(10)
	state.player(0).marbles[1] = Spot.track(40)
	var moves: Array[Move] = generator.legal_moves(state, 0, Card.new(Card.Rank.SEVEN))
	var chooser := MoveChooser.new()
	chooser.reset(moves)
	var whole: MoveChoice = _find(chooser.choices(), MarbleRef.new(0, 0), Spot.track(17))
	var index: int = chooser.pick(whole)
	assert_true(index >= 0)
	assert_eq(moves[index].steps.size(), 1)


func test_focusing_a_starting_block_marble_offers_the_start() -> void:
	state.player(0).marbles[0] = Spot.track(10)
	var moves: Array[Move] = generator.legal_moves(state, 0, Card.new(Card.Rank.SIX))
	var chooser := MoveChooser.new()
	chooser.reset(moves)
	chooser.focus_marble(MarbleRef.new(0, 3), true)
	var choices: Array[MoveChoice] = chooser.choices()
	assert_eq(choices.size(), 1)
	assert_true(choices[0].to.equals(Spot.track(0)))


func _find(choices: Array[MoveChoice], ref: MarbleRef, to: Spot) -> MoveChoice:
	for choice: MoveChoice in choices:
		if choice.marble.equals(ref) and choice.to.equals(to):
			return choice
	return null
