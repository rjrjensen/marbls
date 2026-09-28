class_name RiskEvaluator
extends MoveEvaluator
## Appetite for gambles: dropping into the Bull's Eye (stuck until a face
## card) and long Fast Track rides. Weighted by (gambler - 0.5), so cautious
## personalities avoid them and gamblers seek them.

const BULLS_EYE_THRILL := 8.0
const FAST_TRACK_THRILL := 3.0


func score(context: MoveContext) -> float:
	var total: float = 0.0
	for step: MarbleStep in context.move.steps:
		if step.to.kind == Spot.Kind.BULLS_EYE:
			total += BULLS_EYE_THRILL
		var from_corner: bool = step.from.is_track() and context.before.topology.is_fast_track_corner(step.from.index)
		if from_corner and step.path.size() > 0 and step.path[0].is_track() \
				and absi(step.path[0].index - step.from.index) == BoardTopology.SEGMENT_LENGTH:
			total += FAST_TRACK_THRILL
	return total
