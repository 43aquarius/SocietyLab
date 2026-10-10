## 模拟主管线：年度推进的编排者。
## 顺序：生产 → 人口 → 技术(+扩散) → 制度 → 冲突 → 贸易 → 分配 →
##       建筑/阶段 → 形态识别 → 环境事件 → 统计快照。
extends RefCounted

signal year_advanced(year)
signal event_fired(entry)
signal form_changed(settlement, old_form, new_form)
signal power_applied(power_id, x, y, sid)

const WorldGen = preload("res://scripts/sim/WorldGenerator.gd")
const WorldStateScript = preload("res://scripts/sim/WorldState.gd")
const SettlementScript = preload("res://scripts/sim/Settlement.gd")
const Econ = preload("res://scripts/sim/EconomySystem.gd")
const Pop = preload("res://scripts/sim/PopulationSystem.gd")
const Tech = preload("res://scripts/sim/TechnologySystem.gd")
const Inst = preload("res://scripts/sim/InstitutionSystem.gd")
const Conflict = preload("res://scripts/sim/ConflictSystem.gd")
const Events = preload("res://scripts/sim/EventSystem.gd")
const Powers = preload("res://scripts/sim/GodPowers.gd")
const History = preload("res://scripts/sim/HistoryManager.gd")

var world
var rng: RNGService
var history
var econ
var pop_system
var tech_system
var inst_system
var conflict_system
var event_system
var god_powers

func _init() -> void:
	history = History.new()
	econ = Econ.new(self)
	pop_system = Pop.new(self)
	tech_system = Tech.new(self)
	inst_system = Inst.new(self)
	conflict_system = Conflict.new(self)
	event_system = Events.new(self)
	god_powers = Powers.new(self)

# ==================== 会话建立 ====================
func new_game(opts: Dictionary) -> void:
	var seed_val := int(opts.get("seed", 0))
	rng = RNGService.new(seed_val)
	world = WorldGen.generate(opts, rng)
	world.god_mode = int(opts.get("god_mode", GameConfig.MODE_FREE))
	world.faith = GameConfig.FAITH_START
	world.year = 0
	history = History.new()
	history.log({
		"year": 0, "place": world.world_name, "cat": "inst",
		"title": "创世：%s" % world.world_name,
		"desc": "世界在 %d 个聚落的火光中开始它的历史。" % world.settlements.size(),
		"causes": ["世界种子 %d" % seed_val],
		"effects": ["%d 个初始聚落" % world.settlements.size()],
		"player_involved": true, "importance": 3,
	})
	# 第 0 年先跑一遍派生量，避免渲染/面板读到空值
	for s in world.settlements:
		_prepare_new_settlement(s)
	tick()

func load_game(payload: Dictionary) -> void:
	world = WorldStateScript.from_dict(payload.get("world", {}))
	rng = RNGService.new(world.seed_val)
	rng.from_dict(payload.get("rng", {}))
	history = History.new()
	history.from_dict(payload.get("history", {}))
	world.terrain_dirty = true
	world.objects_dirty = true
	emit_signal("year_advanced", world.year)

func session_payload() -> Dictionary:
	return {
		"version": 1,
		"meta": {
			"name": world.world_name, "seed": world.seed_val,
			"god_mode": world.god_mode, "year": world.year,
			"settlements": world.settlements.size(),
		},
		"world": world.to_dict(),
		"rng": rng.to_dict(),
		"history": history.to_dict(),
	}

# ==================== 年度推进 ====================
func tick() -> void:
	if world == null:
		return
	world.year += 1
	world.expire_effects(world.year)
	if world.god_mode == GameConfig.MODE_LIMITED:
		world.faith = min(world.faith + GameConfig.FAITH_REGEN, 999.0)
	# 冷却递减
	for s in world.settlements:
		for k in s.event_cooldowns.keys():
			s.event_cooldowns[k] = int(s.event_cooldowns[k]) - 1
			if int(s.event_cooldowns[k]) <= 0:
				s.event_cooldowns.erase(k)
	# 1 生产
	for s in world.settlements:
		econ.process(s, world)
	# 2 人口
	for s in world.settlements:
		pop_system.process(s, world)
	# 3 技术
	for s in world.settlements:
		tech_system.process(s, world)
	tech_system.diffusion_pass(world)
	# 4 制度
	for s in world.settlements:
		inst_system.process(s, world)
	# 5 冲突
	for s in world.settlements:
		conflict_system.process(s, world)
	conflict_system.war_pass(world)
	# 6 贸易
	econ.trade_pass(world)
	# 7 分配
	for s in world.settlements:
		econ.distribute(s)
	# 8 建筑与阶段
	for s in world.settlements:
		_construction_pass(s, world)
	# 9 形态识别
	for s in world.settlements:
		_classify_pass(s)
	# 10 环境事件
	event_system.check_pass(world)
	# 11 统计
	_stats_pass()
	# 12 快照
	if world.year % GameConfig.SNAPSHOT_EVERY == 0:
		history.add_snapshot(world, rng)
	emit_signal("year_advanced", world.year)

