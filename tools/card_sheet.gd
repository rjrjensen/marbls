extends Control
## Every card face a deck can hold, at three sizes, to check them by eye.
## Open tools/card_sheet.tscn in the editor and run it (F6), or save a picture:
##
##   godot res://tools/card_sheet.tscn -- --screenshot /path/to/sheet.png

const CARD_FACE_SCENE := preload("res://ui/cards/card_face.tscn")
const SHEET_SIZE := Vector2(74.0, 104.0)
const BIG_SIZE := Vector2(170.0, 238.0)
const SMALL_SIZE := Vector2(36.0, 50.0)

@onready var _sheet: GridContainer = %Sheet
@onready var _big: HBoxContainer = %Big
@onready var _small: HBoxContainer = %Small


func _ready() -> void:
	for card: Card in Deck.standard(2).draw_pile:
		_add(_sheet, card, SHEET_SIZE)
	for card: Card in [
		Card.new(Card.Rank.TEN, Card.Suit.HEARTS), Card.new(Card.Rank.NINE, Card.Suit.CLUBS),
		Card.new(Card.Rank.QUEEN, Card.Suit.DIAMONDS), Card.new(Card.Rank.JOKER),
	]:
		_add(_big, card, BIG_SIZE)
	for card: Card in [
		Card.new(Card.Rank.ACE, Card.Suit.SPADES), Card.new(Card.Rank.SEVEN, Card.Suit.HEARTS),
		Card.new(Card.Rank.EIGHT, Card.Suit.CLUBS), Card.new(Card.Rank.TEN, Card.Suit.DIAMONDS),
		Card.new(Card.Rank.JACK, Card.Suit.SPADES), Card.new(Card.Rank.KING, Card.Suit.HEARTS),
		Card.new(Card.Rank.JOKER),
	]:
		_add(_small, card, SMALL_SIZE)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var at: int = args.find("--screenshot")
	if at != -1 and at + 1 < args.size():
		_save_screenshot.call_deferred(args[at + 1])


func _add(parent: Control, card: Card, card_size: Vector2) -> void:
	var face := CARD_FACE_SCENE.instantiate() as CardFace
	face.custom_minimum_size = card_size
	parent.add_child(face)
	face.show_card(card)


func _save_screenshot(path: String) -> void:
	for i: int in 3:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
