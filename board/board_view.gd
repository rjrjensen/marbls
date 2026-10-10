class_name BoardView
extends Node3D
## Draws a [GameState]: the board, its holes and every marble.
##
## The hole layout of one arm lives in arm.tscn (and starting_block.tscn).
## Only their *placement* around the hub is computed here, because the number
## of arms changes with the number of players. Emits taps upward; the
## [GameController] decides what they mean.

signal marble_tapped(ref: MarbleRef)
## Index into the choices last passed to [method show_choices].
signal ghost_tapped(choice_index: int)

## Length of each hub edge, in hole spacings (matches the physical board).
const HUB_SIDE := 4.0
const HOP_SECONDS := 0.13
const HOP_HEIGHT := 0.45
## Sideways distance between ghosts that would sit in the same hole.
const SHARED_HOLE_SPREAD := 0.35

@export var arm_scene: PackedScene
@export var starting_block_scene: PackedScene
@export var marble_scene: PackedScene

var _topology: BoardTopology
var _track_holes: Dictionary[int, BoardHole] = {}
## Per arm: slot -> hole.
var _home_holes: Dictionary[int, Array] = {}
var _block_holes: Dictionary[int, Array] = {}
## Key "seat/marble" -> view.
var _marbles: Dictionary[String, MarbleView] = {}
var _seat_arms: Array[int] = []
var _radius: float = 10.0

@onready var _base: MeshInstance3D = $Base
@onready var _bulls_eye: BoardHole = $BullsEye
@onready var _pieces: Node3D = $Pieces
@onready var _marble_layer: Node3D = $Marbles
@onready var _ghost_layer: Node3D = $Ghosts
@onready var _hop_sound: AudioStreamPlayer = $HopSound
@onready var _kill_sound: AudioStreamPlayer = $KillSound


## Rebuilds everything for this game's board and seats.
func build(state: GameState) -> void:
	_clear()
	_topology = state.topology
	var arm_count: int = _topology.arm_count
	var apothem: float = HUB_SIDE / 2.0 / tan(PI / arm_count)
	for p: PlayerState in state.players:
		_seat_arms.append(p.arm)

	for arm: int in arm_count:
		var arm_node := arm_scene.instantiate() as Node3D
		arm_node.transform = Transform3D(Basis(Vector3.UP, -_arm_angle(arm)), arm_direction(arm) * apothem)
		_pieces.add_child(arm_node)
		_home_holes[arm] = [null, null, null, null]
		for hole: BoardHole in _holes_in(arm_node):
			if hole.role == BoardHole.Role.TRACK:
				_track_holes[_topology.wrap_index(_topology.starting_exit(arm) + hole.number)] = hole
			elif hole.role == BoardHole.Role.HOME_BASE:
				_home_holes[arm][hole.number] = hole

	for p: PlayerState in state.players:
		var color: Color = SeatColors.color(p.seat)
		var block := starting_block_scene.instantiate() as Node3D
		var corner: Vector3 = arm_direction(p.arm) * apothem + _arm_tangent(p.arm) * HUB_SIDE / 2.0
		var outward: Vector3 = (arm_direction(p.arm) + arm_direction(p.arm + 1)).normalized()
		block.transform = Transform3D(Basis(Vector3.UP, -atan2(outward.x, -outward.z)), corner)
		_pieces.add_child(block)
		(block as StartingBlock).set_color(color)
		_block_holes[p.arm] = [null, null, null, null]
		for hole: BoardHole in _holes_in(block):
			_block_holes[p.arm][hole.number] = hole
			hole.set_ring_color(color)
		for slot: int in 4:
			(_home_holes[p.arm][slot] as BoardHole).set_ring_color(color)
		_track_holes[_topology.starting_exit(p.arm)].set_ring_color(color)
		_track_holes[_topology.own_fast_track_corner(p.arm)].set_ring_color(color.darkened(0.25))

	_radius = 0.0
	for hole: BoardHole in _holes_in(_pieces):
		_radius = maxf(_radius, Vector2(hole.global_position.x, hole.global_position.z).length())
	_radius += 1.0
	var base_mesh := _base.mesh as CylinderMesh
	base_mesh.top_radius = _radius
	base_mesh.bottom_radius = _radius

	for p: PlayerState in state.players:
		for i: int in p.marbles.size():
			var view := marble_scene.instantiate() as MarbleView
			_marble_layer.add_child(view)
			view.ref = MarbleRef.new(p.seat, i)
			view.setup(SeatColors.color(p.seat), false)
			view.tapped.connect(_on_marble_tapped)
			_marbles[_key(view.ref)] = view
	sync_marbles(state)


## Distance from the center to the edge of the board.
func radius() -> float:
	return _radius


## Unit vector from the center out along an arm.
func arm_direction(arm: int) -> Vector3:
	var angle: float = _arm_angle(arm)
	return Vector3(sin(angle), 0.0, -cos(angle))


func hole_for(seat: int, marble: int, spot: Spot) -> BoardHole:
	var arm: int = _seat_arms[seat]
	match spot.kind:
		Spot.Kind.STARTING_BLOCK:
			return _block_holes[arm][marble]
		Spot.Kind.MAIN_TRACK:
			return _track_holes[spot.index]
		Spot.Kind.HOME_BASE:
			return _home_holes[arm][spot.index]
		_:
			return _bulls_eye


## Where a marble rests when it's at [param spot].
func rest_position(ref: MarbleRef, spot: Spot) -> Vector3:
	return hole_for(ref.seat, ref.marble, spot).global_position + Vector3.UP * MarbleView.REST_HEIGHT


