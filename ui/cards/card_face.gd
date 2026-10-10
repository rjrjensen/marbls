class_name CardFace
extends Control
## The face of one playing card, drawn from a template instead of 54 images.
##
## The art is laid out at [constant DESIGN_SIZE] (5 pixels per card unit of
## [CardFaceLayout]) and scaled to fit whatever size this control is given,
## so the same scene works as a big flash or a small pile top.

const DESIGN_SIZE := Vector2(250.0, 350.0)
const UNIT: float = DESIGN_SIZE.x / CardFaceLayout.CARD_SIZE.x
const RED_INK := Color("#c1121f")
const BLACK_INK := Color("#1b1b1b")
const JOKER_INK := Color("#5a2a8a")
## Indexed by [enum Card.Suit].
const SUIT_TEXTURES: Array[Texture2D] = [
	preload("res://ui/cards/suits/clubs.svg"),
	preload("res://ui/cards/suits/diamonds.svg"),
	preload("res://ui/cards/suits/hearts.svg"),
	preload("res://ui/cards/suits/spades.svg"),
]
const STAR_TEXTURE: Texture2D = preload("res://ui/cards/art/star.svg")
const RANK_FONT_SIZE := 60
## "10" is two characters, so it is printed smaller to fit the same corner.
const TEN_FONT_SIZE := 46

var _kind: CardFaceLayout.Kind = CardFaceLayout.Kind.PIPS
var _ink: Color = BLACK_INK
var _rank_text: String = ""
var _suit_texture: Texture2D = null
var _pip_nodes: Array[TextureRect] = []

@onready var _art: Control = %Art
@onready var _indices: Array[Control] = [%TopIndex, %BottomIndex]
@onready var _pips: Control = %Pips
@onready var _pip_template: TextureRect = %PipTemplate
@onready var _court: Control = %Court
@onready var _court_frame: Panel = %Frame
@onready var _court_letter: Label = %Letter
@onready var _court_suit: TextureRect = %Suit
@onready var _joker: Control = %Joker


func _ready() -> void:
	resized.connect(_fit)
	_fit()


func show_card(card: Card) -> void:
	var layout := CardFaceLayout.for_card(card)
	_kind = layout.kind
	if card.is_joker():
		_ink = JOKER_INK
		_rank_text = ""
		_suit_texture = STAR_TEXTURE
	else:
		var red: bool = card.suit == Card.Suit.HEARTS or card.suit == Card.Suit.DIAMONDS
		_ink = RED_INK if red else BLACK_INK
		_rank_text = Card.RANK_NAMES[card.rank]
		_suit_texture = SUIT_TEXTURES[card.suit]
	_show_indices()
	_show_pips(layout.pips)
	_court.visible = _kind == CardFaceLayout.Kind.COURT
	_joker.visible = _kind == CardFaceLayout.Kind.JOKER
	if _court.visible:
		_court_letter.text = _rank_text
		_court_letter.label_settings.font_color = _ink
		(_court_frame.get_theme_stylebox("panel") as StyleBoxFlat).border_color = _ink
		_court_suit.texture = _suit_texture
		_court_suit.self_modulate = _ink


func shown_kind() -> CardFaceLayout.Kind:
	return _kind


func shown_pip_count() -> int:
	var count: int = 0
	for pip: TextureRect in _pip_nodes:
		if pip.visible:
			count += 1
	return count


## The rank printed in the corners ("" on a Joker, which shows a star).
func shown_rank_text() -> String:
	return _rank_text


## The suit symbol in the corners and pips (a star on a Joker).
func shown_suit_texture() -> Texture2D:
	return _suit_texture


## The colour the rank and suit are printed in.
func ink() -> Color:
	return _ink


func _show_indices() -> void:
	for index: Control in _indices:
		var rank := index.get_node("Rank") as Label
		rank.text = _rank_text
		rank.label_settings.font_size = TEN_FONT_SIZE if _rank_text == "10" else RANK_FONT_SIZE
		rank.label_settings.font_color = _ink
		var suit := index.get_node("Suit") as TextureRect
		suit.texture = _suit_texture
		suit.self_modulate = _ink


func _show_pips(pips: Array[CardFaceLayout.Pip]) -> void:
	while _pip_nodes.size() < pips.size():
		var node := _pip_template.duplicate() as TextureRect
		_pips.add_child(node)
		_pip_nodes.append(node)
	for i: int in _pip_nodes.size():
		var node: TextureRect = _pip_nodes[i]
		node.visible = i < pips.size()
		if not node.visible:
			continue
		var rect: Rect2 = pips[i].rect()
		node.position = rect.position * UNIT
		node.size = rect.size * UNIT
		node.pivot_offset = node.size / 2.0
		node.rotation = PI if pips[i].flipped else 0.0
		node.texture = _suit_texture
		node.self_modulate = _ink


## Scales the art to fit this control, centred, keeping the card's shape.
func _fit() -> void:
	var fit: float = minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	_art.scale = Vector2.ONE * fit
	_art.position = (size - DESIGN_SIZE * fit) / 2.0
