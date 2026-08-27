## GameState.gd
## Autoload singleton that tracks global game state across scenes.
## Signals allow loose coupling between all game systems.
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal wave_changed(wave_number: int)
signal lives_changed(lives: int)
signal game_over_triggered()
signal game_started()

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const MAX_LIVES: int = 3
const STARTING_WAVE: int = 1

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var current_wave: int = STARTING_WAVE
var score: int = 0
var lives: int = MAX_LIVES
var is_playing: bool = false
var active_powerups: Dictionary = {
    "triple_shot": false,
    "shield": false,
    "speed_boost": false,
}
var powerup_timers: Dictionary = {}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func start_game() -> void:
    current_wave = STARTING_WAVE
    score = 0
    lives = MAX_LIVES
    is_playing = true
    _clear_all_powerups()
    emit_signal("game_started")
    emit_signal("lives_changed", lives)
    emit_signal("wave_changed", current_wave)

func next_wave() -> void:
    current_wave += 1
    emit_signal("wave_changed", current_wave)

func add_score(points: int) -> void:
    score += points
    ScoreManager.try_save_high_score(score)

func lose_life() -> void:
    if active_powerups["shield"]:
        _deactivate_powerup("shield")
        return
    lives -= 1
    emit_signal("lives_changed", lives)
    if lives <= 0:
        is_playing = false
        emit_signal("game_over_triggered")

func activate_powerup(type: String, duration: float) -> void:
    active_powerups[type] = true
    if powerup_timers.has(type) and is_instance_valid(powerup_timers[type]):
        powerup_timers[type].stop()
        powerup_timers[type].queue_free()
    var t := Timer.new()
    t.wait_time = duration
    t.one_shot = true
    t.timeout.connect(_on_powerup_expired.bind(type))
    add_child(t)
    t.start()
    powerup_timers[type] = t

func has_powerup(type: String) -> bool:
    return active_powerups.get(type, false)

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------
func _on_powerup_expired(type: String) -> void:
    _deactivate_powerup(type)

func _deactivate_powerup(type: String) -> void:
    active_powerups[type] = false
    if powerup_timers.has(type) and is_instance_valid(powerup_timers[type]):
        powerup_timers[type].queue_free()
    powerup_timers.erase(type)

func _clear_all_powerups() -> void:
    for key in active_powerups.keys():
        active_powerups[key] = false
    for key in powerup_timers.keys():
        if is_instance_valid(powerup_timers[key]):
            powerup_timers[key].stop()
            powerup_timers[key].queue_free()
    powerup_timers.clear()
