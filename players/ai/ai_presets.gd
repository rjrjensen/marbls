class_name AIPresets
extends RefCounted
## The built-in personalities (players/ai/profiles), in the order new
## computer opponents are seated.

const PROFILES: Array[AIProfile] = [
	preload("res://players/ai/profiles/kelsey.tres"),
	preload("res://players/ai/profiles/jordan.tres"),
	preload("res://players/ai/profiles/grandmaster.tres"),
	preload("res://players/ai/profiles/turtle.tres"),
	preload("res://players/ai/profiles/rookie.tres"),
]


static func for_opponent(index: int) -> AIProfile:
	return PROFILES[index % PROFILES.size()]


static func named(display_name: String) -> AIProfile:
	for profile: AIProfile in PROFILES:
		if profile.display_name == display_name:
			return profile
	return null
