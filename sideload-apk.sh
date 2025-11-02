#!/bin/bash

# Side Runner APK Sideloader Script
# This script installs the Side Runner APK to a connected Android device via USB
#
# Features:
# - Auto-delete: Automatically uninstalls existing app version
# - Auto-start: Automatically launches the app after installation
# - Auto-debug: Automatically starts live log monitoring for touch controls
#
# Configure behavior by changing these variables:
# - AUTO_DELETE=true/false
# - AUTO_START=true/false  
# - AUTO_DEBUG=true/false

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - Load from config file if it exists
CONFIG_FILE="sideload-config.conf"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${BLUE}Loading configuration from $CONFIG_FILE...${NC}"
    source "$CONFIG_FILE"
else
    # Default configuration
    APK_NAME="side-runner-final-mobile.apk"
    PACKAGE_NAME="com.example.siderunner"
    AUTO_DELETE=true
    AUTO_START=true
    AUTO_DEBUG=true
fi

APK_PATH="/tmp/$APK_NAME"

echo -e "${BLUE}=== Side Runner APK Sideloader ===${NC}"
echo ""

# Check if APK exists
if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}Error: APK file not found at $APK_PATH${NC}"
    echo "Make sure the APK is in the current directory or update APK_PATH"
    exit 1
fi

echo -e "${GREEN}✓ Found APK:${NC} $APK_PATH"
echo -e "${BLUE}APK Size:${NC} $(ls -lh "$APK_PATH" | awk '{print $5}')"
echo ""

# Check if ADB is installed
if ! command -v adb &> /dev/null; then
    echo -e "${RED}Error: ADB (Android Debug Bridge) is not installed or not in PATH${NC}"
    echo ""
    echo "To install ADB on macOS:"
    echo "  brew install android-platform-tools"
    echo ""
    echo "Or download Android SDK Platform Tools from:"
    echo "  https://developer.android.com/studio/releases/platform-tools"
    exit 1
fi

echo -e "${GREEN}✓ ADB found:${NC} $(which adb)"
echo ""

# Check for connected devices
echo -e "${BLUE}Checking for connected devices...${NC}"
adb devices -l

DEVICE_COUNT=$(adb devices | grep -v "List of devices" | grep -c "device$" || true)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${RED}Error: No Android devices connected or authorized${NC}"
    echo ""
    echo "Please ensure:"
    echo "1. Device is connected via USB"
    echo "2. USB Debugging is enabled in Developer Options"
    echo "3. You've authorized this computer on the device"
    echo "4. Device shows up in 'adb devices' command"
    exit 1
elif [ "$DEVICE_COUNT" -gt 1 ]; then
    echo -e "${YELLOW}Warning: Multiple devices connected${NC}"
    echo "This script will install to the first available device"
    echo ""
fi

echo -e "${GREEN}✓ Found $DEVICE_COUNT connected device(s)${NC}"
echo ""

# Check if app is already installed and auto-uninstall if configured
echo -e "${BLUE}Checking if app is already installed...${NC}"
if adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
    echo -e "${YELLOW}App is already installed${NC}"
    if [ "$AUTO_DELETE" = true ]; then
        echo -e "${BLUE}Auto-uninstalling existing app...${NC}"
        if adb uninstall "$PACKAGE_NAME"; then
            echo -e "${GREEN}✓ Successfully uninstalled existing version${NC}"
        else
            echo -e "${YELLOW}⚠ Uninstall failed, continuing anyway...${NC}"
        fi
    else
        read -p "Do you want to uninstall the existing version first? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Uninstalling existing app...${NC}"
            adb uninstall "$PACKAGE_NAME" || echo -e "${YELLOW}Uninstall failed, continuing anyway...${NC}"
        fi
    fi
else
    echo -e "${GREEN}✓ App not currently installed${NC}"
fi
echo ""

# Install the APK
echo -e "${BLUE}Installing APK...${NC}"
echo "This may take a moment depending on APK size and device speed..."
echo ""

if adb install "$APK_PATH"; then
    echo ""
    echo -e "${GREEN}🎉 SUCCESS! APK installed successfully${NC}"
    echo ""
    echo -e "${BLUE}App Details:${NC}"
    echo "  Package: $PACKAGE_NAME"
    echo "  APK: $APK_NAME"
    echo "  Size: $(ls -lh "$APK_PATH" | awk '{print $5}')"
    echo ""
    echo -e "${GREEN}You can now find 'Side Runner' in your device's app drawer${NC}"
    
    # Auto-launch the app if configured
    if [ "$AUTO_START" = true ]; then
        echo -e "${BLUE}Auto-launching Side Runner...${NC}"
        adb shell monkey -p "$PACKAGE_NAME" 1
        
        # Wait a moment for app to start
        sleep 3
        echo -e "${GREEN}✓ App launched${NC}"
        
        # Auto-start debug monitoring if configured
        if [ "$AUTO_DEBUG" = true ]; then
            echo ""
            echo -e "${YELLOW}=== AUTO DEBUG MONITORING ===${NC}"
            echo "Monitoring touch controls, mobile manager, and game events..."
            echo "Press Ctrl+C to stop monitoring"
            echo ""
            
            # Clear logcat buffer first to see only new logs
            adb logcat -c
            
            # Start monitoring with better filtering
            adb logcat -v time | grep -E "(TouchControls|MobileManager|godot.*Touch|godot.*Lane|godot.*Game|godot.*Pause|godot.*HUD|side-runner)" --line-buffered | while IFS= read -r line; do
                # Color-code important messages
                if echo "$line" | grep -q "TouchControls"; then
                    echo -e "${BLUE}$line${NC}"
                elif echo "$line" | grep -q "MobileManager"; then
                    echo -e "${GREEN}$line${NC}"
                elif echo "$line" | grep -q "Touch.*triggered"; then
                    echo -e "${YELLOW}$line${NC}"
                elif echo "$line" | grep -q "Game.*over\|Pause\|Resume"; then
                    echo -e "${RED}$line${NC}"
                else
                    echo "$line"
                fi
            done
        else
            echo ""
            echo -e "${YELLOW}=== DEBUG INFO ===${NC}"
            echo "Monitor logs manually with:"
            echo "  adb logcat | grep -E '(TouchControls|MobileManager|godot)'"
        fi
    else
        # Offer to launch the app manually
        read -p "Do you want to launch the app now? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Launching Side Runner...${NC}"
            adb shell monkey -p "$PACKAGE_NAME" 1
            
            # Wait a moment for app to start
            sleep 2
            
            echo ""
            echo -e "${YELLOW}=== DEBUG INFO ===${NC}"
            echo "If touch controls aren't working, you can monitor logs with:"
            echo "  adb logcat | grep -E '(TouchControls|MobileManager|godot)'"
            echo ""
            echo "Press Ctrl+C to stop log monitoring when you start it."
            echo ""
            
            read -p "Do you want to start live log monitoring now? (y/N): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}Starting live log monitoring...${NC}"
                echo "Watch for TouchControls and MobileManager messages"
                echo "Press Ctrl+C to stop monitoring"
                echo ""
                adb logcat | grep -E "(TouchControls|MobileManager|godot|side-runner)"
            fi
        fi
    fi
else
    echo ""
    echo -e "${RED}❌ Installation failed${NC}"
    echo ""
    echo "Common solutions:"
    echo "1. Enable 'Install from unknown sources' in device settings"
    echo "2. Try uninstalling any existing version first"
    echo "3. Check device storage space"
    echo "4. Ensure device is not locked during installation"
    exit 1
fi

echo ""
echo -e "${BLUE}=== Installation Complete ===${NC}"