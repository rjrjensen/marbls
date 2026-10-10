class_name Card
extends RefCounted
## One playing card. Treat as immutable once created.
##
## What each rank *does* (steps, starting, play again) is decided by the
## [RuleSet], not by the card, so house rules can change it.

enum Rank { ACE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, TEN, JACK, QUEEN, KING, JOKER }
enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES, NONE }

const RANK_NAMES: PackedStringArray = [
	"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "Joker",
]
const SUIT_SYMBOLS: PackedStringArray = ["♣", "♦", "♥", "♠", ""]

var rank: Rank
var suit: Suit


func _init(p_rank: Rank, p_suit: Suit = Suit.NONE) -> void:
	rank = p_rank
	suit = p_suit


func is_joker() -> bool:
	return rank == Rank.JOKER


## Hearts and Diamonds are printed in red; the Joker is neither red nor black.
func is_red() -> bool:
	return suit == Suit.HEARTS or suit == Suit.DIAMONDS


func is_face_card() -> bool:
	return rank == Rank.JACK or rank == Rank.QUEEN or rank == Rank.KING


func equals(other: Card) -> bool:
	return other != null and rank == other.rank and suit == other.suit


func to_dict() -> Dictionary:
	return {"rank": rank, "suit": suit}


static func from_dict(data: Dictionary) -> Card:
	return Card.new(int(data["rank"]) as Rank, int(data["suit"]) as Suit)


func _to_string() -> String:
	return RANK_NAMES[rank] + SUIT_SYMBOLS[suit]
