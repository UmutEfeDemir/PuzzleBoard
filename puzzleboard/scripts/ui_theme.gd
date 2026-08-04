extends RefCounted
class_name UITheme

## PuzzBoard'un tüm ekranlarında (Ana Menü, Level Seç, Ayarlar, Oyun İçi)
## kullanılan ortak renk paleti ve UI yardımcıları. Renk değerleri
## "PuzzBoard - Game Screens.html" tasarım referansındaki hex kodlarla
## birebir eşleşiyor. StyleBoxFlat gradyan desteklemediği için buton/rozet
## iç dolgularında iki tonun ortalaması (solid) kullanılıyor; ekran arka
## planı gerçek 3 durak gradyan olarak GradientTexture2D ile çiziliyor.

# --- Zemin gradyanı: linear-gradient(165deg, #7c6bff 0%, #5b46e0 55%, #4433c4 100%) ---
# (static var olarak aşağıdaki "Koyu / Beyaz Tema" bölümünde tanımlı, temaya göre değişir)

# --- Aksan (buton/yıldız) gradyanı: linear-gradient(180deg, #ffcf5c, #ff9d3d) ---
const COLOR_ACCENT_TOP := Color("ffcf5c")
const COLOR_ACCENT_BOTTOM := Color("ff9d3d")
const COLOR_ACCENT := Color("ffb64d")  # iki tonun ortalaması, düz dolgu için
const COLOR_ACCENT_SHADOW := Color("d9701c")
const COLOR_ACCENT_TEXT := Color("5a3200")
const COLOR_TAG_YELLOW := Color("ffd166")

# --- "Mevcut level" rozeti: linear-gradient(180deg, #ff9d3d, #ff6b6b) ---
const COLOR_CURRENT := Color("ff8454")
const COLOR_CURRENT_SHADOW := Color("c23f3f")
const COLOR_DANGER := Color("ff6b6b")

# --- Kartlar / metin: temaya göre değişir, bkz. aşağıdaki Koyu/Beyaz Tema bölümü ---
static var COLOR_CARD := Color.WHITE
static var COLOR_CARD_TRANSLUCENT := Color(1, 1, 1, 0.16)
static var COLOR_CARD_BORDER := Color(1, 1, 1, 0.25)
static var COLOR_TEXT_LIGHT := Color.WHITE
static var COLOR_TEXT_DARK := Color("3a2a55")  # kart üstü metin — koyu temada kart da koyu olduğu için bu değer AÇIK renk olur
static var COLOR_TEXT_MUTED := Color("8b81b3")
static var COLOR_LOCKED_BG := Color(1, 1, 1, 0.18)
static var COLOR_DIVIDER := Color(0, 0, 0, 0.08)


# ============================================================
# Koyu / Beyaz Tema
# ============================================================
# StyleBoxFlat'lar oluşturulurken yukarıdaki static var'ların O ANKİ
# değeri kopyalanıyor, yani zaten inşa edilmiş ekranlar tema değişince
# otomatik güncellenmez — tema değiştikten sonra ekranı yeniden yüklemek
# (get_tree().reload_current_scene()) gerekir.

static var COLOR_BG_TOP := Color("7c6bff")
static var COLOR_BG_MID := Color("5b46e0")
static var COLOR_BG_BOTTOM := Color("4433c4")

const _LIGHT_BG_TOP := Color("7c6bff")
const _LIGHT_BG_MID := Color("5b46e0")
const _LIGHT_BG_BOTTOM := Color("4433c4")
const _LIGHT_CARD := Color.WHITE
const _LIGHT_CARD_TRANSLUCENT := Color(1, 1, 1, 0.16)
const _LIGHT_CARD_BORDER := Color(1, 1, 1, 0.25)
const _LIGHT_TEXT_LIGHT := Color.WHITE
const _LIGHT_TEXT_DARK := Color("3a2a55")
const _LIGHT_TEXT_MUTED := Color("8b81b3")
const _LIGHT_LOCKED_BG := Color(1, 1, 1, 0.18)
const _LIGHT_DIVIDER := Color(0, 0, 0, 0.08)

