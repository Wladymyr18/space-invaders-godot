## EnemyBullet.gd
## Attach to: res://scenes/EnemyBullet.tscn
## Node tree:
##   EnemyBullet (Area2D)
##     Sprite2D          — red/orange elongated rect
##     CollisionShape2D
##     VisibleOnScreenNotifier2D
extends Area2D

@export var speed: float  = 320.0
@export var damage: int   = 1

var _direction: Vector2 = Vector2.DOWN

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)
    $VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func setup(dir: Vector2 = Vector2.DOWN) -> void:
    _direction = dir.normalized()

func _physics_process(delta: float) -> void:
    position += _direction * speed * delta

func _on_area_entered(area: Node) -> void:
    if area.is_in_group("player"):
        area.take_hit()
        queue_free()

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        body.take_hit()
        queue_free()
