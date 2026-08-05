extends Node2D

## Bu script boş bir Node2D sahnesine atanır (scenes/LevelSelect.tscn).
## res://levels/ altındaki tüm .tres dosyalarını otomatik tarar,
## yeni level eklediğinde bu ekranı GÜNCELLEMENE gerek yok.
##
## Level durumları: bir önceki level en az 1 yıldızla tamamlanmadıysa
## sonraki level kilitli sayılır. İlk level her zaman açıktır.
## Düğümler zikzak bir yol üzerinde sırayla sola-sağa kayarak dizilir.
##
## 100 leveli tek bir uzun listede göstermek yerine, her biri 25 levellik
## "Bölüm"lere ayrılmış durumda (bkz. SEGMENT_SIZE). Bölümler arasında
## sekme şeridi YERİNE ok (< >) ile gezinilir — level sayısı ileride
## 300-400'e çıkınca (bkz. GELISTIRME_DURUMU.md) bölüm sayısı da 12-16'ya
## çıkacak, sabit genişlikte bir sekme şeridi o zaman kullanışsız olurdu;
## ok navigasyonu kaç bölüm olursa olsun aynı kalır. Bir bölümün kilidi,
## bir önceki bölümde en az STARS_REQUIRED_TO_UNLOCK_SEGMENT yıldız
## kazanılmış olmasına bağlı.

const LEVELS_DIR := "res://levels/"
const SEGMENT_SIZE := 25
const STARS_REQUIRED_TO_UNLOCK_SEGMENT := 40

const SIDE_MARGIN := 24
const NODE_W := 120.0
const NODE_H := 150.0
const VERTICAL_SPACING := 160.0
const TOP_PADDING := 40.0
const BOTTOM_PADDING := 40.0

## Sabit değil: ekran genişliğine göre _ready()'de hesaplanır, böylece
## zigzag yol her zaman gerçek ekran genişliğini kullanır (sol tarafa
## yapışıp sağda boşluk bırakmaz).
var _path_width: float
var _left_x: float
var _right_x: float

var _all_paths: Array[String] = []
var _segments: Array = []  # Array[Array[String]]
var _current_segment: int = 0

var _pager_title: Label
var _pager_subtitle: Label
var _prev_btn: Button
var _next_btn: Button
var _scroll: ScrollContainer
var _path_outer_margin: MarginContainer
var _path_container: Control


func _ready() -> void:
	UITheme.load_theme()

	_path_width = get_viewport_rect().size.x - SIDE_MARGIN * 2.0
	_left_x = _path_width * 0.12
	_right_x = _path_width * 0.88 - NODE_W

	var canvas := CanvasLayer.new()
	add_child(canvas)
	UITheme.add_gradient_background(canvas)

	var root_box := VBoxContainer.new()
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root_box)

	root_box.add_child(_build_header())

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_path_outer_margin = MarginContainer.new()
	_path_outer_margin.add_theme_constant_override("margin_left", SIDE_MARGIN)
	_path_outer_margin.add_theme_constant_override("margin_right", SIDE_MARGIN)
	_path_outer_margin.add_theme_constant_override("margin_top", 8)
	_path_outer_margin.add_theme_constant_override("margin_bottom", 24)
	_scroll.add_child(_path_outer_margin)

	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		root_box.add_child(_scroll)
		var warn := Label.new()
		warn.text = "res://levels/ klasörü bulunamadı. Önce bir level .tres dosyası oluştur."
		warn.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
		_path_outer_margin.add_child(warn)
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
	_all_paths = paths

	if paths.is_empty():
		root_box.add_child(_scroll)
		var empty_label := Label.new()
		empty_label.text = "Henüz level yok."
		empty_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
		_path_outer_margin.add_child(empty_label)
		return

	_segments = _build_segments(paths)

	root_box.add_child(_build_progress_summary(paths))
	root_box.add_child(_build_segment_pager())
	root_box.add_child(_scroll)

	_current_segment = _find_initial_segment()
	_update_pager()
	_render_segment(_current_segment)


