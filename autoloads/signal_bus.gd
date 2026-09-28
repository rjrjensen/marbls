extends Node
## Game-wide events (see docs/DESIGN.md §2). Anything that isn't a direct
## parent/child conversation goes through here: sound, animation, HUD,
## analytics and cinematics all listen without knowing about each other.
##
## The presentation layer forwards every [MatchEvent] from its match host as
## [signal match_event]. Add narrower signals as features need them.

@warning_ignore("unused_signal")
signal match_event(event: MatchEvent)
