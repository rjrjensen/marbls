extends Node
## Balance check: plays many AI-vs-AI games and prints win rates and kills per
## personality. Seats rotate so no personality always sits in the same place.
##
##   scripts/simulate.sh [games] [players]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var games: int = int(args[0]) if args.size() > 0 else 40
	var seat_count: int = int(args[1]) if args.size() > 1 else 4
	var names: Array[String] = []
	for profile: AIProfile in AIPresets.PROFILES:
		names.append(profile.display_name)

	var wins: Dictionary[String, int] = {}
	var kills: Dictionary[String, int] = {}
	var seated: Dictionary[String, int] = {}
	var total_turns: int = 0
	var unfinished: int = 0
	for game_index: int in games:
		var lineup: Array = []
		for seat: int in seat_count:
			lineup.append(names[(game_index + seat) % names.size()])
		var result: Dictionary = AISimulation.play(seat_count, game_index + 1, false, lineup)
		if not result["finished"]:
			unfinished += 1
			continue
		total_turns += int(result["turns"])
		var seat_kills: Array = result["kills_by_seat"]
		for seat: int in seat_count:
			var who: String = lineup[seat]
			seated[who] = seated.get(who, 0) + 1
			kills[who] = kills.get(who, 0) + int(seat_kills[seat])
		for winner: Variant in result["winners"]:
			var winner_name: String = lineup[int(winner)]
			wins[winner_name] = wins.get(winner_name, 0) + 1

	print("\n%d games, %d players each (%d unfinished), %.0f turns on average\n" % [
		games, seat_count, unfinished, float(total_turns) / maxf(1.0, float(games - unfinished))])
	print("%-16s %6s %8s %12s" % ["Personality", "Games", "Win %", "Kills/game"])
	for who: String in names:
		var played: int = seated.get(who, 0)
		if played == 0:
			continue
		print("%-16s %6d %7.0f%% %12.1f" % [
			who, played, 100.0 * wins.get(who, 0) / played, float(kills.get(who, 0)) / played])
	get_tree().quit()
