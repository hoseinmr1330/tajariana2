extends SceneTree

# Godot stores project settings in project.godot using the section name plus
# the relative key. This script writes the setting with ConfigFile, then
# verifies the exact serialized value before the texture import is launched.
const SETTING_SECTION: String = "rendering"
const SETTING_KEY: String = "textures/vram_compression/import_etc2_astc"
const SETTING_PATH: String = "rendering/textures/vram_compression/import_etc2_astc"

func _initialize() -> void:
    call_deferred("_prepare")

func _prepare() -> void:
    var project_file: String = ProjectSettings.globalize_path("res://project.godot")
    var config := ConfigFile.new()
    var load_error: int = config.load(project_file)
    if load_error != OK:
        push_error("CI PREPARE: Cannot read project.godot; error code %d" % load_error)
        quit(20)
        return

    config.set_value(SETTING_SECTION, SETTING_KEY, true)
    var save_error: int = config.save(project_file)
    if save_error != OK:
        push_error("CI PREPARE: Cannot save project.godot; error code %d" % save_error)
        quit(21)
        return

    var verification := ConfigFile.new()
    var verify_error: int = verification.load(project_file)
    if verify_error != OK:
        push_error("CI PREPARE: Cannot reload project.godot after saving.")
        quit(22)
        return

    var saved_value: Variant = verification.get_value(SETTING_SECTION, SETTING_KEY, false)
    if saved_value != true:
        push_error("CI PREPARE: ETC2/ASTC setting did not persist as true.")
        quit(23)
        return

    # Also set the live ProjectSettings value for this process. The next
    # editor/import process will read the persisted value from project.godot.
    ProjectSettings.set_setting(SETTING_PATH, true)
    var live_value: bool = bool(ProjectSettings.get_setting(SETTING_PATH, false))
    if not live_value:
        push_error("CI PREPARE: Godot did not accept the live ETC2/ASTC setting.")
        quit(24)
        return

    print("CI PREPARE: %s = true (saved and read back)" % SETTING_PATH)
    quit(0)
