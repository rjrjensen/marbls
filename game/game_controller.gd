class_name GameController
extends Node
## Runs a hot-seat game: owns the match host, plays its events on the board
## one at a time, and turns taps into intents.
##
## Children only get told what to show (passed down) and report taps
## (signaled up). Every event is also forwarded to the SignalBus.

## Off in tests: everything snaps into place instantly.
@export var animate: bool = true
@export var default_seat_count: int = 4

var _host: LocalMatchHost
var _queue: Array[MatchEvent] = []
var _busy: bool = false

@onready var _board: BoardView = $Board
@onready var _camera: BoardCamera = $BoardCamera
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_hud.draw_pressed.connect(press_draw)
	_hud.new_game_requested.connect(func(seat_count: int) -> void: new_game(seat_count, randi()))
	_board.ghost_tapped.connect(choose)
	_board.marble_tapped.connect(_on_marble_tapped)
	new_game(default_seat_count, randi())


func new_game(seat_count: int, seed_value: int) -> void:
	_queue.clear()
	_busy = false
	var game := Match.create_standard(RuleSet.new(), seat_count, seed_value)
	_host = LocalMatchHost.new(game)
	_host.events_emitted.connect(_on_events)
	_board.build(_host.state())
	_camera.frame(_board.radius())
	_hud.show_card(null)
	_hud.show_message("Tap Draw to start")
	_host.start()


func state() -> GameState:
	return _host.state()


func legal_moves() -> Array[Move]:
	return _host.legal_moves()


## Draws for whoever's turn it is, if drawing is allowed right now.
func press_draw() -> void:
	if _busy or state().phase != GameState.Phase.AWAITING_DRAW:
		return
	_board.clear_choices()
	_host.submit(MatchIntent.draw_card(state().current_seat))


## Plays the legal move at [param move_index].
func choose(move_index: int) -> void:
	if _busy or state().phase != GameState.Phase.AWAITING_MOVE:
		return
	_board.clear_choices()
	_host.submit(MatchIntent.choose_move(state().current_seat, move_index))


func is_busy() -> bool:
	return _busy


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		press_draw()


func _on_events(events: Array[MatchEvent]) -> void:
	_queue.append_array(events)
	if not _busy:
		_play_queue()


func _play_queue() -> void:
	_busy = true
	_hud.set_draw_enabled(false)
	while not _queue.is_empty():
		var event: MatchEvent = _queue.pop_front()
		SignalBus.match_event.emit(event)
		await _present(event)
	_busy = false
	_ready_for_input()


func _present(event: MatchEvent) -> void:
	var seat_name: String = SeatColors.display_name(event.seat) if event.seat >= 0 else ""
	match event.kind:
		MatchEvent.Kind.TURN_STARTED:
			_hud.show_turn(seat_name, SeatColors.color(event.seat))
			_hud.show_deck_count(state().player(event.seat).deck.draw_pile.size())
			await _camera.face(_board.arm_direction(state().player(event.seat).arm), animate)
		MatchEvent.Kind.DECK_RESHUFFLED:
			_hud.show_message("Out of cards: reshuffled the deck")
		MatchEvent.Kind.CARD_DRAWN:
			_hud.show_card(event.card)
			_hud.show_deck_count(state().player(event.seat).deck.draw_pile.size())
			_hud.show_message("")
		MatchEvent.Kind.NO_LEGAL_MOVE:
			_hud.show_message("No move with that card")
			await _pause(1.0)
		MatchEvent.Kind.MARBLE_MOVED:
			await _board.play_step(event.step, animate)
		MatchEvent.Kind.MARBLE_KILLED:
			_hud.show_message("%s killed %s's marble!" % [seat_name, SeatColors.display_name(event.victim.seat)])
			if animate:
				_camera.shake()
			await _board.play_kill(event.victim, state(), animate)
		MatchEvent.Kind.PLAY_AGAIN:
			_hud.show_message("Play again!")
		MatchEvent.Kind.GAME_OVER:
			var names: PackedStringArray = []
			for winner: int in event.winners:
				names.append(SeatColors.display_name(winner))
			_hud.show_game_over("%s wins!" % " & ".join(names))
		MatchEvent.Kind.INTENT_REJECTED:
			_hud.show_message(event.reason)


func _ready_for_input() -> void:
	match state().phase:
		GameState.Phase.AWAITING_DRAW:
			_hud.set_draw_enabled(true)
		GameState.Phase.AWAITING_MOVE:
			_hud.show_message("Tap a glowing ghost marble to move")
			_board.show_choices(legal_moves(), _all_move_indices())


func _on_marble_tapped(ref: MarbleRef) -> void:
	if _busy or state().phase != GameState.Phase.AWAITING_MOVE:
		return
	var indices: Array[int] = []
	var tapped_in_block: bool = state().spot_of(ref).is_starting_block()
	for index: int in legal_moves().size():
		var step: MarbleStep = legal_moves()[index].steps[0]
		var same_marble: bool = step.marble.equals(ref)
		var starts_from_same_block: bool = tapped_in_block and step.from.is_starting_block() \
				and step.marble.seat == ref.seat
		if same_marble or starts_from_same_block:
			indices.append(index)
	# Tapping a marble that can't move shows every choice again.
	_board.show_choices(legal_moves(), indices if not indices.is_empty() else _all_move_indices())


func _all_move_indices() -> Array[int]:
	var indices: Array[int] = []
	for index: int in legal_moves().size():
		indices.append(index)
	return indices


func _pause(seconds: float) -> void:
	if animate:
		await get_tree().create_timer(seconds).timeout
