extends TestCase
## Drives the real game scene (animations off) through a few hundred intents
## and checks the board always shows what the rules say.

const GAME_SCENE := preload("res://game/game.tscn")


func test_the_board_always_matches_the_game_state() -> void:
	_play_and_check(false)


func test_the_board_matches_in_a_team_game_too() -> void:
	_play_and_check(true)


func _play_and_check(teams: bool) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var game := GAME_SCENE.instantiate() as GameController
	game.animate = false
	tree.root.add_child(game)
	game.new_game(4, 21, teams)

	var board := game.get_node("Board") as BoardView
	var driver := RandomNumberGenerator.new()
	driver.seed = 3
	for i: int in 600:
		if game.state().phase == GameState.Phase.GAME_OVER:
			break
		if game.state().phase == GameState.Phase.AWAITING_DRAW:
			game.press_draw()
		else:
			game.choose(driver.randi_range(0, game.legal_moves().size() - 1))
		assert_false(game.is_busy(), "instant mode never waits")
		for p: PlayerState in game.state().players:
			for m: int in p.marbles.size():
				var ref := MarbleRef.new(p.seat, m)
				var expected: Vector3 = board.rest_position(ref, p.marbles[m])
				if board.marble_view(ref).global_position.distance_to(expected) > 0.01:
					fail("step %d: %s is drawn in the wrong place" % [i, ref])
					return
	tree.root.remove_child(game)
	game.free()


func test_new_game_rebuilds_for_a_different_player_count() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var game := GAME_SCENE.instantiate() as GameController
	game.animate = false
	tree.root.add_child(game)
	game.new_game(6, 1)
	var board := game.get_node("Board") as BoardView
	assert_eq(board.track_hole_count(), 84)
	game.new_game(2, 1)
	assert_eq(board.track_hole_count(), 56)
	tree.root.remove_child(game)
	game.free()


func test_computer_opponents_take_their_turns_until_its_yours() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var game := GAME_SCENE.instantiate() as GameController
	game.animate = false
	tree.root.add_child(game)
	game.new_game(4, 8, false, true)
	assert_false(game.is_computer(0))
	assert_true(game.is_computer(1) and game.is_computer(2) and game.is_computer(3))
	var board := game.get_node("Board") as BoardView
	var driver := RandomNumberGenerator.new()
	driver.seed = 4
	for i: int in 500:
		if game.state().phase == GameState.Phase.GAME_OVER:
			break
		assert_eq(game.state().current_seat, 0, "the computers always hand the turn back")
		if game.state().phase == GameState.Phase.AWAITING_DRAW:
			game.press_draw()
		else:
			game.choose(driver.randi_range(0, game.legal_moves().size() - 1))
		for p: PlayerState in game.state().players:
			for m: int in p.marbles.size():
				var ref := MarbleRef.new(p.seat, m)
				if board.marble_view(ref).global_position.distance_to(board.rest_position(ref, p.marbles[m])) > 0.01:
					fail("step %d: %s is drawn in the wrong place" % [i, ref])
					return
	tree.root.remove_child(game)
	game.free()