func _build_segments(paths: Array[String]) -> Array:
	var segments: Array = []
	var i := 0
	while i < paths.size():
		var end: int = min(i + SEGMENT_SIZE, paths.size())
		var chunk: Array[String] = []
		for j in range(i, end):
			chunk.append(paths[j])
		segments.append(chunk)
		i = end
	return segments


func _stars_in_segment(s: int) -> int:
	var total := 0
	for path in _segments[s]:
		var level: LevelData = load(path)
		total += SaveManager.get_stars(level.level_name)
	return total


## Bölüm s'nin açık olup olmadığı — bir önceki bölümde en az
## STARS_REQUIRED_TO_UNLOCK_SEGMENT yıldız kazanılmış olmasına bağlı (sadece
## son leveli bitirmek yetmez, toplam yıldız barajı var). 0. bölüm her zaman
## açık (ilk level zaten hep açık).
func _is_segment_unlocked(s: int) -> bool:
	if s == 0:
		return true
	return _stars_in_segment(s - 1) >= STARS_REQUIRED_TO_UNLOCK_SEGMENT


## Oyuncunun "şimdi" olduğu (tamamlanmamış ilk açık) levelin hangi bölümde
## olduğunu bulur — ekran ilk açıldığında oraya odaklanmak için.
func _find_initial_segment() -> int:
	var previous_completed := true
	for i in _all_paths.size():
		var level: LevelData = load(_all_paths[i])
		var stars: int = SaveManager.get_stars(level.level_name)
		var locked := not previous_completed
		if not locked and stars == 0:
			return int(i / SEGMENT_SIZE)
		previous_completed = stars > 0
	return max(0, _segments.size() - 1)


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


## Kaç level tamamlandı + toplam kaç yıldız kazanıldı özetini, ince bir
## ilerleme çubuğuyla birlikte gösteren kart. Scroll alanının dışında
## (header'ın hemen altında) durur, listeyi kaydırırken kaybolmaz.
func _build_progress_summary(paths: Array[String]) -> Control:
	var completed := 0
	var stars_earned := 0
	for path in paths:
		var level: LevelData = load(path)
		var stars: int = SaveManager.get_stars(level.level_name)
		if stars > 0:
			completed += 1
		stars_earned += stars
	var stars_total := paths.size() * 3

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", SIDE_MARGIN)
	margin.add_theme_constant_override("margin_right", SIDE_MARGIN)
	margin.add_theme_constant_override("margin_bottom", 10)

	var card := UITheme.make_card(14, 14)
	margin.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var row := HBoxContainer.new()
	vbox.add_child(row)

	var completed_label := Label.new()
	completed_label.text = "%d / %d Level Tamamlandı" % [completed, paths.size()]
	completed_label.add_theme_font_size_override("font_size", 14)
	completed_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_DARK)
	completed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(completed_label)

	var stars_label := Label.new()
	stars_label.text = "★ %d / %d" % [stars_earned, stars_total]
	stars_label.add_theme_font_size_override("font_size", 14)
	stars_label.add_theme_color_override("font_color", UITheme.COLOR_TAG_YELLOW)
	row.add_child(stars_label)

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.max_value = paths.size()
	bar.value = completed

	var track_style := StyleBoxFlat.new()
	track_style.bg_color = UITheme.COLOR_DIVIDER
	track_style.corner_radius_top_left = 4
	track_style.corner_radius_top_right = 4
	track_style.corner_radius_bottom_left = 4
	track_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", track_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = UITheme.COLOR_ACCENT
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill_style)

	vbox.add_child(bar)

	return margin


