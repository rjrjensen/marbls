class_name Hud
extends CanvasLayer
## On-screen controls for hot-seat play. Shows what it's told and signals up
## what the player pressed; it never touches game state.

signal draw_pressed
## Start picking a move over (e.g. a different first marble for a Seven).
signal back_pressed
signal new_game_requested(seat_count: int, teams: bool, vs_computer: bool)

const SUIT_NAMES: PackedStringArray = ["Clubs", "Diamonds", "Hearts", "Spades", ""]
const MIN_SEATS := 2
const MAX_SEATS := 8
const FLIP_SECONDS := 0.14

@export var card_back_style: StyleBox

var _last_seat_count: int = 4
var _last_teams: bool = false
var _last_vs_computer: bool = true
var _draw_pulse: Tween = null
var _card_face_style: StyleBox

@onready var _turn_label: Label = %TurnLabel
@onready var _message_label: Label = %MessageLabel
@onready var _card: PanelContainer = %Card
@onready var _card_rank: Label = %CardRank
@onready var _card_suit: Label = %CardSuit
@onready var _draw_button: Button = %DrawButton
@onready var _back_button: Button = %BackButton
@onready var _deck_label: Label = %DeckLabel
@onready var _menu_button: Button = %MenuButton
@onready var _new_game_panel: Control = %NewGamePanel
@onready var _seat_buttons: GridContainer = %SeatButtons
@onready var _close_menu_button: Button = %CloseMenuButton
@onready var _teams_toggle: CheckButton = %TeamsToggle
@onready var _computer_toggle: CheckButton = %ComputerToggle
@onready var _game_over_panel: Control = %GameOverPanel
@onready var _winner_label: Label = %WinnerLabel
@onready var _play_again_button: Button = %PlayAgainButton
@onready var _celebration: Celebration = %Celebration
@onready var _cut_panel: CutPanel = %CutPanel



func _ready() -> void:
	_card_face_style = _card.get_theme_stylebox("panel")
	_draw_button.pressed.connect(draw_pressed.emit)
	_back_button.pressed.connect(back_pressed.emit)
	_back_button.visible = false
	_menu_button.pressed.connect(func() -> void: _new_game_panel.visible = true)
	_close_menu_button.pressed.connect(func() -> void: _new_game_panel.visible = false)
	_play_again_button.pressed.connect(
		func() -> void: _request_new_game(_last_seat_count, _last_teams, _last_vs_computer)
	)
	for seat_count: int in range(MIN_SEATS, MAX_SEATS + 1):
		var button := Button.new()
		button.text = "%d players" % seat_count
		button.custom_minimum_size = Vector2(170, 80)
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(
			func() -> void:
				_request_new_game(seat_count, _teams_toggle.button_pressed, _computer_toggle.button_pressed)
		)
		_seat_buttons.add_child(button)
	_new_game_panel.visible = false
	_game_over_panel.visible = false


func show_turn(title: String, color: Color) -> void:
	_turn_label.text = title
	_turn_label.add_theme_color_override("font_color", color)


func show_message(text: String) -> void:
	_message_label.text = text


## Turns the drawn card over: the back shrinks away, the face grows in.
func flip_card(card: Card, animate: bool) -> void:
	if not animate:
		show_card(card)
		return
	_card.pivot_offset = _card.size / 2.0
	_card.add_theme_stylebox_override("panel", card_back_style)
	_card_rank.text = ""
	_card_suit.text = ""
	var shrink := create_tween().set_trans(Tween.TRANS_SINE)
	shrink.tween_property(_card, "scale", Vector2(0.0, 1.12), FLIP_SECONDS)
	await shrink.finished
	_card.add_theme_stylebox_override("panel", _card_face_style)
	show_card(card)
	var grow := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	grow.tween_property(_card, "scale", Vector2.ONE, FLIP_SECONDS * 1.4)
	await grow.finished


func show_card(card: Card) -> void:
	if card == null:
		_card_rank.text = "?"
		_card_suit.text = ""
		return
	_card_rank.text = Card.RANK_NAMES[card.rank]
	_card_suit.text = SUIT_NAMES[card.suit]
	var red: bool = card.suit == Card.Suit.HEARTS or card.suit == Card.Suit.DIAMONDS
	var ink := Color("#c1121f") if red else Color("#1b1b1b")
	_card_rank.add_theme_color_override("font_color", ink)
	_card_suit.add_theme_color_override("font_color", ink)


func set_back_visible(visible_now: bool) -> void:
	_back_button.visible = visible_now


func show_deck_count(cards_left: int) -> void:
	_deck_label.text = "%d cards left" % cards_left


## Enables the Draw button; while enabled it gently pulses so it's obvious
## whose move it is.
func set_draw_enabled(enabled: bool) -> void:
	_draw_button.disabled = not enabled
	if _draw_pulse != null:
		_draw_pulse.kill()
		_draw_pulse = null
	_draw_button.pivot_offset = _draw_button.size / 2.0
	_draw_button.scale = Vector2.ONE
	if enabled:
		_draw_pulse = create_tween().set_loops()
		_draw_pulse.tween_property(_draw_button, "scale", Vector2.ONE * 1.08, 0.55).set_trans(Tween.TRANS_SINE)
		_draw_pulse.tween_property(_draw_button, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)


func show_game_over(text: String) -> void:
	_winner_label.text = text
	_game_over_panel.visible = true


## Bouncing cards in the winners' colors.
func celebrate(colors: Array[Color]) -> void:
	_celebration.play(colors)


func cut_panel() -> CutPanel:
	return _cut_panel


func _request_new_game(seat_count: int, teams: bool, vs_computer: bool) -> void:
	_last_seat_count = seat_count
	_last_teams = teams
	_last_vs_computer = vs_computer
	_new_game_panel.visible = false
	_game_over_panel.visible = false
	_celebration.stop()
	new_game_requested.emit(seat_count, teams, vs_computer)
