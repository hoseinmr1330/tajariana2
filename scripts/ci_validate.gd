extends SceneTree

const ETC2_SETTING := "rendering/textures/vram_compression/import_etc2_astc"
const ETC2_SECTION := "rendering"
const ETC2_KEY := "textures/vram_compression/import_etc2_astc"
const MAIN_SCENE := "res://scenes/main.tscn"
const REQUIRED_ASSETS := [
    "res://assets/app_icon.png",
    "res://assets/barracks.png",
    "res://assets/castle.png",
    "res://assets/commander_portrait.png",
    "res://assets/farm.png",
    "res://assets/goldmine.png",
    "res://assets/icon_archer.png",
    "res://assets/icon_cavalry.png",
    "res://assets/icon_food.png",
    "res://assets/icon_gem.png",
    "res://assets/icon_gold.png",
    "res://assets/icon_helmet.png",
    "res://assets/icon_siege.png",
    "res://assets/icon_stone.png",
    "res://assets/icon_wood.png",
    "res://assets/kingdom_ground.png",
    "res://assets/lumbermill.png",
    "res://assets/quarry.png",
    "res://assets/world_map.png",
]

func _initialize() -> void:
    call_deferred("_run_validation")

func _run_validation() -> void:
    var configured_main_scene := str(ProjectSettings.get_setting("application/run/main_scene", ""))
    if configured_main_scene != MAIN_SCENE:
        push_error("Main scene setting is incorrect: " + configured_main_scene)
        quit(1)
        return

    var orientation := int(ProjectSettings.get_setting("display/window/handheld/orientation", -1))
    if orientation != 0:
        push_error("Expected landscape orientation (0), got: " + str(orientation))
        quit(1)
        return

    var export_preset_file := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
    if export_preset_file == null:
        push_error("Android export preset file is missing or unreadable.")
        quit(10)
        return
    var export_preset_text := export_preset_file.get_as_text()
    export_preset_file.close()
    if export_preset_text.contains("screen/orientation="):
        push_error("Android export preset contains an obsolete screen/orientation option; use the project orientation setting.")
        quit(11)
        return

    var etc2_enabled: bool = bool(ProjectSettings.get_setting(ETC2_SETTING, false))
    var project_config := ConfigFile.new()
    var project_config_error: Error = project_config.load(ProjectSettings.globalize_path("res://project.godot"))
    if project_config_error != OK:
        push_error("Could not read project.godot during ETC2/ASTC validation.")
        quit(2)
        return
    var serialized_etc2: Variant = project_config.get_value(ETC2_SECTION, ETC2_KEY, false)
    print("CI CHECK: runtime %s = %s; serialized project value = %s" % [ETC2_SETTING, str(etc2_enabled), str(serialized_etc2)])
    if not etc2_enabled or serialized_etc2 != true:
        push_error("Android export blocked: ETC2/ASTC must be true both in loaded ProjectSettings and in project.godot.")
        quit(2)
        return

    var main_scene_resource := load(MAIN_SCENE)
    if main_scene_resource == null or not (main_scene_resource is PackedScene):
        push_error("Main scene could not be loaded as a PackedScene: " + MAIN_SCENE)
        quit(3)
        return

    for asset_path in REQUIRED_ASSETS:
        if load(asset_path) == null:
            push_error("Required asset failed to load: " + asset_path)
            quit(4)
            return

    var game_scene: PackedScene = main_scene_resource
    var game_root := game_scene.instantiate()
    if game_root == null:
        push_error("Main scene could not be instantiated.")
        quit(5)
        return

    root.add_child(game_root)
    await process_frame
    await process_frame

    var resource_labels: Dictionary = game_root.get("resource_labels")
    var building_buttons: Dictionary = game_root.get("building_buttons")
    if resource_labels.size() != 5 or building_buttons.size() != 6:
        push_error("The main scene did not finish building its HUD/city controls.")
        quit(6)
        return

    var body_control := game_root.get("body") as Control
    if body_control == null:
        push_error("Main scene did not create its content container.")
        quit(7)
        return

    for view_id in ["army", "world", "research", "diplomacy", "city"]:
        game_root.call("_show_view", view_id)
        await process_frame
        if body_control.get_child_count() == 0:
            push_error("Screen failed to render: " + view_id)
            quit(8)
            return

    game_root.call("_open_building", "castle")
    await process_frame
    if game_root.get("modal_layer") == null:
        push_error("Building details modal failed to open.")
        quit(9)
        return
    game_root.call("_close_modal")

    print("CI CHECK: ETC2/ASTC enabled; all assets loaded; main scene, all screens and building modal rendered.")
    quit(0)
