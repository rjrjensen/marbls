class_name ProgressEvaluator
extends MoveEvaluator
## Distance gained toward Home Base, with bonuses for getting a marble out of
## the Starting Block, making it safe in Home Base, and earning a Fast Track ride.

const START_BONUS := 8.0
const HOME_BONUS := 10.0
const FAST_TRACK_BONUS := 5.0


func score(context: MoveContext) -> float:
	var total: float = 0.0
	for step: MarbleStep in context.move.steps:
		var owner: int = step.marble.seat
		if not context.team.has(owner):
			continue  # moving an opponent (a Jack swap) is judged by its effect on us below
		total += BoardMetrics.progress(context.after, owner, step.to) \
				- BoardMetrics.progress(context.before, owner, step.from)
		if step.from.is_starting_block():
			total += START_BONUS
		if step.to.is_home() and not step.from.is_home():
			total += HOME_BONUS
		var topology: BoardTopology = context.before.topology
		if context.rules.fast_track_enabled and step.to.is_track() and topology.is_fast_track_corner(step.to.index) \
				and step.to.index != topology.own_fast_track_corner(context.before.player(owner).arm) \
				and context.move.kind != Move.Kind.SWAP:
			total += FAST_TRACK_BONUS
	# A swap can also set an opponent back or push them forward.
	if context.move.kind == Move.Kind.SWAP:
		var theirs: MarbleStep = context.move.steps[1]
		if not context.team.has(theirs.marble.seat):
			total -= BoardMetrics.progress(context.after, theirs.marble.seat, theirs.to) \
					- BoardMetrics.progress(context.before, theirs.marble.seat, theirs.from)
	return total
