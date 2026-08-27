## Game.gd
## Master controller for the gameplay scene.
## Attach to: res://scenes/Game.tscn  (root Node2D)
##
## Full node tree expected:
##   Game (Node2D)
##     Background (ColorRect or ParallaxBackground)
##     BulletContainer (Node2D)   — all bullets live here
##     EntityContainer (Node2D)   — formation, boss, powerups live here
##     Player (CharacterBody2D)   — res://scenes/Player.tscn
##     HUD (CanvasLayer)          — res://scenes/ui/HUD.tscn
##     PauseMenu (CanvasLayer)    — res://scenes/ui/PauseMenu.tscn
##     PowerUpSpawner (Node)
##     WaveLabel (Label)          — "Wave X" announcement
##     GameCamera (Camera2D)      — optional screen-shake
extends Node2D

# ---------------------------------------------------------------------------
# Scene references (preloaded for zero-stutter instantiation)
# ---------------------------------------------------------------------------
@export var formation_scene: PackedScene = preload("res://scenes/EnemyFormation.tscn")
@export var boss_scene: PackedScene      = preload("res://scenes/Boss.tscn")

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var bullet_container: Node2D      = $BulletContainer
@onready var entity_container: Node2D      = $EntityContainer
@onready var player: CharacterBody2D       = $Player
@onready var hud                           = $HUD
@onready var pause_menu                    = $PauseMenu
@onready var powerup_spawner: Node         = $PowerUpSpawner
@onready var wave_label: Label             = $WaveLabel
@onready var game_camera: Camera2D         = $GameCamera

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _formation: Node = null
var _boss: Node      = null
var _wave_active: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    GameState.game_over_triggered.connect(_on_game_over)
    GameState.wave_changed.connect(_on_wave_changed)

    # Wire player bullet signal
    player.bullet_fired.connect(_on_player_bullet_fired)
    player.add_to_group("player")

    # Wire powerup spawner
    powerup_spawner.set_spawn_parent(entity_container)

    # HUD connections
    hud.connect("left_pressed",  player.set_touch_move.bind(-1.0))
    hud.connect("left_released", player.set_touch_move.bind(0.0))
    hud.connect("right_pressed", player.set_touch_move.bind(1.0))
    hud.connect("right_released",player.set_touch_move.bind(0.0))
    hud.connect("shoot_pressed",  player.set_touch_shoot.bind(true))
    hud.connect("shoot_released", player.set_touch_shoot.bind(false))
    hud.connect("pause_pressed",  _on_pause_pressed)

    pause_menu.connect("resume_pressed", _on_resume)
    pause_menu.connect("quit_pressed",   _on_quit)
    pause_menu.hide()

    wave_label.modulate.a = 0.0

    GameState.start_game()
    AudioManager.play_music("game_music")
    _start_wave(GameState.current_wave)

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        _on_pause_pressed()

# ---------------------------------------------------------------------------
# Wave management
# ---------------------------------------------------------------------------
func _start_wave(wave: int) -> void:
    _wave_active = false
    await _show_wave_label(wave)
    _wave_active = true

    if _is_boss_wave(wave):
        _spawn_boss(wave)
    else:
        _spawn_formation(wave)

func _is_boss_wave(wave: int) -> bool:
    return wave % 3 == 0   # Every third wave is a boss wave

func _spawn_formation(wave: int) -> void:
    if _formation and is_instance_valid(_formation):
        _formation.queue_free()
    _formation = formation_scene.instantiate()
    entity_container.add_child(_formation)
    _formation.bullet_spawned.connect(_on_formation_bullet_spawned)
    _formation.formation_cleared.connect(_on_formation_cleared)

    # Wire per-enemy signals for powerup drops
    _formation.connect("formation_cleared", _on_formation_cleared)
    _formation.build_formation(wave)

    # Patch per-enemy kill → powerup
    for enemy in _formation.get_children():
        if enemy.has_signal("enemy_killed"):
            enemy.enemy_killed.connect(_on_enemy_killed_powerup_check)

func _spawn_boss(wave: int) -> void:
    if _boss and is_instance_valid(_boss):
        _boss.queue_free()
    _boss = boss_scene.instantiate()
    entity_container.add_child(_boss)
    _boss.position = Vector2(240.0, 100.0)
    _boss.bullet_spawned.connect(_on_formation_bullet_spawned)
    _boss.boss_killed.connect(_on_boss_killed)
    _boss.setup(wave)

func _on_formation_cleared() -> void:
    if not _wave_active:
        return
    AudioManager.play_sfx("wave_clear")
    GameState.add_score(500)   # Bonus for clearing the wave
    await get_tree().create_timer(1.5).timeout
    GameState.next_wave()

func _on_boss_killed(_points: int) -> void:
    if not _wave_active:
        return
    AudioManager.play_sfx("wave_clear")
    AudioManager.play_music("game_music")
    GameState.add_score(1000)  # Wave clear bonus
    await get_tree().create_timer(2.0).timeout
    GameState.next_wave()

func _on_wave_changed(wave: int) -> void:
    _start_wave(wave)

# ---------------------------------------------------------------------------
# Bullet routing
# ---------------------------------------------------------------------------
func _on_player_bullet_fired(bullet: Node2D, pos: Vector2, dir: Vector2) -> void:
    bullet_container.add_child(bullet)
    bullet.global_position = pos
    if bullet.has_method("setup"):
        bullet.setup(dir)

func _on_formation_bullet_spawned(bullet: Node2D, pos: Vector2, dir: Vector2) -> void:
    bullet_container.add_child(bullet)
    bullet.global_position = pos
    if bullet.has_method("setup"):
        bullet.setup(dir)

# ---------------------------------------------------------------------------
# Power-up drop on enemy kill
# ---------------------------------------------------------------------------
func _on_enemy_killed_powerup_check(_enemy: Node, _points: int, pos: Vector2) -> void:
    powerup_spawner.try_drop(pos)

# ---------------------------------------------------------------------------
# Wave announcement
# ---------------------------------------------------------------------------
func _show_wave_label(wave: int) -> void:
    wave_label.text = ("BOSS WAVE %d!" % wave) if _is_boss_wave(wave) else ("WAVE %d" % wave)
    var tween := create_tween()
    tween.tween_property(wave_label, "modulate:a", 1.0, 0.3)
    tween.tween_interval(1.2)
    tween.tween_property(wave_label, "modulate:a", 0.0, 0.5)
    await tween.finished

# ---------------------------------------------------------------------------
# Pause
# ---------------------------------------------------------------------------
func _on_pause_pressed() -> void:
    get_tree().paused = true
    pause_menu.show()

func _on_resume() -> void:
    get_tree().paused = false
    pause_menu.hide()

func _on_quit() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ---------------------------------------------------------------------------
# Game over
# ---------------------------------------------------------------------------
func _on_game_over() -> void:
    _wave_active = false
    AudioManager.stop_music()
    await get_tree().create_timer(1.0).timeout
    # Pass final score via GameState then go to GameOver scene
    get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

# ---------------------------------------------------------------------------
# Screen shake (call when boss attacks)
# ---------------------------------------------------------------------------
func camera_shake(intensity: float = 8.0, duration: float = 0.3) -> void:
    if not game_camera:
        return
    var tween := create_tween()
    var steps: int = int(duration / 0.05)
    for i in steps:
        tween.tween_property(game_camera, "offset",
            Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.05)
    tween.tween_property(game_camera, "offset", Vector2.ZERO, 0.05)
