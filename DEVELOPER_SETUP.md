# Space Invaders Pro — Developer Setup Guide

## Project overview

| Item | Value |
|---|---|
| Engine | Godot 4.2+ |
| Language | GDScript |
| Orientation | Portrait (480 × 854) |
| Target platform | Android APK (also runs on PC) |

---

## 1. First-time project setup

1. Open Godot 4.x and choose **Import Project**.
2. Navigate to `SpaceInvadersGodot/` and select `project.godot`.
3. The editor will import all resources automatically.

---

## 2. Generate placeholder sprites (first run only)

1. In the Godot editor, open `scripts/GeneratePlaceholderSprites.gd`.
2. Go to **File > Run** (or press Ctrl+Shift+X).
3. PNG files will be written to `assets/sprites/`.
4. Assign each texture to the relevant Sprite2D node in the scenes below.

### Sprite assignment table

| File | Scene / Node | Size |
|---|---|---|
| `player_ship.png` | Player.tscn > Sprite2D | 32×32 |
| `enemy_grunt.png` | Enemy.tscn > Sprite2D | 28×22 |
| `enemy_soldier.png` | Enemy.tscn > Sprite2D (soldier) | 28×22 |
| `enemy_commander.png` | Enemy.tscn > Sprite2D (commander) | 28×22 |
| `boss.png` | Boss.tscn > Sprite2D | 80×50 |
| `player_bullet.png` | PlayerBullet.tscn > Sprite2D | 6×16 |
| `enemy_bullet.png` | EnemyBullet.tscn > Sprite2D | 6×14 |
| `powerup.png` | PowerUp.tscn > Sprite2D | 24×24 |
| `icon.png` | Project icon (project.godot) | 128×128 |

---

## 3. Collision layers

| Layer bit | Name | Used by |
|---|---|---|
| 1 (bit 0) | World | Static walls |
| 2 (bit 1) | Player | Player body |
| 3 (bit 2) | Enemy | Enemy bodies |
| 4 (bit 3) | PlayerBullet | Player shots |
| 5 (bit 4) | EnemyBullet | Enemy shots |
| 6 (bit 5) | PowerUp | Drop pickups |

Set these in **Project > Project Settings > Layer Names > 2D Physics**.

---

## 4. Audio assets

Place audio files in `assets/audio/`. AudioManager expects:

**SFX (WAV, mono, 44100 Hz):**
- `sfx/shoot.wav`
- `sfx/explosion.wav`
- `sfx/powerup.wav`
- `sfx/boss_shoot.wav`
- `sfx/shield_hit.wav`
- `sfx/player_die.wav`
- `sfx/wave_clear.wav`

**Music (OGG Vorbis, stereo):**
- `music/menu.ogg`
- `music/game.ogg`
- `music/boss.ogg`

Free sources: OpenGameArt.org, Freesound.org, Kenney.nl (CC0 licensed).

---

## 5. AnimationPlayer animations required

### Player.tscn > AnimationPlayer
| Name | Description |
|---|---|
| `explode` | Flash white → shrink to 0 scale over 0.4 s |

### Enemy.tscn > AnimationPlayer
| Name | Description |
|---|---|
| `idle` | 2-frame alternating sprite animation (classic look) |
| `explode` | Flash + scale to 0 over 0.25 s |

### Boss.tscn > AnimationPlayer
| Name | Description |
|---|---|
| `idle` | Slow pulsing glow |
| `explode` | Large flash + particles over 0.6 s |

### PowerUp.tscn > AnimationPlayer
| Name | Description |
|---|---|
| `bob` | Sine-wave Y oscillation ±4 px, looping |

---

## 6. Scene descriptions

### MainMenu.tscn
Root `Control` fills the viewport. Dark background, centered VBox with
animated title, Play and High Scores buttons, version label bottom-left.

### Game.tscn
Root `Node2D`. Contains:
- `Background` ColorRect — deep space colour.
- `BulletContainer` Node2D — all bullets are reparented here so they
  are not destroyed when the formation reloads.
