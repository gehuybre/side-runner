#!/bin/bash

# Android Export Script for Side Runner

echo "=== Side Runner Android Export Setup ==="

# Set up environment variables
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"

# Verify environment
echo "Java version:"
java -version
echo ""
echo "Android SDK location: $ANDROID_HOME"
echo "ADB location: $(which adb)"
echo ""

# Update Godot editor settings with correct paths
GODOT_SETTINGS="$HOME/Library/Application Support/Godot/editor_settings-4.5.tres"
if [ -f "$GODOT_SETTINGS" ]; then
    echo "Updating Godot editor settings..."
    # Backup original
    cp "$GODOT_SETTINGS" "$GODOT_SETTINGS.backup"
    
    # Update Android SDK path
    sed -i '' "s|export/android/android_sdk_path = \".*\"|export/android/android_sdk_path = \"$ANDROID_HOME\"|" "$GODOT_SETTINGS"
    
    # Update Java SDK path if needed
    sed -i '' "s|export/android/java_sdk_path = \".*\"|export/android/java_sdk_path = \"$JAVA_HOME\"|" "$GODOT_SETTINGS"
    
    echo "Updated Android SDK path to: $ANDROID_HOME"
    echo "Updated Java SDK path to: $JAVA_HOME"
else
    echo "Warning: Godot editor settings not found at $GODOT_SETTINGS"
fi

# Create output directory
mkdir -p /tmp/android-export

# Try export
echo ""
echo "Attempting Android export..."
echo "Export command: /Applications/Godot.app/Contents/MacOS/Godot --headless --export-debug \"Android\" \"/tmp/android-export/side-runner.apk\" --path ."
echo ""

/Applications/Godot.app/Contents/MacOS/Godot --headless --export-debug "Android" "/tmp/android-export/side-runner.apk" --path .

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Android export successful!"
    echo "APK location: /tmp/android-export/side-runner.apk"
    ls -la /tmp/android-export/
else
    echo ""
    echo "❌ Android export failed."
    echo "Common issues and solutions:"
    echo "1. Make sure Android SDK is properly installed at $ANDROID_HOME"
    echo "2. Verify Java is working: java -version"
    echo "3. Check if adb is accessible: $ANDROID_HOME/platform-tools/adb version"
    echo "4. Ensure Android templates are installed"
    echo ""
    echo "Trying alternative export with verbose output..."
    /Applications/Godot.app/Contents/MacOS/Godot --headless --export-debug "Android" "/tmp/android-export/side-runner-alt.apk" --path . --verbose
fi