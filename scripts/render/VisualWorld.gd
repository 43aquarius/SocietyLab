## 世界渲染器：静态层（地形/道路/建筑）+ 动态层（居民/粒子/水面/覆盖提示）。
## 模拟与渲染彻底分离：本组件只读 WorldState，绝不修改模拟数据。
extends Node2D

var world
var origin := Vector2.ZERO
var static_layer: StaticLayer
var dynamic_layer: DynamicLayer
var _water_tiles: Array = []
var _time := 0.0

func _ready() -> void:
        static_layer = StaticLayer.new()
        static_layer.vw = self
        add_child(static_layer)
        dynamic_layer = DynamicLayer.new()
        dynamic_layer.vw = self
        add_child(dynamic_layer)

func build(p_world) -> void:
        world = p_world
        origin = IsoMath.map_origin(world.size)
        _water_tiles = []
        for x in world.size:
                for y in world.size:
                        if world.terrain[world.idx(x, y)] == GameConfig.T_WATER:
                                _water_tiles.append(Vector2i(x, y))
        static_layer.mark_dirty()
        dynamic_layer.build_villagers()
        position = Vector2.ZERO

func tile_center_w(x: int, y: int) -> Vector2:
        return IsoMath.tile_center(x, y) + origin

# ==================== 外部接口 ====================
func on_objects_changed() -> void:
        if static_layer:
                static_layer.mark_dirty()

func on_year_advanced() -> void:
        # 农田视觉轮转 & 居民数量调整
        if dynamic_layer:
                dynamic_layer.sync_villager_counts()
        if static_layer:
                static_layer.mark_dirty()

func set_brush(brush: Dictionary) -> void:
        ## {power, x, y, valid} / {} 清除
        dynamic_layer.brush = brush

func set_hover(x: int, y: int) -> void:
        dynamic_layer.hover_tile = Vector2i(x, y)

func set_selection(sel: Dictionary) -> void:
        dynamic_layer.selection = sel
        static_layer.mark_dirty()

func flash_power(power_id: String, x: int, y: int, sid: int) -> void:
        dynamic_layer.power_flash(power_id, x, y, sid)

func event_visual(entry: Dictionary) -> void:
        dynamic_layer.event_burst(entry)

