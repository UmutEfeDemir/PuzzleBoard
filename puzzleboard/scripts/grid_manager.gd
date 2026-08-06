extends Node2D
class_name GridManager

## Sokoban tarzı grid mantığının kalbi.
## Görsel katmandan bağımsız - sadece state ve kurallar burada.
## TileMap/Sprite'lar bu sınıfı dinleyip görseli günceller.

signal player_moved(from: Vector2i, to: Vector2i)
signal box_pushed(from: Vector2i, to: Vector2i)
signal level_completed
signal move_count_changed(count: int)
signal box_deadlocked(pos: Vector2i)
signal door_state_changed(is_open: bool)

var level: LevelData
var player_pos: Vector2i
var box_positions: Array[Vector2i] = []

## Kapılar şu an açık mı (bkz. LevelData.switches/doors). Level'de kapı
## tanımlı değilse hep false kalır ama hiçbir etkisi olmaz (_is_blocked
## sadece level.doors doluysa devreye giriyor).
var doors_open: bool = false

var _undo_stack: Array[MoveCommand] = []
var _redo_stack: Array[MoveCommand] = []
var move_count: int = 0


func load_level(p_level: LevelData) -> void:
	level = p_level
	player_pos = level.player_start
	box_positions = level.boxes.duplicate()
	_undo_stack.clear()
	_redo_stack.clear()
	move_count = 0
	move_count_changed.emit(move_count)
	_update_door_state()


## Duvar VEYA (kapalı) kapı olduğu için geçilemeyen hücre mi?
func _is_blocked(pos: Vector2i) -> bool:
	if level.is_wall(pos):
		return true
	if level.is_door(pos) and not doors_open:
		return true
	return false


## Herhangi bir kutu bir düğmenin üzerindeyse kapılar açık, değilse kapalı.
## Kutu düğmeden ayrılırsa (itilirse) kapı otomatik geri kapanır.
func _update_door_state() -> void:
	var should_be_open := false
	for switch_pos in level.switches:
		if switch_pos in box_positions:
			should_be_open = true
			break
	if should_be_open != doors_open:
		doors_open = should_be_open
		door_state_changed.emit(doors_open)


## dir: Vector2i.UP / DOWN / LEFT / RIGHT
## Geri döndürdüğü bool: hamle geçerli miydi
func try_move(dir: Vector2i) -> bool:
	var target_pos: Vector2i = player_pos + dir

	if not level.is_within_bounds(target_pos) or _is_blocked(target_pos):
		return false

	var box_index: int = box_positions.find(target_pos)

	if box_index == -1:
		# Boş kareye normal hareket
		var cmd := MoveCommand.new(player_pos, target_pos)
		_apply_command(cmd)
		return true

	# Hedefte kutu var, itmeyi dene
	var box_target: Vector2i = target_pos + dir
	if not level.is_within_bounds(box_target) or _is_blocked(box_target):
		return false
	if box_target in box_positions:
		return false  # arkasında başka kutu var, itilemez

	var cmd := MoveCommand.new(player_pos, target_pos, true, target_pos, box_target)
	_apply_command(cmd)
	return true


## Sadece state'i günceller + sinyalleri yollar (undo_stack/move_count'a
## dokunmaz). try_move() ve redo() ikisi de bunu kullanır.
func _apply_move(cmd: MoveCommand) -> void:
	player_pos = cmd.player_to
	player_moved.emit(cmd.player_from, cmd.player_to)

	if cmd.pushed_box:
		var idx: int = box_positions.find(cmd.box_from)
		box_positions[idx] = cmd.box_to
		box_pushed.emit(cmd.box_from, cmd.box_to)
		_update_door_state()
		_check_deadlock(cmd.box_to)


func _apply_command(cmd: MoveCommand) -> void:
	_apply_move(cmd)
	_undo_stack.append(cmd)
	_redo_stack.clear()  # yeni hamle eskiden geri alınmış hamlelerin "ileri"sini geçersiz kılar
	move_count += 1
	move_count_changed.emit(move_count)

	_check_win()


func undo() -> void:
	if _undo_stack.is_empty():
		return

	var cmd: MoveCommand = _undo_stack.pop_back()
	player_pos = cmd.player_from
	player_moved.emit(cmd.player_to, cmd.player_from)

	if cmd.pushed_box:
		var idx: int = box_positions.find(cmd.box_to)
		box_positions[idx] = cmd.box_from
		box_pushed.emit(cmd.box_to, cmd.box_from)
		_update_door_state()

	_redo_stack.append(cmd)
	move_count = max(0, move_count - 1)
	move_count_changed.emit(move_count)


func can_undo() -> bool:
	return not _undo_stack.is_empty()


func redo() -> void:
	if _redo_stack.is_empty():
		return

	var cmd: MoveCommand = _redo_stack.pop_back()
	_apply_move(cmd)
	_undo_stack.append(cmd)
	move_count += 1
	move_count_changed.emit(move_count)

	_check_win()


func can_redo() -> bool:
	return not _redo_stack.is_empty()


## Basit "köşe" deadlock kontrolü: kutu hedefte değilse ve yatayda (sol
## VEYA sağ) ile dikeyde (üst VEYA alt) duvar varsa, kutu bir daha asla
## itilemez (o yönde itmek için oyuncunun duvarın olduğu hücrede durması
## gerekirdi). Kutuların birbirini kilitlemesi gibi daha karmaşık
## durumlar (freeze deadlock) burada tespit edilmiyor.
func _check_deadlock(pos: Vector2i) -> void:
	if level.is_target(pos):
		return

	var blocked_horizontal := level.is_wall(pos + Vector2i.LEFT) or level.is_wall(pos + Vector2i.RIGHT)
	var blocked_vertical := level.is_wall(pos + Vector2i.UP) or level.is_wall(pos + Vector2i.DOWN)

	if blocked_horizontal and blocked_vertical:
		box_deadlocked.emit(pos)


func _check_win() -> void:
	for target in level.targets:
		if target not in box_positions:
			return
	level_completed.emit()


func get_stars() -> int:
	if move_count <= level.moves_for_3_stars:
		return 3
	elif move_count <= level.moves_for_2_stars:
		return 2
	return 1
