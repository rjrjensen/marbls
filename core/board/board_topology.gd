class_name BoardTopology
extends RefCounted
## The board as a graph, independent of how it's drawn (see docs/DESIGN.md §2).
##
## The Main Track is a ring of [constant SEGMENT_LENGTH] spaces per arm,
## numbered clockwise. Arm [code]a[/code]'s Starting Exit is [code]14 * a[/code],
## its Home Base entrance is 2 spaces before that, and the Fast Track corners
## sit at offset 5 of every segment.

const SEGMENT_LENGTH := 14
const FAST_TRACK_OFFSET := 5
const HOME_ENTRANCE_BEFORE_EXIT := 2
## How far before its Starting Exit an arm's own Fast Track corner is.
const OWN_FAST_TRACK_BEFORE_EXIT := 9

var arm_count: int
var home_length: int


func _init(p_arm_count: int, p_home_length: int = 4) -> void:
	assert(p_arm_count >= 3, "Boards need at least 3 arms.")
	arm_count = p_arm_count
	home_length = p_home_length


func track_length() -> int:
	return SEGMENT_LENGTH * arm_count


func wrap_index(track_index: int) -> int:
	return posmod(track_index, track_length())


func starting_exit(arm: int) -> int:
	return SEGMENT_LENGTH * arm


func home_entrance(arm: int) -> int:
	return wrap_index(starting_exit(arm) - HOME_ENTRANCE_BEFORE_EXIT)


## The Fast Track corner of this arm's color: the last one before its Home Base.
func own_fast_track_corner(arm: int) -> int:
	return wrap_index(starting_exit(arm) - OWN_FAST_TRACK_BEFORE_EXIT)


func is_fast_track_corner(track_index: int) -> bool:
	return posmod(track_index, SEGMENT_LENGTH) == FAST_TRACK_OFFSET


## Spaces travelled clockwise from this arm's Starting Exit to [param track_index].
func distance_from_exit(arm: int, track_index: int) -> int:
	return wrap_index(track_index - starting_exit(arm))


## The next spot one step forward for a marble owned by [param arm], or null
## if the marble can't go further (the end of its Home Base).
## A marble at its own Home Base entrance always turns in.
func next_forward(arm: int, spot: Spot) -> Spot:
	match spot.kind:
		Spot.Kind.MAIN_TRACK:
			if spot.index == home_entrance(arm):
				return Spot.home(0)
			return Spot.track(wrap_index(spot.index + 1))
		Spot.Kind.HOME_BASE:
			if spot.index + 1 < home_length:
				return Spot.home(spot.index + 1)
			return null
		_:
			return null


## The next spot one step backward, or null. Home Base marbles never move
## backward, and backward moves never turn into a Home Base.
func next_backward(_arm: int, spot: Spot) -> Spot:
	if spot.kind == Spot.Kind.MAIN_TRACK:
		return Spot.track(wrap_index(spot.index - 1))
	return null
