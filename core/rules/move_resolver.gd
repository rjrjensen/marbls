class_name MoveResolver
extends RefCounted
## Applies a legal [Move] to a [GameState] and reports what happened.
## Only [Match] calls this.


func apply(state: GameState, move: Move) -> Array[MatchEvent]:
	var events: Array[MatchEvent] = []
	for step: MarbleStep in move.steps:
		var victims_from: Array[Spot] = []
		for victim: MarbleRef in step.kills:
			victims_from.append(state.spot_of(victim))
		apply_step(state, step)
		events.append(MatchEvent.marble_moved(move, step))
		for i: int in step.kills.size():
			events.append(MatchEvent.marble_killed(step.marble, step.kills[i], victims_from[i]))
	return events


## Moves one marble and sends anything it killed back to its Starting Block.
static func apply_step(state: GameState, step: MarbleStep) -> void:
	for victim: MarbleRef in step.kills:
		state.player(victim.seat).marbles[victim.marble] = Spot.starting_block()
		state.player(victim.seat).fast_track_ready[victim.marble] = false
	state.player(step.marble.seat).marbles[step.marble.marble] = step.to
