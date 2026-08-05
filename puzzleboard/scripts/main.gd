extends Node2D

## Bu script boş bir Node2D sahnesine atanır (scenes/Main.tscn).
## Board, oyuncu, kutular tamamen Panel + StyleBoxFlat ile kod içinde çizilir
## (yuvarlak köşeler, sprite/tileset asset'i olmadan). PC'ye geçince sprite
## kullanmak istersen sadece _build_board() içindeki Panel'leri Sprite2D ile
## değiştir. Genel UI renkleri/butonları UITheme'den gelir (scripts/ui_theme.gd).
##
## Board kendi koyu renk paletinde kalıyor (bulmaca okunurluğu için), ama
## etrafındaki HUD/kart/buton dili artık PuzzBoard'un beyaz kart + mor zemin
## kimliğiyle eşleşiyor.

const CELL_SIZE := 64.0
const CELL_GAP := 4.0
const COLOR_FLOOR := Color(0.18, 0.18, 0.23)
const COLOR_WALL := Color(0.05, 0.05, 0.07)
const COLOR_TARGET := Color(0.95, 0.75, 0.25)
const COLOR_PLAYER := Color(0.35, 0.65, 0.95)
const COLOR_BOX := Color(0.78, 0.55, 0.32)
const COLOR_BOX_ON_TARGET := Color(0.45, 0.85, 0.45)
const COLOR_SCREEN_BG := Color("5b46e0")  # zemin gradyanının orta durağı
const COLOR_ICON_PURPLE := Color("5b46e0")
const COLOR_TRACK := Color("e2ddf7")
const COLOR_TRACK_SHADOW := Color("d8d2f5")

var grid_manager: GridManager
var swipe_input: SwipeInput

var board_layer: Node2D
var box_nodes: Dictionary = {}  # Vector2i (güncel pozisyon) -> Panel
var player_node: Panel

var move_value_label: Label
var progress_bar: ProgressBar
var _progress_fill_style: StyleBoxFlat

var completion_overlay: Control
var completion_title: Label
var completion_moves_value: Label
var completion_best_value: Label
var star_badges: Array[Panel] = []
var next_level_button: Button

var level_finished: bool = false

var deadlock_toast: Control
var _deadlock_tween: Tween
var _shake_tween: Tween

## Bu leveldeki ücretsiz geri alma hakkı kullanıldı mı? Level başına sıfırlanır
## (bu script her level yüklendiğinde yeniden _ready() çalıştırıyor).
var _free_undo_used := false


func _ready() -> void:
	UITheme.load_theme()

	grid_manager = GridManager.new()
	add_child(grid_manager)

	swipe_input = SwipeInput.new()
	add_child(swipe_input)

	var level_path: String = GameState.current_level_path
	if level_path == "":
		level_path = "res://levels/level_001.tres"

	var level: LevelData = load(level_path)
	grid_manager.load_level(level)

	_build_board(level)
	_build_ui()

	swipe_input.swiped.connect(_on_swiped)
	grid_manager.player_moved.connect(_on_player_moved)
	grid_manager.box_pushed.connect(_on_box_pushed)
	grid_manager.level_completed.connect(_on_level_completed)
	grid_manager.move_count_changed.connect(_on_move_count_changed)
	grid_manager.box_deadlocked.connect(_on_box_deadlocked)


func _make_cell_panel(color: Color, size: Vector2, corner_radius: int) -> Panel:
	var panel := Panel.new()
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_detail = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _build_board(level: LevelData) -> void:
	RenderingServer.set_default_clear_color(COLOR_SCREEN_BG)

	board_layer = Node2D.new()
	add_child(board_layer)
	_fit_board_to_screen(level)

	for x in range(level.grid_width):
		for y in range(level.grid_height):
			var pos := Vector2i(x, y)
			var is_wall := level.is_wall(pos)
			var cell_size := Vector2(CELL_SIZE - CELL_GAP, CELL_SIZE - CELL_GAP)
			var cell := _make_cell_panel(COLOR_WALL if is_wall else COLOR_FLOOR, cell_size, 4 if is_wall else 10)
			cell.position = Vector2(pos) * CELL_SIZE
			board_layer.add_child(cell)

			if not is_wall and level.is_target(pos):
				var marker_size := CELL_SIZE * 0.32
				var marker := _make_cell_panel(COLOR_TARGET, Vector2(marker_size, marker_size), int(marker_size / 2))
				marker.position = cell.position + cell_size / 2 - marker.size / 2
				board_layer.add_child(marker)

	for box_pos in level.boxes:
		var box_color := COLOR_BOX_ON_TARGET if level.is_target(box_pos) else COLOR_BOX
		var box := _make_cell_panel(box_color, Vector2(CELL_SIZE - 12, CELL_SIZE - 12), 14)
		box.position = Vector2(box_pos) * CELL_SIZE + Vector2(6, 6)
		board_layer.add_child(box)
		box_nodes[box_pos] = box

	var player_size := CELL_SIZE - 16
	player_node = _make_cell_panel(COLOR_PLAYER, Vector2(player_size, player_size), int(player_size / 2))
	player_node.position = Vector2(level.player_start) * CELL_SIZE + Vector2(8, 8)
	board_layer.add_child(player_node)


