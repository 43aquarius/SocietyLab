## 经济系统：粮食与资源生产、消费与储量、群体收入分配、基尼与土地集中。
## 建筑效果（fx）由 SimulationManager.recompute_fx 聚合为"总和"语义；
## 死亡倍率（death_mult）为"乘积"语义。
extends RefCounted

var _sim  # SimulationManager（鸭子类型，避免循环引用）

func _init(sim) -> void:
	_sim = sim

## 每年生产与消费（分配由 distribute 在冲突/贸易之后单独调用）
func process(s, ws) -> void:
	var fx: Dictionary = s.derived.get("fx", {})
	var workers: float = float(s.population) * GameConfig.WORKER_RATIO
	# ---------- 食物 ----------
	var farms := _done_farms(s)
	var food_prod := 0.0
	var agri_used := workers * 0.85
	if not farms.is_empty() and s.knows("early_agri"):
		var need_labor: float = float(farms.size()) * GameConfig.FARM_WORKERS
		agri_used = min(workers * 0.78, need_labor)
		var labor_ratio: float = clamp(agri_used / need_labor, 0.0, 1.0)
		var fert_sum := 0.0
		for b in farms:
			var tx: int = int(b.get("tx", 0))
			var ty: int = int(b.get("ty", 0))
			var f: float = ws.get_fertility(tx, ty) * ws.tile_moisture_mod(tx, ty)
			var key: String = str(b.get("key", "farm"))
			if key == "farm_irrigated":
				f *= 1.25
			elif key == "farm_modern":
				f *= 1.6
			fert_sum += f
		var fert_avg: float = fert_sum / max(1, farms.size())
		var tech_yield := 1.0 + s.tech_level("agriculture") * 0.012
		if s.knows("crop_rotation"):
			tech_yield += 0.15
		var tools_mult := 1.0 + s.tech_level("tools") * 0.006
		if s.knows("bronze"):
			tools_mult += 0.05
		if s.knows("iron"):
			tools_mult += 0.07
		var inst_mult := 1.0 + float(fx.get("craft", 0.0)) * 0.4
		var weather := _weather_avg(ws, s)
		var bless: float = ws.settlement_prod_mod(s.id, "food")
		food_prod = float(farms.size()) * GameConfig.BASE_FARM_YIELD * fert_avg * labor_ratio
		food_prod *= tech_yield * tools_mult * inst_mult * weather * bless
		var leftover := workers - agri_used
		if leftover > 0.0 and s.tech_level("agriculture") < 40.0:
			food_prod += leftover * 0.5 * GameConfig.GATHER_YIELD * (1.0 + s.tech_level("agriculture") * 0.004)
		s.derived["farm_count"] = farms.size()
	else:
		var gatherers := workers * 0.85
		food_prod = gatherers * GameConfig.GATHER_YIELD * (1.0 + s.tech_level("agriculture") * 0.004)
		food_prod *= ws.settlement_prod_mod(s.id, "food")
		food_prod *= _weather_avg(ws, s)
		s.derived["farm_count"] = 0
	s.derived["food_prod"] = food_prod

	# ---------- 消费与储量 ----------
	var need: float = float(s.population) * GameConfig.FOOD_PER_CAPITA
	s.derived["food_need"] = need
	var avail := s.food_store + food_prod
	var intake: float = min(need, avail)
	s.food_store = max(0.0, avail - intake)
	var intake_ratio: float = intake / max(1.0, need)
	s.derived["intake_ratio"] = intake_ratio
	var food_cap: float = GameConfig.STORAGE_BASE + float(fx.get("food_cap", 0.0))
	var spoil: float = GameConfig.SPOILAGE_BASE
	if s.knows("pottery"):
		spoil *= 0.7
	spoil *= 1.0 - clamp(float(fx.get("spoil_reduce", 0.0)), 0.0, 0.85)
	if s.knows("sanitation"):
		spoil *= 0.8
	s.food_store = min(s.food_store * (1.0 - spoil), food_cap)
	# 饥饿记账
	if intake_ratio < GameConfig.FAMINE_TRIGGER_RATIO:
		s.hunger_years += 1
	else:
		s.hunger_years = max(0, s.hunger_years - 1)
	var surplus_ratio: float = clamp((avail - need) / max(1.0, need), 0.0, 1.5)
	s.derived["surplus_ratio"] = surplus_ratio
	s.derived["starving"] = clamp((GameConfig.FAMINE_TRIGGER_RATIO - intake_ratio) / GameConfig.FAMINE_TRIGGER_RATIO, 0.0, 1.0)

	# ---------- 手工业与资源 ----------
	var craft_workers: float = max(0.0, workers - agri_used)
	var craft_mult := 1.0 + s.tech_level("tools") * 0.008 + float(fx.get("craft", 0.0))
	var craft_output: float = craft_workers * 2.2 * craft_mult * ws.settlement_prod_mod(s.id, "craft")
	s.derived["craft_output"] = craft_output
	var forest := _terrain_count(ws, s, GameConfig.T_FOREST)
	var rock := _terrain_count(ws, s, GameConfig.T_ROCK) + _terrain_count(ws, s, GameConfig.T_MOUNTAIN)
	var ore := _resource_count(ws, s, [GameConfig.RES_IRON, GameConfig.RES_GOLD])
	var stone_res := _resource_count(ws, s, [GameConfig.RES_STONE])
	var labor_cap: float = craft_workers * 1.2
	var wood_gain := min(forest * GameConfig.WOOD_PER_FOREST_TILE, labor_cap)
	var stone_gain := min(rock * GameConfig.STONE_PER_ROCK_TILE + stone_res * 2.0, labor_cap) * (1.0 + float(fx.get("tools", 0.0)))
	var metal_eff := 0.4
	if s.knows("bronze"):
		metal_eff = 1.0
	elif s.knows("iron"):
		metal_eff = 1.3
	var metal_gain := min(ore * GameConfig.METAL_PER_ORE_TILE, labor_cap) * metal_eff
	var upkeep_wood: float = float(s.population) * 0.02 + 0.5
	s.wood = max(0.0, s.wood + wood_gain - upkeep_wood)
	s.stone += stone_gain
	s.metal += metal_gain
	var res_cap: float = 400.0 + float(fx.get("res_cap", 0.0))
	s.wood = min(s.wood, res_cap)
	s.stone = min(s.stone, res_cap)
	s.metal = min(s.metal, res_cap)
	# 环境压力
	var claim_area: float = float((s.claim_radius * 2 + 1) * (s.claim_radius * 2 + 1))
	s.derived["resource_pressure"] = clamp(float(s.population) / (claim_area * 12.0), 0.0, 1.0)
	s.derived["pollution"] = clamp(float(fx.get("pollution", 0.0)) * 8.0 + float(s.population) * 0.00004, 0.0, 1.0)
	# 群体构成
	_update_group_sizes(s)

