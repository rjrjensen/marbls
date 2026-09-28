class_name LookaheadEvaluator
extends MoveEvaluator
## Thinks one card ahead: for each card still in its own deck (it can count
## what it has played), how much progress would its best next move make from
## the position this move leaves? Averages over the cards it expects.
##
## [member memory] blurs the count toward a fresh deck: 1.0 counts perfectly,
## 0.0 just assumes any card is as likely as in a new deck.

var memory: float = 1.0
var _generator: MoveGenerator


func _init(p_memory: float) -> void:
	memory = p_memory


func score(context: MoveContext) -> float:
	if _generator == null:
		_generator = MoveGenerator.new(context.rules)
	var odds: Dictionary[int, float] = expected_next_card_odds(context.before.player(context.seat).deck, context.rules)
	var total: float = 0.0
	for rank: int in odds:
		total += odds[rank] * _best_next_progress(context, rank as Card.Rank)
	return total


## Probability of each rank being the next card, as this AI believes it.
func expected_next_card_odds(deck: Deck, rules: RuleSet) -> Dictionary[int, float]:
	var remaining: Dictionary[int, float] = {}
	var fresh: Dictionary[int, float] = {}
	for rank: int in range(Card.Rank.ACE, Card.Rank.JOKER + 1):
		var per_deck: float = float(rules.jokers_per_deck) if rank == Card.Rank.JOKER else 4.0
		fresh[rank] = per_deck / (52.0 + rules.jokers_per_deck)
		remaining[rank] = 0.0
	for card: Card in deck.draw_pile:
		remaining[card.rank] += 1.0
	var left: float = float(deck.draw_pile.size())
	var odds: Dictionary[int, float] = {}
	for rank: int in fresh:
		var counted: float = remaining[rank] / left if left > 0.0 else fresh[rank]
		odds[rank] = memory * counted + (1.0 - memory) * fresh[rank]
	return odds


## The most progress any single marble of the team could make with a card of
## [param rank] from the position after the move (a cheap stand-in for the
## full move list: no splits or swaps).
func _best_next_progress(context: MoveContext, rank: Card.Rank) -> float:
	var best: float = 0.0
	var rules: RuleSet = context.rules
	var after: GameState = context.after
	for member: int in context.team:
		var player: PlayerState = after.player(member)
		for i: int in player.marbles.size():
			var ref := MarbleRef.new(member, i)
			var from: Spot = player.marbles[i]
			if from.is_starting_block():
				if rules.can_start(rank):
					best = maxf(best, ProgressEvaluator.START_BONUS)
				continue
			var before_progress: float = BoardMetrics.progress(after, member, from)
			for step: MarbleStep in _generator.marble_steps(after, ref, rules.steps_for(rank), rules.moves_backward(rank)):
				best = maxf(best, BoardMetrics.progress(after, member, step.to) - before_progress)
	return best
