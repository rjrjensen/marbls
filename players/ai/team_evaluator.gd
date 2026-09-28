class_name TeamEvaluator
extends MoveEvaluator
## Progress made by teammates' marbles (a split Seven, or moving a partner's
## marbles after finishing). Zero outside team games.


func score(context: MoveContext) -> float:
	var total: float = 0.0
	for member: int in context.team:
		if member == context.seat:
			continue
		total += BoardMetrics.seat_progress(context.after, member) - BoardMetrics.seat_progress(context.before, member)
	return total
