## 事件系统：扫描式环境事件（其他系统直接调用 sim.fire_event）。
## 每个事件 = 条件检查 + 结果计算 + 叙事呈现；
## 事件的"原因"来自真实模拟变量快照，不允许编造。
extends RefCounted

var _sim

func _init(sim) -> void:
	_sim = sim

## 每年扫描（在主管线末段调用）
func check_pass(ws) -> void:
	for s in ws.settlements:
		_ev_harvest(s, ws)
		_ev_famine(s, ws)
		_ev_epidemic(s, ws)
		_ev_land_grab(s, ws)
		_ev_idea_spread(s, ws)
		_ev_trade_boom(s, ws)
		_ev_golden_age(s, ws)
		_ev_degradation(s, ws)
		_ev_city_decline(s, ws)

func _cool(s, ev: String, years: int) -> void:
	s.event_cooldowns[ev] = years

func _ready(s, ev: String) -> bool:
	return int(s.event_cooldowns.get(ev, 0)) <= 0

# ---------- 丰产 ----------
func _ev_harvest(s, ws) -> void:
	if not _ready(s, "harvest"):
		return
	var weather: float = 1.0
	var n := 0
	for t in s.claimed_tiles():
		if ws.in_bounds(t.x, t.y):
			weather += ws.tile_moisture_mod(t.x, t.y) - 1.0
			n += 1
	weather /= max(1, n)
	var surplus: float = float(s.derived.get("surplus_ratio", 0.0))
	if weather > 1.08 and surplus > 0.25 and _sim.rng.chance("event", 0.3):
		s.food_store += float(s.population) * 0.8
		_cool(s, "harvest", 6)
		_sim.fire_event("harvest", s, {
			"title": "%s 丰收" % s.display_name(),
			"desc": "风调雨顺，仓廪充实。",
			"causes": ["区域湿度 %.2f（偏丰）" % weather, "剩余率 %.2f" % surplus],
			"effects": ["存粮增加"],
		}, 1)

# ---------- 饥荒（重大事件，附神力介入选项） ----------
func _ev_famine(s, ws) -> void:
	if s.famine_active:
		# 恢复条件
		if s.hunger_years == 0 and float(s.derived.get("intake_ratio", 1.0)) > 0.85:
			s.famine_active = false
			_sim.fire_event("harvest", s, {
				"title": "%s 走出饥荒" % s.display_name(),
				"desc": "存粮与产出恢复，饥饿终于过去。",
				"causes": ["粮食摄入恢复到需求的 85% 以上"],
				"effects": ["饥荒状态解除"],
			}, 2)
		return
	if not _ready(s, "famine"):
		return
	if s.hunger_years >= GameConfig.FAMINE_DEFICIT_YEARS and float(s.derived.get("intake_ratio", 1.0)) < GameConfig.FAMINE_TRIGGER_RATIO:
		s.famine_active = true
		_cool(s, "famine", 5)
		_sim.fire_event("famine", s, {
			"title": "饥荒笼罩 %s" % s.display_name(),
			"desc": "连续 %d 年粮食摄入不足需求的 %.0f%%。人口开始减少，人们考虑离开。神可以介入，也可以任由自然裁决。" % [s.hunger_years, GameConfig.FAMINE_TRIGGER_RATIO * 100.0],
			"causes": [
				"存粮 %.0f / 年需求 %.0f" % [s.food_store, float(s.derived.get("food_need", 0.0))],
				"当年产出 %.0f，摄入率 %.0f%%" % [float(s.derived.get("food_prod", 0.0)), float(s.derived.get("intake_ratio", 1.0)) * 100.0],
				"人口 %d 持续消耗" % s.population,
			],
			"effects": ["死亡率大幅上升", "迁移压力加剧", "可能触发人口流失与骚乱"],
			"actions": [
				{"label": "施予甘霖", "power": "rain", "cost": 6},
				{"label": "丰饶祝福", "power": "bless", "cost": 10},
			],
		}, 3)

