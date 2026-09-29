class_name GameController
extends Node
## Runs a game on one device: owns the match host, plays its events on the
## board one at a time, turns taps into intents, and lets computer players
## (an [AIPlayer] per seat) take their turns.
##
## Children only get told what to show (passed down) and report taps
## (signaled up). Every event is also forwarded to the SignalBus.

## Off in tests: everything snaps into place instantly.
@export var animate: bool = true
@export var default_seat_count: int = 4
@export var default_vs_computer: bool = true
## Seconds a computer player "thinks" before drawing or moving.
@export var ai_think_seconds: float = 0.6

var _host: LocalMatchHost
var _queue: Array[MatchEvent] = []
var _busy: bool = false
var _chooser := MoveChooser.new()
var _choices: Array[MoveChoice] = []
## Computer players by seat; every other seat is a person on this device.
var _ai_players: Dictionary[int, AIPlayer] = {}
## Bumped by every new game, so a computer turn scheduled in an old game is dropped.
var _generation: int = 0
var _ai_pending: bool = false
var _running_ai: bool = false
## Seats that have cut in the current round of the starting ceremony.
var _cut_round: Array[int] = []
var _cutting: bool = false

@onready var _board: BoardView = $Board
@onready var _camera: BoardCamera = $BoardCamera
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_hud.draw_pressed.connect(press_draw)
	_hud.new_game_requested.connect(
		func(seat_count: int, teams: bool, vs_computer: bool) -> void:
			new_game(seat_count, randi(), teams, vs_computer)
	)
	_board.ghost_tapped.connect(_on_ghost_tapped)
	_hud.back_pressed.connect(_on_back_pressed)
	_board.marble_tapped.connect(_on_marble_tapped)
	new_game(default_seat_count, randi(), false, default_vs_computer)


## Starts a game. With [param vs_computer], you play Red (seat 0) and every
## other seat is a computer personality; otherwise everyone shares the device.
func new_game(seat_count: int, seed_value: int, teams: bool = false, vs_computer: bool = false) -> void:
	_generation += 1
	_queue.clear()
	_busy = false
	_cut_round.clear()
	_cutting = false
	_hud.cut_panel().visible = false
	_ai_pending = false
	var rules := RuleSet.new()
	if teams and seat_count >= 4 and seat_count % 2 == 0:
		rules.team_of_seat = RuleSet.opposite_partners(seat_count)
	var game := Match.create_standard(rules, seat_count, seed_value)
	_ai_players.clear()
	if vs_computer:
		for seat: int in range(1, seat_count):
			_ai_players[seat] = AIPlayer.new(AIPresets.for_opponent(seat - 1), rules, seed_value + seat)
	_host = LocalMatchHost.new(game)
	_host.events_emitted.connect(_on_events)
	_board.build(_host.state())
	_camera.frame(_board.radius())
	if _single_human_seat() >= 0:
		_camera.face(_board.arm_direction(state().player(_single_human_seat()).arm), false)
	_hud.show_card(null)
	_hud.show_message("Tap Draw to start")
	_host.start()


func is_computer(seat: int) -> bool:
	return _ai_players.has(seat)


func state() -> GameState:
	return _host.state()


func legal_moves() -> Array[Move]:
	return _host.legal_moves()


## Draws for whoever's turn it is, if drawing is allowed right now.
func press_draw() -> void:
	if _busy or state().phase != GameState.Phase.AWAITING_DRAW or is_computer(state().current_seat):
		return
	_board.clear_choices()
	_host.submit(MatchIntent.draw_card(state().current_seat))


## Plays the legal move at [param move_index].
func choose(move_index: int) -> void:
	if _busy or state().phase != GameState.Phase.AWAITING_MOVE or is_computer(state().current_seat):
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
	var seat_name: String = _seat_name(event.seat) if event.seat >= 0 else ""
	match event.kind:
		MatchEvent.Kind.CARD_CUT:
			if not _cutting:
				_cutting = true
				_hud.cut_panel().begin()
			elif _cut_round.has(event.seat):
				_cut_round.clear()
				_hud.cut_panel().show_tie()
				await _pause(0.8)
			_cut_round.append(event.seat)
			_hud.cut_panel().show_cut(_seat_name(event.seat), SeatColors.color(event.seat), event.card)
			await _pause(0.7)
		MatchEvent.Kind.TURN_STARTED:
			if _cutting:
				_cutting = false
				_hud.cut_panel().show_winner(_seat_name(event.seat))
				await _pause(1.6)
				_hud.cut_panel().visible = false
			_hud.show_turn(_turn_title(event.seat), SeatColors.color(event.seat))
			_hud.show_deck_count(state().player(event.seat).deck.draw_pile.size())
			if _single_human_seat() < 0:
				await _camera.face(_board.arm_direction(state().player(event.seat).arm), animate)
		MatchEvent.Kind.DECK_RESHUFFLED:
			_hud.show_message("Out of cards: reshuffled the deck")
		MatchEvent.Kind.CARD_DRAWN:
			await _hud.flip_card(event.card, animate)
			_hud.show_deck_count(state().player(event.seat).deck.draw_pile.size())
			_hud.show_message("")
		MatchEvent.Kind.NO_LEGAL_MOVE:
			_hud.show_message("No move with that card")
			await _pause(1.0)
		MatchEvent.Kind.MARBLE_MOVED:
			await _board.play_step(event.step, animate)
			_announce_landing(event)
		MatchEvent.Kind.MARBLE_KILLED:
			_hud.show_message("%s killed %s marble!" % [seat_name, _possessive(event.victim.seat)])
			if animate:
				_camera.shake()
			await _board.play_kill(event.victim, state(), animate)
		MatchEvent.Kind.PLAY_AGAIN:
			_hud.show_message("Play again!")
		MatchEvent.Kind.GAME_OVER:
			var names: PackedStringArray = []
			for winner: int in event.winners:
				names.append(_seat_name(winner))
			var colors: Array[Color] = []
			for winner: int in event.winners:
				colors.append(SeatColors.color(winner))
			var human_won: bool = _single_human_seat() < 0 or event.winners.has(_single_human_seat())
			if event.winners.has(_single_human_seat()):
				_hud.show_game_over("You win!" if event.winners.size() == 1 else "Your team wins!")
			else:
				_hud.show_game_over("%s win%s!" % [" & ".join(names), "" if names.size() > 1 else "s"])
			if human_won and animate:
				_hud.celebrate(colors)
		MatchEvent.Kind.INTENT_REJECTED:
			_hud.show_message(event.reason)


