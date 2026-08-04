extends RefCounted
class_name SaveManager

## Level başına en yüksek yıldızı user://save_data.json içinde tutar.
## Autoload eklemene gerek yok, direkt SaveManager.save_stars(...) diye çağır.

const SAVE_PATH := "user://save_data.json"
const SETTINGS_KEY := "_settings"  # level isimleriyle çakışmasın diye alt çizgiyle başlıyor


static func _load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


static func _save_data(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


static func _get_record(data: Dictionary, level_name: String) -> Dictionary:
	var raw = data.get(level_name, {})
	if raw is Dictionary:
		return raw
	return {}  # eski format (düz int yıldız) ile karşılaşırsak sıfırdan başla


## Yıldız ve en az hamle rekorunu, sadece önceki rekordan iyiyse günceller.
static func save_result(level_name: String, stars: int, moves: int) -> void:
	var data := _load_data()
	var record := _get_record(data, level_name)
	var current_stars: int = record.get("stars", 0)
	var current_moves: int = record.get("best_moves", -1)
	if stars > current_stars:
		record["stars"] = stars
	if current_moves == -1 or moves < current_moves:
		record["best_moves"] = moves
	data[level_name] = record
	_save_data(data)


static func get_stars(level_name: String) -> int:
	var data := _load_data()
	return _get_record(data, level_name).get("stars", 0)


## Kaydedilmiş rekor yoksa -1 döner.
static func get_best_moves(level_name: String) -> int:
	var data := _load_data()
	return _get_record(data, level_name).get("best_moves", -1)


static func get_setting(key: String, default_value: Variant) -> Variant:
	var data := _load_data()
	var settings: Dictionary = data.get(SETTINGS_KEY, {})
	return settings.get(key, default_value)


static func set_setting(key: String, value: Variant) -> void:
	var data := _load_data()
	var settings: Dictionary = data.get(SETTINGS_KEY, {})
	settings[key] = value
	data[SETTINGS_KEY] = settings
	_save_data(data)
