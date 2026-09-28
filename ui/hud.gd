class_name Hud
extends CanvasLayer
## On-screen controls for hot-seat play. Shows what it's told and signals up
## what the player pressed; it never touches game state.

signal draw_pressed
signal new_game_requested(seat_count: int)

const SUIT_NAMES: PackedStringArray = ["Clubs", "Diamonds", "Hearts", "Spades", ""]
const MIN_SEATS := 2
const MAX_SEATS := 8

var _last_seat_count: int = 4

@onready var _turn_label: Label = %TurnLabel
@onready var _message_label: Label = %MessageLabel
@onready var _card_rank: Label = %CardRank
@onready var _card_suit: Label = %CardSuit
@onready var _draw_button: Button = %DrawButton
@onready var _deck_label: Label = %DeckLabel
@onready var _menu_button: Button = %MenuButton
@onready var _new_game_panel: Control = %NewGamePanel
@onready var _seat_buttons: GridContainer = %SeatButtons
@onready var _close_menu_button: Button = %CloseMenuButton
@onready var _game_over_panel: Control = %GameOverPanel
@onready var _winner_label: Label = %WinnerLabel
@onready var _play_again_button: Button = %PlayAgainButton



func _ready() -> void:
	_draw_button.pressed.connect(draw_pressed.emit)
	_menu_button.pressed.connect(func() -> void: _new_game_panel.visible = true)
	_close_menu_button.pressed.connect(func() -> void: _new_game_panel.visible = false)
	_play_again_button.pressed.connect(func() -> void: _request_new_game(_last_seat_count))
	for seat_count: int in range(MIN_SEATS, MAX_SEATS + 1):
		var button := Button.new()
		button.text = "%d players" % seat_count
		button.custom_minimum_size = Vector2(170, 80)
		button.pressed.connect(_request_new_game.bind(seat_count))
		_seat_buttons.add_child(button)
	_new_game_panel.visible = false
	_game_over_panel.visible = false


func show_turn(seat_name: String, color: Color) -> void:
	_turn_label.text = "%s's turn" % seat_name
	_turn_label.add_theme_color_override("font_color", color)


func show_message(text: String) -> void:
	_message_label.text = text


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


func show_deck_count(cards_left: int) -> void:
	_deck_label.text = "%d cards left" % cards_left


func set_draw_enabled(enabled: bool) -> void:
	_draw_button.disabled = not enabled


func show_game_over(text: String) -> void:
	_winner_label.text = text
	_game_over_panel.visible = true


func _request_new_game(seat_count: int) -> void:
	_last_seat_count = seat_count
	_new_game_panel.visible = false
	_game_over_panel.visible = false
	new_game_requested.emit(seat_count)
