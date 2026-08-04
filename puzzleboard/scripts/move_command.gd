extends RefCounted
class_name MoveCommand

## Command Pattern: her hamle bir obje.
## Bu sayede undo/redo neredeyse bedavaya geliyor.
## GridManager bu komutu execute() ile uygular, undo() ile geri alır.

var player_from: Vector2i
var player_to: Vector2i

# Eğer bu hamlede bir kutu da itildiyse:
var pushed_box: bool = false
var box_from: Vector2i
var box_to: Vector2i


func _init(p_from: Vector2i, p_to: Vector2i, p_pushed_box: bool = false,
		p_box_from: Vector2i = Vector2i.ZERO, p_box_to: Vector2i = Vector2i.ZERO) -> void:
	player_from = p_from
	player_to = p_to
	pushed_box = p_pushed_box
	box_from = p_box_from
	box_to = p_box_to


func describe() -> String:
	if pushed_box:
		return "Player %s->%s, pushed box %s->%s" % [player_from, player_to, box_from, box_to]
	return "Player %s->%s" % [player_from, player_to]
