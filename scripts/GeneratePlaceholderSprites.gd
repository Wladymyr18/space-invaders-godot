## GeneratePlaceholderSprites.gd
## Run this ONCE via Godot's "Run > Execute Script" (Ctrl+Shift+X) from the
## editor to generate programmatic placeholder textures for all entities.
## Delete this script after real art assets are imported.
##
## Usage: In Godot editor — Script > Run Current Script
@tool
extends EditorScript

func _run() -> void:
    _make_ship("res://assets/sprites/player_ship.png",    Color(0.2, 0.8, 1.0), 32, 32)
    _make_ship("res://assets/sprites/enemy_grunt.png",    Color(0.4, 1.0, 0.4), 28, 22)
    _make_ship("res://assets/sprites/enemy_soldier.png",  Color(0.4, 0.7, 1.0), 28, 22)
    _make_ship("res://assets/sprites/enemy_commander.png",Color(1.0, 0.4, 0.4), 28, 22)
    _make_ship("res://assets/sprites/boss.png",           Color(1.0, 0.3, 0.3), 80, 50)
    _make_bullet("res://assets/sprites/player_bullet.png",Color(0.2, 1.0, 1.0), 6, 16)
    _make_bullet("res://assets/sprites/enemy_bullet.png", Color(1.0, 0.3, 0.1), 6, 14)
    _make_star("res://assets/sprites/powerup.png",         Color(1.0, 0.85, 0.0), 24)
    _make_ship("res://assets/sprites/icon.png",            Color(0.2, 1.0, 0.4), 128, 128)
    print("Placeholder sprites generated in res://assets/sprites/")

func _make_ship(path: String, color: Color, w: int, h: int) -> void:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    # Draw a simple filled rect as placeholder
    for x in w:
        for y in h:
            if _in_ship_outline(x, y, w, h):
                img.set_pixel(x, y, color)
    img.save_png(path)
    var tex := ImageTexture.create_from_image(img)
    ResourceSaver.save(tex, path)

func _in_ship_outline(x: int, y: int, w: int, h: int) -> bool:
    # Rough triangle / diamond fill
    var cx: float = w / 2.0
    var pct_y: float = float(y) / float(h)
    var half_w: float = cx * (1.0 - pct_y * 0.7)
    return abs(x - cx) < half_w

func _make_bullet(path: String, color: Color, w: int, h: int) -> void:
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(color)
    img.save_png(path)

func _make_star(path: String, color: Color, size: int) -> void:
    var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var c: int = size / 2
    for x in size:
        for y in size:
            var dx: float = abs(x - c)
            var dy: float = abs(y - c)
            if dx + dy <= c:
                img.set_pixel(x, y, color)
    img.save_png(path)
