class_name MoveChooser
extends RefCounted
## Narrows the legal moves down one marble at a time, so a split Seven or a
## Jack swap is picked with a couple of simple taps instead of a screen full
## of overlapping ghosts.
##
## At each depth it offers the distinct "marble -> spot" first steps of the
## remaining moves. Picking one keeps only the moves that start that way; once
## a single move is left (or every remaining move is complete) it's chosen.

var _moves: Array[Move] = []
var _candidates: Array[int] = []
var _depth: int = 0


func reset(moves: Array[Move]) -> void:
	_moves = moves
	_depth = 0
	_candidates.clear()
	for index: int in moves.size():
		_candidates.append(index)


## 0 while picking the first marble, 1 for the second half of a split, ...
func depth() -> int:
	return _depth


## Only offer moves that start with [param ref] (or, for a Starting Block
## marble, that start any marble of the same seat). Ignored if none do.
func focus_marble(ref: MarbleRef, in_starting_block: bool) -> void:
	var focused: Array[int] = []
	for index: int in _all_indices():
		var step: MarbleStep = _moves[index].steps[0]
		var starts_from_block: bool = in_starting_block and step.from.is_starting_block() and step.marble.seat == ref.seat
		if step.marble.equals(ref) or starts_from_block:
			focused.append(index)
	_depth = 0
	_candidates = focused if not focused.is_empty() else _all_indices()


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
			out.append(MoveChoice.new(step.marble, step.to))
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


func _all_indices() -> Array[int]:
	var indices: Array[int] = []
	for index: int in _moves.size():
		indices.append(index)
	return indices
