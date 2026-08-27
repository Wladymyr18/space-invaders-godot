## PauseMenu.gd
## Attach to: res://scenes/ui/PauseMenu.tscn  (root: CanvasLayer)
##
## Node tree:
##   PauseMenu (CanvasLayer)
##     DimRect (ColorRect)   — semi-transparent black overlay
##     CenterContainer
##       VBoxContainer
##         PausedLabel (Label)  — "PAUSED"
##         ResumeButton (Button)
##         QuitButton (Button)
extends CanvasLayer

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal resume_pressed()
signal quit_pressed()

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var quit_button: Button   = $CenterContainer/VBoxContainer/QuitButton

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    resume_button.pressed.connect(func(): emit_signal("resume_pressed"))
    quit_button.pressed.connect(func():   emit_signal("quit_pressed"))
    # Ensure pause menu still processes while game is paused
    process_mode = Node.PROCESS_MODE_ALWAYS
