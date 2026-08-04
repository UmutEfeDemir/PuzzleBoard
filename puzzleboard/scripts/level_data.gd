extends Resource
class_name LevelData

## Bir level'ın tüm verisini tutan Resource.
## .tres dosyası olarak kaydedilir, sahne DEĞİLDİR.
## Bu sayede yeni level eklemek = yeni .tres dosyası oluşturmak.

@export var level_name: String = "Level 1"
@export var grid_width: int = 8
@export var grid_height: int = 8

# Duvarlar: Vector2i array olarak
@export var walls: Array[Vector2i] = []

# Kutular: başlangıç pozisyonları
@export var boxes: Array[Vector2i] = []

# Hedefler: kutuların üzerine gelmesi gereken noktalar
@export var targets: Array[Vector2i] = []

# Oyuncu başlangıç pozisyonu
@export var player_start: Vector2i = Vector2i.ZERO

# Opsiyonel: yıldız sistemi için hamle limitleri
@export var moves_for_3_stars: int = 15
@export var moves_for_2_stars: int = 25


func is_wall(pos: Vector2i) -> bool:
	return pos in walls


func is_target(pos: Vector2i) -> bool:
	return pos in targets


func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height
