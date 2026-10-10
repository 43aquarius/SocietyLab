## 世界状态容器：地形、资源、效果、聚落集合与全局状态。
## 只存数据 + 存取辅助，不做模拟逻辑（模拟由各 System 负责）。
## dirty 标记供渲染层判断需要重绘。
extends RefCounted

var seed_val: int = 0
var world_name: String = "未名世界"
var size: int = 48
var terrain: PackedInt32Array = PackedInt32Array()
var fertility: PackedFloat32Array = PackedFloat32Array()   # 0..1（神力可修改）
var resource: PackedInt32Array = PackedInt32Array()        # 资源点类型
var settlements: Array = []                               # Array of Settlement
var effects: Array = []                                   # 天气/赐福/启蒙效果
var year: int = 0
var god_mode: int = 0                                    # GameConfig.MODE_*
var faith: float = 0.0
var stats: Array = []                                     # 每年世界统计（观察者用）
var next_settlement_id: int = 1

# 渲染脏标记
var terrain_dirty: bool = true
var objects_dirty: bool = true

func _init(map_size: int = 48, master_seed: int = 0) -> void:
        size = map_size
        seed_val = master_seed
        terrain.resize(size * size)
        fertility.resize(size * size)
        resource.resize(size * size)
        for i in size * size:
                terrain[i] = GameConfig.T_GRASS
                fertility[i] = 0.3
                resource[i] = 0

func idx(x: int, y: int) -> int:
        return y * size + x

func in_bounds(x: int, y: int) -> bool:
        return x >= 0 and y >= 0 and x < size and y < size

func get_terrain(x: int, y: int) -> int:
        if not in_bounds(x, y):
                return -1
        return terrain[idx(x, y)]

func set_terrain(x: int, y: int, t: int) -> void:
        if not in_bounds(x, y):
                return
        terrain[idx(x, y)] = t
        var base := GameConfig.terrain_fert(t)
        fertility[idx(x, y)] = base
        terrain_dirty = true
        objects_dirty = true

func get_fertility(x: int, y: int) -> float:
        if not in_bounds(x, y):
                return 0.0
        return fertility[idx(x, y)]

func set_fertility(x: int, y: int, v: float) -> void:
        if in_bounds(x, y):
                fertility[idx(x, y)] = clamp(v, 0.0, 1.0)
                terrain_dirty = true

func get_resource(x: int, y: int) -> int:
        if not in_bounds(x, y):
                return 0
        return resource[idx(x, y)]

func set_resource(x: int, y: int, r: int) -> void:
        if in_bounds(x, y):
                resource[idx(x, y)] = r
                objects_dirty = true

func has_building_at(x: int, y: int) -> bool:
        for s in settlements:
                for b in s.buildings:
                        if int(b.get("tx", -1)) == x and int(b.get("ty", -1)) == y:
                                return true
        return false

func settlement_by_id(id: int):
        for s in settlements:
                if s.id == id:
                        return s
        return null

func settlement_at_tile(x: int, y: int):
        ## 谁的领地包含此格（含建筑）
        for s in settlements:
                for b in s.buildings:
                        if int(b.get("tx", -1)) == x and int(b.get("ty", -1)) == y:
                                return s
                if s.claims_tile(x, y):
                        return s
        return null

# ==================== 效果（神力天气/赐福，有期限） ====================
func add_effect(e: Dictionary) -> void:
        effects.append(e)
        objects_dirty = true

func expire_effects(until_year: int) -> void:
        var kept: Array = []
        for e in effects:
                if int(e.get("until", 0)) > until_year:
                        kept.append(e)
        if kept.size() != effects.size():
                objects_dirty = true
        effects = kept

func tile_moisture_mod(x: int, y: int) -> float:
        var mult := 1.0
        for e in effects:
                if e.get("kind", "") == "rain" or e.get("kind", "") == "drought":
                        var dx: int = abs(int(e.get("x", -99)) - x)
                        var dy: int = abs(int(e.get("y", -99)) - y)
                        if dx <= int(e.get("radius", 1)) and dy <= int(e.get("radius", 1)):
                                if e.get("kind", "") == "rain":
                                        mult *= (1.0 + float(e.get("power", 0.3)))
                                else:
                                        mult *= (1.0 - float(e.get("power", 0.35)))
        return mult

func settlement_prod_mod(sid: int, kind: String) -> float:
        var mult := 1.0
        for e in effects:
                if int(e.get("settlement", -1)) == sid and e.get("prod_kind", "") == kind:
                        mult *= (1.0 + float(e.get("power", 0.25)))
        return mult

func settlement_research_mod(sid: int) -> float:
        var mult := 1.0
        for e in effects:
                if int(e.get("settlement", -1)) == sid and e.get("kind", "") == "enlight":
                        mult += float(e.get("power", 1.0))
        return mult

# ==================== 序列化 ====================
func to_dict() -> Dictionary:
        var sdicts: Array = []
        for s in settlements:
                sdicts.append(s.to_dict())
        return {
                "seed": seed_val, "name": world_name, "size": size,
                "terrain": terrain.to_array(), "fertility": fertility.to_array(),
                "resource": resource.to_array(),
                "settlements": sdicts, "effects": effects.duplicate(true),
                "year": year, "god_mode": god_mode, "faith": faith,
                "stats": stats.duplicate(true),
                "next_id": next_settlement_id,
        }

static func _ints(a: Array, n: int) -> PackedInt32Array:
        var out := PackedInt32Array()
        out.resize(n)
        for i in n:
                var v = a[i] if i < a.size() else 0
                out[i] = int(v) if v != null else 0
        return out

static func _floats(a: Array, n: int) -> PackedFloat32Array:
        var out := PackedFloat32Array()
        out.resize(n)
        for i in n:
                var v = a[i] if i < a.size() else 0.0
                out[i] = float(v) if v != null else 0.0
        return out

static func from_dict(d: Dictionary) -> WorldState:
        var ws: WorldState = load("res://scripts/sim/WorldState.gd").new(int(d.get("size", 48)), int(d.get("seed", 0)))
        ws.world_name = str(d.get("name", ""))
        ws.year = int(d.get("year", 0))
        ws.god_mode = int(d.get("god_mode", 0))
        ws.faith = float(d.get("faith", 0.0))
        ws.next_settlement_id = int(d.get("next_id", 1))
        var n := ws.size * ws.size
        ws.terrain = _ints(d.get("terrain", []), n)
        ws.fertility = _floats(d.get("fertility", []), n)
        ws.resource = _ints(d.get("resource", []), n)
        var SettlementScript = load("res://scripts/sim/Settlement.gd")
        ws.settlements = []
        for sd in d.get("settlements", []):
                ws.settlements.append(SettlementScript.from_dict(sd))
        ws.effects = d.get("effects", [])
        var st: Array = d.get("stats", [])
        ws.stats = st
        ws.terrain_dirty = true
        ws.objects_dirty = true
        return ws