const _DARK_BG_TOP := Color("2a2550")
const _DARK_BG_MID := Color("1c1836")
const _DARK_BG_BOTTOM := Color("100e1e")
const _DARK_CARD := Color("211d3a")
const _DARK_CARD_TRANSLUCENT := Color(1, 1, 1, 0.07)
const _DARK_CARD_BORDER := Color(1, 1, 1, 0.14)
const _DARK_TEXT_LIGHT := Color(0.94, 0.93, 0.98)
const _DARK_TEXT_DARK := Color(0.94, 0.93, 0.98)  # koyu temada kart da koyu, metin açık olmalı
const _DARK_TEXT_MUTED := Color("a89bd4")
const _DARK_LOCKED_BG := Color(1, 1, 1, 0.06)
const _DARK_DIVIDER := Color(1, 1, 1, 0.08)

const SETTING_KEY_DARK_THEME := "dark_theme"


static func is_dark_mode() -> bool:
	return SaveManager.get_setting(SETTING_KEY_DARK_THEME, false)


## Kayıtlı tema tercihini okuyup renkleri buna göre ayarlar. Her ekranın
## _ready()'sinin EN BAŞINDA, herhangi bir UI kurulmadan önce çağrılmalı.
static func load_theme() -> void:
	_apply(is_dark_mode())


## Kullanıcı Ayarlar'da temayı değiştirdiğinde çağrılır, tercihi kaydeder.
static func set_dark_mode(dark: bool) -> void:
	SaveManager.set_setting(SETTING_KEY_DARK_THEME, dark)
	_apply(dark)


static func _apply(dark: bool) -> void:
	COLOR_BG_TOP = _DARK_BG_TOP if dark else _LIGHT_BG_TOP
	COLOR_BG_MID = _DARK_BG_MID if dark else _LIGHT_BG_MID
	COLOR_BG_BOTTOM = _DARK_BG_BOTTOM if dark else _LIGHT_BG_BOTTOM
	COLOR_CARD = _DARK_CARD if dark else _LIGHT_CARD
	COLOR_CARD_TRANSLUCENT = _DARK_CARD_TRANSLUCENT if dark else _LIGHT_CARD_TRANSLUCENT
	COLOR_CARD_BORDER = _DARK_CARD_BORDER if dark else _LIGHT_CARD_BORDER
	COLOR_TEXT_LIGHT = _DARK_TEXT_LIGHT if dark else _LIGHT_TEXT_LIGHT
	COLOR_TEXT_DARK = _DARK_TEXT_DARK if dark else _LIGHT_TEXT_DARK
	COLOR_TEXT_MUTED = _DARK_TEXT_MUTED if dark else _LIGHT_TEXT_MUTED
	COLOR_LOCKED_BG = _DARK_LOCKED_BG if dark else _LIGHT_LOCKED_BG
	COLOR_DIVIDER = _DARK_DIVIDER if dark else _LIGHT_DIVIDER


## Referanstaki "linear-gradient(165deg, #7c6bff 0%, #5b46e0 55%, #4433c4 100%)"
## zeminini üreten dokuyu döndürür. Nereye ekleneceğine çağıran karar verir.
static func make_gradient_rect() -> TextureRect:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([COLOR_BG_TOP, COLOR_BG_MID, COLOR_BG_BOTTOM])

	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 4
	tex.height = 4
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.15, 0.0)
	tex.fill_to = Vector2(0.85, 1.0)

	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Tüm ekranların ortak zemin gradyanını canvas'ın en arkasına ekler.
static func add_gradient_background(canvas: CanvasLayer) -> TextureRect:
	var rect := make_gradient_rect()
	canvas.add_child(rect)
	canvas.move_child(rect, 0)
	return rect


static func make_panel(color: Color, size: Vector2, radius: int) -> Panel:
	var panel := Panel.new()
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.corner_detail = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel


## Beyaz (veya verilen renkte) kart: PanelContainer olduğu için içine
## eklenen TEK child'ın (genelde bir VBoxContainer) minimum boyutuna göre
## otomatik büyür.
static func make_card(radius: int = 22, margin: int = 20, color = null) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_CARD if color == null else color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.corner_detail = 8
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	panel.add_theme_stylebox_override("panel", style)
	return panel


## Zemin üstündeki yarı saydam kart (ör. Ana Menü ikincil butonları,
## Level Seç geri butonu). İnce beyaz kenarlıkla (border) çevrili.
static func make_translucent_card(radius: int = 18, margin: int = 14) -> PanelContainer:
	var panel := make_card(radius, margin, COLOR_CARD_TRANSLUCENT)
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_CARD_BORDER
	return panel


## "Chunky" mobil buton: alt kenarda kalın renkli çizgiyle 3D basma hissi verir.
## Basılınca çizgi kaybolur, metin biraz aşağı kayar (gerçek buton basma hissi).
static func make_chunky_button(text: String, min_size: Vector2, bg: Color, shadow: Color, text_color: Color, font_size: int = 22, corner_radius: int = 18) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_disabled_color", Color(text_color, 0.45))

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.corner_radius_top_left = corner_radius
	normal.corner_radius_top_right = corner_radius
	normal.corner_radius_bottom_left = corner_radius
	normal.corner_radius_bottom_right = corner_radius
	normal.corner_detail = 8
	normal.border_width_bottom = 6
	normal.border_color = shadow

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.08)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.border_width_bottom = 0
	pressed.content_margin_top = pressed.content_margin_top + 6

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = COLOR_LOCKED_BG
	disabled.border_color = Color(0, 0, 0, 0)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_stylebox_override("disabled", disabled)
	return btn


## Zemin üstündeki yarı saydam ikincil buton (ör. "🏆 Skorlar", geri oku).
static func make_translucent_button(text: String, min_size: Vector2, font_size: int = 17) -> Button:
	var btn := make_chunky_button(text, min_size, COLOR_CARD_TRANSLUCENT, Color(0, 0, 0, 0), COLOR_TEXT_LIGHT, font_size)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style: StyleBoxFlat = btn.get_theme_stylebox(state)
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_color = COLOR_CARD_BORDER
	return btn


## Beyaz kart üstündeki düz (arkaplansız) metin satırı butonu.
static func make_flat_row_button(text: String, color = null) -> Button:
	var use_color: Color = COLOR_TEXT_DARK if color == null else color
	var btn := Button.new()
	btn.text = text
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", use_color)
	btn.add_theme_color_override("font_hover_color", use_color)
	return btn


## Referanstaki özel hap (pill) toggle switch. Godot'un native CheckButton'ı
## farklı göründüğü için Panel + Tween ile elden yapıldı. toggled_callback
## her tıklamada yeni bool değerle çağrılır.
static func make_toggle(initial: bool, toggled_callback: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(50, 28)
	btn.toggle_mode = true
	btn.button_pressed = initial

	var track_on := StyleBoxFlat.new()
	track_on.bg_color = COLOR_ACCENT
	track_on.corner_radius_top_left = 16
	track_on.corner_radius_top_right = 16
	track_on.corner_radius_bottom_left = 16
	track_on.corner_radius_bottom_right = 16

	var track_off := track_on.duplicate() as StyleBoxFlat
	track_off.bg_color = Color("e2ddf7")

	btn.add_theme_stylebox_override("normal", track_off)
	btn.add_theme_stylebox_override("hover", track_off)
	btn.add_theme_stylebox_override("pressed", track_on)
	btn.add_theme_stylebox_override("hover_pressed", track_on)
	btn.add_theme_stylebox_override("focus", track_off)

	var thumb := make_panel(COLOR_CARD, Vector2(22, 22), 11)
	thumb.position = Vector2(3 if not initial else 25, 3)
	btn.add_child(thumb)

	btn.toggled.connect(func(pressed: bool):
		var tw: Tween = btn.create_tween()
		tw.tween_property(thumb, "position:x", 25.0 if pressed else 3.0, 0.12)
		toggled_callback.call(pressed)
	)

	return btn