# ==================== 建筑与 fx ====================
func recompute_fx(s) -> void:
	var fx := {}
	var death_mult := 1.0
	for b in s.buildings:
		if not b.get("done", false):
			continue
		var info: Dictionary = Database.BUILDINGS.get(str(b.get("key", "")), {})
		var bfx: Dictionary = info.get("fx", {})
		for k in bfx:
			if str(k) == "death_mult":
				death_mult *= float(bfx[k])
			else:
				fx[k] = float(fx.get(k, 0.0)) + float(bfx[k])
	fx["death_mult"] = death_mult
	s.derived["fx"] = fx

func _construction_pass(s, ws) -> void:
	recompute_fx(s)
	_advance_builds(s, ws)
	_plan_builds(s, ws)
	_stage_check(s, ws)
	world.objects_dirty = true

func _advance_builds(s, ws) -> void:
	for b in s.buildings:
		if b.get("done", false):
			continue
		var key: String = str(b.get("key", ""))
		var info: Dictionary = Database.BUILDINGS.get(key, {})
		var cost: Dictionary = info.get("cost", {})
		if not b.get("paid", false):
			# 尝试支付
			if s.wood >= float(cost.get("wood", 0.0)) and s.stone >= float(cost.get("stone", 0.0)) and s.metal >= float(cost.get("metal", 0.0)):
				s.wood -= float(cost.get("wood", 0.0))
				s.stone -= float(cost.get("stone", 0.0))
				s.metal -= float(cost.get("metal", 0.0))
				b["paid"] = true
		if not b.get("paid", false):
			continue  # 资源不足，等待
		b["progress"] = float(b.get("progress", 0.0)) + 1.0
		var years: float = max(1.0, float(info.get("years", 1)))
		if float(b["progress"]) >= years:
			b["done"] = true
			b["year_built"] = ws.year

func _plan_builds(s, ws) -> void:
	var pending := 0
	for b in s.buildings:
		if not b.get("done", false):
			pending += 1
	var limit := 2
	if s.population > 500:
		limit += 1
	if s.population > 1500:
		limit += 1
	if pending >= limit:
		return
	var cap := pop_system.housing_cap(s)
	# ---- 住房 ----
	if float(s.population) > float(cap) * 0.88:
		var key := _era_housing(s)
		if key != "" and _count_pending(s, key) < 3:
			var tile = _place_building(s, ws, key, "ring")
			if tile != null:
				s.buildings.append({"key": key, "tx": tile.x, "ty": tile.y, "progress": 0.0, "done": false})
	# ---- 农田 ----
	if s.knows("early_agri"):
		var want_farms: int = ceili(float(s.population) / 38.0)
		var have := 0
		for b in s.buildings:
			if str(b.get("key", "")).begins_with("farm"):
				have += 1
		if have < want_farms:
			var fkey := "farm"
			if s.knows("electricity") and s.metal > 20.0:
				fkey = "farm_modern"
			elif s.knows("irrigation"):
				fkey = "farm_irrigated"
			var tile = _place_farm(s, ws)
			if tile != null:
				s.buildings.append({"key": fkey, "tx": tile.x, "ty": tile.y, "progress": 0.0, "done": false})
	# ---- 仓储 ----
	if s.knows("pottery") and s.food_store > (GameConfig.STORAGE_BASE + 500.0 * s.count_building("granary")) * 0.9 and _count_pending(s, "granary") == 0:
		var tile = _place_building(s, ws, "granary", "near")
		if tile != null:
			s.buildings.append({"key": "granary", "tx": tile.x, "ty": tile.y, "progress": 0.0, "done": false})
	# ---- 其他设施（一次性/按需） ----
	var singles := []
	if s.population >= 120 and s.knows("currency") and not s.has_building("market") and _count_pending(s, "market") == 0:
		singles.append("market")
	if s.population >= 220 and s.knows("writing") and not s.has_building("admin_hall") and _count_pending(s, "admin_hall") == 0:
		singles.append("admin_hall")
	if s.population >= 260 and s.knows("masonry") and float(s.inst.get("land_concentration", 0.0)) > 0.3 and not s.has_building("manor") and _count_pending(s, "manor") == 0:
		singles.append("manor")
	if s.population >= 400 and s.knows("masonry") and float(s.inst.get("state_capacity", 0.0)) > 0.25 and not s.has_building("castle") and _count_pending(s, "castle") == 0:
		singles.append("castle")
	if s.population >= 300 and s.knows("writing") and not s.has_building("temple") and _count_pending(s, "temple") == 0:
		singles.append("temple")
	if s.knows("printing") and not s.has_building("assembly") and _count_pending(s, "assembly") == 0:
		singles.append("assembly")
	if s.knows("writing") and s.population >= 180 and not s.has_building("school") and _count_pending(s, "school") == 0:
		singles.append("school")
	if s.knows("hygiene") and s.population >= 250 and not s.has_building("hospital") and _count_pending(s, "hospital") == 0:
		singles.append("hospital")
	if s.knows("cooperatives") and s.population >= 200 and s.count_building("cooperative") < 2:
		singles.append("cooperative")
	if s.knows("knapped_tools") and s.population >= 60 and s.count_building("workshop") < ceili(float(s.population) / 150.0):
		singles.append("workshop")
	if s.knows("steam_engine") and s.metal > 40.0 and s.population >= 500 and s.count_building("factory") < ceili(float(s.population) / 800.0):
		singles.append("factory")
	if s.knows("currency") and float(s.derived.get("trade_income", 0.0)) > 8.0 and s.count_building("warehouse") < 2:
		singles.append("warehouse")
	# 资源充足才立项
	for key in singles:
		var info: Dictionary = Database.BUILDINGS.get(key, {})
		var cost: Dictionary = info.get("cost", {})
		if s.wood * 2.0 < float(cost.get("wood", 0.0)) or s.stone * 2.0 < float(cost.get("stone", 0.0)) or s.metal * 2.0 < float(cost.get("metal", 0.0)):
			continue
		var mode := "near"
		if key == "castle" or key == "manor":
			mode = "ring"
		var tile = _place_building(s, ws, key, mode)
		if tile != null:
			s.buildings.append({"key": key, "tx": tile.x, "ty": tile.y, "progress": 0.0, "done": false})
		break  # 每年最多一个大型设施

