extends Node2D

## PuzzBoard'un açılış (splash) ekranı (scenes/Splash.tscn).
## Proje Ayarları > Uygulama > Çalıştır > Ana Sahne burasıdır — Ana Menü
## değil, önce burası açılır.
##
## Sırayla iki aşama gösterir: DMR Studio rozeti, ardından PuzzBoard logosu.
## Her ikisi de hafifçe dönerek + büyüyerek belirip bir süre durduktan sonra
## sönüyor. Ekrana dokunmak/tıklamak splash'ı atlayıp direkt Ana Menü'ye
## geçiyor (tekrar tekrar izlemek sıkıcı olmasın diye).

const NEXT_SCENE := "res://scenes/MainMenu.tscn"
const GAME_LOGO_PATH := "res://art/PuzzBoardLOGO.png"

const BG_COLOR := Color("0c0b16")
const BADGE_BG := Color("0f1015")
const BADGE_ACCENT := Color("00c2e0")
const BADGE_TEXT := Color("f5f6f8")

const START_ANGLE := -9.0  # derece
const ENTER_TIME := 0.5
const HOLD_TIME := 1.0
const EXIT_TIME := 0.3

var _center: CenterContainer
var _skipped := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(BG_COLOR)

	var canvas := CanvasLayer.new()
	add_child(canvas)

	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_center)

	var skip_catcher := Control.new()
	skip_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	skip_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_catcher.gui_input.connect(_on_skip_input)
	canvas.add_child(skip_catcher)

	_run_intro()


func _on_skip_input(event: InputEvent) -> void:
	var is_tap: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed)
	if is_tap:
		_go_to_main_menu()


func _run_intro() -> void:
	await _play_stage(_build_studio_badge())
	if _skipped:
		return

	await _play_stage(_build_image_stage(GAME_LOGO_PATH))
	if _skipped:
		return

	_go_to_main_menu()


## DMR Studio rozeti — SVG olarak denendi ama Godot'un SVG içe aktarıcısı
## <text> elemanlarını render etmiyor (yazılar kayboluyor). Bunun yerine
## projenin geri kalanıyla aynı yöntemle (Panel + Label) kod içinde çizildi.
func _build_studio_badge() -> Control:
	var card := UITheme.make_card(26, 30, BADGE_BG)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	var accent := UITheme.make_panel(BADGE_ACCENT, Vector2(70, 4), 2)
	accent.custom_minimum_size = Vector2(70, 4)
	accent.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(accent)

	var dmr_label := Label.new()
	dmr_label.text = _spaced("DMR")
	dmr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dmr_label.add_theme_font_size_override("font_size", 46)
	dmr_label.add_theme_color_override("font_color", BADGE_TEXT)
	vbox.add_child(dmr_label)

	var divider := UITheme.make_panel(Color(1, 1, 1, 0.25), Vector2(90, 2), 0)
	divider.custom_minimum_size = Vector2(90, 2)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(divider)

	var studio_label := Label.new()
	studio_label.text = _spaced("STUDIO")
	studio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	studio_label.add_theme_font_size_override("font_size", 15)
	studio_label.add_theme_color_override("font_color", Color(BADGE_TEXT, 0.85))
	vbox.add_child(studio_label)

	return card


func _spaced(text: String) -> String:
	var result := ""
	for i in text.length():
		result += text[i]
		if i < text.length() - 1:
			result += " "
	return result


func _build_image_stage(path: String) -> Control:
	var img := TextureRect.new()
	img.texture = load(path)
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # yoksa min boyut texture'ın gerçek (dev) pikseli olur
	img.custom_minimum_size = Vector2(300, 300)
	return img


## node'u hafifçe dönerek + büyüyerek + belirerek gösterir, bir süre
## bekletir, sonra söndürüp kaldırır. Skip yapılırsa daha fazla beklemeden
## döner (sahne zaten değişiyor olacak).
func _play_stage(node: Control) -> void:
	_center.add_child(node)
	node.modulate = Color(1, 1, 1, 0)
	node.scale = Vector2(0.85, 0.85)
	node.rotation_degrees = START_ANGLE

	await get_tree().process_frame  # gerçek boyutu bilinsin diye bir kare bekle
	node.pivot_offset = node.size / 2.0

	var tw := create_tween()
	tw.tween_property(node, "modulate:a", 1.0, ENTER_TIME)
	tw.parallel().tween_property(node, "scale", Vector2.ONE, ENTER_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(node, "rotation_degrees", 0.0, ENTER_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(HOLD_TIME)
	tw.tween_property(node, "modulate:a", 0.0, EXIT_TIME)
	await tw.finished

	if is_instance_valid(node):
		node.queue_free()


func _go_to_main_menu() -> void:
	if _skipped:
		return
	_skipped = true
	get_tree().change_scene_to_file(NEXT_SCENE)
