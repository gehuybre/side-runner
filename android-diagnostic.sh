#!/bin/bash

echo "=== Godot Android Export Diagnostic ==="

# Environment setup
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/build-tools/34.0.0"

echo "Environment:"
echo "JAVA_HOME: $JAVA_HOME"
echo "ANDROID_HOME: $ANDROID_HOME"
echo "PATH includes Android tools: $(echo $PATH | grep android)"

echo ""
echo "Java Check:"
java -version 2>&1 | head -3

echo ""
echo "Android SDK Structure:"
echo "Platform tools: $(ls -la $ANDROID_HOME/platform-tools/adb 2>/dev/null || echo 'NOT FOUND')"
echo "Build tools: $(ls -la $ANDROID_HOME/build-tools/ 2>/dev/null || echo 'NOT FOUND')"
echo "Platforms: $(ls -la $ANDROID_HOME/platforms/ 2>/dev/null || echo 'NOT FOUND')"

echo ""
echo "ADB Test:"
$ANDROID_HOME/platform-tools/adb version 2>&1 | head -3

echo ""
echo "Build tools check:"
ls -la $ANDROID_HOME/build-tools/34.0.0/ | head -10

echo ""
echo "Godot Editor Settings:"
grep -E "android|java" ~/Library/Application\ Support/Godot/editor_settings-4.5.tres

echo ""
echo "Export Templates Check:"
ls -la ~/Library/Application\ Support/Godot/export_templates/4.5.1.stable/android_* | head -3

echo ""
echo "=== Attempting Export with Debug Output ==="
echo "Starting Godot export..."

# Try export with maximum verbosity
/Applications/Godot.app/Contents/MacOS/Godot \
  --path . \
  --headless \
  --verbose \
  --export-debug "Android Simple" "/tmp/side-runner-diagnostic.apk" 2>&1

echo ""
echo "Exit code: $?"
echo "Output APK: $(ls -la /tmp/side-runner-diagnostic.apk 2>/dev/null || echo 'NOT CREATED')"

echo ""
echo "=== End Diagnostic ==="