func _era_housing(s) -> String:
	if s.knows("electricity"):
		return "apartment"
	if s.knows("masonry") and s.population > 600:
		return "house_town"
	if s.knows("masonry"):
		return "house_brick"
	if s.knows("knapped_tools"):
		return "house_wood"
	return "hut"

func _count_pending(s, key: String) -> int:
	var n := 0
	for b in s.buildings:
		if str(b.get("key", "")) == key and not b.get("done", false):
			n += 1
	return n

## 建筑选址：ring=围绕中心环形；near=离中心最近的空地
func _place_building(s, ws, key: String, mode: String):
	if mode == "ring":
		for r in range(1, s.claim_radius + 1):
			var cands: Array = []
			for dx in range(-r, r + 1):
				for dy in range(-r, r + 1):
					if max(abs(dx), abs(dy)) != r:
						continue
					var x: int = s.cx + dx
					var y: int = s.cy + dy
					if not ws.in_bounds(x, y):
						continue
					var t: int = ws.get_terrain(x, y)
					if not (t == GameConfig.T_GRASS or t == GameConfig.T_FERTILE or t == GameConfig.T_SAND):
						continue
					if ws.get_resource(x, y) != 0:
						continue
					if ws.has_building_at(x, y):
						continue
					cands.append(Vector2i(x, y))
			if not cands.is_empty():
				return cands[int(rng.randi_range("sim", 0, cands.size() - 1)) % cands.size()]
	else:
		var best: Variant = null
		var best_d := 1e9
		for t2 in s.claimed_tiles():
			var x: int = t2.x
			var y: int = t2.y
			if not ws.in_bounds(x, y):
				continue
			var tt: int = ws.get_terrain(x, y)
			if not (tt == GameConfig.T_GRASS or tt == GameConfig.T_FERTILE or tt == GameConfig.T_SAND):
				continue
			if ws.get_resource(x, y) != 0:
				continue
			if ws.has_building_at(x, y):
				continue
			var d: float = pow(x - s.cx, 2.0) + pow(y - s.cy, 2.0)
			if d < best_d:
				best_d = d
				best = Vector2i(x, y)
		return best
	return null

