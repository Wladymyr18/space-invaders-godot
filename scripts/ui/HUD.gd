## HUD.gd
## In-game heads-up display + touch controls overlay.
## Attach to: res://scenes/ui/HUD.tscn  (root: CanvasLayer)
##
## Node tree:
##   HUD (CanvasLayer)
##     MarginContainer
##       VBoxContainer
##         TopBar (HBoxContainer)
##           ScoreLabel (Label)
##           WaveLabel  (Label)
##           LivesContainer (HBoxContainer)  — heart icons
##         TouchControls (HBoxContainer)   — only visible on mobile
##           LeftButton  (TouchScreenButton or Button)
##           RightButton (TouchScreenButton or Button)
##           ShootButton (TouchScreenButton or Button)
##         PowerUpBar (HBoxContainer)
##           TripleShotIcon (TextureRect + Label)
##           ShieldIcon     (TextureRect + Label)
##           SpeedIcon      (TextureRect + Label)
extends CanvasLayer

# ---------------------------------------------------------------------------
# Signals (forwarded to Player via Game.gd)
# ---------------------------------------------------------------------------
signal left_pressed()
signal left_released()
signal right_pressed()
signal right_released()
signal shoot_pressed()
signal shoot_released()
signal pause_pressed()

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var score_label: Label         = $MarginContainer/VBoxContainer/TopBar/ScoreLabel
@onready var wave_label: Label          = $MarginContainer/VBoxContainer/TopBar/WaveLabel
@onready var lives_container: HBoxContainer = $MarginContainer/VBoxContainer/TopBar/LivesContainer
@onready var touch_controls: Control    = $MarginContainer/VBoxContainer/TouchControls
@onready var powerup_bar: HBoxContainer = $MarginContainer/VBoxContainer/PowerUpBar
@onready var triple_label: Label        = $MarginContainer/VBoxContainer/PowerUpBar/TripleShotIcon/Label
@onready var shield_label: Label        = $MarginContainer/VBoxContainer/PowerUpBar/ShieldIcon/Label
@onready var speed_label: Label         = $MarginContainer/VBoxContainer/PowerUpBar/SpeedIcon/Label

# Button refs
@onready var btn_left: Button  = $MarginContainer/VBoxContainer/TouchControls/LeftButton
@onready var btn_right: Button = $MarginContainer/VBoxContainer/TouchControls/RightButton
@onready var btn_shoot: Button = $MarginContainer/VBoxContainer/TouchControls/ShootButton
@onready var btn_pause: Button = $MarginContainer/VBoxContainer/TopBar/PauseButton

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    # Score & lives updates
    GameState.lives_changed.connect(_on_lives_changed)
    GameState.wave_changed.connect(_on_wave_changed)

    # Touch button signals
    btn_left.button_down.connect(func(): emit_signal("left_pressed"))
    btn_left.button_up.connect(func():   emit_signal("left_released"))
    btn_right.button_down.connect(func(): emit_signal("right_pressed"))
    btn_right.button_up.connect(func():   emit_signal("right_released"))
    btn_shoot.button_down.connect(func(): emit_signal("shoot_pressed"))
    btn_shoot.button_up.connect(func():   emit_signal("shoot_released"))
    btn_pause.pressed.connect(func():    emit_signal("pause_pressed"))

    # Show touch controls only on mobile
    touch_controls.visible = OS.has_feature("mobile") or OS.has_feature("android")

    _refresh_lives(GameState.lives)
    _refresh_wave(GameState.current_wave)
    _refresh_score()

func _process(_delta: float) -> void:
    _refresh_score()
    _refresh_powerup_bar()

# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------
func _on_lives_changed(lives: int) -> void:
    _refresh_lives(lives)

func _on_wave_changed(wave: int) -> void:
    _refresh_wave(wave)

# ---------------------------------------------------------------------------
# Refresh helpers
# ---------------------------------------------------------------------------
func _refresh_score() -> void:
    score_label.text = "SCORE: %07d" % GameState.score

func _refresh_wave(wave: int) -> void:
    wave_label.text = "WAVE %d" % wave

func _refresh_lives(count: int) -> void:
    for child in lives_container.get_children():
        child.queue_free()
    for i in count:
        var icon := Label.new()
        icon.text = "♥"
        icon.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
        icon.add_theme_font_size_override("font_size", 22)
        lives_container.add_child(icon)

func _refresh_powerup_bar() -> void:
    var triple: bool = GameState.has_powerup("triple_shot")
    var shield: bool = GameState.has_powerup("shield")
    var speed:  bool = GameState.has_powerup("speed_boost")

    triple_label.get_parent().modulate.a = 1.0 if triple else 0.3
    shield_label.get_parent().modulate.a = 1.0 if shield else 0.3
    speed_label.get_parent().modulate.a  = 1.0 if speed  else 0.3
