## PlayerBullet.gd
## Attach to: res://scenes/PlayerBullet.tscn
## Node tree:
##   PlayerBullet (Area2D)
##     Sprite2D
##     CollisionShape2D (small capsule)
##     VisibleOnScreenNotifier2D
extends Area2D

@export var speed: float  = 700.0
@export var damage: int   = 1

var _direction: Vector2 = Vector2.UP

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)
    $VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func setup(dir: Vector2) -> void:
    _direction = dir.normalized()

func _physics_process(delta: float) -> void:
    position += _direction * speed * delta

func _on_body_entered(body: Node) -> void:
    _hit(body)

func _on_area_entered(area: Node) -> void:
    _hit(area)

func _hit(target: Node) -> void:
    if target.has_method("take_hit"):
        target.take_hit(damage)
        queue_free()
