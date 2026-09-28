class_name MoveContext
extends RefCounted
## Everything an evaluator needs to judge one candidate move.

var rules: RuleSet
var seat: int
var move: Move
var before: GameState
## [member before] with the move applied (a simulation copy).
var after: GameState
## The seat and its teammates.
var team: Array[int] = []


func _init(p_rules: RuleSet, p_seat: int, p_move: Move, p_before: GameState) -> void:
	rules = p_rules
	seat = p_seat
	move = p_move
	before = p_before
	after = p_before.copy_for_simulation()
	for step: MarbleStep in move.steps:
		MoveResolver.apply_step(after, step)
	team = rules.team_members(seat)
