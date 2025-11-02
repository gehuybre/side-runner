#!/bin/bash

echo "🔧 Configuring Godot Android SDK Settings..."

# Set up environment
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME="$HOME/android-sdk"

GODOT_SETTINGS="$HOME/Library/Application Support/Godot/editor_settings-4.5.tres"

if [ -f "$GODOT_SETTINGS" ]; then
    echo "📝 Updating Godot editor settings..."
    
    # Backup original
    cp "$GODOT_SETTINGS" "$GODOT_SETTINGS.backup-$(date +%Y%m%d-%H%M%S)"
    
    # Update Android SDK path
    sed -i '' "s|export/android/android_sdk_path = \".*\"|export/android/android_sdk_path = \"$ANDROID_HOME\"|" "$GODOT_SETTINGS"
    
    # Update Java SDK path
    sed -i '' "s|export/android/java_sdk_path = \".*\"|export/android/java_sdk_path = \"$JAVA_HOME\"|" "$GODOT_SETTINGS"
    
    echo "✅ Updated Android SDK path to: $ANDROID_HOME"
    echo "✅ Updated Java SDK path to: $JAVA_HOME"
    
    # Verify the changes
    echo ""
    echo "📋 Current settings:"
    grep -E "android_sdk_path|java_sdk_path" "$GODOT_SETTINGS"
    
else
    echo "❌ Godot editor settings not found at: $GODOT_SETTINGS"
    echo "Please run Godot at least once to create the settings file."
fi

echo ""
echo "🎯 Next steps:"
echo "1. Close and reopen Godot"
echo "2. Go to Project → Export"
echo "3. Select Android preset"
echo "4. Verify the paths are now correctly set"
echo "5. Try exporting again"

echo ""
echo "Environment verification:"
echo "Java: $(java -version 2>&1 | head -1)"
echo "Android SDK: $(ls -d $ANDROID_HOME 2>/dev/null && echo 'Found' || echo 'Not found')"
echo "ADB: $($ANDROID_HOME/platform-tools/adb version 2>/dev/null | head -1 || echo 'Not found')"