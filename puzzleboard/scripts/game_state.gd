extends RefCounted
class_name GameState

## Sahneler arası basit veri taşıyıcı (autoload gerektirmez).
## LevelSelect ekranı burayı set eder, Main sahnesi burayı okur.

static var current_level_path: String = ""
static var level_list: Array[String] = []
static var current_level_index: int = -1
