class_name CutPanel
extends PanelContainer
## The starting ceremony: everyone cuts their deck, the cards turn over one by
## one, ties cut again, and the highest card goes first (Joker beats Ace).

const SUIT_NAMES: PackedStringArray = ["Clubs", "Diamonds", "Hearts", "Spades", ""]

@onready var _rows: VBoxContainer = %CutRows
@onready var _title: Label = %CutTitle


func begin() -> void:
	for child: Node in _rows.get_children():
		child.queue_free()
	_title.text = "Cutting for first player"
	visible = true


func show_cut(seat_name: String, color: Color, card: Card) -> void:
	var row := Label.new()
	var card_name: String = Card.RANK_NAMES[card.rank]
	if not card.is_joker():
		card_name += " of " + SUIT_NAMES[card.suit]
	row.text = "%s:  %s" % [seat_name, card_name]
	row.add_theme_font_size_override("font_size", 30)
	row.add_theme_color_override("font_color", color.lightened(0.25))
	row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rows.add_child(row)
	row.pivot_offset = Vector2(200, 20)
	row.scale = Vector2(0.2, 0.2)
	row.create_tween().tween_property(row, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func show_tie() -> void:
	var row := Label.new()
	row.text = "Tie! Cut again..."
	row.add_theme_font_size_override("font_size", 26)
	row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rows.add_child(row)


func show_winner(seat_name: String) -> void:
	_title.text = "%s go%s first!" % [seat_name, "" if seat_name == "You" else "es"]
