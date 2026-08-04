extends Node
class_name SwipeInput

## Mobilde swipe algılama. GridManager sahnesine child olarak ekle,
## "swiped" sinyalini dinle.
## Buton kontrolü için ayrıca GridManager.try_move() direkt çağrılabilir.

signal swiped(dir: Vector2i)

@export var min_swipe_distance: float = 50.0

var _touch_start: Vector2 = Vector2.ZERO
var _touch_active: bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_touch_active = true
		else:
			if _touch_active:
				_evaluate_swipe(event.position)
			_touch_active = false

	# Editörde mouse ile test için
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_touch_start = event.position
				_touch_active = true
			else:
				if _touch_active:
					_evaluate_swipe(event.position)
				_touch_active = false


func _evaluate_swipe(end_pos: Vector2) -> void:
	var delta: Vector2 = end_pos - _touch_start
	if delta.length() < min_swipe_distance:
		return

	var dir: Vector2i
	if abs(delta.x) > abs(delta.y):
		dir = Vector2i.RIGHT if delta.x > 0 else Vector2i.LEFT
	else:
		dir = Vector2i.DOWN if delta.y > 0 else Vector2i.UP

	swiped.emit(dir)
