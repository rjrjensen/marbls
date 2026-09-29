class_name Celebration
extends Control
## The win celebration, a nod to old Windows Solitaire: cards leap from the
## top of the screen and bounce along the bottom, leaving fading trails in the
## winners' colors. Simple for now; the big-moments milestone will fancy it up.

const GRAVITY := 2400.0
const BOUNCE := 0.8
const SPAWN_EVERY := 0.3
const RUN_SECONDS := 8.0
const STAMP_EVERY := 0.03
const TRAIL_SECONDS := 1.3
const RANKS: PackedStringArray = ["A", "K", "Q", "J", "7", "6"]

@export var card_scene: PackedScene


class Flyer:
	extends RefCounted
	var card: Control
	var velocity: Vector2


var _flyers: Array[Flyer] = []
var _colors: Array[Color] = []
var _elapsed: float = 0.0
var _spawn_timer: float = 0.0
var _stamp_timer: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


## Starts the show in the winners' colors.
func play(colors: Array[Color]) -> void:
	stop()
	_colors = colors if not colors.is_empty() else [Color.WHITE]
	_elapsed = 0.0
	visible = true
	set_process(true)


func stop() -> void:
	set_process(false)
	_flyers.clear()
	for child: Node in get_children():
		child.queue_free()


func _process(delta: float) -> void:
	_elapsed += delta
	_spawn_timer -= delta
	if _elapsed < RUN_SECONDS and _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_EVERY
		_spawn()
	_stamp_timer -= delta
	var stamp_now: bool = _stamp_timer <= 0.0
	if stamp_now:
		_stamp_timer = STAMP_EVERY

	var floor_y: float = size.y
	for flyer: Flyer in _flyers.duplicate():
		flyer.velocity.y += GRAVITY * delta
		flyer.card.position += flyer.velocity * delta
		var bottom: float = flyer.card.position.y + flyer.card.size.y
		if bottom > floor_y:
			flyer.card.position.y = floor_y - flyer.card.size.y
			flyer.velocity.y = -absf(flyer.velocity.y) * BOUNCE
		if stamp_now:
			_stamp(flyer.card)
		if flyer.card.position.x > size.x + 100.0 or flyer.card.position.x < -200.0:
			_flyers.erase(flyer)
			flyer.card.queue_free()
	if _elapsed >= RUN_SECONDS and _flyers.is_empty():
		set_process(false)


func _spawn() -> void:
	var card := card_scene.instantiate() as PanelContainer
	add_child(card)
	var color: Color = _colors[randi() % _colors.size()]
	var face := (card.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	face.border_color = color
	card.add_theme_stylebox_override("panel", face)
	var rank := card.get_node("Rank") as Label
	rank.text = RANKS[randi() % RANKS.size()]
	rank.add_theme_color_override("font_color", color.darkened(0.2))
	var from_left: bool = randf() < 0.5
	card.position = Vector2(-80.0 if from_left else size.x - 4.0, randf_range(0.05, 0.3) * size.y)
	var flyer := Flyer.new()
	flyer.card = card
	flyer.velocity = Vector2(randf_range(180.0, 380.0) * (1.0 if from_left else -1.0), randf_range(-500.0, 0.0))
	_flyers.append(flyer)


## Leaves a fading copy behind: the trail.
func _stamp(card: Control) -> void:
	var ghost := card.duplicate() as Control
	add_child(ghost)
	move_child(ghost, 0)
	ghost.position = card.position
	var fade := ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, TRAIL_SECONDS)
	fade.tween_callback(ghost.queue_free)
