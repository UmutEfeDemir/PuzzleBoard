extends Control
class_name PathLine

## Level Seç ekranındaki zikzak yolu çizen basit yardımcı Control.
## Line2D yerine _draw() kullanıyoruz çünkü Line2D bir Node2D'dir ve
## ScrollContainer'ın kaydırma dönüşümünü takip etmez — Control tabanlı
## _draw() ise diğer UI elemanlarıyla aynı koordinat sisteminde kalır.

var points: PackedVector2Array = PackedVector2Array()
var dot_color: Color = Color("ffd166", 0.5)
var dot_radius: float = 3.0
var dot_gap: float = 16.0


## Referanstaki kesikli SVG yol çizgisini (stroke-dasharray) taklit etmek
## için düz çizgi yerine düzenli aralıklarla küçük noktalar çiziyoruz.
func _draw() -> void:
	if points.size() < 2:
		return
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var seg := b - a
		var length := seg.length()
		if length <= 0.0:
			continue
		var dir := seg / length
		var d := 0.0
		while d < length:
			draw_circle(a + dir * d, dot_radius, dot_color)
			d += dot_gap