## Board'u, HUD'un altında kalan alana göre ortalar ve gerekirse küçültür.
## Böylece hücre sayısı (level genişliği/yüksekliği) ekran boyutunu aşan
## levellar da (ör. Level 7) taşmadan/sola yapışmadan sığar.
const BOARD_TOP_RESERVED := 160.0
const BOARD_SIDE_MARGIN := 24.0
const BOARD_BOTTOM_MARGIN := 24.0

func _fit_board_to_screen(level: LevelData) -> void:
	var level_px_size := Vector2(level.grid_width, level.grid_height) * CELL_SIZE
	var viewport_size: Vector2 = get_viewport_rect().size

	var available_size := Vector2(
		viewport_size.x - BOARD_SIDE_MARGIN * 2.0,
		viewport_size.y - BOARD_TOP_RESERVED - BOARD_BOTTOM_MARGIN
	)

	var fit_scale: float = min(1.0, min(available_size.x / level_px_size.x, available_size.y / level_px_size.y))
	board_layer.scale = Vector2(fit_scale, fit_scale)

	var scaled_size := level_px_size * fit_scale
	board_layer.position = Vector2(
		(viewport_size.x - scaled_size.x) / 2.0,
		BOARD_TOP_RESERVED + (available_size.y - scaled_size.y) / 2.0
	)


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var top_margin := MarginContainer.new()
	top_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_margin.add_theme_constant_override("margin_left", 20)
	top_margin.add_theme_constant_override("margin_top", 44)
	top_margin.add_theme_constant_override("margin_right", 20)
	canvas.add_child(top_margin)

	var hud_vbox := VBoxContainer.new()
	hud_vbox.add_theme_constant_override("separation", 10)
	top_margin.add_child(hud_vbox)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	hud_vbox.add_child(row)

	var close_btn := UITheme.make_chunky_button("X", Vector2(38, 38), Color.WHITE, COLOR_TRACK_SHADOW, COLOR_ICON_PURPLE, 16, 12)
	close_btn.pressed.connect(_go_level_select)
	row.add_child(close_btn)

	var center_card := UITheme.make_card(16, 12)
	center_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(center_card)

	var center_vbox := VBoxContainer.new()
	center_vbox.add_theme_constant_override("separation", 0)
	center_card.add_child(center_vbox)

	var level_caption := Label.new()
	level_caption.text = grid_manager.level.level_name.to_upper()
	level_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_caption.add_theme_font_size_override("font_size", 12)
	level_caption.add_theme_color_override("font_color", UITheme.COLOR_TEXT_MUTED)
	center_vbox.add_child(level_caption)

	var moves_row := HBoxContainer.new()
	moves_row.alignment = BoxContainer.ALIGNMENT_CENTER
	moves_row.add_theme_constant_override("separation", 4)
	center_vbox.add_child(moves_row)

	move_value_label = Label.new()
	move_value_label.text = "0"
	move_value_label.add_theme_font_size_override("font_size", 20)
	move_value_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_DARK)
	moves_row.add_child(move_value_label)

	var moves_suffix := Label.new()
	moves_suffix.text = "hamle"
	moves_suffix.add_theme_font_size_override("font_size", 14)
	moves_suffix.add_theme_color_override("font_color", UITheme.COLOR_TEXT_MUTED)
	moves_suffix.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	moves_row.add_child(moves_suffix)

	var undo_btn := UITheme.make_chunky_button("Geri Al", Vector2(84, 38), Color.WHITE, COLOR_TRACK_SHADOW, COLOR_ICON_PURPLE, 14, 12)
	undo_btn.pressed.connect(_do_undo)
	row.add_child(undo_btn)

	var redo_btn := UITheme.make_chunky_button("İleri Al", Vector2(84, 38), Color.WHITE, COLOR_TRACK_SHADOW, COLOR_ICON_PURPLE, 14, 12)
	redo_btn.pressed.connect(_do_redo)
	row.add_child(redo_btn)

	progress_bar = ProgressBar.new()
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 10)
	progress_bar.max_value = grid_manager.level.moves_for_2_stars
	progress_bar.value = 0

	var track_style := StyleBoxFlat.new()
	track_style.bg_color = COLOR_TRACK
	track_style.corner_radius_top_left = 6
	track_style.corner_radius_top_right = 6
	track_style.corner_radius_bottom_left = 6
	track_style.corner_radius_bottom_right = 6
	progress_bar.add_theme_stylebox_override("background", track_style)

	_progress_fill_style = StyleBoxFlat.new()
	_progress_fill_style.bg_color = UITheme.COLOR_ACCENT
	_progress_fill_style.corner_radius_top_left = 6
	_progress_fill_style.corner_radius_top_right = 6
	_progress_fill_style.corner_radius_bottom_left = 6
	_progress_fill_style.corner_radius_bottom_right = 6
	progress_bar.add_theme_stylebox_override("fill", _progress_fill_style)
	hud_vbox.add_child(progress_bar)

	_build_completion_overlay(canvas)
	_build_deadlock_toast(canvas)


