class_name RulesTestCase
extends TestCase
## Shared setup for the special-rule tests (see docs/RULES.md).
## Classic 4-player board: seat 0 exits at 0, its Home Base entrance is 54,
## the Fast Track corners are 5, 19, 33 and 47, and 47 is seat 0's own color.

var rules := RuleSet.new()
var state: GameState = Match.create_standard(rules, 4, 1).state
var generator := MoveGenerator.new(rules)


func place(seat: int, marble: int, spot: Spot) -> void:
	state.player(seat).marbles[marble] = spot


func moves_for(seat: int, rank: Card.Rank) -> Array[Move]:
	return generator.legal_moves(state, seat, Card.new(rank, Card.Suit.SPADES))


func destinations_of(moves: Array[Move], ref: MarbleRef) -> Array[String]:
	var out: Array[String] = []
	for move: Move in moves:
		if move.steps.size() == 1 and move.steps[0].marble.equals(ref):
			out.append(str(move.steps[0].to))
	out.sort()
	return out


func sorted(items: Array[String]) -> Array[String]:
	var copy: Array[String] = items.duplicate()
	copy.sort()
	return copy


## A 4-player match where seat 0 goes first and will draw [param ranks] in order.
func _match_with_top_cards(ranks: Array[Card.Rank]) -> Match:
	var match_rules := RuleSet.new()
	match_rules.cut_for_first_seat = false
	var game := Match.create_standard(match_rules, 4, 9)
	game.start()
	var reversed: Array[Card.Rank] = ranks.duplicate()
	reversed.reverse()
	for rank: Card.Rank in reversed:
		game.state.player(0).deck.draw_pile.append(Card.new(rank, Card.Suit.HEARTS))
	return game


## Plays everyone else's turn with a card that can't move, until seat 0 is up.
func _pass_to_seat_zero(game: Match) -> void:
	while game.state.current_seat != 0 or game.state.phase != GameState.Phase.AWAITING_DRAW:
		var seat: int = game.state.current_seat
		if game.state.phase == GameState.Phase.AWAITING_DRAW:
			game.state.player(seat).deck.draw_pile.append(Card.new(Card.Rank.TWO, Card.Suit.CLUBS))
			game.submit(MatchIntent.draw_card(seat))
		else:
			game.submit(MatchIntent.choose_move(seat, 0))


func _index_to(game: Match, spot: Spot) -> int:
	for index: int in game.legal_moves().size():
		if game.legal_moves()[index].steps[0].to.equals(spot):
			return index
	return -1
