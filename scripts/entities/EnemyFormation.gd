## EnemyFormation.gd
## Manages the classic Space Invaders grid of enemies.
## Attach to: res://scenes/EnemyFormation.tscn  (Node2D root)
## The formation moves left/right, drops down when hitting walls,
## and speeds up as enemies are destroyed.
extends Node2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal formation_cleared()
signal bullet_spawned(bullet: Node2D, pos: Vector2, dir: Vector2)

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var enemy_scene: PackedScene    = preload("res://scenes/Enemy.tscn")
@export var enemy_bullet_scene: PackedScene = preload("res://scenes/EnemyBullet.tscn")
@export var columns: int               = 11
@export var rows: int                  = 5
@export var h_spacing: float           = 40.0
@export var v_spacing: float           = 36.0
@export var base_move_speed: float     = 40.0   ## px/s horizontal
@export var drop_distance: float       = 20.0   ## px dropped per wall hit
@export var speed_scale_per_kill: float = 0.015 ## speed factor added per kill

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------
var _enemies: Array[Node] = []
var _move_dir: float      = 1.0    # +1 right, -1 left
var _speed: float         = 0.0
var _total_enemies: int   = 0
var _killed_count: int    = 0
var _drop_pending: bool   = false
var _left_bound: float    = 30.0
var _right_bound: float   = 450.0
var _descent_limit: float = 680.0  # y at which enemies reach player zone

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    _speed = base_move_speed

func _physics_process(delta: float) -> void:
    if _enemies.is_empty():
        return
    _move_formation(delta)
    _check_descent_gameover()

# ---------------------------------------------------------------------------
# Public — called by Game scene
# ---------------------------------------------------------------------------
func build_formation(wave: int) -> void:
    # Clear any leftover
    for e in _enemies:
        if is_instance_valid(e):
            e.queue_free()
    _enemies.clear()
    _killed_count = 0
    _move_dir = 1.0
    _drop_pending = false

    # Scale difficulty per wave
    var extra_health: int  = (wave - 1) / 3
    var type_thresholds := _get_type_distribution(wave)

    _total_enemies = columns * rows
    var start_x: float = (480.0 - (columns - 1) * h_spacing) / 2.0
    var start_y: float = 80.0

    for row in rows:
        for col in columns:
            var e: Node = enemy_scene.instantiate()
            var etype := _pick_type(row, type_thresholds)
            e.enemy_type   = etype
            e.max_health   = 1 + extra_health
            e.can_shoot    = (row == rows - 1)   # bottom row fires
            e.enemy_killed.connect(_on_enemy_killed)
            e.bullet_requested.connect(_on_bullet_requested)
            add_child(e)
            e.position = Vector2(start_x + col * h_spacing, start_y + row * v_spacing)
            _enemies.append(e)

    _speed = base_move_speed + wave * 5.0
    _update_shooters()

# ---------------------------------------------------------------------------
# Formation movement
# ---------------------------------------------------------------------------
func _move_formation(delta: float) -> void:
    if _drop_pending:
        _drop_pending = false
        _descend()
        _move_dir *= -1.0
        return

    var dx: float = _move_dir * _speed * delta
    for e in _enemies:
        if is_instance_valid(e):
            e.position.x += dx

    _check_wall_hit()

func _check_wall_hit() -> void:
    var min_x: float = INF
    var max_x: float = -INF
    for e in _enemies:
        if is_instance_valid(e):
            min_x = minf(min_x, e.global_position.x)
            max_x = maxf(max_x, e.global_position.x)
    if _move_dir > 0 and max_x >= _right_bound:
        _drop_pending = true
    elif _move_dir < 0 and min_x <= _left_bound:
        _drop_pending = true

func _descend() -> void:
    for e in _enemies:
        if is_instance_valid(e):
            e.position.y += drop_distance

func _check_descent_gameover() -> void:
    for e in _enemies:
        if is_instance_valid(e) and e.global_position.y >= _descent_limit:
            # Enemies reached the player — game over
            GameState.lose_life()
            GameState.lose_life()
            GameState.lose_life()
            return

# ---------------------------------------------------------------------------
# Enemy destroyed callback
# ---------------------------------------------------------------------------
func _on_enemy_killed(enemy: Node, points: int, pos: Vector2) -> void:
    _enemies.erase(enemy)
    _killed_count += 1
    GameState.add_score(points)

    # Speed up remaining enemies
    _speed = base_move_speed + _killed_count * speed_scale_per_kill * base_move_speed

    # Refresh which row can shoot
    _update_shooters()

    if _enemies.is_empty():
        emit_signal("formation_cleared")

func _on_bullet_requested(pos: Vector2, dir: Vector2) -> void:
    var b: Node2D = enemy_bullet_scene.instantiate()
    emit_signal("bullet_spawned", b, pos, dir)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _update_shooters() -> void:
    # Only the lowest alive enemy in each column can shoot
    var col_shooters: Dictionary = {}
    for e in _enemies:
        if not is_instance_valid(e):
            continue
        e.can_shoot = false
        var col_idx: int = int(round((e.position.x - (480.0 - (columns - 1) * h_spacing) / 2.0) / h_spacing))
        var cur_y: float = col_shooters.get(col_idx, -INF)
        if e.position.y > cur_y:
            col_shooters[col_idx] = e.position.y
    # Second pass — mark the lowest in each col
    for e in _enemies:
        if not is_instance_valid(e):
            continue
        var col_idx: int = int(round((e.position.x - (480.0 - (columns - 1) * h_spacing) / 2.0) / h_spacing))
        if col_shooters.has(col_idx) and e.position.y == col_shooters[col_idx]:
            e.can_shoot = true

func _get_type_distribution(wave: int) -> Array:
    # Returns row-index thresholds for grunt / soldier / commander
    if wave <= 2:
        return [3, 5]    # rows 0-2 grunt, 3-4 soldier
    elif wave <= 4:
        return [2, 4]    # rows 0-1 grunt, 2-3 soldier, 4 commander
    else:
        return [1, 3]    # row 0 grunt, 1-2 soldier, 3-4 commander

func _pick_type(row: int, thresholds: Array) -> String:
    if row < thresholds[0]:
        return "grunt"
    elif row < thresholds[1]:
        return "soldier"
    else:
        return "commander"
