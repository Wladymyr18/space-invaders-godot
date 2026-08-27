## GameOver.gd
## Attach to: res://scenes/GameOver.tscn  (root: Control)
##
## Node tree:
##   GameOver (Control)
##     Background (ColorRect)
##     CenterContainer
##       VBoxContainer
##         GameOverLabel (Label)  — "GAME OVER"
##         FinalScoreLabel (Label)
##         RankLabel (Label)      — "NEW HIGH SCORE #X!" or ""
##         Spacer
##         NameLineEdit (LineEdit) — only visible if new high score
##         SubmitButton (Button)  — only visible if new high score
##         RetryButton (Button)
##         MenuButton (Button)
extends Control

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var final_score_label: Label    = $CenterContainer/VBoxContainer/FinalScoreLabel
@onready var rank_label: Label           = $CenterContainer/VBoxContainer/RankLabel
@onready var name_line_edit: LineEdit    = $CenterContainer/VBoxContainer/NameLineEdit
@onready var submit_button: Button       = $CenterContainer/VBoxContainer/SubmitButton
@onready var retry_button: Button        = $CenterContainer/VBoxContainer/RetryButton
@onready var menu_button: Button         = $CenterContainer/VBoxContainer/MenuButton
@onready var game_over_label: Label      = $CenterContainer/VBoxContainer/GameOverLabel

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _final_score: int = 0
var _rank: int        = -1
var _submitted: bool  = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    _final_score = GameState.score
    _rank = ScoreManager.get_rank(_final_score)

    final_score_label.text = "SCORE: %07d" % _final_score

    if _rank != -1:
        rank_label.text = "NEW HIGH SCORE  #%d!" % _rank
        rank_label.add_theme_color_override("font_color", Color(1, 0.9, 0.1))
        name_line_edit.visible = true
        submit_button.visible  = true
        submit_button.pressed.connect(_on_submit_pressed)
    else:
        rank_label.text        = ""
        name_line_edit.visible = false
        submit_button.visible  = false

    retry_button.pressed.connect(_on_retry_pressed)
    menu_button.pressed.connect(_on_menu_pressed)

    _animate_entrance()

func _animate_entrance() -> void:
    game_over_label.modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(game_over_label, "modulate:a", 1.0, 0.8)

# ---------------------------------------------------------------------------
# Handlers
# ---------------------------------------------------------------------------
func _on_submit_pressed() -> void:
    if _submitted:
        return
    _submitted = true
    var player_name: String = name_line_edit.text.strip_edges()
    if player_name.is_empty():
        player_name = "AAA"
    ScoreManager.submit_score(player_name, _final_score)
    submit_button.disabled = true
    submit_button.text = "SAVED!"
    rank_label.text = "#%d  %s — %d" % [_rank, player_name, _final_score]

func _on_retry_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_menu_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
