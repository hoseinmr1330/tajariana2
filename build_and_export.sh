#!/usr/bin/env bash
set -euo pipefail

# Requires Godot 4.7.2 Standard and matching Android export templates.
# Java 17 and the Android SDK must also be configured in Godot Editor Settings.
mkdir -p build
godot --headless --editor --path . --import
godot --headless --path . --export-debug "Android" build/TajAriana.apk
printf '\nAPK created: %s/build/TajAriana.apk\n' "$PWD"
