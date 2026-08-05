extends Node

## Autoload (bkz. project.godot [autoload]). Basit ses efekti oynatıcı.
##
## Şu an res://audio/sfx/ altında hiçbir ses dosyası YOK. play() çağrıldığında
## dosya bulunamazsa sessizce hiçbir şey yapmaz (hata da vermez) — yani kod
## şimdiden çağrılabilir, ses dosyaları eklenince otomatik çalmaya başlar,
## başka bir kod değişikliği gerekmez. Kendi dosyanı SFX_FILES'taki adla
## res://audio/sfx/ klasörüne koymanız yeterli.
##
## Ayarlar ekranındaki "Ses Efektleri" toggle'ı (SaveManager "sound_effects"
## anahtarı) kapalıysa play() hiçbir şey çalmaz.
##
## Desteklenen olaylar:
##   "move"     - oyuncu boş kareye hareket eder
##   "push"     - kutu itilir
##   "invalid"  - geçersiz hamle (duvar / itilemeyen kutu)
##   "undo"     - geri al
##   "redo"     - ileri al
##   "win"      - level tamamlanır
##   "deadlock" - kutu sıkışma uyarısı

const SFX_DIR := "res://audio/sfx/"
const SFX_FILES := {
	"move": "move.ogg",
	"push": "push.ogg",
	"invalid": "invalid.ogg",
	"undo": "undo.ogg",
	"redo": "redo.ogg",
	"win": "win.ogg",
	"deadlock": "deadlock.ogg",
}

const POOL_SIZE := 4
const SETTING_KEY := "sound_effects"

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _stream_cache: Dictionary = {}  # sfx_name -> AudioStream (bulunamadıysa null)


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sfx_name: String) -> void:
	if not SaveManager.get_setting(SETTING_KEY, true):
		return

	var stream := _get_stream(sfx_name)
	if stream == null:
		return

	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.play()


func _get_stream(sfx_name: String) -> AudioStream:
	if _stream_cache.has(sfx_name):
		return _stream_cache[sfx_name]

	var stream: AudioStream = null
	var file_name: String = SFX_FILES.get(sfx_name, "")
	if file_name != "":
		var path := SFX_DIR + file_name
		if ResourceLoader.exists(path):
			stream = load(path)

	_stream_cache[sfx_name] = stream
	return stream
