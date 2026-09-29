class_name BoardMetrics
extends RefCounted
## How far along a marble is, and how exposed it is. Shared by the evaluators.

## Chance that one random card from a fresh deck moves a marble exactly
## [code]d[/code] spaces forward (index = d). A, J, Q, K and the Jokers move 1;
## the Four goes backward.
const FORWARD_ODDS: Array[float] = [
	0.0, 18.0 / 54.0, 4.0 / 54.0, 4.0 / 54.0, 0.0, 4.0 / 54.0,
	4.0 / 54.0, 4.0 / 54.0, 4.0 / 54.0, 4.0 / 54.0, 4.0 / 54.0,
]
const BACKWARD_FOUR_ODDS := 4.0 / 54.0
## Ace, Six or Joker.
const START_CARD_ODDS := 10.0 / 54.0


## 0 in the Starting Block, about the track length just before Home Base,
## and a little more for each Home Base slot.
static func progress(state: GameState, seat: int, spot: Spot) -> float:
	var topology: BoardTopology = state.topology
	var arm: int = state.player(seat).arm
	match spot.kind:
		Spot.Kind.STARTING_BLOCK:
			return 0.0
		Spot.Kind.MAIN_TRACK:
			var remaining: int = topology.wrap_index(topology.home_entrance(arm) - spot.index)
			return float(topology.track_length() - remaining)
		Spot.Kind.HOME_BASE:
			return float(topology.track_length() + 1 + spot.index)
		_:
			# The Bull's Eye leads to the own color's corner, after a wait.
			var corner := Spot.track(topology.own_fast_track_corner(arm))
			return progress(state, seat, corner) - 6.0


## Total progress of a seat's marbles.
static func seat_progress(state: GameState, seat: int) -> float:
	var total: float = 0.0
	for spot: Spot in state.player(seat).marbles:
		total += progress(state, seat, spot)
	return total


## Expected progress a seat stands to lose to opponents' next cards: for each
## exposed marble, the chance some opponent can land on it times what it's worth.
static func danger(state: GameState, seat: int, rules: RuleSet) -> float:
	var team: Array[int] = rules.team_members(seat)
	var total: float = 0.0
	var length: int = state.topology.track_length()
	var player: PlayerState = state.player(seat)
	for spot: Spot in player.marbles:
		if not spot.is_track():
			continue
		var hit_chance: float = 0.0
		for other: PlayerState in state.players:
			if team.has(other.seat):
				continue
			for their: Spot in other.marbles:
				if not their.is_track():
					continue
				var behind: int = posmod(spot.index - their.index, length)
				if behind > 0 and behind < FORWARD_ODDS.size():
					hit_chance += FORWARD_ODDS[behind]
				if posmod(their.index - spot.index, length) == 4:
					hit_chance += BACKWARD_FOUR_ODDS
			# Sitting on their Starting Exit: any start card (A, 6, Joker) brings
			# a marble out on top of ours.
			var on_their_exit: bool = spot.index == state.topology.starting_exit(other.arm)
			if on_their_exit and not rules.starting_exit_must_be_empty and other.first_marble_in_starting_block() >= 0:
				hit_chance += START_CARD_ODDS
		total += minf(hit_chance, 1.0) * progress(state, seat, spot)
	return total
