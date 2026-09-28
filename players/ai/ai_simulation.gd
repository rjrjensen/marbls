class_name AISimulation
extends RefCounted
## Plays whole games between computer players, headless. Used by the tests
## and by tools/simulate.tscn for balancing.


## Plays one game. [param profile_names] seats the named presets (defaulting
## to the preset rotation). Returns finished, winners, kills_by_seat, turns.
static func play(
	seat_count: int, seed_value: int, teams: bool, profile_names: Array = [], max_intents: int = 20000
) -> Dictionary:
	var rules := RuleSet.new()
	if teams:
		rules.team_of_seat = RuleSet.opposite_partners(seat_count)
	var game := Match.create_standard(rules, seat_count, seed_value)
	var players: Array[AIPlayer] = []
	for seat: int in seat_count:
		var profile: AIProfile = AIPresets.named(String(profile_names[seat])) if seat < profile_names.size() \
				else AIPresets.for_opponent(seat)
		players.append(AIPlayer.new(profile, rules, seed_value * 31 + seat))
	var kills: Array[int] = []
	kills.resize(seat_count)
	kills.fill(0)
	game.start()
	var intents: int = 0
	while game.state.phase != GameState.Phase.GAME_OVER and intents < max_intents:
		var seat: int = game.state.current_seat
		var events: Array[MatchEvent]
		if game.state.phase == GameState.Phase.AWAITING_DRAW:
			events = game.submit(MatchIntent.draw_card(seat))
		else:
			var choice: int = players[seat].choose_move(game.state, seat, game.legal_moves())
			events = game.submit(MatchIntent.choose_move(seat, choice))
		for event: MatchEvent in events:
			if event.kind == MatchEvent.Kind.MARBLE_KILLED:
				kills[event.seat] += 1
		intents += 1
	return {
		"finished": game.state.phase == GameState.Phase.GAME_OVER,
		"winners": game.state.winners.duplicate(),
		"kills_by_seat": kills,
		"turns": game.state.turn_number,
	}
