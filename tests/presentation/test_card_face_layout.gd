extends TestCase
## Where the suit symbols go on a card face. Card units: the card is 50 wide
## and 70 tall, like the prototype's SVG.

const SPOT_RANKS: Array[Card.Rank] = [
	Card.Rank.ACE, Card.Rank.TWO, Card.Rank.THREE, Card.Rank.FOUR, Card.Rank.FIVE,
	Card.Rank.SIX, Card.Rank.SEVEN, Card.Rank.EIGHT, Card.Rank.NINE, Card.Rank.TEN,
]


func test_ace_to_ten_have_one_pip_per_spot() -> void:
	var expected: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	for i: int in SPOT_RANKS.size():
		var layout := CardFaceLayout.for_card(Card.new(SPOT_RANKS[i], Card.Suit.SPADES))
		assert_eq(layout.kind, CardFaceLayout.Kind.PIPS, Card.RANK_NAMES[SPOT_RANKS[i]])
		assert_eq(layout.pips.size(), expected[i], Card.RANK_NAMES[SPOT_RANKS[i]])


func test_no_two_pips_overlap() -> void:
	for rank: Card.Rank in SPOT_RANKS:
		var pips: Array[CardFaceLayout.Pip] = CardFaceLayout.for_card(Card.new(rank, Card.Suit.CLUBS)).pips
		for i: int in pips.size():
			for j: int in range(i + 1, pips.size()):
				assert_false(pips[i].rect().intersects(pips[j].rect()),
						"%s: pip %d %s overlaps pip %d %s" % [
							Card.RANK_NAMES[rank], i, pips[i].rect(), j, pips[j].rect()])


func test_pips_stay_on_the_card_and_clear_of_the_corner_indices() -> void:
	var card_rect := Rect2(Vector2.ZERO, CardFaceLayout.CARD_SIZE)
	var top_left: Rect2 = CardFaceLayout.CORNER_INDEX
	var bottom_right := Rect2(CardFaceLayout.CARD_SIZE - top_left.end, top_left.size)
	for rank: Card.Rank in SPOT_RANKS:
		var name: String = Card.RANK_NAMES[rank]
		for pip: CardFaceLayout.Pip in CardFaceLayout.for_card(Card.new(rank, Card.Suit.HEARTS)).pips:
			assert_true(card_rect.encloses(pip.rect()), "%s: pip %s is off the card" % [name, pip.rect()])
			assert_false(pip.rect().intersects(top_left), "%s: pip %s hits the top index" % [name, pip.rect()])
			assert_false(pip.rect().intersects(bottom_right), "%s: pip %s hits the bottom index" % [name, pip.rect()])
