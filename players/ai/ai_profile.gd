class_name AIProfile
extends Resource
## An AI personality: trait sliders from 0 to 1 (see docs/DESIGN.md "AI players").
## Presets live in players/ai/profiles/*.tres; players can make their own.

@export var display_name: String = "Computer"
## Landing on opponents, even when it doesn't help win.
@export_range(0.0, 1.0) var aggression: float = 0.5
## Getting marbles out, around and home.
@export_range(0.0, 1.0) var goal_focus: float = 0.5
## Not ending where an opponent's next card can hit you.
@export_range(0.0, 1.0) var caution: float = 0.5
## Plans around the cards still in its own deck (0 = never).
@export_range(0.0, 1.0) var foresight: float = 0.0
## How well it remembers which of its cards are already played.
@export_range(0.0, 1.0) var memory: float = 0.5
## Helping and protecting teammates.
@export_range(0.0, 1.0) var teamwork: float = 0.5
## Taking the Bull's Eye and Fast Track gambles (0.5 = neutral).
@export_range(0.0, 1.0) var gambler: float = 0.5
## Random error that makes easier opponents feel human.
@export_range(0.0, 1.0) var sloppiness: float = 0.0
