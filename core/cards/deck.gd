class_name Deck
extends RefCounted
## A player's personal deck: a face-down draw pile and a face-up discard pile.
##
## The top of the draw pile is the *end* of [member draw_pile]. All shuffling
## takes the match's seeded RNG so games are reproducible.

var draw_pile: Array[Card] = []
var discard_pile: Array[Card] = []


## A standard 52-card deck plus [param joker_count] Jokers, unshuffled.
static func standard(joker_count: int) -> Deck:
	var deck := Deck.new()
	for suit: int in [Card.Suit.CLUBS, Card.Suit.DIAMONDS, Card.Suit.HEARTS, Card.Suit.SPADES]:
		for rank: int in range(Card.Rank.ACE, Card.Rank.KING + 1):
			deck.draw_pile.append(Card.new(rank as Card.Rank, suit as Card.Suit))
	for i: int in joker_count:
		deck.draw_pile.append(Card.new(Card.Rank.JOKER))
	return deck


func total_cards() -> int:
	return draw_pile.size() + discard_pile.size()


func is_draw_pile_empty() -> bool:
	return draw_pile.is_empty()


## Fisher-Yates shuffle of the draw pile.
func shuffle(rng: RandomNumberGenerator) -> void:
	for i: int in range(draw_pile.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: Card = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = swap


## Moves the discard pile back under the draw pile and shuffles everything.
func reshuffle(rng: RandomNumberGenerator) -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle(rng)


## Takes the top card. The caller reshuffles first if the draw pile is empty.
func draw() -> Card:
	assert(not draw_pile.is_empty(), "Deck.draw() on an empty draw pile; reshuffle first.")
	return draw_pile.pop_back()


func discard(card: Card) -> void:
	discard_pile.append(card)


## A random card from the draw pile, left in place. Used when cutting for first player.
func peek_random(rng: RandomNumberGenerator) -> Card:
	return draw_pile[rng.randi_range(0, draw_pile.size() - 1)]


func to_dict() -> Dictionary:
	return {"draw": _cards_to_array(draw_pile), "discard": _cards_to_array(discard_pile)}


static func from_dict(data: Dictionary) -> Deck:
	var deck := Deck.new()
	deck.draw_pile = _cards_from_array(data["draw"])
	deck.discard_pile = _cards_from_array(data["discard"])
	return deck


static func _cards_to_array(cards: Array[Card]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for card: Card in cards:
		out.append(card.to_dict())
	return out


static func _cards_from_array(items: Array) -> Array[Card]:
	var out: Array[Card] = []
	for item: Dictionary in items:
		out.append(Card.from_dict(item))
	return out
