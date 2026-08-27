## Boss.gd
## End-of-wave boss enemy with multiple attack phases.
## Attach to: res://scenes/Boss.tscn
## Node tree:
##   Boss (CharacterBody2D)
##     Sprite2D
##     CollisionShape2D   — large rect
##     HealthBar (ProgressBar or TextureProgressBar)
##     PhaseLabel (Label) — shows current phase name
##     AnimationPlayer
##     ShootTimer (Timer)
##     MoveTimer (Timer)
##     BulletSpawnPoints (Node2D)
##       Left  (Marker2D)
##       Center(Marker2D)
##       Right (Marker2D)
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal boss_killed(points: int)
signal bullet_spawned(bullet: Node2D, pos: Vector2, dir: Vector2)

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var base_health: int          = 30
@export var point_value: int          = 5000
@export var enemy_bullet_scene: PackedScene = preload("res://scenes/EnemyBullet.tscn")

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var sprite: Sprite2D               = $Sprite2D
@onready var health_bar                     = $HealthBar
@onready var phase_label: Label             = $PhaseLabel
@onready var anim_player: AnimationPlayer   = $AnimationPlayer
@onready var shoot_timer: Timer             = $ShootTimer
@onready var move_timer: Timer              = $MoveTimer
@onready var spawn_left: Marker2D           = $BulletSpawnPoints/Left
@onready var spawn_center: Marker2D         = $BulletSpawnPoints/Center
@onready var spawn_right: Marker2D          = $BulletSpawnPoints/Right

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const PHASES: Array = [
    {"name": "Sweep",    "health_pct": 1.0,  "speed": 120.0},
    {"name": "Barrage",  "health_pct": 0.66, "speed": 180.0},
    {"name": "Frenzy",   "health_pct": 0.33, "speed": 260.0},
]
const SCREEN_MIN_X: float = 80.0
const SCREEN_MAX_X: float = 400.0

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _health: int         = 0
var _max_health: int     = 0
var _phase_index: int    = 0
var _move_dir: float     = 1.0
var _speed: float        = 120.0
var _alive: bool         = true

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    set_collision_layer_value(3, true)   # boss layer
    add_to_group("boss")

func _physics_process(delta: float) -> void:
    if not _alive:
        return
    velocity.x = _move_dir * _speed
    velocity.y = 0.0
    move_and_slide()
    position.x = clampf(position.x, SCREEN_MIN_X, SCREEN_MAX_X)
    if position.x <= SCREEN_MIN_X or position.x >= SCREEN_MAX_X:
        _move_dir *= -1.0

# ---------------------------------------------------------------------------
# Public init
# ---------------------------------------------------------------------------
func setup(wave: int) -> void:
    _max_health = base_health + wave * 10
    _health     = _max_health
    _phase_index = 0
    _speed = PHASES[0]["speed"]
    health_bar.max_value = _max_health
    health_bar.value     = _health
    phase_label.text     = PHASES[0]["name"]
    shoot_timer.wait_time = 1.2
    shoot_timer.timeout.connect(_on_shoot_timer)
    shoot_timer.start()
    AudioManager.play_music("boss_music")

# ---------------------------------------------------------------------------
# Damage
# ---------------------------------------------------------------------------
func take_hit(damage: int = 1) -> void:
    if not _alive:
        return
    _health -= damage
    health_bar.value = _health
    _flash()
    _check_phase()
    if _health <= 0:
        _die()

func _flash() -> void:
    var tween := create_tween()
    tween.tween_property(sprite, "modulate", Color(2, 2, 2), 0.05)
    tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)

func _check_phase() -> void:
    var pct: float = float(_health) / float(_max_health)
    for i in range(PHASES.size() - 1, _phase_index, -1):
        if pct <= PHASES[i]["health_pct"]:
            _enter_phase(i)
            break

func _enter_phase(index: int) -> void:
    if index <= _phase_index:
        return
    _phase_index = index
    _speed = PHASES[index]["speed"]
    phase_label.text = PHASES[index]["name"]
    # Brief warning flash
    var tween := create_tween()
    tween.tween_property(sprite, "modulate", Color(2, 0.2, 0.2), 0.2)
    tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)

func _die() -> void:
    _alive = false
    shoot_timer.stop()
    AudioManager.play_sfx("explosion")
    set_deferred("monitoring", false)
    anim_player.play("explode")
    await anim_player.animation_finished
    emit_signal("boss_killed", point_value)
    queue_free()

# ---------------------------------------------------------------------------
# Attack patterns
# ---------------------------------------------------------------------------
func _on_shoot_timer() -> void:
    if not _alive:
        return
    match _phase_index:
        0: _attack_single_column()
        1: _attack_spread()
        2: _attack_barrage()
    # Shoot faster in higher phases
    shoot_timer.wait_time = maxf(0.4, 1.2 - _phase_index * 0.3)
    shoot_timer.start()

func _attack_single_column() -> void:
    """Phase 1 — single aimed shot downward."""
    _spawn_bullet(spawn_center.global_position, Vector2.DOWN)

func _attack_spread() -> void:
    """Phase 2 — 3-way spread."""
    _spawn_bullet(spawn_left.global_position, Vector2.DOWN)
    _spawn_bullet(spawn_center.global_position, Vector2.DOWN)
    _spawn_bullet(spawn_right.global_position, Vector2.DOWN)

func _attack_barrage() -> void:
    """Phase 3 — rapid 5-way fan."""
    var angles := [-30.0, -15.0, 0.0, 15.0, 30.0]
    for a in angles:
        var dir := Vector2.DOWN.rotated(deg_to_rad(a))
        _spawn_bullet(spawn_center.global_position, dir)

func _spawn_bullet(pos: Vector2, dir: Vector2) -> void:
    var b: Node2D = enemy_bullet_scene.instantiate()
    if b.has_method("setup"):
        b.setup(dir)
    emit_signal("bullet_spawned", b, pos, dir)
    AudioManager.play_sfx("boss_shoot")