## 群体收入分配 → 财富存量 → 基尼/工资/精英权力（在冲突与贸易之后调用）
func distribute(s) -> void:
	var pool: float = max(0.0, float(s.derived.get("food_prod", 0.0)) - float(s.derived.get("food_need", 0.0)))
	pool += float(s.derived.get("craft_output", 0.0)) + float(s.derived.get("trade_income", 0.0))
	var tax_rate: float = float(s.inst.get("tax_rate", 0.18))
	var state_take: float = clamp(tax_rate, 0.0, 0.5)
	var rest := pool * (1.0 - state_take)
	var land_conc: float = float(s.inst.get("land_concentration", 0.0))
	var private_o: float = float(s.inst.get("private", 0.0))
	var market: float = float(s.inst.get("market_dev", 0.0))
	var forced: float = float(s.inst.get("forced", 0.0))
	var bonded: float = float(s.inst.get("bonded", 0.0))
	var coop: float = float(s.inst.get("coop", 0.0))
	var elite_share := clamp(0.26 + land_conc * 0.22 + private_o * 0.14 + market * 0.08, 0.06, 0.74)
	var merchant_share := clamp(0.08 + market * 0.30, 0.02, 0.34)
	var admin_share := clamp(0.10 + float(s.inst.get("state_capacity", 0.0)) * 0.22, 0.05, 0.3)
	var laborer_share := clamp(1.0 - elite_share - merchant_share - admin_share, 0.1, 0.8)
	laborer_share = clamp(laborer_share - forced * 0.18 - bonded * 0.12 + coop * 0.10, 0.1, 0.85)
	elite_share = clamp(1.0 - laborer_share - merchant_share - admin_share, 0.05, 0.8)
	# 入账（绝对存量）
	var g
	g = s.groups["laborer"]; g["stock"] = float(g.get("stock", 10.0)) + rest * laborer_share + pool * state_take * 0.35
	g = s.groups["elite"]; g["stock"] = float(g.get("stock", 10.0)) + rest * elite_share
	g = s.groups["merchant"]; g["stock"] = float(g.get("stock", 4.0)) + rest * merchant_share
	g = s.groups["admin"]; g["stock"] = float(g.get("stock", 4.0)) + rest * admin_share + pool * state_take * 0.65
	# 财富份额（归一化）
	var total_stock := 0.0
	for gid in s.groups:
		total_stock += float(s.groups[gid].get("stock", 0.0))
	if total_stock <= 0.0:
		total_stock = 1.0
	for gid in s.groups:
		s.groups[gid]["wealth"] = clamp(float(s.groups[gid].get("stock", 0.0)) / total_stock, 0.0, 1.0)
	s.derived["gini"] = _weighted_gini(s)
	var lab_pop: float = max(1.0, float(s.population) * float(s.groups["laborer"].get("size", 0.8)))
	s.derived["wage_level"] = (rest * laborer_share + pool * state_take * 0.35) / lab_pop
	s.derived["elite_power"] = clamp(float(s.groups["elite"].get("wealth", 0.2)) * (1.0 + float(s.derived.get("fx", {}).get("defense", 0.0))), 0.0, 1.0)
	if not s.event_cooldowns.has("land_reform_recent"):
		s.inst["land_concentration"] = clamp(float(s.inst.get("land_concentration", 0.0)) + 0.0025 * (private_o * 1.2 + market * 0.6), 0.0, 0.85)
	# 专业化 = 非农劳动占比
	var workers: float = float(s.population) * GameConfig.WORKER_RATIO
	var agri_share := 0.85
	if s.knows("early_agri") and s.derived.get("farm_count", 0) > 0:
		agri_share = clamp(min(workers * 0.78, float(s.derived["farm_count"]) * GameConfig.FARM_WORKERS) / max(1.0, workers), 0.1, 1.0)
	var spec_target: float = clamp(1.0 - agri_share, 0.0, 0.95)
	s.inst["specialization"] = lerp(float(s.inst.get("specialization", 0.0)), spec_target, 0.12)
	s.derived["productivity"] = 1.0 + s.tech_level("tools") * 0.008 + s.tech_level("industry") * 0.01
	var market_target: float = clamp(0.1 + market + float(s.derived.get("fx", {}).get("market", 0.0)) * 2.0, 0.0, 1.0)
	s.inst["market_dev"] = lerp(float(s.inst.get("market_dev", 0.0)), market_target, 0.08)

