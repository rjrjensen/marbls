class_name RuleSet
extends Resource
## Every rule that could reasonably vary between tables.
##
## "Rules are subject to change, of course. Sometimes midgame!" Where the
## README is ambiguous, add an option here instead of hard-coding a choice
## (see docs/DESIGN.md §9 for the open questions).

@export var marbles_per_player: int = 4
@export var jokers_per_deck: int = 2
## Decided (family feedback): starting a marble kills an opponent sitting on
## your Starting Exit. Set true for the stricter "start space must be empty".
@export var starting_exit_must_be_empty: bool = false
## Open question: does a play-again card with no legal move still let you
## draw again? Assumed yes.
@export var play_again_without_move: bool = true
## Cut for the first player (highest card goes first, Ace high). When false,
## seat 0 goes first.
@export var cut_for_first_seat: bool = true
## Open question: where a Joker ranks when cutting. True ranks it above Ace.
@export var jokers_cut_high: bool = true
## A marble whose move ends exactly on a Fast Track corner may ride the Fast
## Track (corner to corner) with its owner's next card.
@export var fast_track_enabled: bool = true
## A Main Track marble that reaches a Fast Track corner with one step left
## may drop into the Bull's Eye instead.
@export var bulls_eye_enabled: bool = true
## Decided: any movement that lands a marble on a Fast Track corner, a Jack
## swap included, puts it on the Fast Track.
@export var swap_grants_fast_track: bool = true
## Team number for each seat, e.g. [0, 1, 0, 1] for partners sitting
## opposite at a 4-player table. Empty means everyone plays for themselves.
@export var team_of_seat: PackedInt32Array = PackedInt32Array()


## Partners sit opposite each other: 4 players make 2 teams, 6 make 3, 8 make 4.
static func opposite_partners(seat_count: int) -> PackedInt32Array:
	var teams := PackedInt32Array()
	for seat: int in seat_count:
		teams.append(seat % (seat_count / 2))
	return teams


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


## Face cards are the only way out of the Bull's Eye.
func can_exit_bulls_eye(rank: Card.Rank) -> bool:
	return rank == Card.Rank.JACK or rank == Card.Rank.QUEEN or rank == Card.Rank.KING


func can_swap(rank: Card.Rank) -> bool:
	return rank == Card.Rank.JACK


func can_split(rank: Card.Rank) -> bool:
	return rank == Card.Rank.SEVEN


func is_team_game() -> bool:
	return not team_of_seat.is_empty()


## Everyone on [param seat]'s team, including [param seat].
func team_members(seat: int) -> Array[int]:
	var members: Array[int] = []
	if not is_team_game():
		members.append(seat)
		return members
	for other: int in team_of_seat.size():
		if team_of_seat[other] == team_of_seat[seat]:
			members.append(other)
	return members


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
		"fast_track_enabled": fast_track_enabled,
		"bulls_eye_enabled": bulls_eye_enabled,
		"swap_grants_fast_track": swap_grants_fast_track,
		"team_of_seat": Array(team_of_seat),
	}


static func from_dict(data: Dictionary) -> RuleSet:
	var rules := RuleSet.new()
	rules.marbles_per_player = int(data["marbles_per_player"])
	rules.jokers_per_deck = int(data["jokers_per_deck"])
	rules.starting_exit_must_be_empty = bool(data["starting_exit_must_be_empty"])
	rules.play_again_without_move = bool(data["play_again_without_move"])
	rules.cut_for_first_seat = bool(data["cut_for_first_seat"])
	rules.jokers_cut_high = bool(data["jokers_cut_high"])
	rules.fast_track_enabled = bool(data.get("fast_track_enabled", true))
	rules.bulls_eye_enabled = bool(data.get("bulls_eye_enabled", true))
	rules.swap_grants_fast_track = bool(data.get("swap_grants_fast_track", true))
	var teams: Array = data.get("team_of_seat", [])
	for team: Variant in teams:
		rules.team_of_seat.append(int(team))
	return rules
