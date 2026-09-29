class_name MoveChooser
extends RefCounted
## Narrows the legal moves down one marble at a time, so a split Seven or a
## Jack swap is picked with a couple of simple taps instead of a screen full
## of overlapping ghosts.
##
## When a card allows multi-marble moves (Seven, Jack) the player picks a
## marble first, then sees only that marble's destinations, each labeled with
## the spaces it uses. At each depth it offers the distinct "marble -> spot"
## steps of the remaining moves. Picking one keeps only the moves that start
## that way; once a single move is left (or every remaining move is complete)
## it's chosen.

var _moves: Array[Move] = []
var _candidates: Array[int] = []
var _depth: int = 0
var _focused: bool = false


func reset(moves: Array[Move]) -> void:
	_moves = moves
	_depth = 0
	_focused = false
	_candidates.clear()
	for index: int in moves.size():
		_candidates.append(index)


## 0 while picking the first marble, 1 for the second half of a split, ...
func depth() -> int:
	return _depth


## True while a marble has been picked (or the second half is being chosen).
func is_focused() -> bool:
	return _focused or _depth > 0


## Multi-marble cards ask for a marble before showing any destinations.
func needs_marble_first() -> bool:
	if is_focused():
		return false
	for move: Move in _moves:
		if move.steps.size() > 1:
			return first_marbles().size() > 1
	return false


## The marbles that can start a move (a Starting Block counts once).
func first_marbles() -> Array[MarbleRef]:
	var refs: Array[MarbleRef] = []
	for index: int in _candidates:
		var ref: MarbleRef = _moves[index].steps[0].marble
		var known: bool = false
		for other: MarbleRef in refs:
			known = known or other.equals(ref)
		if not known:
			refs.append(ref)
	return refs


## Only offer moves that start with [param ref] (or, for a Starting Block
## marble, that start any marble of the same seat). Returns false (and
## changes nothing) if that marble can't move.
func focus_marble(ref: MarbleRef, in_starting_block: bool) -> bool:
	var focused: Array[int] = []
	for index: int in _all_indices():
		var step: MarbleStep = _moves[index].steps[0]
		var starts_from_block: bool = in_starting_block and step.from.is_starting_block() and step.marble.seat == ref.seat
		if step.marble.equals(ref) or starts_from_block:
			focused.append(index)
	if focused.is_empty():
		return false
	_depth = 0
	_focused = true
	_candidates = focused
	return true


func choices() -> Array[MoveChoice]:
	var out: Array[MoveChoice] = []
	for index: int in _candidates:
		var steps: Array[MarbleStep] = _moves[index].steps
		if steps.size() <= _depth:
			continue
		var step: MarbleStep = steps[_depth]
		var known: bool = false
		for choice: MoveChoice in out:
			known = known or choice.matches(step)
		if not known:
			out.append(MoveChoice.new(step.marble, step.to, _label(_moves[index], step)))
	return out


## Returns the chosen move's index, or -1 if another pick is needed.
func pick(choice: MoveChoice) -> int:
	var remaining: Array[int] = []
	for index: int in _candidates:
		var steps: Array[MarbleStep] = _moves[index].steps
		if steps.size() > _depth and choice.matches(steps[_depth]):
			remaining.append(index)
	if remaining.is_empty():
		return -1
	var continuing: Array[int] = []
	for index: int in remaining:
		if _moves[index].steps.size() > _depth + 1:
			continuing.append(index)
	if remaining.size() == 1 or continuing.is_empty():
		return remaining[0]
	_candidates = continuing
	_depth += 1
	return -1


static func _label(move: Move, step: MarbleStep) -> String:
	match move.kind:
		Move.Kind.START:
			return "out"
		Move.Kind.SWAP:
			return "swap"
		Move.Kind.BULLS_EYE_EXIT:
			return "exit"
		_:
			return str(step.path.size())


func _all_indices() -> Array[int]:
	var indices: Array[int] = []
	for index: int in _moves.size():
		indices.append(index)
	return indices
