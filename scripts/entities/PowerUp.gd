## PowerUp.gd
## Drops from killed enemies, drifts downward, collected by player on overlap.
## Attach to: res://scenes/PowerUp.tscn
## Node tree:
##   PowerUp (Area2D)
##     Sprite2D         — colour-coded icon
##     CollisionShape2D — small circle
##     Label            — short type name displayed beneath icon
##     VisibleOnScreenNotifier2D
##     AnimationPlayer  — gentle bob animation
extends Area2D

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var fall_speed: float    = 80.0
@export var duration: float      = 8.0    ## How long the powerup lasts after collection
@export var lifetime: float      = 10.0   ## Seconds before auto-despawn

## Type: "triple_shot" | "shield" | "speed_boost"
@export var powerup_type: String = "triple_shot"

# ---------------------------------------------------------------------------
# Color map
# ---------------------------------------------------------------------------
const TYPE_COLORS: Dictionary = {
    "triple_shot": Color(1.0, 0.85, 0.0),   # gold
    "shield":      Color(0.2, 0.6, 1.0),    # blue
    "speed_boost": Color(0.2, 1.0, 0.4),    # green
}
const TYPE_LABELS: Dictionary = {
    "triple_shot": "3X",
    "shield":      "SH",
    "speed_boost": "SP",
}

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------
@onready var sprite: Sprite2D     = $Sprite2D
@onready var label: Label         = $Label
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _age: float = 0.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    add_to_group("powerup")
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)
    $VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

    sprite.modulate = TYPE_COLORS.get(powerup_type, Color.WHITE)
    label.text      = TYPE_LABELS.get(powerup_type, "?")
    anim_player.play("bob")

func _physics_process(delta: float) -> void:
    position.y += fall_speed * delta
    _age += delta
    # Blink when close to expiring
    if _age > lifetime * 0.7:
        modulate.a = 0.5 + 0.5 * sin(_age * 12.0)
    if _age >= lifetime:
        queue_free()

# ---------------------------------------------------------------------------
# Collection
# ---------------------------------------------------------------------------
func _on_area_entered(area: Node) -> void:
    if area.is_in_group("player"):
        _collect()

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        _collect()

func _collect() -> void:
    AudioManager.play_sfx("powerup")
    GameState.activate_powerup(powerup_type, duration)
    queue_free()