## "< Bölüm N (başlangıç-bitiş) >" şeklinde bir pager — sekme şeridi yerine
## bunu kullanıyoruz çünkü kaç bölüm olursa olsun (4 de olsa 16 da) aynı
## genişlikte kalıyor. Kilitli bir bölüme de gidilebilir (gezip kaç yıldız
## gerektiğini görebilsin diye), sadece içindeki levellar kilitli görünür.
func _build_segment_pager() -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", SIDE_MARGIN)
	margin.add_theme_constant_override("margin_right", SIDE_MARGIN)
	margin.add_theme_constant_override("margin_bottom", 10)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	_prev_btn = UITheme.make_translucent_button("<", Vector2(44, 52), 18)
	_prev_btn.pressed.connect(func(): _on_segment_selected(_current_segment - 1))
	row.add_child(_prev_btn)

	var card := UITheme.make_card(14, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	_pager_title = Label.new()
	_pager_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pager_title.add_theme_font_size_override("font_size", 16)
	_pager_title.add_theme_color_override("font_color", UITheme.COLOR_TEXT_DARK)
	vbox.add_child(_pager_title)

	_pager_subtitle = Label.new()
	_pager_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pager_subtitle.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_pager_subtitle)

	_next_btn = UITheme.make_translucent_button(">", Vector2(44, 52), 18)
	_next_btn.pressed.connect(func(): _on_segment_selected(_current_segment + 1))
	row.add_child(_next_btn)

	return margin


func _update_pager() -> void:
	var s := _current_segment
	var chunk: Array = _segments[s]
	var start: int = s * SEGMENT_SIZE + 1
	var end: int = start + chunk.size() - 1

	_pager_title.text = "Bölüm %d" % (s + 1)

	if _is_segment_unlocked(s):
		_pager_subtitle.text = "%d-%d" % [start, end]
		_pager_subtitle.add_theme_color_override("font_color", UITheme.COLOR_TEXT_MUTED)
	else:
		var have := _stars_in_segment(s - 1)
		_pager_subtitle.text = "🔒 %d-%d  ·  %d/%d ★ gerekiyor" % [start, end, have, STARS_REQUIRED_TO_UNLOCK_SEGMENT]
		_pager_subtitle.add_theme_color_override("font_color", UITheme.COLOR_DANGER)

	_prev_btn.disabled = s == 0
	_next_btn.disabled = s == _segments.size() - 1


func _on_segment_selected(s: int) -> void:
	if s < 0 or s >= _segments.size() or s == _current_segment:
		return
	_current_segment = s
	_update_pager()
	_render_segment(s)
	_scroll.scroll_vertical = 0


## Seçili bölümün zigzag yolunu (path_container'ı sıfırdan kurup) çizer.
func _render_segment(s: int) -> void:
	if _path_container != null and is_instance_valid(_path_container):
		_path_container.queue_free()

	var segment_paths: Array = _segments[s]
	var global_offset := s * SEGMENT_SIZE

	_path_container = Control.new()
	_path_container.custom_minimum_size = Vector2(_path_width, TOP_PADDING + segment_paths.size() * VERTICAL_SPACING + BOTTOM_PADDING)
	_path_outer_margin.add_child(_path_container)

	var path_line := PathLine.new()
	path_line.set_anchors_preset(Control.PRESET_FULL_RECT)
	_path_container.add_child(path_line)

	var badge_centers: PackedVector2Array = PackedVector2Array()

	var previous_completed := _is_segment_unlocked(s)  # bölüm sınırını aşan kilit zinciri
	var current_assigned := false
	for i in segment_paths.size():
		var path: String = segment_paths[i]
		var global_index := global_offset + i
		var level: LevelData = load(path)
		var stars: int = SaveManager.get_stars(level.level_name)
		var locked: bool = not previous_completed
		var is_current: bool = not locked and stars == 0 and not current_assigned
		if is_current:
			current_assigned = true

		var node_pos := Vector2(
			_left_x if i % 2 == 0 else _right_x,
			TOP_PADDING + i * VERTICAL_SPACING
		)
		var badge_center := _add_level_node(_path_container, path, level, global_index, stars, locked, is_current, node_pos)
		badge_centers.append(badge_center)

		previous_completed = stars > 0

	path_line.points = badge_centers
	path_line.queue_redraw()


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
