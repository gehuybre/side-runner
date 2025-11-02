# Menu System Documentation

## Main Menu (`scenes/main_menu.tscn`)
- Entry point of the game
- Contains Start Game, Options (placeholder), and Quit buttons
- Styled with custom fonts and button themes
- Starts the game by loading `world-1.tscn`

## Pause Menu (`scenes/pause_menu.tscn`)
- Accessible during gameplay by pressing ESC
- Integrated into `world-1.tscn` as part of the CanvasLayer
- Contains Resume, Restart, Main Menu, and Quit Game options
- Pauses the game tree when active
- Uses `PROCESS_MODE_WHEN_PAUSED` to remain functional while game is paused

## Controls
- **ESC**: Opens/closes pause menu during gameplay
- **UI Navigation**: Arrow keys to navigate menu buttons
- **Enter/Space**: Activate selected button

## Integration
- Main menu is set as the default scene in `project.godot`
- Pause menu is included in the world scene's CanvasLayer
- Both menus use the game's font assets for consistent styling
- Pause functionality works with the existing game restart system

## Scene Structure
```
World Scene:
├── Player
├── ParallaxScroller  
├── Camera2D
├── Spawner
└── CanvasLayer
    ├── HUD
    └── PauseMenu
```

## Future Enhancements
- Options menu implementation (audio settings, controls customization)
- Save/load high scores
- Level selection
- Settings persistence