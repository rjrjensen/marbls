class_name MoveEvaluator
extends RefCounted
## One way of judging a move. An [AIPlayer] adds up several of these, each
## weighted by a trait of its [AIProfile] (composition: personalities are just
## different weights, not different classes).


## Higher is better for the seat making the move. Roughly "spaces of progress".
func score(_context: MoveContext) -> float:
	return 0.0
