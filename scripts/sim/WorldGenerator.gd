## 程序化世界生成：值噪声地形 + 河流 + 资源点 + 初始聚落选址。
## 地形完全由种子决定（可复现）；聚落初值使用 RNGService "gen" 通道。
extends RefCounted

const RELIEF_AMP := {0: 0.55, 1: 1.0, 2: 1.6}
const RICHNESS_RATE := {0: 0.05, 1: 0.09, 2: 0.15}

static func _ihash(x: int, y: int, s: int) -> float:
	var h: int = (x * 374761393 + y * 668265263) ^ (s * 1442695041)
	h = (h ^ (h >> 13)) & 0xFFFFFFFF
	h = (h * 1274126177) & 0xFFFFFFFF
	h = (h ^ (h >> 16)) & 0xFFFFFFFF
	return float(h) / 4294967295.0

static func _smooth(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

static func _value_noise(x: float, y: float, s: int) -> float:
	var xi := int(floor(x))
	var yi := int(floor(y))
	var fx := _smooth(x - float(xi))
	var fy := _smooth(y - float(yi))
	var a := _ihash(xi, yi, s)
	var b := _ihash(xi + 1, yi, s)
	var c := _ihash(xi, yi + 1, s)
	var d := _ihash(xi + 1, yi + 1, s)
	return lerp(lerp(a, b, fx), lerp(c, d, fx), fy)

static func _fbm(x: float, y: float, s: int, octaves: int = 3) -> float:
	var sum := 0.0
	var amp := 0.5
	var norm := 0.0
	var fx := x
	var fy := y
	for i in octaves:
		sum += _value_noise(fx, fy, s + i * 977) * amp
		norm += amp
		amp *= 0.5
		fx *= 2.03
		fy *= 2.07
	return sum / max(norm, 0.0001)

## 主入口：opts = {seed, size, relief(0/1/2), richness(0/1/2), settlements(int)}
static func generate(opts: Dictionary, rng: RNGService) -> WorldState:
	var size := int(opts.get("size", 48))
	var seed_v := int(opts.get("seed", 0))
	var relief := int(opts.get("relief", 1))
	var richness := int(opts.get("richness", 1))
	var n_settle := int(opts.get("settlements", 2))
	var ws: WorldState = load("res://scripts/sim/WorldState.gd").new(size, seed)
	ws.world_name = Names.world_name(rng)
	var amp: float = RELIEF_AMP.get(relief, 1.0)
	var rate: float = RICHNESS_RATE.get(richness, 0.09)
	var e_scale := 6.0 / float(size) * 14.0   # 地形特征频率
	var m_scale := 4.0 / float(size) * 14.0

	# 1) 基础海拔/湿度场
	var elev := {}
	var moist := {}
	for x in size:
		for y in size:
			var e := _fbm(float(x) / float(size) * e_scale, float(y) / float(size) * e_scale, seed_v, 3)
			var m := _fbm(float(x) / float(size) * m_scale + 31.7, float(y) / float(size) * m_scale + 17.3, seed_v + 555, 3)
			e = clamp(0.5 + (e - 0.5) * amp * 2.0, 0.0, 1.0)
			elev[Vector2i(x, y)] = e
			moist[Vector2i(x, y)] = m

	# 2) 地形归类
	for x in size:
		for y in size:
			var key := Vector2i(x, y)
			var e: float = elev[key]
			var m: float = moist[key]
			var t := GameConfig.T_GRASS
			if e > 0.74:
				t = GameConfig.T_MOUNTAIN
			elif e > 0.63:
				t = GameConfig.T_ROCK
			elif e < 0.30:
				t = GameConfig.T_WATER
			else:
				if m > 0.62:
					t = GameConfig.T_FOREST
			ws.terrain[ws.idx(x, y)] = t
			ws.fertility[ws.idx(x, y)] = GameConfig.terrain_fert(t)

	# 3) 河流：从高处往边缘蜿蜒
	var river_count := 2 + (1 if seed_v % 3 == 0 else 0)
	for r in river_count:
		var start := _pick_high_tile(elev, size, seed_v + r * 131)
		if start == null:
			continue
		var cur: Vector2i = start
		var guard := 0
		while guard < size * 3:
			guard += 1
			var i := ws.idx(cur.x, cur.y)
			if ws.terrain[i] == GameConfig.T_GRASS or ws.terrain[i] == GameConfig.T_FOREST:
				ws.terrain[i] = GameConfig.T_WATER
				ws.fertility[i] = 0.0
			# 朝最近的边界走，同时向低处偏
			var best: Vector2i = cur
			var best_score := -1e9
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
					Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				var nx: int = cur.x + d.x
				var ny: int = cur.y + d.y
				if nx < 0 or ny < 0 or nx >= size or ny >= size:
					continue
				var edge := float(size - 1 - nx) + float(size - 1 - ny) + float(nx) + float(ny)
				var sc := -edge * 0.4 - float(elev.get(Vector2i(nx, ny), 1.0)) * 6.0
				sc += _ihash(nx, ny, seed + 77 + r) * 1.4
				if sc > best_score:
					best_score = sc
					best = Vector2i(nx, ny)
			if best == cur:
				break
			cur = best
			if cur.x == 0 or cur.y == 0 or cur.x == size - 1 or cur.y == size - 1:
				break

	# 4) 河岸沃土 + 水边沙地
	for x in size:
		for y in size:
			var t := ws.terrain[ws.idx(x, y)]
			if t != GameConfig.T_GRASS and t != GameConfig.T_FOREST:
				continue
			var near_water := false
			var d2 := 3
			for dx in range(-d2, d2 + 1):
				for dy in range(-d2, d2 + 1):
					if ws.in_bounds(x + dx, y + dy) and ws.terrain[ws.idx(x + dx, y + dy)] == GameConfig.T_WATER:
						near_water = true
						break
			if not near_water:
				continue
			var m: float = moist.get(Vector2i(x, y), 0.5)
			var near := false
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					if ws.in_bounds(x + dx, y + dy) and ws.terrain[ws.idx(x + dx, y + dy)] == GameConfig.T_WATER:
						near = true
			if near and m > 0.35 and _ihash(x, y, seed_v + 4242) > 0.35:
				ws.terrain[ws.idx(x, y)] = GameConfig.T_FERTILE
				ws.fertility[ws.idx(x, y)] = 0.9
			elif t == GameConfig.T_GRASS and m < 0.45:
				ws.terrain[ws.idx(x, y)] = GameConfig.T_SAND
				ws.fertility[ws.idx(x, y)] = 0.08

	# 5) 资源点
	for x in size:
		for y in size:
			var t := ws.terrain[ws.idx(x, y)]
			if t == GameConfig.T_ROCK or t == GameConfig.T_MOUNTAIN:
				if _ihash(x, y, seed_v + 991) < rate:
					var roll := _ihash(x, y, seed_v + 313)
					if roll < 0.68:
						ws.resource[ws.idx(x, y)] = GameConfig.RES_IRON
					elif roll < 0.86:
						ws.resource[ws.idx(x, y)] = GameConfig.RES_GOLD
					else:
						ws.resource[ws.idx(x, y)] = GameConfig.RES_STONE

	# 6) 聚落选址
	var sites: Array = []
	var want: int = clamp(n_settle, 1, 4)
	var attempts := 0
	while sites.size() < want and attempts < 400:
		attempts += 1
		var cand := _best_site(ws, elev, moist, sites, size, seed + attempts)
		if cand != null:
			sites.append(cand)
	var SettlementScript = load("res://scripts/sim/Settlement.gd")
	for site in sites:
		var s: Settlement = SettlementScript.new()
		s.id = ws.next_settlement_id
		ws.next_settlement_id += 1
		s.base_name = Names.settlement_base(rng)
		s.cx = site.x
		s.cy = site.y
		s.claim_radius = 3
		s.population = rng.randi_range("gen", 18, 30)
		s.food_store = float(s.population) * 3.0
		s.wood = 20.0
		# 初始帐篷
		s.buildings.append({"key": "camp_tent", "tx": site.x, "ty": site.y, "progress": 1.0, "done": true, "year_built": 0})
		var off := rng.randi_range("gen", 1, 2)
		s.buildings.append({"key": "camp_tent", "tx": site.x + off, "ty": site.y + (3 - off), "progress": 1.0, "done": true, "year_built": 0})
		ws.settlements.append(s)
	ws.terrain_dirty = true
	ws.objects_dirty = true
	return ws

static func _pick_high_tile(elev: Dictionary, size: int, s: int) -> Variant:
	var best: Variant = null
	var best_e := -1.0
	for k in 12:
		var x := int(_ihash(k, s, 5) * float(size - 4)) + 2
		var y := int(_ihash(k, s, 9) * float(size - 4)) + 2
		var e: float = elev.get(Vector2i(x, y), 0.0)
		if e > best_e:
			best_e = e
			best = Vector2i(x, y)
	return best

static func _best_site(ws: WorldState, elev: Dictionary, moist: Dictionary, taken: Array, size: int, salt: int) -> Variant:
	var best: Variant = null
	var best_score := -1e9
	for x in range(3, size - 3):
		for y in range(3, size - 3):
			var t := ws.terrain[ws.idx(x, y)]
			if t != GameConfig.T_GRASS:
				continue
			if ws.settlement_at_tile(x, y) != null:
				continue
			if not (ws.get_resource(x, y) == 0):
				continue
			var too_close := false
			for p in taken:
				if abs(p.x - x) + abs(p.y - y) < 14:
					too_close = true
					break
			if too_close:
				continue
			var score := 0.0
			var water_near := false
			for dx in range(-4, 5):
				for dy in range(-4, 5):
					if not ws.in_bounds(x + dx, y + dy):
						continue
					var tt := ws.terrain[ws.idx(x + dx, y + dy)]
					if tt == GameConfig.T_FERTILE:
						score += 2.2
					elif tt == GameConfig.T_WATER:
						score += 0.9
						water_near = true
					elif tt == GameConfig.T_FOREST:
						score += 0.55
					elif tt == GameConfig.T_ROCK:
						score += 0.3
					elif tt == GameConfig.T_MOUNTAIN:
						score -= 0.8
					if ws.get_resource(x + dx, y + dy) != 0:
						score += 0.5
			if water_near:
				score += 1.4
			score += _ihash(x, y, salt) * 1.5
			if score > best_score:
				best_score = score
				best = Vector2i(x, y)
	return best
