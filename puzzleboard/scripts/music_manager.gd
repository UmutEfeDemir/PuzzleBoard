extends Node

## Autoload (bkz. project.godot [autoload]). Sahneler arası arka plan
## müziğinin kesintisiz çalması için tek gerçek autoload bu — GameState ve
## SaveManager static class oldukları için autoload gerektirmiyordu, ama
## müzik çalmaya devam eden bir Node (AudioStreamPlayer) sahne geçişlerinde
## static class ile yaşatılamaz.
##
## Şu an res://audio/music.ogg diye bir dosya YOK — müzik açık olsa bile
## çalacak bir şey bulamadığı için sessiz kalır. Kendi müzik dosyanı
## res://audio/music.ogg olarak eklediğinde (proje köküne "audio" klasörü
## oluşturup içine koy) otomatik çalmaya başlar, kod değişikliği gerekmez.
## Farklı bir formatla (.mp3/.wav) veya farklı bir isimle eklersen aşağıdaki
## MUSIC_PATH sabitini güncelle.

const MUSIC_PATH := "res://audio/music.ogg"

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

	if ResourceLoader.exists(MUSIC_PATH):
		var stream := load(MUSIC_PATH)
		if "loop" in stream:
			stream.loop = true
		_player.stream = stream

	_apply_setting()


func set_enabled(enabled: bool) -> void:
	SaveManager.set_setting("music", enabled)
	_apply_setting()


func _apply_setting() -> void:
	var enabled: bool = SaveManager.get_setting("music", false)
	if enabled and _player.stream != null:
		if not _player.playing:
			_player.play()
	else:
		_player.stop()
