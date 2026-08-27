## Enemy.gd
## Base class for all standard enemies in the formation.
## Attach to: res://scenes/Enemy.tscn
## Node tree:
##   Enemy (Area2D)
##     Sprite2D
##     CollisionShape2D
##     AnimationPlayer
##     ShootTimer (Timer)  — randomised between enemies
extends Area2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal enemy_killed(enemy: Node, points: int, position: Vector2)
signal bullet_requested(position: Vector2, direction: Vector2)

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var max_health: int   = 1
@export var point_value: int  = 100
@export var shoot_chance: float = 0.02   ## Per-tick probability of shooting
@export var bullet_scene: PackedScene = preload("res://scenes/EnemyBullet.tscn")

## Enemy type controls sprite frame / colour tint
@export_enum("grunt", "soldier", "commander") var enemy_type: String = "grunt"

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var sprite: Sprite2D         = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var shoot_timer: Timer       = $ShootTimer

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _health: int = 1
var _alive: bool = true
## Set by EnemyFormation — whether this enemy is in the bottom row and can fire
var can_shoot: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    _health = max_health
    _apply_type_visuals()
    shoot_timer.wait_time = randf_range(1.5, 4.0)
    shoot_timer.timeout.connect(_on_shoot_timer)
    shoot_timer.start()

# ---------------------------------------------------------------------------
# Visual differentiation by type
# ---------------------------------------------------------------------------
func _apply_type_visuals() -> void:
    match enemy_type:
        "grunt":
            sprite.modulate = Color(0.6, 1.0, 0.6)   # green tint
            point_value = 100
        "soldier":
            sprite.modulate = Color(0.6, 0.8, 1.0)   # blue tint
            point_value = 200
        "commander":
            sprite.modulate = Color(1.0, 0.5, 0.5)   # red tint
            point_value = 300

# ---------------------------------------------------------------------------
# Damage
# ---------------------------------------------------------------------------
func take_hit(damage: int = 1) -> void:
    if not _alive:
        return
    _health -= damage
    _flash()
    if _health <= 0:
        _die()

func _flash() -> void:
    var tween := create_tween()
    tween.tween_property(sprite, "modulate:v", 2.5, 0.05)
    tween.tween_property(sprite, "modulate:v", 1.0, 0.05)

func _die() -> void:
    _alive = false
    AudioManager.play_sfx("explosion")
    emit_signal("enemy_killed", self, point_value, global_position)
    anim_player.play("explode")
    set_deferred("monitoring", false)
    set_deferred("monitorable", false)
    await anim_player.animation_finished
    queue_free()

# ---------------------------------------------------------------------------
# Shooting
# ---------------------------------------------------------------------------
func _on_shoot_timer() -> void:
    if not _alive or not can_shoot:
        shoot_timer.wait_time = randf_range(1.5, 4.0)
        shoot_timer.start()
        return
    _fire()
    shoot_timer.wait_time = randf_range(1.5, 4.0)
    shoot_timer.start()

func _fire() -> void:
    AudioManager.play_sfx("shoot")
    emit_signal("bullet_requested", global_position, Vector2.DOWN)