## 农田选址：领地内肥力最高的空地（沃土优先）
func _place_farm(s, ws):
	var best: Variant = null
	var best_f := -1.0
	for t in s.claimed_tiles():
		var x: int = t.x
		var y: int = t.y
		if not ws.in_bounds(x, y):
			continue
		var tt: int = ws.get_terrain(x, y)
		if not (tt == GameConfig.T_FERTILE or tt == GameConfig.T_GRASS):
			continue
		if ws.get_resource(x, y) != 0:
			continue
		if ws.has_building_at(x, y):
			continue
		var f: float = ws.get_fertility(x, y)
		# 灌溉技术偏好近水
		if s.knows("irrigation"):
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if ws.in_bounds(x + d.x, y + d.y) and ws.get_terrain(x + d.x, y + d.y) == GameConfig.T_WATER:
					f *= 1.2
					break
		if f > best_f:
			best_f = f
			best = Vector2i(x, y)
	return best

func _stage_check(s, ws) -> void:
	var next_stage: int = s.stage + 1
	var info: Dictionary = Database.STAGES.get(next_stage, {})
	if info.is_empty():
		return
	var pop_ok: bool = s.population >= int(info.get("pop", 999999))
	var needs: Dictionary = info.get("needs", {})
	var ok := pop_ok
	if needs.has("tech"):
		ok = ok and s.knows(str(needs["tech"]))
	if needs.has("buildings"):
		for bk in needs["buildings"]:
			ok = ok and s.has_building(str(bk))
	if not ok:
		return
	s.stage = next_stage
	s.expand_claim()
	var reasons: Array = ["人口达到 %d" % int(info.get("pop", 0))]
	if needs.has("tech"):
		reasons.append("掌握 %s" % Database.tech_name(str(needs["tech"])))
	if needs.has("buildings"):
		for bk in needs["buildings"]:
			reasons.append("建成 %s" % Database.building_name(str(bk)))
	fire_event("city", s, {
		"title": "%s 发展为%s" % [s.base_name, str(info.get("name", ""))],
		"desc": "%s 从 %s 成长为 %s。聚落的规模与组织方式正在改变。" % [s.display_name(), s.stage_name(), str(info.get("name", ""))],
		"causes": reasons,
		"effects": ["领地扩张", "住房与设施需求上升", "名字更新为「%s」" % s.display_name()],
	}, 3)

# ==================== 形态识别 ====================
func _classify_pass(s) -> void:
	var result: Dictionary = SocietyClassifier.classify(s)
	var old_form := s.form
	var changed := s.set_form(result.get("form", "mixed"))
	s.form_scores = result.get("scores", {})
	if changed and world.year > 3:
		fire_event("inst", s, {
			"title": "%s 进入%s" % [s.display_name(), Database.form_name(s.form)],
			"desc": str((Database.FORMS.get(s.form, {}) as Dictionary).get("desc", "")),
			"causes": _form_causes(s),
			"effects": ["社会形态判定变更", "后续制度演化路径改变"],
		}, 3)
		emit_signal("form_changed", s, old_form, s.form)

func _form_causes(s) -> Array:
	var out: Array = []
	var sc: Dictionary = s.form_scores
	for k in ["primitive", "slave", "feudal", "capitalist", "socialist"]:
		out.append("%s 匹配度 %.2f" % [Database.form_name(k), float(sc.get(k, 0.0))])
	out.append("强制劳动 %.2f / 依附 %.2f / 雇佣 %.2f / 合作 %.2f" % [
		float(s.inst.get("forced", 0.0)), float(s.inst.get("bonded", 0.0)),
		float(s.inst.get("wage", 0.0)), float(s.inst.get("coop", 0.0))])
	out.append("土地集中 %.2f / 市场 %.2f / 公有 %.2f" % [
		float(s.inst.get("land_concentration", 0.0)), float(s.inst.get("market_dev", 0.0)),
		float(s.inst.get("state", 0.0)) + float(s.inst.get("coop", 0.0))])
	return out

# ==================== 新聚落 ====================
func find_found_site(ws, from) -> Variant:
	var best: Variant = null
	var best_score := -1e9
	for x in range(3, ws.size - 3):
		for y in range(3, ws.size - 3):
			var t: int = ws.get_terrain(x, y)
			if t != GameConfig.T_GRASS:
				continue
			if ws.settlement_at_tile(x, y) != null:
				continue
			var near := false
			for s2 in ws.settlements:
				var d: float = sqrt(pow(s2.cx - x, 2.0) + pow(s2.cy - y, 2.0))
				if d < 9.0:
					near = true
					break
			if near:
				continue
			var score := 0.0
			for dx in range(-3, 4):
				for dy in range(-3, 4):
					if not ws.in_bounds(x + dx, y + dy):
						continue
					var tt: int = ws.get_terrain(x + dx, y + dy)
					if tt == GameConfig.T_FERTILE:
						score += 2.0
					elif tt == GameConfig.T_WATER:
						score += 0.8
					elif tt == GameConfig.T_FOREST:
						score += 0.4
			var d_from: float = sqrt(pow(from.cx - x, 2.0) + pow(from.cy - y, 2.0))
			if d_from > 24.0 or d_from < 9.0:
				continue
			score -= d_from * 0.15
			if score > best_score:
				best_score = score
				best = Vector2i(x, y)
	return best

