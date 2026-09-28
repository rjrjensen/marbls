class_name MoveResolver
extends RefCounted
## Applies a legal [Move] to a [GameState] and reports what happened.
## Only [Match] calls this.


func apply(state: GameState, move: Move) -> Array[MatchEvent]:
	var events: Array[MatchEvent] = []
	for step: MarbleStep in move.steps:
		state.player(step.marble.seat).marbles[step.marble.marble] = step.to
		events.append(MatchEvent.marble_moved(move, step))
		for victim: MarbleRef in step.kills:
			var victim_from: Spot = state.spot_of(victim)
			state.player(victim.seat).marbles[victim.marble] = Spot.starting_block()
			events.append(MatchEvent.marble_killed(step.marble, victim, victim_from))
	return events