func trade_pass(ws) -> void:
	## 世界级贸易：成对结算（在 distribute 之前调用）
	for a in ws.settlements:
		a.derived["trade_income"] = 0.0
	for i in ws.settlements.size():
		for j in range(i + 1, ws.settlements.size()):
			var a = ws.settlements[i]
			var b = ws.settlements[j]
			var dist: float = sqrt(pow(a.cx - b.cx, 2.0) + pow(a.cy - b.cy, 2.0))
			if dist > 16.0:
				continue
			var ma: float = float(a.inst.get("market_dev", 0.0))
			var mb: float = float(b.inst.get("market_dev", 0.0))
			if ma < 0.15 or mb < 0.15:
				continue
			if not a.knows("currency") or not b.knows("currency"):
				continue
			var pair := (ma + mb) * 9.0 / pow(max(2.0, dist), 0.5)
			if a.knows("roads") and b.knows("roads"):
				pair *= 1.45
			a.derived["trade_income"] = float(a.derived.get("trade_income", 0.0)) + pair
			b.derived["trade_income"] = float(b.derived.get("trade_income", 0.0)) + pair
			if _resource_count(ws, a, [GameConfig.RES_IRON, GameConfig.RES_GOLD]) == 0 and b.metal > 2.0:
				a.derived["metal_contact"] = true
			if _resource_count(ws, b, [GameConfig.RES_IRON, GameConfig.RES_GOLD]) == 0 and a.metal > 2.0:
				b.derived["metal_contact"] = true

