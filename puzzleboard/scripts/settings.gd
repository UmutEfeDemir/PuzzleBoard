extends Node2D

## PuzzBoard ayarlar ekranı (scenes/Settings.tscn).
## Ses/Müzik/Titreşim/Tema tercihleri SaveManager üzerinden
## user://save_data.json içinde kalıcı tutulur.
## - Titreşim gerçekten çalışıyor: Main sahnesi bu ayarı okuyup
##   Input.vibrate_handheld() çağırıyor.
## - Müzik gerçekten çalışıyor: MusicManager (autoload) bu ayarı okuyup
##   res://audio/music.ogg dosyasını çalıp durduruyor (dosya yoksa sessizce
##   hiçbir şey yapmaz).
## - Ses Efektleri şu an gerçek bir audio sistemine bağlı değil (projede
##   henüz efekt dosyası yok) — tercih kaydediliyor, sistem eklenince
##   buradan okunabilir.
## - Tema değişikliği anında görünmesi için ekran kendini yeniden yükler.

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

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_top", 8)
	content_margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(content_margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	content_margin.add_child(content)

	content.add_child(_build_preferences_card())
	content.add_child(_build_theme_card())


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
	title.text = "Ayarlar"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", UITheme.COLOR_TEXT_LIGHT)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title)

	return margin


func _build_preferences_card() -> Control:
	var card := UITheme.make_card(24, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	_add_toggle_row(vbox, "Ses Efektleri", "sound_effects", true)
	_add_divider(vbox)
	_add_toggle_row(vbox, "Müzik", "music", false, _on_music_toggled)
	_add_divider(vbox)
	_add_toggle_row(vbox, "Titreşim", "vibration", true)
	_add_divider(vbox)
	_add_link_row(vbox, "Dil", "Türkçe >", _show_language_note)

	return card


func _build_theme_card() -> Control:
	var card := UITheme.make_card(24, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)

	var label := Label.new()
	label.text = "Tema"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_DARK)
	outer.add_child(label)

	var picker := HBoxContainer.new()
	picker.add_theme_constant_override("separation", 10)
	outer.add_child(picker)

	var is_dark := UITheme.is_dark_mode()

	var light_btn := _make_theme_option("Beyaz", not is_dark)
	light_btn.pressed.connect(func(): _select_theme(false))
	picker.add_child(light_btn)

	var dark_btn := _make_theme_option("Koyu", is_dark)
	dark_btn.pressed.connect(func(): _select_theme(true))
	picker.add_child(dark_btn)

	return card


func _make_theme_option(text: String, active: bool) -> Button:
	var btn: Button
	if active:
		btn = UITheme.make_chunky_button(text, Vector2(0, 44), UITheme.COLOR_ACCENT, UITheme.COLOR_ACCENT_SHADOW, UITheme.COLOR_ACCENT_TEXT, 16, 14)
	else:
		btn = UITheme.make_chunky_button(text, Vector2(0, 44), Color(0, 0, 0, 0.06), Color(0, 0, 0, 0), UITheme.COLOR_TEXT_MUTED, 16, 14)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return btn


func _select_theme(dark: bool) -> void:
	if UITheme.is_dark_mode() == dark:
		return
	UITheme.set_dark_mode(dark)
	get_tree().reload_current_scene()


func _add_divider(parent: VBoxContainer) -> void:
	var line := UITheme.make_panel(UITheme.COLOR_DIVIDER, Vector2(0, 1), 0)
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(line)


func _add_toggle_row(parent: VBoxContainer, label_text: String, setting_key: String, default_value: bool, on_toggled: Callable = Callable()) -> void:
	var row := MarginContainer.new()
	row.add_theme_constant_override("margin_left", 14)
	row.add_theme_constant_override("margin_right", 14)
	row.add_theme_constant_override("margin_top", 12)
	row.add_theme_constant_override("margin_bottom", 12)
	parent.add_child(row)

	var hbox := HBoxContainer.new()
	row.add_child(hbox)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_DARK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(label)

	var toggle := UITheme.make_toggle(
		SaveManager.get_setting(setting_key, default_value),
		func(pressed: bool):
			SaveManager.set_setting(setting_key, pressed)
			if on_toggled.is_valid():
				on_toggled.call(pressed)
	)
	hbox.add_child(toggle)


func _add_link_row(parent: VBoxContainer, label_text: String, value_text: String, on_press: Callable) -> void:
	var row := MarginContainer.new()
	row.add_theme_constant_override("margin_left", 14)
	row.add_theme_constant_override("margin_right", 14)
	row.add_theme_constant_override("margin_top", 4)
	row.add_theme_constant_override("margin_bottom", 4)
	parent.add_child(row)

	var hbox := HBoxContainer.new()
	row.add_child(hbox)

	var btn := UITheme.make_flat_row_button(label_text)
	btn.custom_minimum_size = Vector2(0, 44)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(on_press)
	hbox.add_child(btn)

	if value_text != "":
		var value_label := Label.new()
		value_label.text = value_text
		value_label.add_theme_font_size_override("font_size", 15)
		value_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_MUTED)
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(value_label)


func _on_music_toggled(pressed: bool) -> void:
	MusicManager.set_enabled(pressed)


func _show_language_note() -> void:
	var dialog := AcceptDialog.new()
	dialog.dialog_text = "Şu an yalnızca Türkçe destekleniyor."
	dialog.title = "Dil"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