# =========================================================
class StaticLayer extends Node2D:
        var vw: VisualWorld
        var _dirty := true

        func mark_dirty() -> void:
                _dirty = true
                queue_redraw()

        func _draw() -> void:
                if vw == null or vw.world == null:
                        return
                var w = vw.world
                # ---- 地形 ----
                for x in w.size:
                        for y in w.size:
                                var t: int = w.terrain[w.idx(x, y)]
                                var c := vw.tile_center_w(x, y)
                                var key := ""
                                match t:
                                        GameConfig.T_GRASS: key = ArtCache.tile_variant("tiles/grass", x, y, 3)
                                        GameConfig.T_FOREST: key = ArtCache.tile_variant("tiles/forest", x, y, 2)
                                        GameConfig.T_WATER: key = ArtCache.tile_variant("tiles/water", x, y, 3)
                                        GameConfig.T_ROCK: key = ArtCache.tile_variant("tiles/rock", x, y, 2)
                                        GameConfig.T_FERTILE: key = ArtCache.tile_variant("tiles/fertile", x, y, 2)
                                        GameConfig.T_SAND: key = ArtCache.tile_variant("tiles/sand", x, y, 2)
                                        GameConfig.T_MOUNTAIN: key = ArtCache.tile_variant("tiles/rock", x, y, 2)
                                var tex := ArtCache.tex(key)
                                if tex != null:
                                        draw_texture_rect(tex, Rect2(c - Vector2(32, 16), Vector2(64, 32)), false)
                # ---- 地表物件 ----
                var items: Array = []   # [depth, callable-ish data]
                for x in w.size:
                        for y in w.size:
                                var c := vw.tile_center_w(x, y)
                                var t: int = w.terrain[w.idx(x, y)]
                                var r: int = w.resource[w.idx(x, y)]
                                if t == GameConfig.T_MOUNTAIN:
                                        items.append([IsoMath.depth(x, y), "prop", ("props/peak_snow" if (x + y) % 5 == 0 else "props/peak"), c])
                                elif t == GameConfig.T_FOREST:
                                        var h := ((x * 31 + y * 17) % 100)
                                        var k1 := "props/pine_%d" % (h % 3)
                                        var k2 := "props/oak_%d" % ((h / 10) % 2)
                                        items.append([IsoMath.depth(x, y) - 0.05, "prop", k1, c + Vector2(-14, 4)])
                                        items.append([IsoMath.depth(x, y) + 0.05, "prop", k2, c + Vector2(15, 9)])
                                elif t == GameConfig.T_ROCK and (x * 7 + y * 13) % 4 == 0:
                                        items.append([IsoMath.depth(x, y), "prop", "props/rock_%d" % ((x + y) % 2), c + Vector2(10, 6)])
                                if r != 0:
                                        var rk := "props/ore_iron"
                                        if r == GameConfig.RES_GOLD:
                                                rk = "props/ore_gold"
                                        elif r == GameConfig.RES_STONE:
                                                rk = "props/rock_0"
                                        items.append([IsoMath.depth(x, y) + 0.2, "prop", rk, c + Vector2(-8, 2)])
                                if t == GameConfig.T_GRASS and (x * 5 + y * 11) % 23 == 0:
                                        items.append([IsoMath.depth(x, y), "prop", "props/bush", c + Vector2(12, 10)])
                                if t == GameConfig.T_FERTILE and (x * 3 + y * 7) % 11 == 0:
                                        items.append([IsoMath.depth(x, y), "prop", "props/reeds", c + Vector2(-18, 8)])
                # ---- 道路 ----
                for s in w.settlements:
                        if s.population < 120:
                                continue
                        var cc := vw.tile_center_w(s.cx, s.cy)
                        for b in s.buildings:
                                if not b.get("done", false):
                                        continue
                                var bc := vw.tile_center_w(int(b.get("tx", 0)), int(b.get("ty", 0)))
                                var col := Color(0.42, 0.32, 0.20, 0.35)
                                if s.knows("roads"):
                                        col = Color(0.5, 0.42, 0.30, 0.55)
                                draw_line(cc, bc, col, 7.0)
                                draw_line(cc + Vector2(0, 6), bc + Vector2(0, 6), Color(0.3, 0.22, 0.14, 0.22), 3.0)
                # ---- 建筑 ----
                for s in w.settlements:
                        for b in s.buildings:
                                var key: String = str(b.get("key", "camp_tent"))
                                var bx: int = int(b.get("tx", 0))
                                var by: int = int(b.get("ty", 0))
                                var bc := vw.tile_center_w(bx, by)
                                var tex_key := key
                                if not b.get("done", false):
                                        tex_key = "buildings/construction"
                                elif key == "farm":
                                        var stage: int = int(int(w.year - int(b.get("year_built", 0))) / 3 + bx) % 3
                                        tex_key = "buildings/farm_" + "abc"[stage]
                                items.append([IsoMath.depth(bx, by) + 0.3, "prop", "buildings/" + tex_key, bc])
                # ---- 按深度绘制 ----
                items.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
                for it in items:
                        var tex := ArtCache.tex(String(it[2]))
                        if tex == null:
                                continue
                        var foot := ArtCache.foot(String(it[2]))
                        var sz := Vector2(tex.get_width(), tex.get_height())
                        var gp: Vector2 = it[3]
                        draw_texture_rect(tex, Rect2(Vector2(gp.x - sz.x * 0.5, gp.y - (sz.y - foot)), sz), false)
                # ---- 选中聚落领地 ----
                var sel: Dictionary = vw.dynamic_layer.selection
                if sel.get("type", "") == "settlement":
                        var s = sel.get("ref", null)
                        if s != null:
                                var R: int = s.claim_radius
                                var d0 := vw.tile_center_w(s.cx - R, s.cy) + Vector2(-32, 0)
                                var d1 := vw.tile_center_w(s.cx, s.cy - R) + Vector2(0, -16)
                                var d2 := vw.tile_center_w(s.cx + R, s.cy) + Vector2(32, 0)
                                var d3 := vw.tile_center_w(s.cx, s.cy + R) + Vector2(0, 16)
                                draw_colored_polygon(PackedVector2Array([d0, d1, d2, d3]), Color(1.0, 0.85, 0.4, 0.08))
                                draw_polyline(PackedVector2Array([d0, d1, d2, d3, d0]), Color(1.0, 0.85, 0.4, 0.9), 2.5)

        func _process(_delta: float) -> void:
                if _dirty:
                        _dirty = false
                if vw and vw.world and vw.world.objects_dirty:
                        vw.world.objects_dirty = false
                        mark_dirty()

