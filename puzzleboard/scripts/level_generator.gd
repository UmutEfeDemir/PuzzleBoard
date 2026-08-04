@tool
extends EditorScript

## Bu scripti Godot editöründe "File > Run" ile çalıştır.
## Level'ları elle Vector2i koordinatları yazarak değil, standart Sokoban
## ASCII haritasıyla tanımlarsın — çok daha hızlı ve göz ile kontrol edilebilir.
##
## Harita karakterleri:
##   #  duvar
##   .  hedef (boş)
##   $  kutu
##   *  hedef üzerinde kutu (zaten tamamlanmış başlangıç)
##   @  oyuncu
##   +  hedef üzerinde oyuncu
##   (boşluk) zemin
##
## Yeni level eklemek için: aşağıya _make_levels() içine bir satır ekle,
## harita + isim + yıldız limitlerini ver. res://levels/ altına .tres olarak
## kaydedilir, Level Select ekranı otomatik listeler (kod değişikliği gerekmez).

func _run() -> void:
	var dir := "res://levels"
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_absolute(dir)

	_make_levels(dir)


func _make_levels(dir: String) -> void:
	# Level 1: tek kutu, tek itme.
	_save_level(dir, "level_01", "Level 1", [
		"#####",
		"#@$.#",
		"#####",
	], 1, 2)

	# Level 2: tek kutu, aynı yönde iki itme.
	_save_level(dir, "level_02", "Level 2", [
		"######",
		"#@$ .#",
		"######",
	], 2, 3)

	# Level 3: iki kutu, iki oda + oda arası gezinme.
	_save_level(dir, "level_03", "Level 3", [
		"######",
		"#@$ .#",
		"#    #",
		"# $ .#",
		"######",
	], 8, 12)

	# Level 4: üç kutu, üç oda + daha uzun gezinme.
	_save_level(dir, "level_04", "Level 4", [
		"######",
		"#@$ .#",
		"#    #",
		"# $ .#",
		"#    #",
		"# $ .#",
		"######",
	], 14, 20)


## --- Alt seviye yardımcılar: yeni level eklerken bunlara dokunmana gerek yok ---

func _save_level(dir: String, file_name: String, level_name: String, ascii_map: Array, moves_3: int, moves_2: int) -> void:
	var level := _level_from_ascii(ascii_map, level_name, moves_3, moves_2)
	var path := "%s/%s.tres" % [dir, file_name]
	ResourceSaver.save(level, path)
	print("Kaydedildi: ", path)


func _level_from_ascii(ascii_map: Array, level_name: String, moves_3: int, moves_2: int) -> LevelData:
	var level := LevelData.new()
	level.level_name = level_name
	level.grid_width = 0
	for row in ascii_map:
		level.grid_width = max(level.grid_width, (row as String).length())
	level.grid_height = ascii_map.size()

	var walls: Array[Vector2i] = []
	var boxes: Array[Vector2i] = []
	var targets: Array[Vector2i] = []
	var player_start := Vector2i.ZERO
	var player_found := false

	for y in range(ascii_map.size()):
		var row: String = ascii_map[y]
		for x in range(row.length()):
			var pos := Vector2i(x, y)
			match row[x]:
				"#":
					walls.append(pos)
				".":
					targets.append(pos)
				"$":
					boxes.append(pos)
				"*":
					boxes.append(pos)
					targets.append(pos)
				"@":
					player_start = pos
					player_found = true
				"+":
					player_start = pos
					player_found = true
					targets.append(pos)

	if not player_found:
		push_warning("Level '%s' haritasında @ (oyuncu) yok!" % level_name)
	if boxes.size() != targets.size():
		push_warning("Level '%s': kutu sayısı (%d) hedef sayısıyla (%d) eşleşmiyor!" % [level_name, boxes.size(), targets.size()])

	level.walls = walls
	level.boxes = boxes
	level.targets = targets
	level.player_start = player_start
	level.moves_for_3_stars = moves_3
	level.moves_for_2_stars = moves_2
	return level