func _build_completion_overlay(canvas: CanvasLayer) -> void:
	completion_overlay = Control.new()
	completion_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	completion_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	completion_overlay.visible = false
	canvas.add_child(completion_overlay)

	var bg := UITheme.make_gradient_rect()
	completion_overlay.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 90)
	margin.add_theme_constant_override("margin_bottom", 48)
	completion_overlay.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(vbox)

	var tag := Label.new()
	tag.text = _spaced("TEBRİKLER")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", UITheme.COLOR_TAG_YELLOW)
	vbox.add_child(tag)

	completion_title = Label.new()
	completion_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion_title.add_theme_font_size_override("font_size", 34)
	completion_title.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
	vbox.add_child(completion_title)

	var stars_row := HBoxContainer.new()
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_row.add_theme_constant_override("separation", 10)
	var stars_margin := MarginContainer.new()
	stars_margin.add_theme_constant_override("margin_top", 30)
	stars_margin.add_theme_constant_override("margin_bottom", 30)
	stars_margin.add_child(stars_row)
	vbox.add_child(stars_margin)

	star_badges.clear()
	var star_sizes := [64.0, 80.0, 64.0]
	for i in 3:
		var badge := UITheme.make_panel(UITheme.COLOR_LOCKED_BG, Vector2(star_sizes[i], star_sizes[i]), int(star_sizes[i] / 2))
		badge.custom_minimum_size = Vector2(star_sizes[i], star_sizes[i])
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if i == 1:
			badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var star_label := Label.new()
		star_label.text = "★"
		star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		star_label.add_theme_font_size_override("font_size", int(star_sizes[i] * 0.42))
		star_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
		badge.add_child(star_label)
		stars_row.add_child(badge)
		star_badges.append(badge)

	var stats_card := UITheme.make_translucent_card(22, 20)
	stats_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(stats_card)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 10)
	stats_card.add_child(stats_vbox)

	var moves_stat := HBoxContainer.new()
	stats_vbox.add_child(moves_stat)
	moves_stat.add_child(_make_stat_label("Hamle", true))
	completion_moves_value = _make_stat_label("0", false)
	moves_stat.add_child(completion_moves_value)

	var best_stat := HBoxContainer.new()
	stats_vbox.add_child(best_stat)
	best_stat.add_child(_make_stat_label("En Az Hamle", true))
	completion_best_value = _make_stat_label("-", false)
	best_stat.add_child(completion_best_value)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 14)
	vbox.add_child(button_row)

	var restart_button := UITheme.make_translucent_button("Tekrar", Vector2(64, 64), 15)
	restart_button.pressed.connect(_restart_level)
	button_row.add_child(restart_button)

	next_level_button = UITheme.make_chunky_button(
		"SONRAKİ >", Vector2(0, 64), UITheme.COLOR_ACCENT, UITheme.COLOR_ACCENT_SHADOW, UITheme.COLOR_ACCENT_TEXT, 19
	)
	next_level_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_level_button.pressed.connect(_go_next_level)
	button_row.add_child(next_level_button)

	var level_select_button := UITheme.make_translucent_button("Level Seçime Dön", Vector2(0, 52), 15)
	level_select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_select_button.pressed.connect(_go_level_select)
	vbox.add_child(level_select_button)


