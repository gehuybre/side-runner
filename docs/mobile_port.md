# Mobile Port Configuration Guide

## Overview
Side Runner has been enhanced with touch controls and mobile platform support for Android and iOS deployment.

## Features Added

### Touch Controls
- **Lane switching**: Left side touch buttons for up/down lane movement
- **Pause control**: Top-right pause button
- **Haptic feedback**: Light vibration on lane changes, medium on pause
- **Auto-detection**: Shows only on mobile platforms (or when manually enabled)
- **Customizable opacity**: Adjustable transparency for better gameplay visibility

### Mobile Manager
- **Platform detection**: Automatically detects Android/iOS platforms
- **Touch control management**: Handles visibility and configuration
- **Haptic feedback system**: Provides tactile feedback for touch interactions
- **Debug mode**: Force mobile mode on desktop for testing

### Input System
- **Dual input support**: Both keyboard and touch inputs work simultaneously
- **Touch emulation**: Mouse clicks emulate touch on desktop for testing
- **Responsive design**: Touch controls adapt to different screen sizes

## Project Settings Changes

### Display
- Added landscape orientation lock (`window/handheld/orientation=1`)
- Mobile renderer enabled (`renderer/rendering_method="mobile"`)
- Touch emulation for desktop testing (`pointing/emulate_touch_from_mouse=true`)

### Export Presets
- **Android**: Configured for API 21+ with ARM64 support
- **iOS**: Ready for App Store submission with proper identifiers
- **Permissions**: Minimal permissions (only vibrate for haptics)

## File Structure

### New Files
- `scripts/touch_controls.gd` - Touch input handling and UI
- `scripts/mobile_manager.gd` - Platform detection and mobile features
- `scenes/touch_controls.tscn` - Touch control UI scene
- `export_presets.cfg` - Android/iOS export configurations

### Modified Files
- `scripts/player.gd` - Added touch input support
- `scripts/pause_menu.gd` - Touch pause functionality
- `scripts/main_menu.gd` - Mobile mode toggle for testing
- `scenes/world-1.tscn` - Integrated touch controls
- `project.godot` - Mobile settings and autoloads

## Usage

### For Players
- **Mobile**: Touch controls appear automatically
- **Desktop**: Use arrow keys as before, or enable "Touch Controls" in main menu for testing

### For Developers
- **Testing mobile mode**: Enable the checkbox in main menu
- **Adjusting touch controls**: Modify exports in TouchControls scene
- **Haptic feedback**: Configure in MobileManager autoload

## Customization Options

### Touch Control Appearance
```gdscript
# In TouchControls script
@export var lane_button_size: Vector2 = Vector2(200, 400)
@export var button_margin: float = 50.0
@export var button_opacity: float = 0.3
@export var touch_feedback_scale: float = 1.2
```

### Mobile Manager Settings
```gdscript
# In MobileManager script
@export var auto_detect_mobile: bool = true
@export var force_mobile_mode: bool = false
@export var touch_controls_opacity: float = 0.4
@export var haptic_feedback: bool = true
```

## Export Instructions

### Android
1. Install Android SDK and set up Godot Android templates
2. Configure signing keys in export preset
3. Update package name: `com.sidrunner.game` (change as needed)
4. Build APK or AAB for Play Store

### iOS
1. Set up Xcode and iOS development certificates
2. Configure provisioning profiles in export preset
3. Update bundle identifier: `com.sidrunner.game` (change as needed)
4. Export to Xcode project for submission to App Store

## Performance Optimizations

### Mobile-Specific
- Mobile renderer for better performance on lower-end devices
- Texture filtering optimized for mobile GPUs
- Minimal permissions to reduce security warnings
- Efficient touch input handling with minimal processing overhead

### Battery Optimization
- Touch controls only visible when needed
- Haptic feedback can be disabled to save battery
- Lightweight visual feedback instead of complex animations

## Testing Checklist

### Desktop Testing
- [ ] Touch controls toggle works in main menu
- [ ] Mouse clicks simulate touch when mobile mode enabled
- [ ] Keyboard controls still work alongside touch
- [ ] Visual feedback appears on simulated touch

### Mobile Testing
- [ ] Touch controls appear automatically on mobile devices
- [ ] Lane switching responds accurately to touch
- [ ] Pause button works reliably
- [ ] Haptic feedback triggers on supported devices
- [ ] Performance remains smooth during gameplay
- [ ] Touch controls don't interfere with game view

### Cross-Platform
- [ ] Save/load works across platforms
- [ ] Settings persist between sessions
- [ ] UI scales properly on different screen sizes
- [ ] Game mechanics identical across input methods

## Troubleshooting

### Touch Controls Not Appearing
- Check if MobileManager autoload is properly configured
- Verify TouchControls scene is added to world scene
- Ensure scene tree path connections are correct

### Haptic Feedback Not Working
- Confirm device supports vibration
- Check if `permissions/vibrate=true` in export preset
- Verify haptic feedback is enabled in MobileManager

### Performance Issues
- Switch to mobile renderer in project settings
- Reduce touch control opacity
- Disable haptic feedback if needed
- Check for memory leaks in touch input handling