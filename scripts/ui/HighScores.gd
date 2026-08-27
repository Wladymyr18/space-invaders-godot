## HighScores.gd
## Attach to: res://scenes/HighScores.tscn  (root: Control)
##
## Node tree:
##   HighScores (Control)
##     Background (ColorRect)
##     VBoxContainer
##       TitleLabel (Label)   — "HIGH SCORES"
##       ScrollContainer
##         ScoreList (VBoxContainer)  — populated at runtime
##       BackButton (Button)  — returns to main menu
##     EmptyLabel (Label)     — shown when no scores exist
extends Control

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var score_list: VBoxContainer = $VBoxContainer/ScrollContainer/ScoreList
@onready var back_button: Button       = $VBoxContainer/BackButton
@onready var empty_label: Label        = $EmptyLabel

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    back_button.pressed.connect(_on_back_pressed)
    ScoreManager.high_scores_updated.connect(_populate)
    _populate(ScoreManager.get_scores())

# ---------------------------------------------------------------------------
# Populate the list
# ---------------------------------------------------------------------------
func _populate(scores: Array) -> void:
    # Clear existing rows
    for child in score_list.get_children():
        child.queue_free()

    if scores.is_empty():
        empty_label.visible = true
        score_list.visible  = false
        return

    empty_label.visible = false
    score_list.visible  = true

    for i in scores.size():
        var entry: Dictionary = scores[i]
        var row := _make_row(i + 1, entry["name"], entry["score"])
        score_list.add_child(row)
        # Stagger entrance animation
        row.modulate.a = 0.0
        var tween := create_tween()
        tween.tween_interval(i * 0.06)
        tween.tween_property(row, "modulate:a", 1.0, 0.2)

# ---------------------------------------------------------------------------
# Row factory
# ---------------------------------------------------------------------------
func _make_row(rank: int, name: String, score: int) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)

    var rank_lbl := Label.new()
    rank_lbl.text = "%2d." % rank
    rank_lbl.custom_minimum_size.x = 36
    rank_lbl.add_theme_color_override("font_color", _rank_color(rank))

    var name_lbl := Label.new()
    name_lbl.text = name.rpad(10)
    name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))

    var score_lbl := Label.new()
    score_lbl.text = "%07d" % score
    score_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))

    row.add_child(rank_lbl)
    row.add_child(name_lbl)
    row.add_child(score_lbl)
    return row

func _rank_color(rank: int) -> Color:
    match rank:
        1: return Color(1.0, 0.85, 0.0)   # gold
        2: return Color(0.8, 0.8, 0.85)   # silver
        3: return Color(0.8, 0.5, 0.2)    # bronze
        _: return Color(0.7, 0.7, 0.7)    # grey

# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------
func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
