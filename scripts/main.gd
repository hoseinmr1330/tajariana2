extends Control

const SAVE_PATH := "user://tajariana_save.json"
const RESOURCE_KEYS := ["gold", "wood", "stone", "food", "gems"]
const RESOURCE_NAMES := {"gold":"طلا", "wood":"چوب", "stone":"سنگ", "food":"غذا", "gems":"الماس"}
const RESOURCE_ICONS := {
    "gold":"res://assets/icon_gold.png",
    "wood":"res://assets/icon_wood.png",
    "stone":"res://assets/icon_stone.png",
    "food":"res://assets/icon_food.png",
    "gems":"res://assets/icon_gem.png"
}
const BUILDINGS := {
    "castle": {"name":"قلعهٔ سلطنتی", "texture":"res://assets/castle.png", "base_gold":900, "base_wood":520, "base_stone":700, "gold_rate":0, "wood_rate":0, "stone_rate":0, "food_rate":0, "power":160},
    "barracks": {"name":"سربازخانه", "texture":"res://assets/barracks.png", "base_gold":620, "base_wood":420, "base_stone":260, "gold_rate":0, "wood_rate":0, "stone_rate":0, "food_rate":0, "power":110},
    "farm": {"name":"مزرعهٔ سلطنتی", "texture":"res://assets/farm.png", "base_gold":360, "base_wood":240, "base_stone":120, "gold_rate":0, "wood_rate":0, "stone_rate":0, "food_rate":38, "power":45},
    "lumbermill": {"name":"کارگاه چوب‌بری", "texture":"res://assets/lumbermill.png", "base_gold":410, "base_wood":190, "base_stone":140, "gold_rate":0, "wood_rate":32, "stone_rate":0, "food_rate":0, "power":55},
    "quarry": {"name":"معدن سنگ", "texture":"res://assets/quarry.png", "base_gold":480, "base_wood":260, "base_stone":180, "gold_rate":0, "wood_rate":0, "stone_rate":30, "food_rate":0, "power":60},
    "goldmine": {"name":"معدن طلا", "texture":"res://assets/goldmine.png", "base_gold":700, "base_wood":360, "base_stone":320, "gold_rate":42, "wood_rate":0, "stone_rate":0, "food_rate":0, "power":90}
}
const FACTIONS := [
    {"name":"اتحاد شمال", "relation":"بی‌طرف", "strength":740, "reward":420},
    {"name":"شاه‌نشین سرخ", "relation":"رقیب", "strength":980, "reward":680},
    {"name":"پادشاهی ساحل", "relation":"دوست", "strength":590, "reward":350}
]

var resources := {"gold":6400, "wood":4200, "stone":3200, "food":5600, "gems":35}
var building_levels := {"castle":2, "barracks":1, "farm":2, "lumbermill":1, "quarry":1, "goldmine":1}
var troops := {"swordsmen":180, "archers":120, "cavalry":48, "siege":8}
var research_levels := {"military":0, "agriculture":0, "engineering":0}
var faction_relations := {"north":0, "red":-10, "coast":25}
var player_level := 7
var player_xp := 340
var enemy_camps_cleared := 0
var current_view := "city"
var body: Control
var modal_layer: Control
var resource_labels: Dictionary = {}
var building_buttons: Dictionary = {}
var toast_label: Label
var tick_count := 0
var selected_building := ""
var nav_buttons: Dictionary = {}
var toast_token := 0
var power_label: Label
var level_label: Label
var rng := RandomNumberGenerator.new()

const GOLD := Color("#e7bf70")
const PALE_GOLD := Color("#f4d99b")
const DARK := Color("#111923")
const DARK_2 := Color("#1b2835")
const PANEL := Color("#172331")
const MUTED := Color("#aeb9c4")
const GREEN := Color("#8fc78c")
const RED := Color("#db8173")

func _ready() -> void:
    _install_runtime_theme()
    rng.randomize()
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _load_game()
    _build_shell()
    _update_hud()
    _show_view("city")
    var timer := Timer.new()
    timer.wait_time = 2.0
    timer.autostart = true
    timer.timeout.connect(_on_game_tick)
    add_child(timer)

func _install_runtime_theme() -> void:
    var arabic_font := SystemFont.new()
    arabic_font.font_names = PackedStringArray(["sans-serif", "Noto Naskh Arabic", "Noto Sans Arabic", "Arial"])
    var ui_theme := Theme.new()
    ui_theme.default_font = arabic_font
    ui_theme.default_font_size = 16
    theme = ui_theme

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
        _save_game()

