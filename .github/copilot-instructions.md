# GitHub Copilot Instructions - Side Runner Game

## Project Overview
This is a Godot 4.5 endless runner game where a player character runs through 3 fixed lanes, avoiding obstacles and collecting items. The game uses a component-based architecture with modular systems for player movement, obstacle spawning, and parallax backgrounds.

## Core Architecture Patterns

### Lane-Based Movement System
- **3-lane constraint**: All movement and spawning occurs on exactly 3 Y-coordinate lanes
- **Coordinate synchronization**: Player (`scripts/player.gd`) and Spawner (`scripts/spawner.gd`) must use matching `lanes_y` arrays
- **Fixed X positioning**: Player stays at a fixed X coordinate (`fixed_x = -400.0`) while world scrolls past
- **Tween-based transitions**: Lane changes use Godot's Tween system with `TRANS_QUAD` and `EASE_OUT`

### World Speed Synchronization
- **Global speed constant**: increasing to increase difficulty  pixels/second is the canonical world speed
- **Critical sync points**: 
  - Parallax background scrolling (`parallax_scroller.gd`)
  - Spawner world speed (`spawner.gd` `world_speed`)
  - Obstacle movement speed (`obstacle-bee.gd` `speed`)
- **Pattern**: Always pass `world_speed` from spawner to spawned obstacles via property setting

### Component Communication via Signals
- **Obstacle pattern**: All obstacles emit `hit_player` signal on collision
- **Collection pattern**: Collectibles emit `collected` signal (planned but not fully implemented)
- **Connection approach**: Spawner connects to signals during `instantiate()` using `Callable(self, "_on_*")`

### Scene Instantiation & Property Injection
```gdscript
# Standard spawning pattern from spawner.gd
var inst := scene.instantiate()
var n2d := inst as Node2D
n2d.position = Vector2(start_x, lanes_y[lane_idx])

# Inject world speed if obstacle supports it
if inst.has_method("set") and "speed" in inst:
    inst.set("speed", world_speed)
```

## File Organization & Naming
- **Scripts**: `scripts/{component-name}.gd` (kebab-case for multi-word components)
- **Scenes**: `scenes/{component-name}.tscn` (matches script naming)
- **Assets**: Organized by type (`Character/`, `Background/`, `Mob/`, etc.)
- **Exports**: All sprites as `.png` with `.import` files, source `.aseprite` files preserved

## Development Patterns

### Export Variable Conventions
- Use `@export` for all tweakable parameters (movement speeds, spawn rates, positions)
- Include default values and inline comments explaining usage
- Group related exports together (e.g., all spawn timing variables)

### Input Handling
- Custom input actions defined in `project.godot`: `lane_up` (Up Arrow), `lane_down` (Down Arrow)
- Use `_unhandled_input()` for player controls to avoid conflicts
- Validate lane bounds with `clamp()` before applying movement

### Parallax Implementation Choice
- **Two implementations**: `ParallaxBackground` (current) and `Parallax2D` (alternative)
- **Current**: Multi-layer system with manual layer multipliers (`[0.25, 0.5, 1.0]`)
- **Auto-configuration**: Both auto-detect sprite widths for seamless looping

### Obstacle Lifecycle
1. Spawned at `start_x` (right edge of screen)
2. Move left at world speed in `_process()`
3. Emit signals on collision/collection
4. Auto-destroy at `destroy_x` (far left to ensure cleanup)

## Critical Coordination Points
- **Lane Y-coordinates**: Must match between player.gd and spawner.gd
- **World speed**: Keep synchronized across parallax, spawner, and all moving objects
- **Collision detection**: Use Area2D with `body_entered` signal for obstacle interactions
- **Scene references**: Spawner holds Array[PackedScene] of obstacle types for random selection

## Debugging & Testing
- Extensive debug printing in spawner for tracking spawn events and failures
- Position logging in obstacles for movement verification
- Always test lane transitions and world speed consistency when making changes

## TODO System Integration
Comments mark incomplete features for game state management:
- Score system integration points in spawner
- Health/damage system hooks in obstacle collision
- HUD and GameManager classes (not yet implemented)