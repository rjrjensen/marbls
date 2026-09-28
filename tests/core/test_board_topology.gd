extends TestCase
## Checks the numbering against the README's ASCII board (4 arms, 56 spaces).


func test_classic_board_has_56_track_spaces() -> void:
	assert_eq(BoardTopology.new(4).track_length(), 56)


func test_exits_entrances_and_corners() -> void:
	var board := BoardTopology.new(4)
	assert_eq(board.starting_exit(0), 0)
	assert_eq(board.starting_exit(1), 14)
	assert_eq(board.home_entrance(0), 54, "two spaces counterclockwise of the exit")
	assert_eq(board.home_entrance(1), 12)
	assert_eq(board.own_fast_track_corner(1), 5)
	assert_eq(board.own_fast_track_corner(0), 47)
	for corner: int in [5, 19, 33, 47]:
		assert_true(board.is_fast_track_corner(corner))
	assert_false(board.is_fast_track_corner(0))


func test_a_marble_turns_into_its_own_home_base_only() -> void:
	var board := BoardTopology.new(4)
	assert_true(board.next_forward(0, Spot.track(54)).equals(Spot.home(0)))
	assert_true(board.next_forward(1, Spot.track(54)).equals(Spot.track(55)), "not arm 1's entrance")
	assert_true(board.next_forward(0, Spot.track(55)).equals(Spot.track(0)), "wraps around")


func test_home_base_ends_and_never_goes_backward() -> void:
	var board := BoardTopology.new(4)
	assert_true(board.next_forward(0, Spot.home(2)).equals(Spot.home(3)))
	assert_null(board.next_forward(0, Spot.home(3)))
	assert_null(board.next_backward(0, Spot.home(1)))


func test_backward_moves_pass_the_home_entrance() -> void:
	var board := BoardTopology.new(4)
	assert_true(board.next_backward(0, Spot.track(0)).equals(Spot.track(55)))
	assert_true(board.next_backward(0, Spot.track(55)).equals(Spot.track(54)))
	assert_true(board.next_backward(0, Spot.track(54)).equals(Spot.track(53)))


func test_six_arm_board() -> void:
	var board := BoardTopology.new(6)
	assert_eq(board.track_length(), 84)
	assert_eq(board.home_entrance(0), 82)
	assert_eq(board.starting_exit(5), 70)
