class_name MatchEvent
extends RefCounted
## Something that happened in a match. The presentation layer animates these
## and forwards them to the SignalBus; the online server sends them to clients.
##
## One class with typed, optional fields (instead of a subclass per kind) keeps
## events easy to switch on and to serialize. Unused fields stay at defaults.

enum Kind {
	GAME_STARTED,
	CARD_CUT,
	TURN_STARTED,
	DECK_RESHUFFLED,
	CARD_DRAWN,
	NO_LEGAL_MOVE,
	MARBLE_MOVED,
	MARBLE_KILLED,
	PLAYER_FINISHED,
	PLAY_AGAIN,
	GAME_OVER,
	INTENT_REJECTED,
}

var kind: Kind
var seat: int = -1
var card: Card = null
## MARBLE_MOVED: the whole move and the part of it this event describes.
var move: Move = null
var step: MarbleStep = null
## MARBLE_KILLED: who did it, who died, and where the victim was.
var killer: MarbleRef = null
var victim: MarbleRef = null
var victim_from: Spot = null
var winners: Array[int] = []
## INTENT_REJECTED: why.
var reason: String = ""


func _init(p_kind: Kind, p_seat: int = -1) -> void:
	kind = p_kind
	seat = p_seat


static func with_card(p_kind: Kind, p_seat: int, p_card: Card) -> MatchEvent:
	var event := MatchEvent.new(p_kind, p_seat)
	event.card = p_card
	return event


static func marble_moved(p_move: Move, p_step: MarbleStep) -> MatchEvent:
	var event := MatchEvent.new(Kind.MARBLE_MOVED, p_step.marble.seat)
	event.move = p_move
	event.step = p_step
	event.card = p_move.card
	return event


static func marble_killed(p_killer: MarbleRef, p_victim: MarbleRef, p_victim_from: Spot) -> MatchEvent:
	var event := MatchEvent.new(Kind.MARBLE_KILLED, p_killer.seat)
	event.killer = p_killer
	event.victim = p_victim
	event.victim_from = p_victim_from
	return event


static func game_over(p_winners: Array[int]) -> MatchEvent:
	var event := MatchEvent.new(Kind.GAME_OVER)
	event.winners = p_winners.duplicate()
	return event


static func rejected(p_seat: int, p_reason: String) -> MatchEvent:
	var event := MatchEvent.new(Kind.INTENT_REJECTED, p_seat)
	event.reason = p_reason
	return event


func _to_string() -> String:
	var text: String = Kind.keys()[kind]
	if seat >= 0:
		text += " seat%d" % seat
	if card != null:
		text += " %s" % card
	if step != null:
		text += " %s" % step
	if victim != null:
		text += " victim=%s" % victim
	if not winners.is_empty():
		text += " winners=%s" % [winners]
	if reason != "":
		text += " (%s)" % reason
	return text
