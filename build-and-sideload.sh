#!/bin/bash

# Build and Sideload Script for Side Runner
# This script builds the APK and immediately sideloads it to a connected Android device

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Side Runner Build & Sideload ===${NC}"
echo ""

# Check if Java and Android SDK are configured
if [ -z "$JAVA_HOME" ]; then
    echo -e "${YELLOW}Setting up Java environment...${NC}"
    export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
    export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
fi

if [ -z "$ANDROID_HOME" ]; then
    echo -e "${YELLOW}Setting up Android SDK environment...${NC}"
    export ANDROID_HOME=~/android-sdk
fi

# Build the APK
echo -e "${BLUE}Building Android APK...${NC}"
if /Applications/Godot.app/Contents/MacOS/Godot --headless --export-debug "Android" /tmp/side-runner-final-mobile.apk --path .; then
    echo -e "${GREEN}✓ APK build successful${NC}"
else
    echo -e "${RED}❌ APK build failed${NC}"
    exit 1
fi

echo ""

# Run the sideload script
echo -e "${BLUE}Running sideload script...${NC}"
./sideload-apk.sh