func _build_shell() -> void:
    var bg := TextureRect.new()
    bg.texture = load("res://assets/kingdom_ground.png")
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_SCALE
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    # Soft cinematic shade over the battlefield for legible HUD.
    var shade_top := ColorRect.new()
    shade_top.color = Color(0.025, 0.04, 0.055, 0.34)
    shade_top.position = Vector2(0, 0)
    shade_top.size = Vector2(1280, 118)
    shade_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade_top)

    _build_top_bar()
    body = Control.new()
    body.position = Vector2(0, 84)
    body.size = Vector2(1280, 542)
    body.clip_contents = true
    add_child(body)
    _build_bottom_bar()

    toast_label = _label(self, "", Rect2(395, 92, 490, 44), 19, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
    toast_label.visible = false
    toast_label.z_index = 100
    var toast_style := _panel_style(Color("#131d29"), GOLD, 2, 10)
    var toast_bg := Panel.new()
    toast_bg.position = Vector2(395, 92)
    toast_bg.size = Vector2(490, 44)
    toast_bg.add_theme_stylebox_override("panel", toast_style)
    toast_bg.name = "ToastBackground"
    toast_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    toast_bg.z_index = 99
    add_child(toast_bg)
    move_child(toast_bg, get_child_count() - 2)
    toast_label.z_index = 100
    toast_bg.visible = false

func _build_top_bar() -> void:
    var bar := Panel.new()
    bar.position = Vector2(0, 0)
    bar.size = Vector2(1280, 84)
    bar.add_theme_stylebox_override("panel", _panel_style(Color("#101923"), Color("#a47b43"), 2, 0))
    add_child(bar)

    var portrait := TextureRect.new()
    portrait.texture = load("res://assets/commander_portrait.png")
    portrait.position = Vector2(13, 7)
    portrait.size = Vector2(68, 68)
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(portrait)

    _label(self, "تاج آریانا", Rect2(92, 7, 225, 30), 25, PALE_GOLD)
    level_label = _label(self, "فرمانروای آریانا  •  سطح %d" % player_level, Rect2(94, 39, 235, 24), 14, MUTED)
    power_label = _label(self, "قدرت %s" % _format_num(_total_power()), Rect2(95, 61, 220, 18), 12, GREEN)

    var positions := {"gold":Vector2(342,12), "wood":Vector2(490,12), "stone":Vector2(638,12), "food":Vector2(786,12)}
    for key in ["gold", "wood", "stone", "food"]:
        _add_resource_card(key, positions[key])
    _add_resource_card("gems", Vector2(948,12), true)

    _add_small_header_button("گزارش", Rect2(1100, 16, 72, 50), Callable(self, "_open_reports"))
    _add_small_header_button("تنظیمات", Rect2(1180, 16, 86, 50), Callable(self, "_open_settings"))

func _add_resource_card(key: String, pos: Vector2, compact: bool = false) -> void:
    var w := 140.0 if not compact else 142.0
    var card := Panel.new()
    card.position = pos
    card.size = Vector2(w, 58)
    card.add_theme_stylebox_override("panel", _panel_style(Color("#1a2734"), Color("#4d5b67"), 1, 7))
    add_child(card)
    var icon := TextureRect.new()
    icon.texture = load(RESOURCE_ICONS[key])
    icon.position = Vector2(7, 11)
    icon.size = Vector2(34, 34)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(icon)
    var amount := _label(card, "", Rect2(45, 6, 88, 24), 17, PALE_GOLD)
    amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    var rate := _label(card, "", Rect2(45, 31, 88, 18), 12, GREEN)
    rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    resource_labels[key] = {"amount":amount, "rate":rate}

func _add_small_header_button(text: String, rect: Rect2, callback: Callable) -> void:
    var b := _button(self, text, rect, callback, false, 13)
    b.add_theme_stylebox_override("normal", _panel_style(Color("#1b2937"), Color("#947343"), 1, 7))
    b.add_theme_stylebox_override("hover", _panel_style(Color("#2a3b4a"), PALE_GOLD, 2, 7))

func _build_bottom_bar() -> void:
    var bar := Panel.new()
    bar.position = Vector2(0, 626)
    bar.size = Vector2(1280, 94)
    bar.add_theme_stylebox_override("panel", _panel_style(Color("#101923"), Color("#a47b43"), 2, 0))
    add_child(bar)
    var nav := [
        {"id":"city", "title":"شهر و سازه‌ها", "sub":"قلمرو سلطنتی"},
        {"id":"army", "title":"ارتش", "sub":"آموزش و آمادگی"},
        {"id":"world", "title":"نقشهٔ جهان", "sub":"فتح سرزمین‌ها"},
        {"id":"research", "title":"فناوری", "sub":"پیشرفت تمدن"},
        {"id":"diplomacy", "title":"دیپلماسی", "sub":"روابط پادشاهی‌ها"}
    ]
    var widths := [245.0, 190.0, 245.0, 190.0, 245.0]
    var x := 25.0
    for i in range(nav.size()):
        var item: Dictionary = nav[i]
        var w: float = widths[i]
        var b := _button(bar, item.title + "\n" + item.sub, Rect2(x, 10, w, 72), func(): _show_view(item.id), current_view == item.id, 18)
        nav_buttons[item.id] = b
        b.add_theme_font_size_override("font_size", 17)
        b.add_theme_color_override("font_color", PALE_GOLD)
        b.add_theme_color_override("font_hover_color", Color.WHITE)
        x += w + 13

func _show_view(view_id: String) -> void:
    current_view = view_id
    _close_modal()
    for child in body.get_children():
        child.queue_free()
    match view_id:
        "city": _render_city()
        "army": _render_army()
        "world": _render_world()
        "research": _render_research()
        "diplomacy": _render_diplomacy()
        _:
            _render_city()
    # Rebuild nav highlighting through a subtle footer caption.
    _update_hud()
    _update_nav()

func _update_nav() -> void:
    for key in nav_buttons.keys():
        var b: Button = nav_buttons[key]
        var active := key == current_view
        b.add_theme_stylebox_override("normal", _panel_style(Color("#34495a") if active else Color("#202f3e"), Color("#d6ad66") if active else Color("#657788"), 2 if active else 1, 8))

func _render_city() -> void:
    building_buttons.clear()
    var placements := {
        "quarry":Rect2(30, 105, 205, 180),
        "barracks":Rect2(275, 284, 205, 185),
        "castle":Rect2(510, 32, 260, 250),
        "lumbermill":Rect2(840, 92, 205, 184),
        "farm":Rect2(1000, 310, 215, 180),
        "goldmine":Rect2(590, 315, 192, 178)
    }
    var order := ["quarry", "barracks", "castle", "lumbermill", "farm", "goldmine"]
    for id in order:
        var rect: Rect2 = placements[id]
        var def: Dictionary = BUILDINGS[id]
        var b := Button.new()
        b.position = rect.position
        b.size = rect.size
        b.flat = true
        b.focus_mode = Control.FOCUS_NONE
        b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
        b.add_theme_stylebox_override("hover", _panel_style(Color(0.95,0.81,0.49,0.08), GOLD, 2, 14))
        b.add_theme_stylebox_override("pressed", _panel_style(Color(0.8,0.62,0.28,0.12), PALE_GOLD, 2, 14))
        var texture_rect := TextureRect.new()
        texture_rect.texture = load(def.texture)
        texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(texture_rect)
        var plate := Panel.new()
        plate.position = Vector2(rect.size.x * 0.17, rect.size.y - 28)
        plate.size = Vector2(rect.size.x * 0.66, 24)
        plate.add_theme_stylebox_override("panel", _panel_style(Color("#101923"), Color("#b28a4f"), 1, 6))
        plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(plate)
        var name_label := _label(plate, "%s  •  %d" % [def.name, building_levels[id]], Rect2(2, 0, plate.size.x - 4, 23), 12, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
        name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.pressed.connect(func(): _open_building(id))
        body.add_child(b)
        building_buttons[id] = b

    var quest := Panel.new()
    quest.position = Vector2(18, 16)
    quest.size = Vector2(248, 91)
    quest.add_theme_stylebox_override("panel", _panel_style(Color(0.07,0.11,0.15,0.92), Color("#a47b43"), 1, 9))
    body.add_child(quest)
    _label(quest, "فرمان‌های سلطنتی", Rect2(13, 8, 220, 25), 17, PALE_GOLD)
    _label(quest, "قلعه را به سطح ۳ ارتقا دهید", Rect2(13, 38, 218, 20), 13, Color("#e8e0d0"))
    _label(quest, "آماده‌سازی سپاه برای فتح مرزها", Rect2(13, 61, 218, 18), 12, MUTED)

    var banner := Panel.new()
    banner.position = Vector2(1010, 12)
    banner.size = Vector2(250, 70)
    banner.add_theme_stylebox_override("panel", _panel_style(Color(0.06,0.09,0.13,0.88), Color("#8c6c3b"), 1, 9))
    body.add_child(banner)
    _label(banner, "قلمرو آریانا", Rect2(12, 7, 225, 25), 18, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
    _label(banner, "صلح داخلی  •  امنیت ۸۶٪", Rect2(12, 37, 225, 20), 13, GREEN, HORIZONTAL_ALIGNMENT_CENTER)
    _label(body, "برای مشاهدهٔ جزئیات، یک ساختمان را انتخاب کنید", Rect2(340, 500, 600, 28), 14, Color("#f5e7c4"), HORIZONTAL_ALIGNMENT_CENTER)

func _render_army() -> void:
    _add_page_backdrop("فرماندهی سپاه", "نیروهای خود را آموزش دهید و برای نبرد آماده کنید.")
    _add_stat_card("شمشیرزنان", troops.swordsmen, "خط مقدم و دفاع شهری", "res://assets/icon_helmet.png", Rect2(42, 95, 270, 185))
    _add_stat_card("کمانداران", troops.archers, "پشتیبانی از فاصلهٔ دور", "res://assets/icon_archer.png", Rect2(345, 95, 270, 185))
    _add_stat_card("سواره‌نظام", troops.cavalry, "یورش سریع و تعقیب دشمن", "res://assets/icon_cavalry.png", Rect2(648, 95, 270, 185))
    _add_stat_card("ادوات محاصره", troops.siege, "تخریب دیوار و برج‌ها", "res://assets/icon_siege.png", Rect2(951, 95, 270, 185))
    _label(body, "آموزش نیرو", Rect2(40, 314, 290, 34), 22, PALE_GOLD)
    _label(body, "هزینهٔ آموزش از منابع شهر کسر می‌شود.", Rect2(40, 348, 500, 25), 14, MUTED)
    _button(body, "آموزش ۲۰ شمشیرزن  •  ۳۲۰ طلا / ۱۸۰ غذا", Rect2(42, 395, 365, 62), func(): _train_troops("swordsmen"), true, 16)
    _button(body, "آموزش ۲۰ کماندار  •  ۳۸۰ طلا / ۲۲۰ غذا", Rect2(430, 395, 365, 62), func(): _train_troops("archers"), false, 16)
    _button(body, "آموزش ۱۰ سواره  •  ۶۰۰ طلا / ۳۰۰ غذا", Rect2(818, 395, 365, 62), func(): _train_troops("cavalry"), false, 16)
    var power_panel := _panel(body, Rect2(42, 485, 1135, 53), Color("#101a25"), GOLD, 1, 8)
    _label(power_panel, "قدرت رزمی کل: %s" % _format_num(_total_power()), Rect2(18, 8, 400, 36), 19, PALE_GOLD)
    _label(power_panel, "آمادگی نیروها بر اساس ترکیب سپاه و سطح فناوری محاسبه می‌شود.", Rect2(430, 8, 680, 36), 14, MUTED)

func _render_world() -> void:
    var bg := TextureRect.new()
    bg.texture = load("res://assets/world_map.png")
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_SCALE
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(bg)
    var dim := ColorRect.new()
    dim.color = Color(0.04,0.07,0.10,0.42)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(dim)
    _label(body, "مرزهای شمالی", Rect2(30, 16, 420, 40), 26, PALE_GOLD)
    _label(body, "اردوگاه‌های دشمن را شکست دهید و منابع قلمرو را به دست آورید.", Rect2(30, 57, 650, 26), 14, Color("#f2e9d8"))
    _region_card("اردوگاه راهزنان", "قدرت دشمن: ۴۲۰", "غنیمت: ۹۰۰ طلا و ۴۰۰ چوب", Rect2(35, 345, 350, 155), "bandits", 420)
    _region_card("دژ شاه‌نشین سرخ", "قدرت دشمن: ۹۸۰", "غنیمت: ۱۸۰۰ طلا و ۸۰۰ سنگ", Rect2(455, 345, 350, 155), "red_keep", 980)
    _region_card("کاروان ساحلی", "قدرت دشمن: ۶۲۰", "غنیمت: ۱۲۰۰ طلا و ۵۰۰ غذا", Rect2(875, 345, 350, 155), "coast", 620)

func _render_research() -> void:
    _add_page_backdrop("تالار دانش و فناوری", "فناوری‌ها توان تولید، قدرت سپاه و سرعت توسعه را افزایش می‌دهند.")
    _research_card("military", "فن‌آوری نظامی", "افزایش قدرت رزمی تمام نیروها", "res://assets/icon_helmet.png", Rect2(45, 125, 360, 290))
    _research_card("agriculture", "کشاورزی پیشرفته", "افزایش تولید غذا و پایداری جمعیت", "res://assets/icon_food.png", Rect2(460, 125, 360, 290))
    _research_card("engineering", "مهندسی سازه", "افزایش تولید چوب و سنگ و کاهش هزینهٔ ساخت", "res://assets/icon_siege.png", Rect2(875, 125, 360, 290))
    _label(body, "هر فناوری را می‌توان چندین بار ارتقا داد؛ هزینه با هر سطح افزایش می‌یابد.", Rect2(45, 458, 1180, 35), 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func _render_diplomacy() -> void:
    _add_page_backdrop("شورای دیپلماسی", "با همسایگان پیمان ببندید، تجارت کنید یا روابط خود را بهبود دهید.")
    var rows := [
        {"key":"north", "title":"اتحاد شمال", "desc":"اتحادی از فرمانروایان کوهستانی؛ علاقه‌مند به چوب و آهن.", "y":115},
        {"key":"red", "title":"شاه‌نشین سرخ", "desc":"رقیب دیرینه؛ مرزهای جنوبی را تهدید می‌کند.", "y":245},
        {"key":"coast", "title":"پادشاهی ساحل", "desc":"بازرگانان دریایی و متحدی بالقوه برای تجارت.", "y":375}
    ]
    for row in rows:
        var p := _panel(body, Rect2(42, row.y, 1190, 106), Color("#182534"), Color("#9b7848"), 1, 10)
        _label(p, row.title, Rect2(18, 8, 300, 28), 20, PALE_GOLD)
        _label(p, row.desc, Rect2(18, 43, 660, 28), 14, MUTED)
        var relation := int(faction_relations[row.key])
        _label(p, "اعتبار: %d" % relation, Rect2(760, 18, 120, 28), 17, _relation_color(relation))
        _button(p, "پیشنهاد تجارت", Rect2(905, 22, 245, 58), func(): _trade_with(row.key), false, 15)

func _add_page_backdrop(title: String, subtitle: String) -> void:
    var veil := ColorRect.new()
    veil.color = Color(0.045, 0.065, 0.085, 0.68)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(veil)
    _label(body, title, Rect2(38, 18, 720, 38), 27, PALE_GOLD)
    _label(body, subtitle, Rect2(40, 59, 870, 25), 14, Color("#d6dce0"))

func _add_stat_card(title: String, amount: int, desc: String, icon_path: String, rect: Rect2) -> void:
    var p := _panel(body, rect, Color("#172534"), Color("#9d7a49"), 1, 11)
    var icon := TextureRect.new()
    icon.texture = load(icon_path)
    icon.position = Vector2(16, 17)
    icon.size = Vector2(58, 58)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    p.add_child(icon)
    _label(p, title, Rect2(88, 16, 165, 29), 19, PALE_GOLD)
    _label(p, _format_num(amount), Rect2(88, 48, 160, 32), 24, Color.WHITE)
    _label(p, desc, Rect2(17, 111, 238, 45), 13, MUTED)

func _region_card(title: String, strength: String, reward: String, rect: Rect2, id: String, enemy_power: int) -> void:
    var p := _panel(body, rect, Color(0.07,0.10,0.14,0.94), Color("#be9658"), 2, 10)
    _label(p, title, Rect2(14, 9, 318, 28), 18, PALE_GOLD)
    _label(p, strength, Rect2(14, 44, 300, 22), 14, Color("#f0e5d3"))
    _label(p, reward, Rect2(14, 70, 315, 22), 13, GREEN)
    _button(p, "اعزام سپاه", Rect2(16, 105, 315, 38), func(): _attack_region(id, enemy_power), true, 15)

func _research_card(id: String, title: String, desc: String, icon_path: String, rect: Rect2) -> void:
    var p := _panel(body, rect, Color("#182635"), Color("#a67b40"), 2, 11)
    var icon := TextureRect.new()
    icon.texture = load(icon_path)
    icon.position = Vector2(138, 22)
    icon.size = Vector2(78, 78)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    p.add_child(icon)
    _label(p, title, Rect2(18, 110, 324, 36), 20, PALE_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
    _label(p, desc, Rect2(22, 151, 316, 50), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    _label(p, "سطح فعلی: %d" % int(research_levels[id]), Rect2(22, 207, 316, 25), 16, GREEN, HORIZONTAL_ALIGNMENT_CENTER)
    _button(p, "تحقیق و ارتقا", Rect2(28, 244, 304, 38), func(): _upgrade_research(id), true, 15)

func _open_building(id: String) -> void:
    selected_building = id
    var def: Dictionary = BUILDINGS[id]
    var level := int(building_levels[id])
    var cost := _building_cost(id)
    var p := _open_modal(def.name, "مدیریت سازهٔ سلطنتی")
    var image := TextureRect.new()
    image.texture = load(def.texture)
    image.position = Vector2(24, 65)
    image.size = Vector2(190, 165)
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    p.add_child(image)
    _label(p, "سطح فعلی: %d" % level, Rect2(238, 76, 330, 30), 20, PALE_GOLD)
    _label(p, _building_description(id), Rect2(238, 113, 330, 55), 14, MUTED)
    _label(p, "هزینهٔ ارتقا", Rect2(238, 174, 320, 25), 15, Color("#e8d8b9"))
    _label(p, "طلا %s   چوب %s   سنگ %s" % [_format_num(cost.gold), _format_num(cost.wood), _format_num(cost.stone)], Rect2(238, 203, 340, 24), 14, PALE_GOLD)
    _button(p, "ارتقا به سطح %d" % (level + 1), Rect2(238, 246, 320, 48), func(): _upgrade_building(id), true, 17)
    _button(p, "بستن", Rect2(475, 18, 90, 35), Callable(self, "_close_modal"), false, 13)

func _open_reports() -> void:
    var p := _open_modal("گزارش‌های سلطنتی", "آخرین رویدادهای قلمرو")
    _label(p, "قلمرو شما در امنیت است. تولید منابع فعال است.", Rect2(24, 82, 530, 30), 15, PALE_GOLD)
    _label(p, "اردوگاه‌های فتح‌شده: %d" % enemy_camps_cleared, Rect2(24, 120, 530, 28), 15, GREEN)
    _label(p, "قدرت کل سپاه: %s" % _format_num(_total_power()), Rect2(24, 160, 530, 28), 15, Color.WHITE)
    _button(p, "تأیید", Rect2(220, 230, 170, 45), Callable(self, "_close_modal"), true, 15)

func _open_settings() -> void:
    var p := _open_modal("تنظیمات بازی", "ذخیره‌سازی و تنظیمات عمومی")
    _label(p, "پیشرفت بازی به‌صورت خودکار روی همین دستگاه ذخیره می‌شود.", Rect2(26, 86, 520, 28), 14, MUTED)
    _button(p, "ذخیرهٔ اکنون", Rect2(34, 145, 230, 52), Callable(self, "_save_and_notify"), true, 16)
    _button(p, "شروع دوباره", Rect2(300, 145, 230, 52), Callable(self, "_confirm_reset"), false, 16)

func _open_modal(title: String, subtitle: String) -> Control:
    _close_modal()
    modal_layer = Control.new()
    modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    modal_layer.z_index = 30
    add_child(modal_layer)
    var veil := ColorRect.new()
    veil.color = Color(0.01,0.02,0.03,0.68)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    modal_layer.add_child(veil)
    var panel := Panel.new()
    panel.position = Vector2(340, 176)
    panel.size = Vector2(600, 360)
    panel.add_theme_stylebox_override("panel", _panel_style(Color("#172331"), Color("#c39a57"), 2, 13))
    modal_layer.add_child(panel)
    _label(panel, title, Rect2(22, 15, 420, 34), 23, PALE_GOLD)
    _label(panel, subtitle, Rect2(22, 49, 520, 22), 13, MUTED)
    return panel

func _close_modal() -> void:
    if is_instance_valid(modal_layer):
        modal_layer.queue_free()
    modal_layer = null

func _upgrade_building(id: String) -> void:
    var cost := _building_cost(id)
    if not _can_afford(cost):
        _notify("منابع کافی برای ارتقای این سازه ندارید.")
        return
    _spend(cost)
    building_levels[id] = int(building_levels[id]) + 1
    player_xp += 45
    if player_xp >= 500 + player_level * 120:
        player_xp = 0
        player_level += 1
        _notify("سطح فرمانروایی شما به %d ارتقا یافت." % player_level)
    else:
        _notify("%s به سطح %d رسید." % [BUILDINGS[id].name, building_levels[id]])
    _save_game()
    _close_modal()
    _show_view("city")

func _building_cost(id: String) -> Dictionary:
    var d: Dictionary = BUILDINGS[id]
    var lv := int(building_levels[id])
    var multiplier := pow(float(lv), 1.32)
    var discount := max(0.72, 1.0 - float(research_levels.engineering) * 0.035)
    return {"gold":int(d.base_gold * multiplier * discount), "wood":int(d.base_wood * multiplier * discount), "stone":int(d.base_stone * multiplier * discount)}

func _building_description(id: String) -> String:
    var d: Dictionary = BUILDINGS[id]
    var result := ""
    if d.gold_rate > 0: result = "تولید طلا: %d واحد در هر دوره" % int(d.gold_rate * building_levels[id])
    elif d.wood_rate > 0: result = "تولید چوب: %d واحد در هر دوره" % int(d.wood_rate * building_levels[id])
    elif d.stone_rate > 0: result = "تولید سنگ: %d واحد در هر دوره" % int(d.stone_rate * building_levels[id])
    elif d.food_rate > 0: result = "تولید غذا: %d واحد در هر دوره" % int(d.food_rate * building_levels[id])
    elif id == "barracks": result = "ظرفیت و سرعت آموزش سربازان را افزایش می‌دهد."
    else: result = "مرکز فرماندهی، ارتقا و توسعهٔ قلمرو شماست."
    return result

func _train_troops(kind: String) -> void:
    var cost := {"gold":320, "food":180}
    var amount := 20
    if kind == "archers": cost = {"gold":380, "food":220}
    elif kind == "cavalry":
        cost = {"gold":600, "food":300}
        amount = 10
    if not _can_afford(cost):
        _notify("برای آموزش نیرو، طلا یا غذای کافی ندارید.")
        return
    _spend(cost)
    troops[kind] = int(troops[kind]) + amount
    _notify("%d نیروی تازه به سپاه پیوست." % amount)
    _save_game()
    _show_view("army")

func _attack_region(id: String, enemy_power: int) -> void:
    var own_power := _total_power()
    if own_power < enemy_power * 0.55:
        _notify("قدرت سپاه برای این نبرد کافی نیست؛ ابتدا نیروها را تقویت کنید.")
        return
    var roll := rng.randf_range(0.82, 1.18)
    var victory := float(own_power) * roll >= float(enemy_power)
    var loss_count := 0
    if victory:
        enemy_camps_cleared += 1
        resources.gold += 900 if id == "bandits" else (1800 if id == "red_keep" else 1200)
        resources.wood += 400 if id == "bandits" else 250
        resources.stone += 250 if id == "red_keep" else 120
        resources.food += 180
        loss_count = int(max(3.0, troops.swordsmen * rng.randf_range(0.035, 0.095)))
        troops.swordsmen = max(0, troops.swordsmen - loss_count)
        player_xp += 95
        _notify("پیروزی! غنیمت به خزانه افزوده شد؛ %d سرباز از دست رفت." % loss_count)
    else:
        loss_count = int(max(5.0, troops.swordsmen * rng.randf_range(0.12, 0.24)))
        troops.swordsmen = max(0, troops.swordsmen - loss_count)
        troops.archers = max(0, troops.archers - int(loss_count * 0.3))
        _notify("شکست در نبرد؛ %d سرباز از سپاه جدا شدند. ارتش را بازسازی کنید." % loss_count)
    _save_game()
    _update_hud()
    _show_view("world")

func _upgrade_research(id: String) -> void:
    var level := int(research_levels[id])
    var cost := {"gold":int(700 * pow(level + 1, 1.35)), "wood":int(350 * pow(level + 1, 1.18)), "stone":int(250 * pow(level + 1, 1.18))}
    if not _can_afford(cost):
        _notify("منابع کافی برای این پژوهش ندارید.")
        return
    _spend(cost)
    research_levels[id] = level + 1
    _notify("فناوری با موفقیت به سطح %d رسید." % (level + 1))
    _save_game()
    _show_view("research")

func _trade_with(key: String) -> void:
    if int(resources.food) < 250:
        _notify("برای پیشنهاد تجارت دست‌کم ۲۵۰ غذا لازم است.")
        return
    resources.food -= 250
    faction_relations[key] = clampi(int(faction_relations[key]) + 12, -100, 100)
    resources.gold += 260
    _notify("تجارت موفق بود؛ اعتبار دیپلماتیک و طلا افزایش یافت.")
    _save_game()
    _show_view("diplomacy")

func _confirm_reset() -> void:
    var p := _open_modal("شروع دوباره؟", "تمام پیشرفت ذخیره‌شده روی این دستگاه پاک خواهد شد.")
    _label(p, "این عمل قابل بازگشت نیست.", Rect2(28, 104, 520, 28), 15, RED)
    _button(p, "بله، شروع دوباره", Rect2(40, 190, 230, 48), Callable(self, "_reset_game"), false, 15)
    _button(p, "انصراف", Rect2(310, 190, 230, 48), Callable(self, "_close_modal"), true, 15)

func _reset_game() -> void:
    resources = {"gold":6400, "wood":4200, "stone":3200, "food":5600, "gems":35}
    building_levels = {"castle":2, "barracks":1, "farm":2, "lumbermill":1, "quarry":1, "goldmine":1}
    troops = {"swordsmen":180, "archers":120, "cavalry":48, "siege":8}
    research_levels = {"military":0, "agriculture":0, "engineering":0}
    faction_relations = {"north":0, "red":-10, "coast":25}
    player_level = 7
    player_xp = 340
    enemy_camps_cleared = 0
    _save_game()
    _close_modal()
    _show_view("city")
    _notify("قلمرو جدید شما آماده است.")

func _on_game_tick() -> void:
    tick_count += 1
    resources.gold += 5 + int(building_levels.goldmine) * 5
    resources.wood += 4 + int(building_levels.lumbermill) * 5 + int(research_levels.engineering) * 3
    resources.stone += 3 + int(building_levels.quarry) * 4 + int(research_levels.engineering) * 2
    resources.food += 6 + int(building_levels.farm) * 6 + int(research_levels.agriculture) * 4
    if tick_count % 15 == 0:
        _save_game()
    _update_hud()

func _total_power() -> int:
    var base := int(troops.swordsmen) + int(troops.archers) * 1.15 + int(troops.cavalry) * 2.6 + int(troops.siege) * 3.8
    var fortification := 0.0
    for id in building_levels.keys():
        fortification += float(BUILDINGS[id].power) * float(building_levels[id]) * 0.18
    var tech := 1.0 + float(research_levels.military) * 0.08
    var castle_bonus := 1.0 + float(building_levels.castle - 1) * 0.025
    return int((base + fortification) * tech * castle_bonus)

func _can_afford(cost: Dictionary) -> bool:
    for key in cost.keys():
        if int(resources.get(key, 0)) < int(cost[key]): return false
    return true

func _spend(cost: Dictionary) -> void:
    for key in cost.keys(): resources[key] = int(resources[key]) - int(cost[key])
    _update_hud()

func _update_hud() -> void:
    for key in resource_labels.keys():
        var entries: Dictionary = resource_labels[key]
        entries.amount.text = _format_num(int(resources[key]))
        var rate := _resource_rate(key)
        entries.rate.text = "+%s / دوره" % _format_num(rate)
    if is_instance_valid(power_label):
        power_label.text = "قدرت %s" % _format_num(_total_power())
    if is_instance_valid(level_label):
        level_label.text = "فرمانروای آریانا  •  سطح %d" % player_level

func _resource_rate(key: String) -> int:
    match key:
        "gold": return 5 + int(building_levels.goldmine) * 5
        "wood": return 4 + int(building_levels.lumbermill) * 5 + int(research_levels.engineering) * 3
        "stone": return 3 + int(building_levels.quarry) * 4 + int(research_levels.engineering) * 2
        "food": return 6 + int(building_levels.farm) * 6 + int(research_levels.agriculture) * 4
        "gems": return 0
    return 0

func _notify(message: String) -> void:
    if not is_instance_valid(toast_label): return
    toast_token += 1
    var local_token := toast_token
    toast_label.text = message
    toast_label.visible = true
    # The toast sits above a dedicated panel created in _build_shell.
    var bg := get_node_or_null("ToastBackground")
    if bg: bg.visible = true
    await get_tree().create_timer(2.8).timeout
    if local_token != toast_token: return
    if is_instance_valid(toast_label):
        toast_label.visible = false
        if bg and is_instance_valid(bg): bg.visible = false

func _save_and_notify() -> void:
    _save_game()
    _close_modal()
    _notify("بازی با موفقیت ذخیره شد.")

func _save_game() -> void:
    var data := {
        "resources":resources,
        "building_levels":building_levels,
        "troops":troops,
        "research_levels":research_levels,
        "faction_relations":faction_relations,
        "player_level":player_level,
        "player_xp":player_xp,
        "enemy_camps_cleared":enemy_camps_cleared
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))
        file.close()

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH): return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null: return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY: return
    var data: Dictionary = parsed
    for key in resources.keys():
        resources[key] = int(data.get("resources", {}).get(key, resources[key]))
    for key in building_levels.keys():
        building_levels[key] = int(data.get("building_levels", {}).get(key, building_levels[key]))
    for key in troops.keys():
        troops[key] = int(data.get("troops", {}).get(key, troops[key]))
    for key in research_levels.keys():
        research_levels[key] = int(data.get("research_levels", {}).get(key, research_levels[key]))
    for key in faction_relations.keys():
        faction_relations[key] = int(data.get("faction_relations", {}).get(key, faction_relations[key]))
    player_level = int(data.get("player_level", player_level))
    player_xp = int(data.get("player_xp", player_xp))
    enemy_camps_cleared = int(data.get("enemy_camps_cleared", enemy_camps_cleared))

func _panel(parent: Control, rect: Rect2, color: Color, border: Color, border_width: int, radius: int) -> Panel:
    var p := Panel.new()
    p.position = rect.position
    p.size = rect.size
    p.add_theme_stylebox_override("panel", _panel_style(color, border, border_width, radius))
    parent.add_child(p)
    return p

func _panel_style(color: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(border_width)
    style.set_corner_radius_all(radius)
    style.shadow_color = Color(0,0,0,0.36)
    style.shadow_size = 7
    style.shadow_offset = Vector2(0,3)
    style.content_margin_left = 8
    style.content_margin_right = 8
    style.content_margin_top = 4
    style.content_margin_bottom = 4
    return style

func _label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var label := Label.new()
    label.text = text
    label.position = rect.position
    label.size = rect.size
    label.horizontal_alignment = align
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.65))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 1)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func _button(parent: Control, text: String, rect: Rect2, callback: Callable, accent: bool = false, font_size: int = 16) -> Button:
    var b := Button.new()
    b.text = text
    b.position = rect.position
    b.size = rect.size
    b.focus_mode = Control.FOCUS_NONE
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    b.add_theme_font_size_override("font_size", font_size)
    b.add_theme_color_override("font_color", PALE_GOLD if accent else Color("#e3e8ed"))
    b.add_theme_color_override("font_hover_color", Color.WHITE)
    b.add_theme_color_override("font_pressed_color", Color.WHITE)
    var normal := _panel_style(Color("#34495a") if accent else Color("#202f3e"), Color("#c49a58") if accent else Color("#657788"), 2 if accent else 1, 8)
    var hover := _panel_style(Color("#425d70"), PALE_GOLD, 2, 8)
    var pressed := _panel_style(Color("#27394a"), Color("#e7bf70"), 2, 8)
    b.add_theme_stylebox_override("normal", normal)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", pressed)
    b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func _format_num(value: int) -> String:
    var s := str(value)
    var out := ""
    var count := 0
    for i in range(s.length() - 1, -1, -1):
        out = s.substr(i, 1) + out
        count += 1
        if count % 3 == 0 and i > 0: out = "," + out
    return out

func _relation_color(value: int) -> Color:
    if value >= 25: return GREEN
    if value <= -10: return RED
    return PALE_GOLD

func _on_building_button_pressed(id: String) -> void:
    _open_building(id)