# ---------- 疫病 ----------
func _ev_epidemic(s, ws) -> void:
	if not _ready(s, "epidemic"):
		return
	var pop: float = float(s.population)
	var crowding: float = pop / max(1.0, float(_sim.pop_system.housing_cap(s)))
	var health: float = float(s.derived.get("health", 0.4))
	var contacts: float = float(s.derived.get("trade_income", 0.0))
	var risk := 0.0
	if pop > 120:
		risk += (crowding - 1.0) * 0.25
	if health < 0.5:
		risk += (0.5 - health) * 0.5
	if contacts > 5.0:
		risk += 0.04
	if _sim.rng.chance("event", max(0.0, risk) * 0.25):
		var severity: float = _sim.rng.randf_range("event", 0.05, 0.12) * (1.5 - health)
		var loss := int(round(pop * severity))
		s.population = max(6, s.population - loss)
		s.research_buffer = max(0.0, s.research_buffer - 2.0)
		_cool(s, "epidemic", 10)
		_sim.fire_event("disease", s, {
			"title": "疫病在 %s 蔓延" % s.display_name(),
			"desc": "拥挤、贸易往来与薄弱的卫生知识让疾病迅速传播。",
			"causes": [
				"住房拥挤度 %.2f（>1 为拥挤）" % crowding,
				"健康水平 %.2f" % health,
				"对外接触（贸易收入 %.1f）" % contacts,
			],
			"effects": ["人口 -%d（约 %.0f%%）" % [loss, severity * 100.0], "研究活动受挫"],
		}, 2)

# ---------- 土地兼并 ----------
func _ev_land_grab(s, ws) -> void:
	if not _ready(s, "land_grab"):
		return
	var lc: float = float(s.inst.get("land_concentration", 0.0))
	var private_o: float = float(s.inst.get("private", 0.0))
	var gini: float = float(s.derived.get("gini", 0.2))
	if lc > 0.55 and private_o > 0.3 and gini > 0.5 and _sim.rng.chance("event", 0.12):
		s.inst["land_concentration"] = clamp(lc + 0.05, 0.0, 0.9)
		s.groups["laborer"]["grievance"] = clamp(float(s.groups["laborer"].get("grievance", 0.0)) + 0.12, 0.0, 1.0)
		_cool(s, "land_grab", 12)
		_sim.fire_event("inst", s, {
			"title": "%s 土地兼并加剧" % s.display_name(),
			"desc": "强者购并弱者田产，自耕者沦为依附者。财富与土地进一步集中。",
			"causes": ["土地集中度 %.2f" % lc, "私有成分 %.2f" % private_o, "基尼系数 %.2f" % gini],
			"effects": ["土地集中度 +0.05", "劳动者不满上升"],
		}, 2)

# ---------- 新思想传播 ----------
func _ev_idea_spread(s, ws) -> void:
	if not _ready(s, "idea_spread"):
		return
	if s.knows("printing") and _sim.rng.chance("event", 0.06):
		s.inst["participation"] = clamp(float(s.inst.get("participation", 0.0)) + 0.05, 0.0, 0.95)
		s.groups["laborer"]["org"] = clamp(float(s.groups["laborer"].get("org", 0.0)) + 0.05, 0.0, 1.0)
		_cool(s, "idea_spread", 15)
		_sim.fire_event("idea", s, {
			"title": "新思想在 %s 传播" % s.display_name(),
			"desc": "印刷品让普通人开始讨论公共事务。组织能力悄然生长。",
			"causes": ["掌握印刷术", "识字与教育基础"],
			"effects": ["政治参与 +0.05", "劳动者组织度 +0.05"],
		}, 1)

# ---------- 商贸繁荣 ----------
func _ev_trade_boom(s, ws) -> void:
	if not _ready(s, "trade_boom"):
		return
	var ti: float = float(s.derived.get("trade_income", 0.0))
	if ti > 12.0 and s.knows("banking") and _sim.rng.chance("event", 0.1):
		s.inst["market_dev"] = clamp(float(s.inst.get("market_dev", 0.0)) + 0.06, 0.0, 1.0)
		s.groups["merchant"]["stock"] = float(s.groups["merchant"].get("stock", 5.0)) * 1.25
		_cool(s, "trade_boom", 10)
		_sim.fire_event("trade", s, {
			"title": "%s 商贸繁荣" % s.display_name(),
			"desc": "信贷与商路让财富加速流转，市场一片兴旺。",
			"causes": ["贸易收入 %.1f" % ti, "掌握金融与信贷"],
			"effects": ["市场发育 +0.06", "商人财富增长"],
		}, 1)

