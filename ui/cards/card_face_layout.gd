class_name CardFaceLayout
extends RefCounted
## Where things go on one card face, in card units: the card is 50 wide and
## 70 tall (the prototype's SVG). Pure data so it can be tested; [CardFace]
## turns it into nodes.

enum Kind { PIPS, COURT, JOKER }

## One suit symbol in the middle of a spot card (A to 10).
class Pip:
	var center: Vector2
	## 1.0 is a symbol [constant GLYPH_SIZE] across.
	var scale: float
	## Pips in the bottom half are printed upside down, like a real card.
	var flipped: bool

	func _init(p_center: Vector2, p_scale: float, p_flipped: bool) -> void:
		center = p_center
		scale = p_scale
		flipped = p_flipped

	## The square the symbol fits in.
	func rect() -> Rect2:
		var extent: float = CardFaceLayout.GLYPH_SIZE * scale
		return Rect2(center - Vector2.ONE * extent / 2.0, Vector2.ONE * extent)


const CARD_SIZE := Vector2(50.0, 70.0)
## Every suit symbol fits in a square this many units across (at scale 1).
const GLYPH_SIZE := 14.0
## The rank and small suit in the top-left corner; the bottom-right corner is
## the same rectangle turned upside down.
const CORNER_INDEX := Rect2(1.5, 3.0, 9.75, 20.5)

## Spot positions, 0 to 1 across the pip area (left to right, top to bottom).
const SPOTS: Dictionary[Card.Rank, Array] = {
	Card.Rank.ACE: [Vector2(0.5, 0.5)],
	Card.Rank.TWO: [Vector2(0.5, 0), Vector2(0.5, 1)],
	Card.Rank.THREE: [Vector2(0.5, 0), Vector2(0.5, 0.5), Vector2(0.5, 1)],
	Card.Rank.FOUR: [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
	Card.Rank.FIVE: [Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 0.5), Vector2(0, 1), Vector2(1, 1)],
	Card.Rank.SIX: [
		Vector2(0, 0), Vector2(1, 0), Vector2(0, 0.5), Vector2(1, 0.5), Vector2(0, 1), Vector2(1, 1),
	],
	Card.Rank.SEVEN: [
		Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 0.25), Vector2(0, 0.5), Vector2(1, 0.5),
		Vector2(0, 1), Vector2(1, 1),
	],
	Card.Rank.EIGHT: [
		Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 0.25), Vector2(0, 0.5), Vector2(1, 0.5),
		Vector2(0.5, 0.75), Vector2(0, 1), Vector2(1, 1),
	],
	Card.Rank.NINE: [
		Vector2(0, 0), Vector2(1, 0), Vector2(0, 1.0 / 3.0), Vector2(1, 1.0 / 3.0), Vector2(0.5, 0.5),
		Vector2(0, 2.0 / 3.0), Vector2(1, 2.0 / 3.0), Vector2(0, 1), Vector2(1, 1),
	],
	Card.Rank.TEN: [
		Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1.0 / 6.0), Vector2(0, 1.0 / 3.0), Vector2(1, 1.0 / 3.0),
		Vector2(0, 2.0 / 3.0), Vector2(1, 2.0 / 3.0), Vector2(0.5, 5.0 / 6.0), Vector2(0, 1), Vector2(1, 1),
	],
}

## The box pip centres are spread over. The 9 and 10 put pips between the
## columns, so they use smaller pips spread a little wider.
const PIP_AREA := Rect2(18.0, 13.0, 14.0, 44.0)
const DENSE_PIP_AREA := Rect2(16.0, 13.0, 18.0, 44.0)
const PIP_SCALE := 0.74
const DENSE_PIP_SCALE := 0.6
const ACE_SCALE := 1.85

var kind: Kind
var pips: Array[Pip] = []


static func for_card(card: Card) -> CardFaceLayout:
	var layout := CardFaceLayout.new()
	if card.is_joker():
		layout.kind = Kind.JOKER
	elif card.is_face_card():
		layout.kind = Kind.COURT
	else:
		layout.kind = Kind.PIPS
		layout.pips = _pips_for(card.rank)
	return layout


static func _pips_for(rank: Card.Rank) -> Array[Pip]:
	var dense: bool = rank == Card.Rank.NINE or rank == Card.Rank.TEN
	var area: Rect2 = DENSE_PIP_AREA if dense else PIP_AREA
	var scale: float = PIP_SCALE
	if rank == Card.Rank.ACE:
		scale = ACE_SCALE
	elif dense:
		scale = DENSE_PIP_SCALE
	var out: Array[Pip] = []
	for spot: Vector2 in SPOTS[rank]:
		var center: Vector2 = area.position + spot * area.size
		out.append(Pip.new(center, scale, spot.y > 0.5))
	return out
