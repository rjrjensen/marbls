class_name KillEvaluator
extends MoveEvaluator
## Landing on opponents: worth more the further along the victim was.
## Killing a teammate is heavily penalized (it's legal, just rude). Also
## rewards hunting: ending where our next cards threaten opponents' marbles.

const KILL_BONUS := 3.0
const TEAMMATE_PENALTY := 25.0
const HUNTING_WEIGHT := 0.6


func score(context: MoveContext) -> float:
	var total: float = 0.0
	for step: MarbleStep in context.move.steps:
		for victim: MarbleRef in step.kills:
			var lost: float = BoardMetrics.progress(context.before, victim.seat, context.before.spot_of(victim))
			if context.team.has(victim.seat):
				total -= lost + TEAMMATE_PENALTY
			else:
				total += lost + KILL_BONUS
	for other: PlayerState in context.before.players:
		if context.team.has(other.seat):
			continue
		total += HUNTING_WEIGHT * (BoardMetrics.danger(context.after, other.seat, context.rules)
				- BoardMetrics.danger(context.before, other.seat, context.rules))
	return total
