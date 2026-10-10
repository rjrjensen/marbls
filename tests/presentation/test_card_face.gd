extends TestCase
## The Card scene shows a face for every card a deck can hold.

const CARD_FACE_SCENE := preload("res://ui/cards/card_face.tscn")
const SUIT_FILES: Dictionary[Card.Suit, String] = {
	Card.Suit.CLUBS: "res://ui/cards/suits/clubs.svg",
	Card.Suit.DIAMONDS: "res://ui/cards/suits/diamonds.svg",
	Card.Suit.HEARTS: "res://ui/cards/suits/hearts.svg",
	Card.Suit.SPADES: "res://ui/cards/suits/spades.svg",
}
const RED_INK := Color("#c1121f")
const BLACK_INK := Color("#1b1b1b")


func make_face() -> CardFace:
	var face := CARD_FACE_SCENE.instantiate() as CardFace
	(Engine.get_main_loop() as SceneTree).root.add_child(face)
	return face


func free_face(face: CardFace) -> void:
	face.get_parent().remove_child(face)
	face.free()


func test_every_card_in_a_deck_has_a_face() -> void:
	var face := make_face()
	for card: Card in Deck.standard(2).draw_pile:
		face.show_card(card)
		var name: String = str(card)
		if card.is_joker():
			assert_eq(face.shown_kind(), CardFaceLayout.Kind.JOKER, name)
			continue
		if card.is_face_card():
			assert_eq(face.shown_kind(), CardFaceLayout.Kind.COURT, name)
			assert_eq(face.shown_pip_count(), 0, name)
		else:
			assert_eq(face.shown_kind(), CardFaceLayout.Kind.PIPS, name)
			assert_eq(face.shown_pip_count(), mini(card.rank + 1, 10), name)
		assert_eq(face.shown_rank_text(), Card.RANK_NAMES[card.rank], name)
		assert_eq(face.shown_suit_texture().resource_path, SUIT_FILES[card.suit], name)
		var red: bool = card.suit == Card.Suit.HEARTS or card.suit == Card.Suit.DIAMONDS
		assert_eq(face.ink(), RED_INK if red else BLACK_INK, name)
	free_face(face)


func test_a_ten_after_a_two_shows_only_ten_pips() -> void:
	var face := make_face()
	face.show_card(Card.new(Card.Rank.TEN, Card.Suit.CLUBS))
	face.show_card(Card.new(Card.Rank.TWO, Card.Suit.CLUBS))
	assert_eq(face.shown_pip_count(), 2)
	face.show_card(Card.new(Card.Rank.TEN, Card.Suit.CLUBS))
	assert_eq(face.shown_pip_count(), 10)
	free_face(face)
