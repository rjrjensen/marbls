extends Node
## Saves a picture of the game table, to check the board's look without
## clicking through the game. Runs the real game scene.
##
##   godot --resolution 720x1280 res://tools/board_shot.tscn -- --seats 6 --screenshot /path/to/board.png

const GAME_SCENE := preload("res://game/game.tscn")


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var seats_at: int = args.find("--seats")
	var seat_count: int = int(args[seats_at + 1]) if seats_at != -1 and seats_at + 1 < args.size() else 4
	var shot_at: int = args.find("--screenshot")
	var game := GAME_SCENE.instantiate() as GameController
	game.ai_think_seconds = 60.0
	add_child(game)
	game.new_game(seat_count, 1, false, true)
	if shot_at != -1 and shot_at + 1 < args.size():
		_save_screenshot.call_deferred(args[shot_at + 1])


func _save_screenshot(path: String) -> void:
	for i: int in 10:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