## GridManager bir kutunun (köşeye sıkışıp) bir daha itilemeyeceğini
## tespit edince gösterilecek, kısa süre sonra sönen bir uyarı rozeti.
func _build_deadlock_toast(canvas: CanvasLayer) -> void:
	var toast_margin := MarginContainer.new()
	toast_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast_margin.add_theme_constant_override("margin_top", 138)
	toast_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(toast_margin)

	var toast_center := CenterContainer.new()
	toast_margin.add_child(toast_center)

	deadlock_toast = UITheme.make_card(14, 10, Color(0, 0, 0, 0.6))
	toast_center.add_child(deadlock_toast)

	var label := Label.new()
	label.text = "⚠ Bu kutu sıkıştı, Geri Al'ı dene"
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
	deadlock_toast.add_child(label)

	deadlock_toast.modulate = Color(1, 1, 1, 0)


func _on_box_deadlocked(_pos: Vector2i) -> void:
	if _deadlock_tween:
		_deadlock_tween.kill()

	deadlock_toast.modulate.a = 0.0
	_deadlock_tween = create_tween()
	_deadlock_tween.tween_property(deadlock_toast, "modulate:a", 1.0, 0.15)
	_deadlock_tween.tween_interval(1.4)
	_deadlock_tween.tween_property(deadlock_toast, "modulate:a", 0.0, 0.3)

	SFXManager.play("deadlock")

	if SaveManager.get_setting("vibration", true):
		Input.vibrate_handheld(15)


func _make_stat_label(text: String, is_key: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT if is_key else UITheme.COLOR_TAG_YELLOW)
	if not is_key:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _spaced(text: String) -> String:
	var result := ""
	for i in text.length():
		result += text[i]
		if i < text.length() - 1:
			result += " "
	return result


func _on_swiped(dir: Vector2i) -> void:
	if level_finished:
		return
	_attempt_move(dir)


## Hamle geçersizse (duvar/kilitli kutu) oyuncuyu o yöne hafifçe sarsarak
## geri bildirim verir — "neden hareket etmedim" hissini azaltır.
func _attempt_move(dir: Vector2i) -> void:
	if not grid_manager.try_move(dir):
		_shake_player(dir)
		SFXManager.play("invalid")


func _shake_player(dir: Vector2i) -> void:
	if _shake_tween:
		_shake_tween.kill()

	var base_pos := Vector2(grid_manager.player_pos) * CELL_SIZE + Vector2(8, 8)
	player_node.position = base_pos
	var offset := Vector2(dir) * 8.0

	_shake_tween = create_tween()
	_shake_tween.tween_property(player_node, "position", base_pos + offset, 0.05)
	_shake_tween.tween_property(player_node, "position", base_pos - offset * 0.4, 0.05)
	_shake_tween.tween_property(player_node, "position", base_pos, 0.05)


func _on_player_moved(_from: Vector2i, to: Vector2i) -> void:
	if _shake_tween:
		_shake_tween.kill()
	var tw := create_tween()
	tw.tween_property(player_node, "position", Vector2(to) * CELL_SIZE + Vector2(8, 8), 0.12)
	SFXManager.play("move")


func _on_box_pushed(from: Vector2i, to: Vector2i) -> void:
	var box: Panel = box_nodes[from]
	box_nodes.erase(from)
	box_nodes[to] = box

	var target_color := COLOR_BOX_ON_TARGET if grid_manager.level.is_target(to) else COLOR_BOX
	var box_style: StyleBoxFlat = box.get_theme_stylebox("panel")
	var tw := create_tween()
	tw.tween_property(box, "position", Vector2(to) * CELL_SIZE + Vector2(6, 6), 0.12)
	tw.parallel().tween_property(box_style, "bg_color", target_color, 0.12)

	SFXManager.play("push")

	if SaveManager.get_setting("vibration", true):
		Input.vibrate_handheld(25)