func marble_view(ref: MarbleRef) -> MarbleView:
	return _marbles[_key(ref)]


func track_hole(track_index: int) -> BoardHole:
	return _track_holes[track_index]


func track_hole_count() -> int:
	return _track_holes.size()


## Snaps every marble to where the state says it is.
func sync_marbles(state: GameState) -> void:
	for p: PlayerState in state.players:
		for i: int in p.marbles.size():
			var ref := MarbleRef.new(p.seat, i)
			marble_view(ref).global_position = rest_position(ref, p.marbles[i])


## Makes each choice's marble glow and shows a ghost where it would go. Ghosts
## that would share a hole (a Jack's kill and its swap) are spread sideways so
## each can be tapped.
func show_choices(choices: Array[MoveChoice]) -> void:
	clear_choices()
	var positions: Array[Vector3] = []
	var sharing: Dictionary[Vector3, int] = {}
	for choice: MoveChoice in choices:
		var spot_position: Vector3 = rest_position(choice.marble, choice.to)
		positions.append(spot_position)
		sharing[spot_position] = sharing.get(spot_position, 0) + 1
	var placed: Dictionary[Vector3, int] = {}
	for index: int in choices.size():
		var choice: MoveChoice = choices[index]
		marble_view(choice.marble).set_glow(true)
		var ghost := marble_scene.instantiate() as MarbleView
		_ghost_layer.add_child(ghost)
		ghost.setup(SeatColors.color(choice.marble.seat), true)
		ghost.move_index = index
		var spot_position: Vector3 = positions[index]
		var crowd: int = sharing[spot_position]
		var slot: int = placed.get(spot_position, 0)
		placed[spot_position] = slot + 1
		ghost.global_position = spot_position + Vector3((slot - (crowd - 1) / 2.0) * SHARED_HOLE_SPREAD, 0.0, 0.0)
		ghost.set_label(choice.label)
		ghost.tapped.connect(_on_ghost_tapped)


## Makes these marbles glow (no ghosts yet): "pick a marble first".
func show_selectable_marbles(refs: Array[MarbleRef]) -> void:
	clear_choices()
	for ref: MarbleRef in refs:
		marble_view(ref).set_glow(true)


func clear_choices() -> void:
	for view: MarbleView in _marbles.values():
		view.set_glow(false)
	for ghost: Node in _ghost_layer.get_children():
		ghost.queue_free()
		_ghost_layer.remove_child(ghost)


## Moves a marble hole by hole along its path.
func play_step(step: MarbleStep, animate: bool) -> void:
	var view: MarbleView = marble_view(step.marble)
	if not animate:
		view.global_position = rest_position(step.marble, step.to)
		return
	for spot: Spot in step.path:
		var target: Vector3 = rest_position(step.marble, spot)
		# Fast Track hops and swaps cover more ground: arc higher, a bit slower.
		var distance: float = view.global_position.distance_to(target)
		var stretch: float = clampf(distance, 1.0, 5.0)
		await _hop(view, target, HOP_SECONDS * sqrt(stretch), HOP_HEIGHT * stretch)
		_play_click()


## Sends a killed marble flying back to its Starting Block.
func play_kill(victim: MarbleRef, state: GameState, animate: bool) -> void:
	var view: MarbleView = marble_view(victim)
	var target: Vector3 = rest_position(victim, state.spot_of(victim))
	if not animate:
		view.global_position = target
		return
	_kill_sound.play()
	var pop := create_tween()
	pop.tween_property(view, "scale", Vector3.ONE * 1.5, 0.08)
	pop.tween_property(view, "scale", Vector3.ONE, 0.12)
	await _hop(view, target, 0.6, 3.0)
	_play_click()


func _hop(view: MarbleView, target: Vector3, seconds: float, height: float) -> void:
	var start: Vector3 = view.global_position
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			view.global_position = start.lerp(target, t) + Vector3.UP * sin(PI * t) * height,
		0.0, 1.0, seconds
	)
	await tween.finished


## Marble on wood, pitched a little differently each time so a run of hops
## doesn't sound mechanical.
func _play_click() -> void:
	_hop_sound.pitch_scale = randf_range(0.9, 1.12)
	_hop_sound.play()


func _on_marble_tapped(view: MarbleView) -> void:
	marble_tapped.emit(view.ref)


func _on_ghost_tapped(view: MarbleView) -> void:
	ghost_tapped.emit(view.move_index)


func _arm_angle(arm: int) -> float:
	return TAU * posmod(arm, _topology.arm_count) / _topology.arm_count


func _arm_tangent(arm: int) -> Vector3:
	var angle: float = _arm_angle(arm)
	return Vector3(cos(angle), 0.0, sin(angle))


func _holes_in(root: Node) -> Array[BoardHole]:
	var found: Array[BoardHole] = []
	for child: Node in root.get_children():
		if child is BoardHole:
			found.append(child as BoardHole)
		else:
			found.append_array(_holes_in(child))
	return found


func _clear() -> void:
	clear_choices()
	for layer: Node in [_pieces, _marble_layer]:
		for child: Node in layer.get_children():
			layer.remove_child(child)
			child.queue_free()
	_track_holes.clear()
	_home_holes.clear()
	_block_holes.clear()
	_marbles.clear()
	_seat_arms.clear()


static func _key(ref: MarbleRef) -> String:
	return "%d/%d" % [ref.seat, ref.marble]
