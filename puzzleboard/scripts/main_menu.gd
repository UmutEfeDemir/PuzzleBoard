extends Node2D

## PuzzBoard'un açılış ekranı (scenes/MainMenu.tscn).
## Proje Ayarları > Uygulama > Çalıştır > Ana Sahne burasıdır.

const LEVELS_DIR := "res://levels/"
const TAG_TEXT := "CASUAL PUZZLE"


func _ready() -> void:
	UITheme.load_theme()

	var canvas := CanvasLayer.new()
	add_child(canvas)
	UITheme.add_gradient_background(canvas)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 26)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var tag := Label.new()
	tag.text = _spaced(TAG_TEXT)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", UITheme.COLOR_TAG_YELLOW)
	vbox.add_child(tag)

	var title := Label.new()
	title.text = "PuzzBoard"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
	vbox.add_child(title)

	vbox.add_child(_build_mascot())

	var play_btn := UITheme.make_chunky_button(
		"OYNA", Vector2(240, 64), UITheme.COLOR_ACCENT, UITheme.COLOR_ACCENT_SHADOW, UITheme.COLOR_ACCENT_TEXT, 26
	)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	vbox.add_child(play_btn)

	var secondary := HBoxContainer.new()
	secondary.add_theme_constant_override("separation", 14)
	secondary.alignment = BoxContainer.ALIGNMENT_CENTER
	secondary.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(secondary)

	var stars := _count_total_stars()
	var stats_label := UITheme.make_translucent_button("★ %d / %d" % [stars.x, stars.y], Vector2(140, 52), 16)
	stats_label.disabled = true
	secondary.add_child(stats_label)

	var settings_btn := UITheme.make_translucent_button("Ayarlar", Vector2(110, 52), 16)
	settings_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Settings.tscn"))
	secondary.add_child(settings_btn)


func _build_mascot() -> Control:
	var mascot := UITheme.make_panel(UITheme.COLOR_ACCENT, Vector2(120, 120), 60)
	mascot.custom_minimum_size = Vector2(120, 120)
	mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var mascot_style: StyleBoxFlat = mascot.get_theme_stylebox("panel")
	mascot_style.shadow_color = Color(0, 0, 0, 0.25)
	mascot_style.shadow_size = 10

	var eye_color := UITheme.COLOR_TEXT_DARK
	var eye_left := UITheme.make_panel(eye_color, Vector2(14, 18), 7)
	eye_left.position = Vector2(36, 46)
	mascot.add_child(eye_left)

	var eye_right := UITheme.make_panel(eye_color, Vector2(14, 18), 7)
	eye_right.position = Vector2(70, 46)
	mascot.add_child(eye_right)

	return mascot


func _spaced(text: String) -> String:
	var result := ""
	for i in text.length():
		result += text[i]
		if i < text.length() - 1:
			result += " "
	return result


## levels/ altındaki her .tres için kazanılan / toplam yıldızı toplar.
func _count_total_stars() -> Vector2i:
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		return Vector2i.ZERO

	var earned := 0
	var total := 0
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var level: LevelData = load(LEVELS_DIR + file_name)
			earned += SaveManager.get_stars(level.level_name)
			total += 3
		file_name = dir.get_next()
	dir.list_dir_end()
	return Vector2i(earned, total)
