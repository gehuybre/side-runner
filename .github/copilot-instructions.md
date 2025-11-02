# GitHub Copilot Instructions - Side Runner Game

## Project Overview
Godot 4.5 endless runner with 3-lane movement, obstacle avoidance, and mobile/desktop support. Uses component-based architecture with autoloaded singletons for cross-scene state management.

## Architecture & Critical Patterns

### Lane System Synchronization
**CRITICAL**: Player and Spawner must maintain identical lane coordinates via signal communication:
```gdscript
# Player emits lanes_updated signal in _ready()
lanes_updated.emit(lanes)
# Spawner receives and syncs: player.lanes_updated.connect(_on_lanes_updated)
```
- Player calculates lanes dynamically based on `lane_gap_ratio` (25% of viewport height)
- Custom lanes override via `custom_lanes_y` export array
- Lane index clamped to [0,2] range with `clamp(lane_index, 0, lanes.size() - 1)`

### World Speed Coordination (630.0 px/s canonical)
**Must sync across**: Spawner `world_speed` → Obstacles `speed` → Parallax `autoscroll`
```gdscript
# Spawner injects speed into obstacles during instantiation
if inst.has_method("set") and "speed" in inst:
    inst.set("speed", world_speed)
```

### Autoload Singletons Pattern
- `GameManager`: Scene management, high score persistence to `user://highscore.save`
- `MobileManager`: Platform detection, touch control auto-configuration
- Access via direct reference: `GameManager.update_high_score(score)`

### Signal-Based Collision System
Obstacles emit `hit_player` signal, use `Area2D.body_entered` with player detection logic:
```gdscript
# Standard pattern in all obstacle scripts
if parent and parent.name == "Player":
    hit_player.emit()
    queue_free()
```

## Mobile Architecture

### Dual Input System
- **Desktop**: `lane_up`/`lane_down` input actions (Up/Down arrows, Escape for pause)
- **Mobile**: Touch controls auto-discovered via scene tree traversal
- Player connects to touch controls: `touch_controls.lane_up_pressed.connect(_on_touch_lane_up)`

### Platform Detection & Auto-Configuration
```gdscript
# MobileManager._detect_platform()
is_mobile_platform = OS.get_name() in ["Android", "iOS"]
# Touch controls show/hide automatically via MobileManager._configure_touch_controls()
```

## Development Workflows

### Testing Mobile on Desktop
- Set `MobileManager.force_mobile_mode = true` in editor (or run `./test-mobile-mode.sh` to toggle the flag and launch Godot)
- Touch controls become visible and functional with mouse
- Use `pointing/emulate_touch_from_mouse=true` project setting

### Build & Deploy (macOS)
```bash
# Desktop test
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/world-1.tscn

# Full Android pipeline (export + sideload to the first connected device)
./build-and-sideload.sh

# Manual export (requires Android SDK + Java configured)
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=$HOME/Library/Android/sdk
/Applications/Godot.app/Contents/MacOS/Godot --headless --export-debug "Android" output.apk --path .

# Manual sideload if you already have an APK
./sideload-apk.sh path/to/app.apk
```

### Scene Instantiation Pattern
```gdscript
# spawner.gd standard pattern
var inst := scene.instantiate()
var n2d := inst as Node2D
n2d.position = Vector2(start_x, lanes_y[lane_idx])
get_parent().add_child(inst)  # Add to world, not spawner
```

## File Organization Rules
- **Scripts**: `scripts/component-name.gd` (kebab-case for multi-word)
- **Scenes**: `scenes/component-name.tscn` (matches script naming)
- **Main scene**: `main_menu.tscn` (defined in project.godot)
- **Assets**: By type (`Character/`, `Background/`, `Mob/`) with `.aseprite` sources preserved

## Common Pitfalls
- **Lane desync**: Always emit `lanes_updated` signal when player lanes change
- **Speed mismatch**: Verify `world_speed` propagation to all moving elements
- **Touch control discovery**: Check scene tree paths in `_connect_touch_controls()`
- **Mobile testing**: Use `force_mobile_mode` rather than changing OS detection
- **Collision detection**: Check both direct Player node and parent relationships
- **Scene changes**: Use `GameManager.change_to_scene()` not direct `get_tree().change_scene_to_file()`

## Tooling Notes
- `export-android.sh` performs a headless export into `/tmp/android-export/side-runner.apk` after syncing editor SDK paths.
- `sideload-config.conf` holds defaults for `sideload-apk.sh` (APK path, package id); scripts should read from it instead of hardcoding values.
- `android-diagnostic.sh` validates Java/SDK paths and Godot export templates; run when export scripts fail.
- Prefer keeping generated APK/ZIP artifacts out of version control or move large binaries to Git LFS to avoid future push warnings.
