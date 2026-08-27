## AudioManager.gd
## Autoload singleton — centralises all sound playback.
## Falls back gracefully when audio files are absent (during development).
extends Node

# ---------------------------------------------------------------------------
# Bus indices (set up in Project > Audio)
# ---------------------------------------------------------------------------
const BUS_MASTER: String = "Master"
const BUS_SFX: String    = "SFX"
const BUS_MUSIC: String  = "Music"

# ---------------------------------------------------------------------------
# Preloaded streams — replace paths once real assets are imported.
# ---------------------------------------------------------------------------
var _streams: Dictionary = {
    # SFX
    "shoot":       "res://assets/audio/sfx/shoot.wav",
    "explosion":   "res://assets/audio/sfx/explosion.wav",
    "powerup":     "res://assets/audio/sfx/powerup.wav",
    "boss_shoot":  "res://assets/audio/sfx/boss_shoot.wav",
    "shield_hit":  "res://assets/audio/sfx/shield_hit.wav",
    "player_die":  "res://assets/audio/sfx/player_die.wav",
    "wave_clear":  "res://assets/audio/sfx/wave_clear.wav",
    # Music
    "menu_music":  "res://assets/audio/music/menu.ogg",
    "game_music":  "res://assets/audio/music/game.ogg",
    "boss_music":  "res://assets/audio/music/boss.ogg",
}

var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
const SFX_POOL_SIZE: int = 8

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_audio_buses()
    # SFX pool
    for i in SFX_POOL_SIZE:
        var p := AudioStreamPlayer.new()
        p.bus = BUS_SFX
        add_child(p)
        _sfx_pool.append(p)
    # Music player
    _music_player = AudioStreamPlayer.new()
    _music_player.bus = BUS_MUSIC
    _music_player.volume_db = -6.0
    add_child(_music_player)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func play_sfx(key: String) -> void:
    if not _streams.has(key):
        push_warning("AudioManager: unknown sfx key '%s'" % key)
        return
    var path: String = _streams[key]
    if not ResourceLoader.exists(path):
        return   # Asset not yet imported — silent fallback
    var stream: AudioStream = load(path)
    var player := _get_free_sfx_player()
    if player:
        player.stream = stream
        player.play()

func play_music(key: String, loop: bool = true) -> void:
    if not _streams.has(key):
        push_warning("AudioManager: unknown music key '%s'" % key)
        return
    var path: String = _streams[key]
    if not ResourceLoader.exists(path):
        return
    var stream: AudioStream = load(path)
    if stream is AudioStreamOggVorbis:
        stream.loop = loop
    _music_player.stream = stream
    _music_player.play()

func stop_music() -> void:
    _music_player.stop()

func set_sfx_volume(linear: float) -> void:
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index(BUS_SFX),
        linear_to_db(clampf(linear, 0.0, 1.0))
    )

func set_music_volume(linear: float) -> void:
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index(BUS_MUSIC),
        linear_to_db(clampf(linear, 0.0, 1.0))
    )

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------
func _get_free_sfx_player() -> AudioStreamPlayer:
    for p in _sfx_pool:
        if not p.playing:
            return p
    # All busy — steal the first one
    return _sfx_pool[0]

func _ensure_audio_buses() -> void:
    if AudioServer.get_bus_index(BUS_SFX) == -1:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_SFX)
        AudioServer.set_bus_send(AudioServer.bus_count - 1, BUS_MASTER)
    if AudioServer.get_bus_index(BUS_MUSIC) == -1:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_MUSIC)
        AudioServer.set_bus_send(AudioServer.bus_count - 1, BUS_MASTER)