# =========================================================
class DynamicLayer extends Node2D:
        var vw: VisualWorld
        var brush: Dictionary = {}
        var hover_tile := Vector2i(-99, -99)
        var selection: Dictionary = {}
        var villagers: Array = []      # per settlement: {sid, list[]}
        var particles: Array = []
        var _smoke_t := 0.0
        var _fx_until: Dictionary = {}   # sid -> {kind, until}

        func build_villagers() -> void:
                villagers = []
                if vw == null or vw.world == null:
                        return
                for s in vw.world.settlements:
                        villagers.append({"sid": s.id, "list": _spawn_for(s)})

        func sync_villager_counts() -> void:
                if vw == null or vw.world == null:
                        return
                var by_id := {}
                for s in vw.world.settlements:
                        by_id[s.id] = s
                var out: Array = []
                for v in villagers:
                        var s = by_id.get(int(v.get("sid", -1)))
                        if s == null:
                                continue
                        var want := _wanted_count(s)
                        while v.get("list", []).size() > want:
                                v["list"].pop_back()
                        while v.get("list", []).size() < want:
                                v["list"].append(_new_actor(s))
                        out.append(v)
                villagers = out

        func _wanted_count(s) -> int:
                var n := int(ceil(float(s.population) / 140.0))
                n = clamp(n, 2, 12)
                if s.famine_active:
                        n = max(1, n / 2)
                return n

        func _spawn_for(s) -> Array:
                var out: Array = []
                for i in _wanted_count(s):
                        out.append(_new_actor(s))
                return out

        func _new_actor(s) -> Dictionary:
                var grp := "laborer"
                var roll := (randi() % 100)
                if roll > 93:
                        grp = "admin"
                elif roll > 85:
                        grp = "merchant"
                elif roll > 76:
                        grp = "elite"
                var a := {
                        "grp": grp, "x": float(s.cx) + randf_range(-1.5, 1.5), "y": float(s.cy) + randf_range(-1.5, 1.5),
                        "tx": float(s.cx), "ty": float(s.cy), "state": "walk", "timer": 0.0,
                        "phase": randf() * 3.0, "speed": randf_range(0.42, 0.62), "carry": false,
                }
                _pick_target(a, s)
                return a

        func _pick_target(a: Dictionary, s) -> void:
                var cands: Array = []
                for b in s.buildings:
                        if b.get("done", false):
                                var k: String = str(b.get("key", ""))
                                var w := 1.0
                                if k.begins_with("farm"):
                                        w = 3.0 if a.get("grp", "") == "laborer" else 0.6
                                elif k == "market":
                                        w = 3.0 if a.get("grp", "") == "merchant" else 1.2
                                elif k == "manor" or k == "castle" or k == "temple":
                                        w = 2.2 if a.get("grp", "") == "elite" else 0.5
                                elif k == "admin_hall":
                                        w = 2.5 if a.get("grp", "") == "admin" else 0.8
                                elif k == "workshop":
                                        w = 1.8
                                cands.append([w, b])
                if cands.is_empty():
                        a["tx"] = float(s.cx) + randf_range(-2.0, 2.0)
                        a["ty"] = float(s.cy) + randf_range(-2.0, 2.0)
                else:
                        var tot := 0.0
                        for c in cands:
                                tot += float(c[0])
                        var r := randf() * tot
                        var acc := 0.0
                        var chosen = cands[0][1]
                        for c in cands:
                                acc += float(c[0])
                                if r <= acc:
                                        chosen = c[1]
                                        break
                        a["tx"] = float(int(chosen.get("tx", s.cx))) + randf_range(-0.7, 0.7)
                        a["ty"] = float(int(chosen.get("ty", s.cy))) + randf_range(-0.7, 0.7)
                a["state"] = "walk"

        func _process(delta: float) -> void:
                vw._time += delta
                var w = vw.world
                if w == null:
                        return
                # 更新居民
                var by_id := {}
                for s in w.settlements:
                        by_id[s.id] = s
                for v in villagers:
                        var s = by_id.get(int(v.get("sid", -1)))
                        if s == null:
                                continue
                        var slow := 0.65 if s.famine_active else 1.0
                        for a in v.get("list", []):
                                if a.get("state", "") == "walk":
                                        var dx: float = float(a["tx"]) - float(a["x"])
                                        var dy: float = float(a["ty"]) - float(a["y"])
                                        var d := Vector2(dx, dy).length()
                                        if d < 0.1:
                                                a["state"] = "idle"
                                                a["timer"] = randf_range(1.2, 3.2)
                                        else:
                                                var sp: float = float(a["speed"]) * slow * delta
                                                a["x"] += dx / d * sp
                                                a["y"] += dy / d * sp
                                                a["phase"] += delta
                                else:
                                        a["timer"] = float(a["timer"]) - delta
                                        if float(a["timer"]) <= 0.0:
                                                _pick_target(a, s)
                # 粒子生成：雨 / 祝福 / 烟囱 / 光柱
                _spawn_weather_particles(delta)
                _smoke_t += delta
                if _smoke_t > 0.55:
                        _smoke_t = 0.0
                        for s in w.settlements:
                                for b in s.buildings:
                                        if not b.get("done", false):
                                                continue
                                        var k: String = str(b.get("key", ""))
                                        if k == "factory":
                                                for off in [Vector2(-30, -78), Vector2(-12, -70)]:
                                                        particles.append(_mk_smoke(vw.tile_center_w(int(b.get("tx", 0)), int(b.get("ty", 0))) + off))
                                        elif k == "workshop" and randf() < 0.5:
                                                particles.append(_mk_smoke(vw.tile_center_w(int(b.get("tx", 0)), int(b.get("ty", 0))) + Vector2(14, -46), 0.6))
                # 粒子更新
                for p in particles:
                        p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
                        p["life"] = float(p["life"]) - delta
                        p["age"] = float(p["age"]) + delta
                var alive: Array = []
                for p in particles:
                        if float(p["life"]) > 0.0:
                                alive.append(p)
                particles = alive
                queue_redraw()

        func _mk_smoke(at: Vector2, scale: float = 1.0) -> Dictionary:
                return {"type": "smoke", "pos": at, "vel": Vector2(randf_range(4, 10), randf_range(-14, -8)),
                        "life": randf_range(2.0, 3.4), "age": 0.0, "size": randf_range(4, 8) * scale}

        func _spawn_weather_particles(delta: float) -> void:
                var w = vw.world
                # 雨
                for e in w.effects:
                        if e.get("kind", "") != "rain":
                                continue
                        var cx: int = int(e.get("x", 0))
                        var cy: int = int(e.get("y", 0))
                        var base := vw.tile_center_w(cx, cy)
                        for i in 10:
                                var px := base.x + randf_range(-110, 110)
                                var py := base.y + randf_range(-70, 40) - 80
                                particles.append({"type": "rain", "pos": Vector2(px, py), "vel": Vector2(26, 300),
                                        "life": 0.9, "age": 0.0, "size": 1.0})
                # 干旱热浪
                for e in w.effects:
                        if e.get("kind", "") != "drought":
                                continue
                        if randf() < 0.3:
                                var base2 := vw.tile_center_w(int(e.get("x", 0)), int(e.get("y", 0)))
                                particles.append({"type": "heat", "pos": base2 + Vector2(randf_range(-90, 90), randf_range(-30, 30)),
                                        "vel": Vector2(6, -26), "life": 1.6, "age": 0.0, "size": randf_range(6, 14)})
                # 祝福金光
                for e in w.effects:
                        if e.get("kind", "") != "bless":
                                continue
                        if randf() < 0.5:
                                var s = w.settlement_by_id(int(e.get("settlement", -1)))
                                if s != null:
                                        var t: Vector2i = s.claimed_tiles()[randi() % s.claimed_tiles().size()]
                                        particles.append({"type": "spark", "pos": vw.tile_center_w(t.x, t.y) + Vector2(randf_range(-20, 20), randf_range(-24, 4)),
                                                "vel": Vector2(0, -22), "life": 1.1, "age": 0.0, "size": randf_range(3, 6)})

        func power_flash(power_id: String, x: int, y: int, _sid: int) -> void:
                var col := Color(1.0, 0.9, 0.5, 0.9)
                match power_id:
                        "forest": col = Color(0.5, 0.85, 0.45, 0.9)
                        "water": col = Color(0.45, 0.75, 1.0, 0.9)
                        "ore": col = Color(0.8, 0.85, 1.0, 0.9)
                        "rain": col = Color(0.5, 0.75, 1.0, 0.8)
                        "drought": col = Color(1.0, 0.6, 0.25, 0.8)
                        "bless": col = Color(1.0, 0.85, 0.3, 0.95)
                        "enlight": col = Color(1.0, 0.95, 0.6, 0.95)
                        "idea": col = Color(1.0, 0.5, 0.35, 0.9)
                var at := vw.tile_center_w(x, y)
                for i in 16:
                        var a := TAU * float(i) / 16.0
                        particles.append({"type": "flash", "pos": at, "vel": Vector2(cos(a), sin(a) * 0.6) * randf_range(60, 150),
                                "life": 0.55, "age": 0.0, "size": randf_range(3, 6), "col": col})
                particles.append({"type": "ring", "pos": at, "vel": Vector2.ZERO, "life": 0.6, "age": 0.0, "size": 10.0, "col": col})

        func event_burst(entry: Dictionary) -> void:
                var w = vw.world
                if w == null:
                        return
                var sid := int(entry.get("sid", -1))
                var s = w.settlement_by_id(sid)
                if s == null:
                        return
                var at := vw.tile_center_w(s.cx, s.cy)
                var cat: String = str(entry.get("cat", ""))
                if cat == "golden" or cat == "city" or cat == "reform":
                        for i in 22:
                                particles.append({"type": "star", "pos": at + Vector2(randf_range(-60, 60), randf_range(-10, 30)),
                                        "vel": Vector2(randf_range(-12, 12), randf_range(-70, -30)), "life": randf_range(1.2, 2.2),
                                        "age": 0.0, "size": randf_range(3, 7)})
                elif cat == "famine" or cat == "war" or cat == "disease":
                        for i in 14:
                                particles.append({"type": "gloom", "pos": at + Vector2(randf_range(-70, 70), randf_range(-20, 20)),
                                        "vel": Vector2(randf_range(-6, 6), randf_range(10, 24)), "life": randf_range(1.5, 2.5),
                                        "age": 0.0, "size": randf_range(5, 10)})

        func _draw() -> void:
                if vw == null or vw.world == null:
                        return
                var w = vw.world
                var t := vw._time
                # ---- 水面波光 ----
                for wt in vw._water_tiles:
                        var c := vw.tile_center_w(wt.x, wt.y)
                        var ph := float((wt.x * 13 + wt.y * 7) % 10) * 0.7
                        var a := 0.25 + 0.25 * sin(t * 1.6 + ph)
                        draw_line(c + Vector2(-16, -2 + 3 * sin(t + ph)), c + Vector2(2, -8 + 3 * sin(t + ph)), Color(0.75, 0.92, 1.0, a), 2.0)
                        draw_line(c + Vector2(6, 4), c + Vector2(20, -2 + 2 * cos(t * 1.3 + ph)), Color(0.85, 0.97, 1.0, a * 0.8), 1.5)
                # ---- 干旱区域覆盖 ----
                for e in w.effects:
                        if e.get("kind", "") == "drought":
                                for dx in range(-1, 2):
                                        for dy in range(-1, 2):
                                                var c := vw.tile_center_w(int(e.get("x", 0)) + dx, int(e.get("y", 0)) + dy)
                                                draw_rect(Rect2(c - Vector2(32, 16), Vector2(64, 32)), Color(1.0, 0.62, 0.2, 0.13))
                # ---- 居民 ----
                for v in villagers:
                        for a in v.get("list", []):
                                var s = w.settlement_by_id(int(v.get("sid", -1)))
                                if s == null:
                                        continue
                                var grp: String = str(a.get("grp", "laborer"))
                                var frame := "idle"
                                if a.get("state", "") == "walk":
                                        frame = "walk_a" if fmod(float(a.get("phase", 0.0)), 0.52) < 0.26 else "walk_b"
                                var key := "villagers/%s_%s" % [grp, frame]
                                var tex := ArtCache.tex(key)
                                if tex == null:
                                        continue
                                var foot := ArtCache.foot(key)
                                var sz := Vector2(tex.get_width(), tex.get_height())
                                var f_x := float(a["x"])
                                var f_y := float(a["y"])
                                var gp := vw.tile_center_w(int(floor(f_x)), int(floor(f_y)))
                                var fxo := f_x - floor(f_x)
                                var fyo := f_y - floor(f_y)
                                gp += Vector2((fxo - fyo) * 32.0, (fxo + fyo) * 16.0)
                                # 阴影
                                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                                draw_circle(gp + Vector2(0, 2), 6.0, Color(0.1, 0.1, 0.15, 0.25))
                                var flip := float(a.get("tx", 0.0)) < float(a["x"])
                                var src := Rect2(Vector2.ZERO, sz)
                                var dst := Rect2(Vector2(gp.x - sz.x * 0.5, gp.y - (sz.y - foot) + 2), sz)
                                if flip:
                                        draw_texture_rect(tex, Rect2(dst.position + Vector2(sz.x, 0), Vector2(-sz.x, sz.y)), false)
                                else:
                                        draw_texture_rect(tex, dst, false)
                # ---- 粒子 ----
                for p in particles:
                        var life_t: float = clamp(float(p["life"]) / 1.6, 0.0, 1.0)
                        match String(p["type"]):
                                "rain":
                                        var rp: Vector2 = p["pos"]
                                        draw_line(rp, rp + Vector2(3, 14), Color(0.55, 0.78, 1.0, 0.55), 2.0)
                                "smoke":
                                        var sp: Vector2 = p["pos"]
                                        var ss: float = float(p["size"]) * (1.0 + float(p["age"]) * 0.7)
                                        draw_circle(sp, ss, Color(0.75, 0.78, 0.82, 0.35 * life_t))
                                "spark":
                                        var sgp: Vector2 = p["pos"]
                                        draw_colored_polygon([sgp + Vector2(0, -float(p["size"])), sgp + Vector2(float(p["size"]) * 0.5, 0), sgp + Vector2(0, float(p["size"])), sgp + Vector2(-float(p["size"]) * 0.5, 0)],
                                                Color(1.0, 0.9, 0.4, 0.85 * life_t))
                                "flash":
                                        var fp: Vector2 = p["pos"]
                                        draw_circle(fp, float(p["size"]), (p.get("col", Color.WHITE) as Color))
                                "ring":
                                        var rsize: float = float(p["size"]) + float(p["age"]) * 220.0
                                        draw_arc(p["pos"] as Vector2, rsize, 0.0, TAU, 40, Color((p.get("col") as Color).r, (p.get("col") as Color).g, (p.get("col") as Color).b, 0.6 * life_t), 3.0)
                                "star":
                                        var stp: Vector2 = p["pos"]
                                        draw_colored_polygon([stp + Vector2(0, -float(p["size"])), stp + Vector2(float(p["size"]) * 0.4, float(p["size"]) * 0.3), stp + Vector2(0, float(p["size"])), stp + Vector2(-float(p["size"]) * 0.4, float(p["size"]) * 0.3)],
                                                Color(1.0, 0.88, 0.45, 0.9 * life_t))
                                "gloom":
                                        var glp: Vector2 = p["pos"]
                                        draw_circle(glp, float(p["size"]), Color(0.35, 0.3, 0.3, 0.3 * life_t))
                                "heat":
                                        var hp: Vector2 = p["pos"]
                                        draw_arc(hp, float(p["size"]) * 2.0, PI, TAU, 12, Color(1.0, 0.7, 0.3, 0.25 * life_t), 2.0)
                # ---- 悬停格 ----
                if hover_tile.x >= 0 and vw.world.in_bounds(hover_tile.x, hover_tile.y):
                        var hc := vw.tile_center_w(hover_tile.x, hover_tile.y)
                        draw_rect(Rect2(hc - Vector2(31, 15), Vector2(62, 30)), Color(1, 1, 1, 0.16), false, 2.0)
                # ---- 笔刷预览 ----
                if not brush.is_empty():
                        var valid: bool = brush.get("valid", true)
                        var col := Color(0.4, 1.0, 0.5, 0.22)
                        var col_edge := Color(0.4, 1.0, 0.5, 0.9)
                        if not valid:
                                col = Color(1.0, 0.35, 0.3, 0.22)
                                col_edge = Color(1.0, 0.35, 0.3, 0.9)
                        var pts: Array = brush.get("tiles", [])
                        var pulse := 0.7 + 0.3 * sin(t * 6.0)
                        for pt in pts:
                                var pc := vw.tile_center_w(int(pt.x), int(pt.y))
                                draw_rect(Rect2(pc - Vector2(31, 15), Vector2(62, 30)), Color(col.r, col.g, col.b, col.a * pulse))
                                draw_rect(Rect2(pc - Vector2(31, 15), Vector2(62, 30)), Color(col_edge.r, col_edge.g, col_edge.b, 0.8 * pulse), false, 2.0)
                # ---- 选中建筑高亮 ----
                if selection.get("type", "") == "building":
                        var b = selection.get("ref", null)
                        if b != null:
                                var bc := vw.tile_center_w(int(b.get("tx", 0)), int(b.get("ty", 0)))
                                var pulse2 := 0.55 + 0.45 * sin(t * 5.0)
                                draw_rect(Rect2(bc - Vector2(31, 15), Vector2(62, 30)), Color(1.0, 0.9, 0.5, 0.25 * pulse2), false, 3.0)
