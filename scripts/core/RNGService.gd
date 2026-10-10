class_name RNGService
## 集中式随机数管理：所有系统通过命名通道取随机数，
## 每个通道独立播种并可序列化 —— 保证同一种子可复现、可调试。
extends RefCounted

var _channels: Dictionary = {}   # String -> RandomNumberGenerator

func _init(master_seed: int = 0) -> void:
	ensure("gen", master_seed)
	ensure("sim", master_seed + 1013)
	ensure("viz", master_seed + 7331)
	ensure("event", master_seed + 4099)

func ensure(channel: String, seed_val: int) -> void:
	if not _channels.has(channel):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_val
		_channels[channel] = rng

func get_rng(channel: String) -> RandomNumberGenerator:
	if not _channels.has(channel):
		ensure(channel, hash(channel))
	return _channels[channel]

func randf(channel: String) -> float:
	return get_rng(channel).randf()

func randf_range(channel: String, lo: float, hi: float) -> float:
	return get_rng(channel).randf_range(lo, hi)

func randi_range(channel: String, lo: int, hi: int) -> int:
	return get_rng(channel).randi_range(lo, hi)

func chance(channel: String, p: float) -> bool:
	return randf(channel) < p

func pick(channel: String, arr: Array):
	if arr.is_empty():
		return null
	return arr[randi_range(channel, 0, arr.size() - 1)]

func weighted_pick(channel: String, items: Array, weights: Array):
	var total := 0.0
	for w in weights:
		total += max(0.0, float(w))
	if total <= 0.0:
		return items[0] if items.size() > 0 else null
	var r := randf(channel) * total
	var acc := 0.0
	for i in items.size():
		acc += max(0.0, float(weights[i]))
		if r <= acc:
			return items[i]
	return items[items.size() - 1]

# ---------- 序列化（存档/分支复现） ----------
func to_dict() -> Dictionary:
	var out := {}
	for ch in _channels:
		var rng: RandomNumberGenerator = _channels[ch]
		out[ch] = {"seed": rng.seed, "state": rng.state}
	return out

func from_dict(d: Dictionary) -> void:
	_channels.clear()
	for ch in d:
		var rng := RandomNumberGenerator.new()
		var info: Dictionary = d[ch]
		rng.seed = int(info.get("seed", 0))
		rng.state = int(info.get("state", 0))
		_channels[ch] = rng
