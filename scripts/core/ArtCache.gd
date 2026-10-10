class_name ArtCache
## 资源缓存中心：加载 assets/manifest.json，按键取纹理（懒加载 + 缓存）。
## 所有图片/图标键统一走这里，避免 preload 路径硬编码。

static var _manifest: Dictionary = {}
static var _tex: Dictionary = {}
static var _ready: bool = false

static func _ensure() -> void:
	if _ready:
		return
	_ready = true
	var f := FileAccess.open("res://assets/manifest.json", FileAccess.READ)
	if f != null:
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Dictionary:
			_manifest = parsed.get("entries", {})
	else:
		push_error("ArtCache: 无法读取 assets/manifest.json —— 请先在编辑器中打开项目完成资源导入")

static func info(key: String) -> Dictionary:
	_ensure()
	if not _manifest.has(key) and _manifest.has("ui/" + key):
		key = "ui/" + key
	return _manifest.get(key, {})

static func tex(key: String) -> Texture2D:
	if _tex.has(key):
		return _tex[key]
	_ensure()
	if not _manifest.has(key) and _manifest.has("ui/" + key):
		key = "ui/" + key
	var entry: Dictionary = _manifest.get(key, {})
	if entry.is_empty():
		push_warning("ArtCache: 缺少素材 %s" % key)
		return null
	var path := "res://assets/" + str(entry.get("file", ""))
	if not ResourceLoader.exists(path):
		# 尚未导入（首次运行前）：尝试直接 load（编辑器上下文中有效）
		var t = load(path)
		if t != null:
			_tex[key] = t
			return t
		push_warning("ArtCache: 资源未导入 %s" % path)
		return null
	var t2: Texture2D = load(path)
	_tex[key] = t2
	return t2

static func foot(key: String) -> float:
	_ensure()
	if not _manifest.has(key) and _manifest.has("ui/" + key):
		key = "ui/" + key
	var entry: Dictionary = _manifest.get(key, {})
	return float(entry.get("foot", 6.0))

static func size_of(key: String) -> Vector2:
	_ensure()
	var entry: Dictionary = _manifest.get(key, {})
	return Vector2(float(entry.get("w", 64.0)), float(entry.get("h", 64.0)))

static func tile_variant(kind: String, x: int, y: int, n: int) -> String:
	## 确定性的图块变体选择（同一格永远同一变体）
	var h: int = (x * 73856093) ^ (y * 19349663)
	h = (h ^ (h >> 13)) & 0x7fffffff
	return "%s_%d" % [kind, h % max(1, n)]
