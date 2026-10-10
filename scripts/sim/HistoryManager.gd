## 历史管理：编年史条目 + 定期世界快照（供历史分支）。
## 条目字段：year / place / cat / title / desc / causes[] / effects[] /
##           player_involved / importance(1~3)
extends RefCounted

const MAX_SNAPSHOTS := 24

var entries: Array = []
var snapshots: Array = []   # {year, world(dict), rng(dict)}

func log(entry: Dictionary) -> void:
	entries.append(entry)

func entries_up_to(year: int) -> Array:
	var out: Array = []
	for e in entries:
		if int(e.get("year", 0)) <= year:
			out.append(e)
	return out

func add_snapshot(world, rng) -> void:
	snapshots.append({
		"year": world.year,
		"world": world.to_dict(),
		"rng": rng.to_dict(),
	})
	if snapshots.size() > MAX_SNAPSHOTS:
		snapshots.pop_front()

func snapshot_years() -> Array:
	var out: Array = []
	for s in snapshots:
		out.append(int(s.get("year", 0)))
	return out

func get_snapshot(year: int) -> Dictionary:
	for s in snapshots:
		if int(s.get("year", -1)) == year:
			return s
	return {}

## 导出条目（存档用）
func to_dict() -> Dictionary:
	return {"entries": entries.duplicate(true), "snapshots": snapshots.duplicate(true)}

func from_dict(d: Dictionary) -> void:
	entries = d.get("entries", [])
	snapshots = d.get("snapshots", [])