func found_settlement(ws, site: Vector2i, pop: int, origin) -> void:
	var s: Settlement = SettlementScript.new()
	s.id = ws.next_settlement_id
	ws.next_settlement_id += 1
	s.base_name = Names.settlement_base(rng)
	s.cx = site.x
	s.cy = site.y
	s.population = pop
	s.food_store = float(pop) * 2.0
	s.wood = 10.0
	s.buildings.append({"key": "camp_tent", "tx": site.x, "ty": site.y, "progress": 1.0, "done": true, "year_built": ws.year})
	_prepare_new_settlement(s)
	ws.settlements.append(s)
	fire_event("migration", origin, {
		"title": "新聚落：%s" % s.display_name(),
		"desc": "从 %s 分出的一支人在此定居。历史翻开了新的一页。" % origin.display_name(),
		"causes": _migration_causes_text(origin),
		"effects": ["%s 建立（%d 人）" % [s.display_name(), pop], "%s 人口 -%d" % [origin.display_name(), pop]],
	}, 3)

func _migration_causes_text(s) -> Array:
	var out: Array = []
	if s.famine_active:
		out.append("饥荒迫使人群离开")
	if float(s.groups["laborer"].get("grievance", 0.0)) > GameConfig.MIGRATION_PRESSURE:
		out.append("社会不满（%.2f）" % float(s.groups["laborer"].get("grievance", 0.0)))
	if not out.is_empty():
		return out
	return ["人口压力"]

func _prepare_new_settlement(s) -> void:
	recompute_fx(s)
	s.derived["fx"] = s.derived.get("fx", {})
	s.derived["health"] = 0.45

# ==================== 事件出口 ====================
func fire_event(cat: String, s, data: Dictionary, importance: int) -> void:
	var player := false
	if s != null and is_instance_valid(s):
		player = (world.year - s.last_divine_year) <= 8
	var entry := {
		"year": world.year,
		"sid": (s.id if s != null else -1),
		"place": (s.display_name() if s != null else world.world_name),
		"cat": cat,
		"title": str(data.get("title", "事件")),
		"desc": str(data.get("desc", "")),
		"causes": data.get("causes", []),
		"effects": data.get("effects", []),
		"player_involved": player,
		"importance": importance,
		"actions": data.get("actions", []),
	}
	history.log(entry)
	emit_signal("event_fired", entry)

# ==================== 统计 ====================
func _stats_pass() -> void:
	var pop_t := 0
	var food_t := 0.0
	var gini_s := 0.0
	var tech_s := 0.0
	var unrest_s := 0.0
	var forms := {}
	var prod := 0.0
	for s in world.settlements:
		pop_t += s.population
		food_t += s.food_store
		gini_s += float(s.derived.get("gini", 0.0))
		var t_avg := 0.0
		for k in s.tech:
			t_avg += float(s.tech[k])
		tech_s += t_avg / max(1.0, float(s.tech.size()))
		unrest_s += float(s.derived.get("unrest", 0.0))
		prod += float(s.derived.get("craft_output", 0.0)) + float(s.derived.get("trade_income", 0.0))
		forms[str(s.id)] = s.form
		s.stat_log.append({
			"year": world.year, "pop": s.population, "form": s.form,
			"gini": float(s.derived.get("gini", 0.0)),
			"intake": float(s.derived.get("intake_ratio", 1.0)),
			"prod": float(s.derived.get("food_prod", 0.0)) + float(s.derived.get("craft_output", 0.0)),
			"wage": float(s.derived.get("wage_level", 0.0)),
			"stability": float(s.derived.get("stability", 0.5)),
		})
		if s.stat_log.size() > 900:
			s.stat_log.pop_front()
	var n := max(1, world.settlements.size())
	world.stats.append({
		"year": world.year, "pop": pop_t, "food": food_t,
		"gini": gini_s / n, "tech": tech_s / n, "unrest": unrest_s / n,
		"prod": prod, "forms": forms,
	})
	if world.stats.size() > 2000:
		world.stats.pop_front()
