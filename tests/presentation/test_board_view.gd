extends TestCase
## The hand-built arm scene has to agree with the rules' board graph for
## every board size: every track space has a hole, neighbours are one hole
## apart, and nothing overlaps.

const BOARD_SCENE := preload("res://board/board.tscn")


func build_board(seat_count: int) -> BoardView:
	var tree := Engine.get_main_loop() as SceneTree
	var board := BOARD_SCENE.instantiate() as BoardView
	tree.root.add_child(board)
	board.build(Match.create_standard(RuleSet.new(), seat_count, 1).state)
	return board


func free_board(board: BoardView) -> void:
	board.get_parent().remove_child(board)
	board.free()


func test_every_track_space_has_a_hole_one_step_from_the_next() -> void:
	for seat_count: int in [2, 3, 4, 5, 6, 8]:
		var board := build_board(seat_count)
		var length: int = BoardTopology.SEGMENT_LENGTH * (4 if seat_count == 2 else seat_count)
		assert_eq(board.track_hole_count(), length, "%d players" % seat_count)
		for i: int in length:
			var here: Vector3 = board.track_hole(i).global_position
			var next: Vector3 = board.track_hole((i + 1) % length).global_position
			assert_true(absf(here.distance_to(next) - 1.0) < 0.01,
					"%d players: track %d -> %d is %.2f apart" % [seat_count, i, i + 1, here.distance_to(next)])
		free_board(board)


func test_home_base_starts_one_step_past_its_entrance() -> void:
	var board := build_board(4)
	var state := Match.create_standard(RuleSet.new(), 4, 1).state
	for seat: int in 4:
		var entrance: Vector3 = board.track_hole(state.topology.home_entrance(seat)).global_position
		var home0: Vector3 = board.hole_for(seat, 0, Spot.home(0)).global_position
		assert_true(absf(entrance.distance_to(home0) - 1.0) < 0.01, "seat %d" % seat)
	free_board(board)


func test_holes_do_not_overlap() -> void:
	for seat_count: int in [3, 4, 6, 8]:
		var board := build_board(seat_count)
		var positions: Array[Vector3] = []
		_collect_hole_positions(board, positions)
		var closest: float = INF
		for i: int in positions.size():
			for j: int in range(i + 1, positions.size()):
				closest = minf(closest, positions[i].distance_to(positions[j]))
		# Eight arms squeeze the holes next to the hub; everything else is >= 1.
		assert_true(closest > (0.7 if seat_count == 8 else 0.95), "%d players: closest %.2f" % [seat_count, closest])
		free_board(board)


func test_marbles_start_in_their_starting_blocks() -> void:
	var board := build_board(4)
	var state := Match.create_standard(RuleSet.new(), 4, 1).state
	for p: PlayerState in state.players:
		for i: int in p.marbles.size():
			var ref := MarbleRef.new(p.seat, i)
			var expected: Vector3 = board.hole_for(p.seat, i, Spot.starting_block()).global_position
			assert_true(board.marble_view(ref).global_position.distance_to(expected) < 0.3)
	free_board(board)


func _collect_hole_positions(node: Node, out: Array[Vector3]) -> void:
	for child: Node in node.get_children():
		if child is BoardHole:
			out.append((child as BoardHole).global_position)
		_collect_hole_positions(child, out)
