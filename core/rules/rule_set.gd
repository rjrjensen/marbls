class_name RuleSet
extends Resource
## Every rule that could reasonably vary between tables.
##
## "Rules are subject to change, of course. Sometimes midgame!" Where the
## README is ambiguous, add an option here instead of hard-coding a choice
## (see docs/DESIGN.md §9 for the open questions).

@export var marbles_per_player: int = 4
@export var jokers_per_deck: int = 2
## README: "If a card can start a marble, the start space must be empty."
## When false, starting kills an opponent sitting on your Starting Exit.
@export var starting_exit_must_be_empty: bool = true
## Open question: does a play-again card with no legal move still let you
## draw again? Assumed yes.
@export var play_again_without_move: bool = true
## Cut for the first player (highest card goes first, Ace high). When false,
## seat 0 goes first.
@export var cut_for_first_seat: bool = true
## Open question: where a Joker ranks when cutting. True ranks it above Ace.
@export var jokers_cut_high: bool = true


## How many spaces a card moves a marble.
func steps_for(rank: Card.Rank) -> int:
	match rank:
		Card.Rank.TWO, Card.Rank.THREE, Card.Rank.FOUR, Card.Rank.FIVE, Card.Rank.SIX, \
		Card.Rank.SEVEN, Card.Rank.EIGHT, Card.Rank.NINE, Card.Rank.TEN:
			return int(rank) + 1
		_:
			return 1


func can_start(rank: Card.Rank) -> bool:
	return rank == Card.Rank.ACE or rank == Card.Rank.SIX or rank == Card.Rank.JOKER


func plays_again(rank: Card.Rank) -> bool:
	match rank:
		Card.Rank.ACE, Card.Rank.SIX, Card.Rank.JACK, Card.Rank.QUEEN, Card.Rank.KING, Card.Rank.JOKER:
			return true
		_:
			return false


func moves_backward(rank: Card.Rank) -> bool:
	return rank == Card.Rank.FOUR


## Ordering used when cutting for first player: 2 lowest, Ace high.
func cut_value(rank: Card.Rank) -> int:
	match rank:
		Card.Rank.ACE:
			return 14
		Card.Rank.JOKER:
			return 15 if jokers_cut_high else 1
		_:
			return int(rank) + 1


func to_dict() -> Dictionary:
	return {
		"marbles_per_player": marbles_per_player,
		"jokers_per_deck": jokers_per_deck,
		"starting_exit_must_be_empty": starting_exit_must_be_empty,
		"play_again_without_move": play_again_without_move,
		"cut_for_first_seat": cut_for_first_seat,
		"jokers_cut_high": jokers_cut_high,
	}


static func from_dict(data: Dictionary) -> RuleSet:
	var rules := RuleSet.new()
	rules.marbles_per_player = int(data["marbles_per_player"])
	rules.jokers_per_deck = int(data["jokers_per_deck"])
	rules.starting_exit_must_be_empty = bool(data["starting_exit_must_be_empty"])
	rules.play_again_without_move = bool(data["play_again_without_move"])
	rules.cut_for_first_seat = bool(data["cut_for_first_seat"])
	rules.jokers_cut_high = bool(data["jokers_cut_high"])
	return rules
