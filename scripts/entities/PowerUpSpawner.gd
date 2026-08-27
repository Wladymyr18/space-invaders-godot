## PowerUpSpawner.gd
## Listens for enemy_killed signals and randomly drops power-ups.
## Attach as an autoload OR as a child Node in the Game scene.
extends Node

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var drop_chance: float        = 0.15   ## 15% base chance per kill
@export var powerup_scene: PackedScene = preload("res://scenes/PowerUp.tscn")

## Weighted distribution for which powerup drops
const DROP_TABLE: Array = [
    {"type": "triple_shot", "weight": 3},
    {"type": "shield",      "weight": 2},
    {"type": "speed_boost", "weight": 2},
]

# Target container node — set by Game scene after _ready
var _spawn_parent: Node = null

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    pass

# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------
func set_spawn_parent(parent: Node) -> void:
    _spawn_parent = parent

func try_drop(pos: Vector2) -> void:
    if randf() > drop_chance:
        return
    if not _spawn_parent:
        push_error("PowerUpSpawner: spawn parent not set!")
        return
    var ptype := _weighted_pick()
    var pu: Node = powerup_scene.instantiate()
    pu.powerup_type = ptype
    _spawn_parent.add_child(pu)
    pu.global_position = pos

# ---------------------------------------------------------------------------
# Weighted random pick
# ---------------------------------------------------------------------------
func _weighted_pick() -> String:
    var total_weight: int = 0
    for entry in DROP_TABLE:
        total_weight += entry["weight"]
    var roll: int = randi() % total_weight
    var cumulative: int = 0
    for entry in DROP_TABLE:
        cumulative += entry["weight"]
        if roll < cumulative:
            return entry["type"]
    return DROP_TABLE[0]["type"]
