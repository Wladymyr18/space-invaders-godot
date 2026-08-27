## MainMenu.gd
## Attach to: res://scenes/MainMenu.tscn  (root: Control or CanvasLayer)
##
## Node tree:
##   MainMenu (Control)
##     Background (ColorRect)  — dark background
##     CenterContainer (CenterContainer)
##       VBoxContainer
##         TitleLabel (Label)     — "SPACE INVADERS PRO"
##         SubtitleLabel (Label)  — "ARCADE EDITION"
##         Spacer (Control)       — min_size (0,30)
##         PlayButton (Button)    — "PLAY"
##         HighScoresButton (Button) — "HIGH SCORES"
##         CreditsLabel (Label)   — small credits
##     VersionLabel (Label)       — bottom-left, version string
##     StarfieldParticles (GPUParticles2D)  — optional animated background
extends Control

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var play_button: Button         = $CenterContainer/VBoxContainer/PlayButton
@onready var high_scores_button: Button  = $CenterContainer/VBoxContainer/HighScoresButton
@onready var title_label: Label          = $CenterContainer/VBoxContainer/TitleLabel

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    play_button.pressed.connect(_on_play_pressed)
    high_scores_button.pressed.connect(_on_high_scores_pressed)

    AudioManager.play_music("menu_music")
    _animate_title()

    # Ensure game tree is unpaused (player may have paused before quitting)
    get_tree().paused = false

func _animate_title() -> void:
    title_label.modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
    tween.tween_interval(0.5)
    tween.set_loops()   # Gentle pulse
    tween.tween_property(title_label, "modulate:a", 0.7, 1.2)
    tween.tween_property(title_label, "modulate:a", 1.0, 1.2)

# ---------------------------------------------------------------------------
# Button handlers
# ---------------------------------------------------------------------------
func _on_play_pressed() -> void:
    AudioManager.play_sfx("shoot")
    get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_high_scores_pressed() -> void:
    AudioManager.play_sfx("shoot")
    get_tree().change_scene_to_file("res://scenes/HighScores.tscn")