# ==================== 辅助 ====================
func _weather_avg(ws, s) -> float:
	var total := 0.0
	var n := 0
	for t in s.claimed_tiles():
		if ws.in_bounds(t.x, t.y):
			total += ws.tile_moisture_mod(t.x, t.y)
			n += 1
	return total / max(1, n)

func _done_farms(s) -> Array:
	var out: Array = []
	for b in s.buildings:
		if b.get("done", false) and str(b.get("key", "")).begins_with("farm"):
			out.append(b)
	return out

func _terrain_count(ws, s, t: int) -> int:
	var n := 0
	for tile in s.claimed_tiles():
		if ws.in_bounds(tile.x, tile.y) and ws.terrain[ws.idx(tile.x, tile.y)] == t:
			n += 1
	return n

func _resource_count(ws, s, kinds: Array) -> int:
	var n := 0
	for tile in s.claimed_tiles():
		if not ws.in_bounds(tile.x, tile.y):
			continue
		var r: int = ws.resource[ws.idx(tile.x, tile.y)]
		if r != 0 and kinds.has(r):
			n += 1
	return n

func _update_group_sizes(s) -> void:
	var spec: float = float(s.inst.get("specialization", 0.0))
	var admin_need: float = float(s.inst.get("state_capacity", 0.0))
	var sizes := {
		"laborer": clamp(0.92 - spec * 0.45 - admin_need * 0.25, 0.5, 0.95),
		"elite": clamp(0.04 + float(s.inst.get("land_concentration", 0.0)) * 0.06 + float(s.inst.get("private", 0.0)) * 0.05, 0.03, 0.14),
		"merchant": clamp(0.02 + float(s.inst.get("market_dev", 0.0)) * 0.12, 0.01, 0.16),
		"admin": clamp(0.02 + admin_need * 0.2 + (0.02 if s.knows("writing") else 0.0), 0.01, 0.14),
	}
	var total := 0.0
	for gid in sizes:
		total += sizes[gid]
	for gid in sizes:
		s.groups[gid]["size"] = sizes[gid] / total

func _weighted_gini(s) -> float:
	var ps: Array = []
	var wsh: Array = []
	for gid in ["laborer", "elite", "merchant", "admin"]:
		ps.append(float(s.groups[gid].get("size", 0.25)))
		wsh.append(float(s.groups[gid].get("wealth", 0.25)))
	var sp := 0.0
	for p in ps:
		sp += p
	if sp <= 0.0:
		return 0.0
	var acc := 0.0
	for i in ps.size():
		for j in ps.size():
			var wi: float = wsh[i] / max(0.0001, ps[i])
			var wj: float = wsh[j] / max(0.0001, ps[j])
			acc += abs(wi - wj) * ps[i] * ps[j]
	return clamp(acc * 0.5 / (sp * sp), 0.0, 1.0)