func _on_move_count_changed(count: int) -> void:
	move_value_label.text = str(count)

	progress_bar.value = count
	var level := grid_manager.level
	if count <= level.moves_for_3_stars:
		_progress_fill_style.bg_color = Color(0.35, 0.75, 0.45)
	elif count <= level.moves_for_2_stars:
		_progress_fill_style.bg_color = UITheme.COLOR_ACCENT
	else:
		_progress_fill_style.bg_color = UITheme.COLOR_DANGER


func _on_level_completed() -> void:
	level_finished = true
	var stars: int = grid_manager.get_stars()
	var moves: int = grid_manager.move_count
	var level_name: String = grid_manager.level.level_name

	var previous_best := SaveManager.get_best_moves(level_name)
	SaveManager.save_result(level_name, stars, moves)

	SFXManager.play("win")
	AdManager.notify_level_completed()

	if SaveManager.get_setting("vibration", true):
		Input.vibrate_handheld(60)

	completion_title.text = level_name + " Tamam!"
	completion_moves_value.text = str(moves)
	completion_best_value.text = str(moves) if previous_best == -1 else str(min(previous_best, moves))

	var has_next: bool = GameState.current_level_index >= 0 \
		and GameState.current_level_index + 1 < GameState.level_list.size()
	next_level_button.visible = has_next

	completion_overlay.modulate = Color(1, 1, 1, 0)
	completion_overlay.visible = true
	var fade := create_tween()
	fade.tween_property(completion_overlay, "modulate:a", 1.0, 0.25)

	_animate_stars(stars)


func _animate_stars(stars: int) -> void:
	for i in star_badges.size():
		var badge := star_badges[i]
		var earned := i < stars
		var star_label: Label = badge.get_child(0)
		var style: StyleBoxFlat = badge.get_theme_stylebox("panel")
		if not earned:
			continue
		badge.scale = Vector2(0.3, 0.3)
		badge.pivot_offset = badge.size / 2
		var tw := create_tween()
		tw.tween_interval(0.12 * i)
		tw.tween_callback(func():
			style.bg_color = UITheme.COLOR_ACCENT
			star_label.add_theme_color_override("font_color", UITheme.COLOR_ACCENT_TEXT)
		)
		tw.tween_property(badge, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK)
		tw.tween_property(badge, "scale", Vector2.ONE, 0.12)


func _restart_level() -> void:
	get_tree().reload_current_scene()


func _go_next_level() -> void:
	var idx: int = GameState.current_level_index + 1
	if idx >= GameState.level_list.size():
		return
	GameState.current_level_index = idx
	GameState.current_level_path = GameState.level_list[idx]
	get_tree().reload_current_scene()


func _go_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")


## Klavye ile test için (mobilde undo_button zaten var).
func _unhandled_input(event: InputEvent) -> void:
	if level_finished:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP, KEY_W:
				_attempt_move(Vector2i.UP)
			KEY_DOWN, KEY_S:
				_attempt_move(Vector2i.DOWN)
			KEY_LEFT, KEY_A:
				_attempt_move(Vector2i.LEFT)
			KEY_RIGHT, KEY_D:
				_attempt_move(Vector2i.RIGHT)
			KEY_Z:
				_do_undo()
			KEY_Y:
				_do_redo()


## Bu leveldeki ilk geri alma ücretsiz; ikincisinden itibaren ödüllü reklam
## izlemek gerekiyor (bkz. ad_manager.gd — SDK bağlanana kadar reklam
## otomatik "izlenmiş" sayılıyor, akış test sırasında bloklanmıyor).
func _do_undo() -> void:
	if not grid_manager.can_undo():
		return
	if not _free_undo_used:
		_free_undo_used = true
		_perform_undo()
	else:
		_confirm_rewarded_undo()


func _confirm_rewarded_undo() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Reklam İzle"
	dialog.dialog_text = "Bu leveldeki ücretsiz geri almayı kullandın. Bir hamle daha geri almak için kısa bir reklam izlemen gerekiyor."
	dialog.ok_button_text = "Reklamı İzle"
	dialog.cancel_button_text = "Vazgeç"
	add_child(dialog)
	dialog.confirmed.connect(func(): AdManager.show_rewarded_ad(_perform_undo))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()


func _perform_undo() -> void:
	grid_manager.undo()
	SFXManager.play("undo")


func _do_redo() -> void:
	grid_manager.redo()
	SFXManager.play("redo")
