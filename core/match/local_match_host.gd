class_name LocalMatchHost
extends RefCounted
## Runs a [Match] in-process. Hot-seat and vs-AI games talk to this; online
## games talk to a RemoteMatchHost with the same shape, and the server runs a
## LocalMatchHost per table.

## Everything one intent (or the start) caused, in order. Events arrive in
## batches so listeners see the state only after the whole batch applied.
signal events_emitted(events: Array[MatchEvent])

var _match: Match


func _init(p_match: Match) -> void:
	_match = p_match


func start() -> void:
	_emit_all(_match.start())


func submit(intent: MatchIntent) -> void:
	_emit_all(_match.submit(intent))


## Read-only view of the game. Callers must not modify it.
func state() -> GameState:
	return _match.state


func legal_moves() -> Array[Move]:
	return _match.legal_moves()


func _emit_all(events: Array[MatchEvent]) -> void:
	events_emitted.emit(events)
