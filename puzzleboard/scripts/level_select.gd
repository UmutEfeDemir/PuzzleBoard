extends Node2D

## Bu script boş bir Node2D sahnesine atanır (scenes/LevelSelect.tscn).
## res://levels/ altındaki tüm .tres dosyalarını otomatik tarar,
## yeni level eklediğinde bu ekranı GÜNCELLEMENE gerek yok.
##
## Level durumları: bir önceki level en az 1 yıldızla tamamlanmadıysa
## sonraki level kilitli sayılır. İlk level her zaman açıktır.
## Düğümler zikzak bir yol üzerinde sırayla sola-sağa kayarak dizilir.

const LEVELS_DIR := "res://levels/"

const PATH_WIDTH := 340.0
const NODE_W := 120.0
const NODE_H := 150.0
const VERTICAL_SPACING := 160.0
const TOP_PADDING := 40.0
const BOTTOM_PADDING := 40.0
const LEFT_X := PATH_WIDTH * 0.12
const RIGHT_X := PATH_WIDTH * 0.88 - NODE_W


func _ready() -> void:
	UITheme.load_theme()

	var canvas := CanvasLayer.new()
	add_child(canvas)
	UITheme.add_gradient_background(canvas)

	var root_box := VBoxContainer.new()
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root_box)

	root_box.add_child(_build_header())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 24)
	outer_margin.add_theme_constant_override("margin_right", 24)
	outer_margin.add_theme_constant_override("margin_top", 8)
	outer_margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(outer_margin)

	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		var warn := Label.new()
		warn.text = "res://levels/ klasörü bulunamadı. Önce bir level .tres dosyası oluştur."
		warn.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
		outer_margin.add_child(warn)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	var paths: Array[String] = []
	while file_name != "":
		if file_name.ends_with(".tres"):
			paths.append(LEVELS_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()

	GameState.level_list = paths

	if paths.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Henüz level yok."
		empty_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
		outer_margin.add_child(empty_label)
		return

	var path_container := Control.new()
	path_container.custom_minimum_size = Vector2(PATH_WIDTH, TOP_PADDING + paths.size() * VERTICAL_SPACING + BOTTOM_PADDING)
	outer_margin.add_child(path_container)

	var path_line := PathLine.new()
	path_line.set_anchors_preset(Control.PRESET_FULL_RECT)
	path_container.add_child(path_line)

	var badge_centers: PackedVector2Array = PackedVector2Array()

	var previous_completed := true  # ilk level her zaman açık
	var current_assigned := false
	for i in paths.size():
		var path: String = paths[i]
		var level: LevelData = load(path)
		var stars: int = SaveManager.get_stars(level.level_name)
		var locked: bool = not previous_completed
		var is_current: bool = not locked and stars == 0 and not current_assigned
		if is_current:
			current_assigned = true

		var node_pos := Vector2(
			LEFT_X if i % 2 == 0 else RIGHT_X,
			TOP_PADDING + i * VERTICAL_SPACING
		)
		var badge_center := _add_level_node(path_container, path, level, i, stars, locked, is_current, node_pos)
		badge_centers.append(badge_center)

		previous_completed = stars > 0

	path_line.points = badge_centers
	path_line.queue_redraw()


func _build_header() -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 8)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	var back_btn := UITheme.make_translucent_button("<", Vector2(40, 40), 18)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	hbox.add_child(back_btn)

	var title := Label.new()
	title.text = "Level Seç"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title)

	return margin


