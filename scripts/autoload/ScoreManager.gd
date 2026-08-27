## ScoreManager.gd
## Autoload singleton — persists and loads the top-10 local high score table.
## Scores are saved to user://high_scores.json on device storage.
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal high_scores_updated(scores: Array)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const SAVE_PATH: String = "user://high_scores.json"
const MAX_ENTRIES: int = 10

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var high_scores: Array = []   # Array of {name:String, score:int}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _load_scores()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func try_save_high_score(score: int) -> bool:
    """Returns true if the score made it into the top-10 list."""
    if score <= 0:
        return false
    if high_scores.size() < MAX_ENTRIES:
        return true
    var lowest: int = high_scores[high_scores.size() - 1]["score"]
    return score > lowest

func submit_score(player_name: String, score: int) -> void:
    """Insert score, sort descending, trim to MAX_ENTRIES and save."""
    var entry := {"name": player_name.substr(0, 10).strip_edges(), "score": score}
    high_scores.append(entry)
    high_scores.sort_custom(_sort_descending)
    if high_scores.size() > MAX_ENTRIES:
        high_scores.resize(MAX_ENTRIES)
    _save_scores()
    emit_signal("high_scores_updated", high_scores)

func get_scores() -> Array:
    return high_scores.duplicate()

func get_rank(score: int) -> int:
    """Returns 1-based rank; returns -1 if score doesn't qualify."""
    for i in high_scores.size():
        if score > high_scores[i]["score"]:
            return i + 1
    if high_scores.size() < MAX_ENTRIES:
        return high_scores.size() + 1
    return -1

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------
func _save_scores() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(high_scores, "\t"))
        file.close()

func _load_scores() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        high_scores = []
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        high_scores = []
        return
    var text := file.get_as_text()
    file.close()
    var result := JSON.parse_string(text)
    if result is Array:
        high_scores = result
        high_scores.sort_custom(_sort_descending)
    else:
        high_scores = []

func _sort_descending(a: Dictionary, b: Dictionary) -> bool:
    return a["score"] > b["score"]
