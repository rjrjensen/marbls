class_name AIPlayer
extends RefCounted
## Picks a move for one seat. Every legal move gets a score of
## sum(trait weight x evaluator score), plus a little noise for sloppy
## personalities, and the best one wins. The AI only sees public information
## plus its own deck history, exactly what a person at the table could know.

## Look-ahead is the slow part, so only the best few candidates get it.
const LOOKAHEAD_CANDIDATES := 6
const NOISE_SCALE := 12.0
const SAFETY_SCALE := 1.5

var profile: AIProfile
var rules: RuleSet

var _rng := RandomNumberGenerator.new()
var _progress := ProgressEvaluator.new()
var _kills := KillEvaluator.new()
var _safety := SafetyEvaluator.new()
var _team := TeamEvaluator.new()
var _risk := RiskEvaluator.new()
var _lookahead: LookaheadEvaluator


## [param seed_value] makes its sloppiness reproducible (tests, replays).
func _init(p_profile: AIProfile, p_rules: RuleSet, seed_value: int) -> void:
	profile = p_profile
	rules = p_rules
	_rng.seed = seed_value
	_lookahead = LookaheadEvaluator.new(profile.memory)


## The index of the move to play from [param moves].
func choose_move(state: GameState, seat: int, moves: Array[Move]) -> int:
	if moves.size() <= 1:
		return 0
	var scores: Array[float] = []
	var contexts: Array[MoveContext] = []
	for move: Move in moves:
		var context := MoveContext.new(rules, seat, move, state)
		contexts.append(context)
		scores.append(_base_score(context))

	if profile.foresight > 0.0:
		for index: int in _top_indices(scores, LOOKAHEAD_CANDIDATES):
			scores[index] += profile.foresight * _lookahead.score(contexts[index])

	var best: int = 0
	for index: int in scores.size():
		if profile.sloppiness > 0.0:
			scores[index] += _rng.randfn(0.0, profile.sloppiness * NOISE_SCALE)
		if scores[index] > scores[best]:
			best = index
	return best


func _base_score(context: MoveContext) -> float:
	return profile.goal_focus * _progress.score(context) \
			+ profile.aggression * _kills.score(context) \
			+ profile.caution * SAFETY_SCALE * _safety.score(context) \
			+ profile.teamwork * _team.score(context) \
			+ (profile.gambler - 0.5) * 2.0 * _risk.score(context)


func _top_indices(scores: Array[float], count: int) -> Array[int]:
	var indices: Array[int] = []
	for index: int in scores.size():
		indices.append(index)
	indices.sort_custom(func(a: int, b: int) -> bool: return scores[a] > scores[b])
	return indices.slice(0, count)
