## Player.gd
## Attach to: res://scenes/Player.tscn
## Node tree expected:
##   Player (CharacterBody2D)
##     Sprite2D          — ship graphic
##     CollisionShape2D  — capsule/rect
##     ShootTimer (Timer)
##     ShieldSprite (Sprite2D) — shield overlay, hidden by default
##     GunPoint (Marker2D)   — muzzle position
##     AnimationPlayer
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal bullet_fired(bullet: Node2D, position: Vector2, direction: Vector2)

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var base_speed: float         = 320.0
@export var shoot_cooldown: float     = 0.25
@export var bullet_scene: PackedScene = preload("res://scenes/PlayerBullet.tscn")

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var shoot_timer: Timer        = $ShootTimer
@onready var shield_sprite: Sprite2D   = $ShieldSprite
@onready var gun_point: Marker2D       = $GunPoint
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D          = $Sprite2D

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _can_shoot: bool     = true
var _is_dead: bool       = false
var _touch_move_dir: float = 0.0   # -1, 0, +1 set by HUD touch buttons
var _touch_shoot: bool     = false

# Screen bounds (set by Game scene)
var screen_min_x: float = 30.0
var screen_max_x: float = 450.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    shoot_timer.wait_time = shoot_cooldown
    shoot_timer.one_shot  = true
    shoot_timer.timeout.connect(_on_shoot_timer_timeout)
    shield_sprite.visible = false
    GameState.lives_changed.connect(_on_lives_changed)

func _physics_process(delta: float) -> void:
    if _is_dead:
        return
    _handle_movement(delta)
    _handle_shoot()

# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------
func _handle_movement(delta: float) -> void:
    var dir: float = 0.0
    # Keyboard
    if Input.is_action_pressed("move_left"):
        dir -= 1.0
    if Input.is_action_pressed("move_right"):
        dir += 1.0
    # Touch override
    if _touch_move_dir != 0.0:
        dir = _touch_move_dir

    var speed: float = base_speed * (1.5 if GameState.has_powerup("speed_boost") else 1.0)
    velocity.x = dir * speed
    velocity.y = 0.0
    move_and_slide()

    # Clamp to playfield
    position.x = clampf(position.x, screen_min_x, screen_max_x)

    # Tilt sprite slightly when moving
    sprite.rotation = lerp_angle(sprite.rotation, dir * 0.15, 0.2)

# ---------------------------------------------------------------------------
# Shooting
# ---------------------------------------------------------------------------
func _handle_shoot() -> void:
    var wants_shoot: bool = Input.is_action_pressed("shoot") or _touch_shoot
    if wants_shoot and _can_shoot:
        _fire()

func _fire() -> void:
    _can_shoot = false
    shoot_timer.start()
    AudioManager.play_sfx("shoot")

    if GameState.has_powerup("triple_shot"):
        _spawn_bullet(Vector2.UP)
        _spawn_bullet(Vector2(-0.3, -0.95).normalized())
        _spawn_bullet(Vector2(0.3, -0.95).normalized())
    else:
        _spawn_bullet(Vector2.UP)

func _spawn_bullet(dir: Vector2) -> void:
    var b: Node2D = bullet_scene.instantiate()
    emit_signal("bullet_fired", b, gun_point.global_position, dir)

func _on_shoot_timer_timeout() -> void:
    _can_shoot = true

# ---------------------------------------------------------------------------
# Damage / death
# ---------------------------------------------------------------------------
func take_hit() -> void:
    if _is_dead:
        return
    AudioManager.play_sfx("player_die")
    GameState.lose_life()
    if GameState.lives <= 0:
        _die()
    else:
        _flash_invincible()

func _die() -> void:
    _is_dead = true
    anim_player.play("explode")
    await anim_player.animation_finished
    queue_free()

func _flash_invincible() -> void:
    # Brief invincibility frames after taking a hit
    set_collision_layer_value(2, false)
    var tween := create_tween()
    tween.set_loops(6)
    tween.tween_property(sprite, "modulate:a", 0.2, 0.1)
    tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
    await tween.finished
    set_collision_layer_value(2, true)

func _on_lives_changed(_lives: int) -> void:
    shield_sprite.visible = GameState.has_powerup("shield")

# ---------------------------------------------------------------------------
# Touch control API (called by HUD)
# ---------------------------------------------------------------------------
func set_touch_move(dir: float) -> void:
    _touch_move_dir = dir

func set_touch_shoot(active: bool) -> void:
    _touch_shoot = active

# ---------------------------------------------------------------------------
# Shield visual sync
# ---------------------------------------------------------------------------
func _process(_delta: float) -> void:
    shield_sprite.visible = GameState.has_powerup("shield")