- `EntityContainer` Node2D — formation / boss / powerups spawn here.
- `Player` CharacterBody2D — always present; spawned by scene directly.
- `HUD` CanvasLayer — score, lives, touch controls.
- `PauseMenu` CanvasLayer — hidden until pause button pressed.
- `PowerUpSpawner` Node — listens for enemy kills, randomly drops.
- `WaveLabel` Label — centred, animated announcement per wave.
- `GameCamera` Camera2D — used for screen-shake effect.

### GameOver.tscn
Full-screen dark overlay. Shows final score, high-score rank if achieved,
name entry LineEdit + Submit button (only visible for new high scores),
Retry and Menu buttons.

### HighScores.tscn
ScrollContainer with dynamically built rows (rank, name, score).
Rows animate in with staggered fade. Back button returns to MainMenu.

### HUD.tscn (CanvasLayer sub-scene)
TopBar HBox: score (left), wave (centre), heart icons (right), pause button.
PowerUpBar HBox: three icons (3X, SH, SP) dimmed when inactive.
TouchControls HBox: Left / Right / Fire buttons — auto-hidden on desktop.

### PauseMenu.tscn (CanvasLayer sub-scene)
Semi-transparent dim overlay + Resume / Quit buttons.
`process_mode = PROCESS_MODE_ALWAYS` so it responds while tree is paused.

---

## 7. Android APK export steps

1. **Install Android SDK & NDK** via Android Studio or sdkmanager.
2. In Godot: **Editor > Editor Settings > Export > Android** — set SDK path.
3. **Project > Export** → select the "Android" preset.
4. Click **Export Project** → choose `.apk` format.
5. For release: add your keystore in the export preset **Keystore** section.
6. Enable **Gradle Build** for access to all Android features.

Minimum SDK: 24 (Android 7.0)  
Target SDK: 34 (Android 14)  
Architecture: arm64-v8a (covers 99% of modern devices)

---

## 8. Wave / difficulty progression

| Wave | Type | Formation | Extra health | Notes |
|---|---|---|---|---|
| 1 | Normal | 11×5 grunts | 0 | Tutorial pace |
| 2 | Normal | 11×5 mixed | 0 | Soldiers appear |
| 3 | Boss | — | +10 HP | Phase 1 boss |
| 4 | Normal | 11×5 mixed | +1 | Faster formation |
| 5 | Normal | 11×5 harder | +1 | Commanders appear |
| 6 | Boss | — | +20 HP | Phase 2/3 unlocks faster |
| ... | ... | ... | +1 per 3 waves | Continues infinitely |

---

## 9. Key signals flow

```
Player.bullet_fired  ──► Game._on_player_bullet_fired
                              └─ BulletContainer.add_child(bullet)

Enemy.enemy_killed   ──► EnemyFormation._on_enemy_killed
                              ├─ GameState.add_score(points)
                              └─ PowerUpSpawner.try_drop(pos)

EnemyFormation.formation_cleared ──► Game._on_formation_cleared
                                          └─ GameState.next_wave()

Boss.boss_killed     ──► Game._on_boss_killed
                              └─ GameState.next_wave()

GameState.game_over_triggered ──► Game._on_game_over
                                       └─ change_scene(GameOver.tscn)

GameState.lives_changed  ──► HUD._on_lives_changed (refresh hearts)
GameState.wave_changed   ──► HUD._on_wave_changed  (refresh label)
                         ──► Game._on_wave_changed  (start next wave)
```

---

## 10. Extending the game

- **New enemy types**: Add a new `enemy_type` enum value in `Enemy.gd`
  and a matching case in `_apply_type_visuals()`.
- **New power-ups**: Add entry to `GameState.active_powerups`,
  `PowerUpSpawner.DROP_TABLE`, and handle the effect in `Player.gd`.
- **New boss attacks**: Add an `_attack_*()` method in `Boss.gd` and
  call it from `_on_shoot_timer()` based on `_phase_index`.
- **Online leaderboard**: Replace `ScoreManager._save_scores()` /
  `_load_scores()` with HTTP calls to your backend.