# ---------- 治世 ----------
func _ev_golden_age(s, ws) -> void:
	if not _ready(s, "golden"):
		return
	if s.population < 300:
		return
	var stability: float = float(s.derived.get("stability", 0.5))
	var surplus: float = float(s.derived.get("surplus_ratio", 0.0))
	var gini: float = float(s.derived.get("gini", 0.3))
	if stability > 0.7 and surplus > 0.35 and gini < 0.45 and _sim.rng.chance("event", 0.08):
		_cool(s, "golden", 40)
		s.groups["laborer"]["grievance"] = clamp(float(s.groups["laborer"].get("grievance", 0.0)) - 0.15, 0.0, 1.0)
		s.inst["trust"] = clamp(float(s.inst.get("trust", 0.3)) + 0.06, 0.0, 0.95)
		_sim.fire_event("golden", s, {
			"title": "%s 的黄金时代" % s.display_name(),
			"desc": "稳定、富足而相对公平的社会迎来了文化与技术的蓬勃发展。",
			"causes": ["稳定度 %.2f" % stability, "剩余率 %.2f" % surplus, "基尼系数 %.2f（低于警戒）" % gini],
			"effects": ["不满显著下降", "制度信任上升", "研究获得加成"],
		}, 3)
		s.research_buffer += 3.0

# ---------- 环境退化 ----------
func _ev_degradation(s, ws) -> void:
	if not _ready(s, "degrade"):
		return
	var pol: float = float(s.derived.get("pollution", 0.0))
	var forest := 0
	var land := 0
	for t in s.claimed_tiles():
		if ws.in_bounds(t.x, t.y):
			land += 1
			if ws.terrain[ws.idx(t.x, t.y)] == GameConfig.T_FOREST:
				forest += 1
	var forest_ratio: float = float(forest) / max(1, land)
	var pressure: float = float(s.derived.get("resource_pressure", 0.0))
	if (pol > 0.3 or (forest_ratio < 0.06 and s.population > 250)) and pressure > 0.4 and _sim.rng.chance("event", 0.08):
		var hit := 0
		for t in s.claimed_tiles():
			if hit >= 3:
				break
			if ws.in_bounds(t.x, t.y) and ws.terrain[ws.idx(t.x, t.y)] == GameConfig.T_FERTILE:
				ws.set_fertility(t.x, t.y, ws.get_fertility(t.x, t.y) - 0.15)
				hit += 1
		_cool(s, "degrade", 15)
		_sim.fire_event("degrade", s, {
			"title": "%s 的土地退化" % s.display_name(),
			"desc": "过度耕作与砍伐让地力衰退。若不节制，饥荒将在未来等着我。",
			"causes": ["污染 %.2f" % pol, "领地内森林比例 %.2f" % forest_ratio, "资源压力 %.2f" % pressure],
			"effects": ["部分沃土肥力 -0.15"],
		}, 2)

# ---------- 城市衰退 ----------
func _ev_city_decline(s, ws) -> void:
	if not _ready(s, "decline"):
		return
	if s.stat_log.size() < 20:
		return
	var past: Dictionary = s.stat_log[s.stat_log.size() - 20]
	var old_pop: float = float(past.get("pop", s.population))
	if old_pop > s.population * 1.28 and old_pop > 150 and _sim.rng.chance("event", 0.2):
		_cool(s, "decline", 25)
		_sim.fire_event("boom", s, {
			"title": "%s 的衰退" % s.display_name(),
			"desc": "二十年间人口缩水近三成。战争、饥荒或迁徙抽空了这座聚落。",
			"causes": ["20 年前人口 %.0f → 现在 %d" % [old_pop, s.population]],
			"effects": ["城市活力下降（研究与市场受创）"],
		}, 2)
		s.inst["market_dev"] = clamp(float(s.inst.get("market_dev", 0.0)) - 0.05, 0.0, 1.0)
