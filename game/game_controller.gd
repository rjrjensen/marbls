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
var _chooser := MoveChooser.new()
var _choices: Array[MoveChoice] = []

@onready var _board: BoardView = $Board
@onready var _camera: BoardCamera = $BoardCamera
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_hud.draw_pressed.connect(press_draw)
	_hud.new_game_requested.connect(
		func(seat_count: int, teams: bool) -> void: new_game(seat_count, randi(), teams)
	)
	_board.ghost_tapped.connect(_on_ghost_tapped)
	_board.marble_tapped.connect(_on_marble_tapped)
	new_game(default_seat_count, randi())


func new_game(seat_count: int, seed_value: int, teams: bool = false) -> void:
	_queue.clear()
	_busy = false
	var rules := RuleSet.new()
	if teams and seat_count >= 4 and seat_count % 2 == 0:
		rules.team_of_seat = RuleSet.opposite_partners(seat_count)
	var game := Match.create_standard(rules, seat_count, seed_value)
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
			_announce_landing(event)
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
			_chooser.reset(legal_moves())
			_show_choices()


func _show_choices() -> void:
	_choices = _chooser.choices()
	_board.show_choices(_choices)
	if _chooser.depth() > 0:
		_hud.show_message("Now the second marble: tap where it goes")
	elif state().current_card != null and state().current_card.rank == Card.Rank.SEVEN:
		_hud.show_message("Move one marble 7, or tap a ghost to split the 7 between two")
	else:
		_hud.show_message("Tap a glowing ghost marble to move")


func _on_ghost_tapped(choice_index: int) -> void:
	if _busy or state().phase != GameState.Phase.AWAITING_MOVE or choice_index >= _choices.size():
		return
	var move_index: int = _chooser.pick(_choices[choice_index])
	if move_index >= 0:
		choose(move_index)
	else:
		_show_choices()


func _on_marble_tapped(ref: MarbleRef) -> void:
	if _busy or state().phase != GameState.Phase.AWAITING_MOVE:
		return
	# Tapping a marble shows just its moves (and starts a split over).
	_chooser.focus_marble(ref, state().spot_of(ref).is_starting_block())
	_show_choices()


func _announce_landing(event: MatchEvent) -> void:
	var owner: PlayerState = state().player(event.step.marble.seat)
	if event.step.to.kind == Spot.Kind.BULLS_EYE:
		_hud.show_message("Into the Bull's Eye! Only a Jack, Queen or King gets it out.")
	elif owner.fast_track_ready[event.step.marble.marble]:
		_hud.show_message("On the Fast Track! Ride it with your next card.")


func _pause(seconds: float) -> void:
	if animate:
		await get_tree().create_timer(seconds).timeout
