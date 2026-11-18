#!/usr/bin/env bash
set -euo pipefail
# Requires Godot 4.7.2 Standard + matching Android export templates, JDK 17 and Android SDK.
# For the reproducible CI build, use the GitHub Actions workflow in .github/workflows/android-apk.yml.
mkdir -p build
rm -rf .godot
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://scripts/ci_validate.gd
godot --headless --path . --export-debug "Android" build/TajAriana.apk
printf '\nAPK created: %s/build/TajAriana.apk\n' "$PWD"
