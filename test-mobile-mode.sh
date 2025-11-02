#!/bin/bash

# Test mobile mode on desktop to verify touch controls
echo "Testing mobile mode on desktop..."

# First, enable force_mobile_mode in the MobileManager script temporarily
echo "Temporarily enabling force_mobile_mode for testing..."

# Create a backup of the original file
cp scripts/mobile_manager.gd scripts/mobile_manager.gd.backup

# Replace force_mobile_mode = false with force_mobile_mode = true
sed -i '' 's/@export var force_mobile_mode: bool = false/@export var force_mobile_mode: bool = true/' scripts/mobile_manager.gd

echo "Starting Godot with mobile mode enabled..."
/Applications/Godot.app/Contents/MacOS/Godot --path . scenes/world-1.tscn

# Restore the original file after testing
echo "Restoring original mobile_manager.gd..."
mv scripts/mobile_manager.gd.backup scripts/mobile_manager.gd

echo "Test complete. Touch controls should have been visible on desktop."