## Bir level düğümünü (rozet + alt yazılar) path_container içine, verilen
## pozisyona ekler. Yol çizgisinin buradan geçmesi için rozetin merkezini
## döndürür.
func _add_level_node(parent: Control, path: String, _level: LevelData, index: int, stars: int, locked: bool, is_current: bool, node_pos: Vector2) -> Vector2:
	var node := Control.new()
	node.position = node_pos
	node.custom_minimum_size = Vector2(NODE_W, NODE_H)
	node.size = Vector2(NODE_W, NODE_H)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)

	var badge_size: Vector2 = Vector2(92, 92) if is_current else Vector2(78, 78)
	var badge_bg: Color = UITheme.COLOR_CURRENT if is_current else UITheme.COLOR_ACCENT
	var badge_shadow: Color = UITheme.COLOR_CURRENT_SHADOW if is_current else UITheme.COLOR_ACCENT_SHADOW
	var badge_top := 18.0 if is_current else 0.0  # "ŞİMDİ" rozetine yer aç

	if locked:
		var locked_circle := UITheme.make_panel(UITheme.COLOR_LOCKED_BG, Vector2(78, 78), 39)
		locked_circle.position = Vector2((NODE_W - 78) / 2.0, 0)
		node.add_child(locked_circle)
		var lock_icon := _build_lock_icon(30.0)
		lock_icon.position = locked_circle.position + Vector2(78, 78) / 2.0 - Vector2(15, 15)
		node.add_child(lock_icon)
	else:
		var badge := UITheme.make_chunky_button(
			str(index + 1), badge_size, badge_bg, badge_shadow, UITheme.COLOR_TEXT_LIGHT if is_current else UITheme.COLOR_ACCENT_TEXT,
			28 if is_current else 24, int(badge_size.y / 2)
		)
		badge.position = Vector2((NODE_W - badge_size.x) / 2.0, badge_top)
		badge.pressed.connect(_on_level_selected.bind(path))
		node.add_child(badge)

		if is_current:
			var pill := UITheme.make_panel(UITheme.COLOR_TAG_YELLOW, Vector2(66, 22), 11)
			pill.position = Vector2((NODE_W - 66) / 2.0, 0)
			node.add_child(pill)
			var pill_label := Label.new()
			pill_label.text = "ŞİMDİ"
			pill_label.size = pill.size
			pill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			pill_label.add_theme_font_size_override("font_size", 12)
			pill_label.add_theme_color_override("font_color", UITheme.COLOR_ACCENT_TEXT)
			pill.add_child(pill_label)

	var badge_top_y := badge_top if not locked else 0.0
	var caption := Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(0, badge_top_y + badge_size.y + 8)
	caption.size = Vector2(NODE_W, 20)
	caption.add_theme_font_size_override("font_size", 15)
	if locked:
		caption.text = "★★★"
		caption.add_theme_color_override("font_color", Color(1, 1, 1, 0.25))
		caption.position = Vector2(0, 78 + 8)
	else:
		caption.text = "★".repeat(stars) + "☆".repeat(3 - stars)
		caption.add_theme_color_override("font_color", UITheme.COLOR_TAG_YELLOW)
	node.add_child(caption)

	return node_pos + Vector2(NODE_W / 2.0, badge_top_y + badge_size.y / 2.0)


func _build_lock_icon(size: float) -> Control:
	var icon_wrap := Control.new()
	icon_wrap.custom_minimum_size = Vector2(size, size)
	icon_wrap.size = Vector2(size, size)
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shackle := Panel.new()
	var shackle_style := StyleBoxFlat.new()
	shackle_style.bg_color = Color(0, 0, 0, 0)
	shackle_style.border_width_top = 3
	shackle_style.border_width_left = 3
	shackle_style.border_width_right = 3
	shackle_style.border_color = Color(1, 1, 1, 0.6)
	shackle_style.corner_radius_top_left = int(size * 0.24)
	shackle_style.corner_radius_top_right = int(size * 0.24)
	shackle.add_theme_stylebox_override("panel", shackle_style)
	shackle.size = Vector2(size * 0.5, size * 0.36)
	shackle.position = Vector2(size * 0.25, size * 0.06)
	icon_wrap.add_child(shackle)

	var body := UITheme.make_panel(Color(1, 1, 1, 0.6), Vector2(size * 0.64, size * 0.42), int(size * 0.1))
	body.position = Vector2(size * 0.18, size * 0.4)
	icon_wrap.add_child(body)

	return icon_wrap


func _on_level_selected(path: String) -> void:
	GameState.current_level_path = path
	GameState.current_level_index = GameState.level_list.find(path)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
