class_name SeatColors
extends RefCounted
## Marble colors and names by seat. Classic board order first.

const COLORS: Array[Color] = [
	Color("#d62828"),  # red
	Color("#1d4ed8"),  # blue
	Color("#f2b705"),  # yellow
	Color("#15803d"),  # green
	Color("#7e22ce"),  # purple
	Color("#ea580c"),  # orange
	Color("#0e9aa7"),  # teal
	Color("#db2777"),  # pink
]
const NAMES: PackedStringArray = ["Red", "Blue", "Yellow", "Green", "Purple", "Orange", "Teal", "Pink"]


static func color(seat: int) -> Color:
	return COLORS[seat % COLORS.size()]


static func display_name(seat: int) -> String:
	return NAMES[seat % NAMES.size()]
