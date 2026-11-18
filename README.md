# Taj Ariana — Godot Android Strategy Game

Godot 4.7.2, GDScript, landscape 1280×720, Persian UI. This is an offline single-player strategy prototype.

## Android build

Use the GitHub Actions workflow at `.github/workflows/android-apk.yml`. It installs the matching Godot export templates and Android SDK, forces ETC2/ASTC texture import, clears and recreates the import cache, runs a Godot smoke test (settings, all image assets, main scene parsing and instantiation), exports a debug APK, checks the APK archive and verifies its signature, then uploads `Taj-Ariana-Android-APK` as an Actions artifact.

The Android preset is landscape and has one-click deployment disabled. No connected phone or emulator is required to build the APK.

## Repository layout

`project.godot`, `export_presets.cfg`, `scenes/`, `scripts/`, `assets/`, and `.github/` must be kept in their current relative locations. Put the contents of this folder in the repository root (or keep the folder as a single subdirectory; the workflow also detects that layout).

See `README_FA.md` for Persian instructions and `CHANGELOG_0.1.4_FA.md` for fixes.


Version 0.1.5 includes explicit GDScript typing fixes and a Godot-driven CI preparation step that persists and verifies the ETC2/ASTC import setting before clean texture import. Android APK builds do not require an attached device or ADB daemon.
