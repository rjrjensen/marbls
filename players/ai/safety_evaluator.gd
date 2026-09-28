class_name SafetyEvaluator
extends MoveEvaluator
## Ending out of reach: how much less of our progress is exposed to the
## opponents' next cards after this move than before it.


func score(context: MoveContext) -> float:
	var total: float = 0.0
	for member: int in context.team:
		total += BoardMetrics.danger(context.before, member, context.rules) \
				- BoardMetrics.danger(context.after, member, context.rules)
	return total
