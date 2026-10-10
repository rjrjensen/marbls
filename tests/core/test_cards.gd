extends TestCase


func test_standard_deck_has_52_cards_plus_jokers() -> void:
	var deck := Deck.standard(2)
	assert_eq(deck.total_cards(), 54)
	var jokers: int = 0
	var per_suit: Dictionary[int, int] = {}
	for card: Card in deck.draw_pile:
		if card.is_joker():
			jokers += 1
		else:
			per_suit[card.suit] = per_suit.get(card.suit, 0) + 1
	assert_eq(jokers, 2)
	for suit: int in [Card.Suit.CLUBS, Card.Suit.DIAMONDS, Card.Suit.HEARTS, Card.Suit.SPADES]:
		assert_eq(per_suit[suit], 13)


func test_shuffle_is_reproducible_from_the_seed() -> void:
	var a := Deck.standard(2)
	var b := Deck.standard(2)
	var rng_a := RandomNumberGenerator.new()
	var rng_b := RandomNumberGenerator.new()
	rng_a.seed = 42
	rng_b.seed = 42
	a.shuffle(rng_a)
	b.shuffle(rng_b)
	for i: int in a.draw_pile.size():
		assert_true(a.draw_pile[i].equals(b.draw_pile[i]), "card %d differs" % i)


func test_reshuffle_brings_back_the_discards() -> void:
	var deck := Deck.standard(0)
	var rng := RandomNumberGenerator.new()
	for i: int in 52:
		deck.discard(deck.draw())
	assert_true(deck.is_draw_pile_empty())
	deck.reshuffle(rng)
	assert_eq(deck.draw_pile.size(), 52)
	assert_eq(deck.discard_pile.size(), 0)


func test_deck_round_trips_through_a_dictionary() -> void:
	var deck := Deck.standard(2)
	deck.discard(deck.draw())
	var copy := Deck.from_dict(JSON.parse_string(JSON.stringify(deck.to_dict())))
	assert_eq(copy.draw_pile.size(), 53)
	assert_eq(copy.discard_pile.size(), 1)
	assert_true(copy.discard_pile[0].equals(deck.discard_pile[0]))


func test_card_table_matches_the_readme() -> void:
	var rules := RuleSet.new()
	var expected_steps: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 1, 1, 1]
	for rank: int in expected_steps.size():
		assert_eq(rules.steps_for(rank as Card.Rank), expected_steps[rank], Card.RANK_NAMES[rank])
	var starters: Array[Card.Rank] = [Card.Rank.ACE, Card.Rank.SIX, Card.Rank.JOKER]
	var play_again: Array[Card.Rank] = [
		Card.Rank.ACE, Card.Rank.SIX, Card.Rank.JACK, Card.Rank.QUEEN, Card.Rank.KING, Card.Rank.JOKER,
	]
	for rank: int in expected_steps.size():
		var r := rank as Card.Rank
		assert_eq(rules.can_start(r), starters.has(r), "can start: " + Card.RANK_NAMES[rank])
		assert_eq(rules.plays_again(r), play_again.has(r), "play again: " + Card.RANK_NAMES[rank])
	assert_true(rules.moves_backward(Card.Rank.FOUR))
	assert_false(rules.moves_backward(Card.Rank.FIVE))


func test_hearts_and_diamonds_are_red() -> void:
	assert_true(Card.new(Card.Rank.ACE, Card.Suit.HEARTS).is_red())
	assert_true(Card.new(Card.Rank.TEN, Card.Suit.DIAMONDS).is_red())
	assert_false(Card.new(Card.Rank.ACE, Card.Suit.SPADES).is_red())
	assert_false(Card.new(Card.Rank.KING, Card.Suit.CLUBS).is_red())
	assert_false(Card.new(Card.Rank.JOKER).is_red())