func _ready_for_input() -> void:
	if state().phase != GameState.Phase.GAME_OVER and is_computer(state().current_seat):
		_hud.set_draw_enabled(false)
		_hud.show_message("%s is thinking..." % _seat_name(state().current_seat))
		_schedule_computer_turn()
		return
	match state().phase:
		GameState.Phase.AWAITING_DRAW:
			_hud.set_back_visible(false)
			_hud.set_draw_enabled(true)
		GameState.Phase.AWAITING_MOVE:
			_chooser.reset(legal_moves())
			_show_choices()


func _show_choices() -> void:
	var card: Card = state().current_card
	var rank: Card.Rank = card.rank if card != null else Card.Rank.ACE
	_hud.set_back_visible(_chooser.is_focused() and _has_multi_marble_moves())
	if _chooser.needs_marble_first():
		_choices = []
		_board.show_selectable_marbles(_chooser.first_marbles())
		if rank == Card.Rank.SEVEN:
			_hud.show_message("Seven: tap the marble to move first (all 7, or part of it)")
		else:
			_hud.show_message("Tap one of your glowing marbles")
		return
	_choices = _chooser.choices()
	_board.show_choices(_choices)
	if _chooser.depth() > 0:
		_hud.show_message("Now move another marble the rest of the 7")
	elif rank == Card.Rank.SEVEN and _chooser.is_focused():
		_hud.show_message("Numbers show spaces used: 7 moves this marble all the way")
	elif rank == Card.Rank.JACK and _chooser.is_focused():
		_hud.show_message("Move 1, or tap \"swap\" to trade places")
	else:
		_hud.show_message("Tap a glowing ghost marble to move")


func _has_multi_marble_moves() -> bool:
	for move: Move in legal_moves():
		if move.steps.size() > 1:
			return true
	return false


func _on_back_pressed() -> void:
	if _busy or state().phase != GameState.Phase.AWAITING_MOVE:
		return
	_chooser.reset(legal_moves())
	_show_choices()


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
	if _chooser.focus_marble(ref, state().spot_of(ref).is_starting_block()):
		_show_choices()


func _announce_landing(event: MatchEvent) -> void:
	var owner: PlayerState = state().player(event.step.marble.seat)
	if event.step.to.kind == Spot.Kind.BULLS_EYE:
		_hud.show_message("Into the Bull's Eye! Only a Jack, Queen or King gets it out.")
	elif owner.fast_track_ready[event.step.marble.marble]:
		_hud.show_message("On the Fast Track! Ride it with your next card.")


## Lets the computer act. Animated games wait a moment first; instant games
## (tests) run computer turns in a loop rather than recursively.
func _schedule_computer_turn() -> void:
	if animate:
		var generation: int = _generation
		await get_tree().create_timer(ai_think_seconds).timeout
		if generation == _generation and not _busy:
			_computer_act()
		return
	_ai_pending = true
	if _running_ai:
		return
	_running_ai = true
	while _ai_pending:
		_ai_pending = false
		_computer_act()
	_running_ai = false


func _computer_act() -> void:
	var seat: int = state().current_seat
	var ai: AIPlayer = _ai_players.get(seat)
	if ai == null:
		return
	match state().phase:
		GameState.Phase.AWAITING_DRAW:
			_host.submit(MatchIntent.draw_card(seat))
		GameState.Phase.AWAITING_MOVE:
			_host.submit(MatchIntent.choose_move(seat, ai.choose_move(state(), seat, legal_moves())))


## The only person playing on this device, or -1 (hot-seat or no people).
func _single_human_seat() -> int:
	var humans: Array[int] = []
	for seat: int in state().seat_count():
		if not is_computer(seat):
			humans.append(seat)
	return humans[0] if humans.size() == 1 and not _ai_players.is_empty() else -1


func _seat_name(seat: int) -> String:
	if is_computer(seat):
		return (_ai_players[seat] as AIPlayer).profile.display_name
	if seat == _single_human_seat():
		return "You"
	return SeatColors.display_name(seat)


func _possessive(seat: int) -> String:
	return "your" if seat == _single_human_seat() else _seat_name(seat) + "'s"


func _turn_title(seat: int) -> String:
	if seat == _single_human_seat():
		return "Your turn"
	if is_computer(seat):
		return "%s's turn (%s)" % [_seat_name(seat), SeatColors.display_name(seat)]
	return "%s's turn" % _seat_name(seat)


func _pause(seconds: float) -> void:
	if animate:
		await get_tree().create_timer(seconds).timeout
