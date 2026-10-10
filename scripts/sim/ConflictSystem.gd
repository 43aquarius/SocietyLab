## 冲突系统：不满积累 → 集体行动（谈判/改革/镇压/暴动/革命），
## 以及聚落间的袭击与战争。
## 假设：
##  - 不满由生活恶化、分配不公、政治封闭共同驱动，向目标值缓移；
##  - 是否爆发、以何种形式爆发，取决于组织度、国家能力、精英权力、
##    改革渠道是否存在 —— 同一问题允许多种结局，不是阈值=革命；
##  - 战争由资源压力+尚武+距离触发；胜方可能获得俘虏（强制劳动上升）。
extends RefCounted

var _sim

func _init(sim) -> void:
	_sim = sim

func process(s, ws) -> void:
	var d: Dictionary = s.derived
	var g = s.groups["laborer"]
	# ---- 不满目标值 ----
	var target := 0.05
	var intake: float = float(d.get("intake_ratio", 1.0))
	if intake < 0.9:
		target += (0.9 - intake) * 1.2
	var gini: float = float(d.get("gini", 0.2))
	if gini > 0.42:
		target += (gini - 0.42) * 1.5
	var land_conc: float = float(s.inst.get("land_concentration", 0.0))
	if land_conc > 0.5:
		target += (land_conc - 0.5) * 0.8
	var wage_trend: float = float(d.get("wage_level", 1.0))
	if wage_trend < 0.8:
		target += (0.8 - wage_trend) * 0.5
	var part: float = float(s.inst.get("participation", 0.0))
	if part < 0.1:
		target += 0.08  # 没有表达渠道会积累更多不满
	var trust: float = float(s.inst.get("trust", 0.35))
	if trust < 0.3:
		target += 0.06
	# 缓移
	var griev: float = float(g.get("grievance", 0.1))
	griev = lerp(griev, clamp(target, 0.0, 1.0), 0.09)
	g["grievance"] = clamp(griev, 0.0, 1.0)
	# ---- 动荡 ----
	var org: float = float(g.get("org", 0.05))
	var unrest: float = clamp(griev * (0.45 + 0.55 * org), 0.0, 1.0)
	d["unrest"] = unrest
	# 防御/稳定派生量
	var fx: Dictionary = d.get("fx", {})
	d["defense"] = clamp(0.08 + float(fx.get("defense", 0.0)) + float(s.inst.get("warlike", 0.0)) * 0.2, 0.0, 1.0)

	# ---- 集体行动 ----
	if unrest > GameConfig.UNREST_TO_ACTION and s.population > 80:
		_collective_action(s, ws, unrest)

func _collective_action(s, ws, unrest: float) -> void:
	var rng: RNGService = _sim.rng
	var g = s.groups["laborer"]
	var org: float = float(g.get("org", 0.05))
	var stc: float = float(s.inst.get("state_capacity", 0.0))
	var elite_power: float = float(s.derived.get("elite_power", 0.2))
	var part: float = float(s.inst.get("participation", 0.0))
	var defense: float = float(s.derived.get("defense", 0.1))

	# 改革渠道：国家有能力、精英未完全垄断、参与渠道存在
	var reform_channel: bool = stc > 0.22 and elite_power < 0.72 and part > 0.08
	var regime_force: float = stc * 0.5 + defense * 0.3 + elite_power * 0.4
	var people_force: float = org * 0.6 + unrest * 0.5 + float(s.population) / 4000.0

	if reform_channel and rng.chance("event", 0.55):
		_reform(s, ws)
	elif regime_force > people_force + 0.25 and stc > 0.3:
		_repress(s, ws)
	elif org > 0.42 and people_force > regime_force:
		_revolution(s, ws)
	else:
		_riot(s, ws)

func _reform(s, ws) -> void:
	var g = s.groups["laborer"]
	s.inst["tax_rate"] = clamp(float(s.inst.get("tax_rate", 0.18)) - 0.02, 0.05, 0.45)
	s.inst["wage"] = clamp(float(s.inst.get("wage", 0.0)) + 0.05, 0.0, 0.7)
	s.inst["land_concentration"] = clamp(float(s.inst.get("land_concentration", 0.0)) - 0.12, 0.0, 0.9)
	s.inst["participation"] = clamp(float(s.inst.get("participation", 0.0)) + 0.06, 0.0, 0.95)
	s.inst["trust"] = clamp(float(s.inst.get("trust", 0.3)) + GameConfig.REFORM_TRUST_GAIN * 3.0, 0.0, 0.95)
	if float(s.inst.get("forced", 0.0)) > 0.1:
		s.inst["forced"] = clamp(float(s.inst.get("forced", 0.0)) - 0.06, 0.0, 1.0)
	if float(s.inst.get("bonded", 0.0)) > 0.1:
		s.inst["bonded"] = clamp(float(s.inst.get("bonded", 0.0)) - 0.08, 0.0, 1.0)
	g["grievance"] = clamp(float(g.get("grievance", 0.0)) - 0.3, 0.0, 1.0)
	s.event_cooldowns["land_reform_recent"] = 15  # 抑制土地集中漂移 15 年
	_sim.fire_event("reform", s, {
		"title": "%s 的重大改革" % s.display_name(),
		"desc": "在持续压力之下，统治者让步：税负减轻、分配规则调整、参与渠道扩大。动荡暂时平息。",
		"causes": [
			"劳动者组织度 %.2f" % float(g.get("org", 0.0)),
			"动荡指数 %.2f（超过行动阈值 %.2f）" % [float(s.derived.get("unrest", 0.0)), GameConfig.UNREST_TO_ACTION],
			"改革渠道存在（国家能力 %.2f）" % float(s.inst.get("state_capacity", 0.0)),
		],
		"effects": ["税率下调", "工资/劳动者份额上升", "土地集中度下降", "政治参与扩大", "制度信任恢复"],
	}, 3)

func _repress(s, ws) -> void:
	var g = s.groups["laborer"]
	g["grievance"] = clamp(float(g.get("grievance", 0.0)) - 0.15, 0.0, 1.0)
	s.inst["trust"] = clamp(float(s.inst.get("trust", 0.3)) - 0.08, 0.05, 0.95)
	s.inst["participation"] = clamp(float(s.inst.get("participation", 0.0)) - 0.04, 0.0, 0.9)
	s.derived["stability"] = clamp(float(s.derived.get("stability", 0.5)) - 0.08, 0.05, 1.0)
	_sim.fire_event("conflict", s, {
		"title": "%s 的镇压" % s.display_name(),
		"desc": "抗议被强力压制。不满暂时沉寂，但信任受到损害，未来可能以更激烈的方式回归。",
		"causes": [
			"国家力量强于民众力量（国家能力 %.2f / 精英权力 %.2f）" % [float(s.inst.get("state_capacity", 0.0)), float(s.derived.get("elite_power", 0.0))],
			"改革渠道不畅",
		],
		"effects": ["不满暂时受抑", "制度信任下降", "政治参与收缩"],
	}, 2)

func _riot(s, ws) -> void:
	var g = s.groups["laborer"]
	g["grievance"] = clamp(float(g.get("grievance", 0.0)) - 0.08, 0.0, 1.0)
	s.derived["stability"] = clamp(float(s.derived.get("stability", 0.5)) - 0.1, 0.05, 1.0)
	# 暴动烧毁一座建筑
	var burned := ""
	var done: Array = s.done_buildings()
	if done.size() > 4:
		var victim = _sim.rng.pick("event", done)
		victim["done"] = false
		victim["progress"] = 0.0
		victim["rioted"] = true
		burned = Database.building_name(str(victim.get("key", "")))
	_sim.fire_event("conflict", s, {
		"title": "%s 爆发骚乱" % s.display_name(),
		"desc": "无处发泄的不满演成骚乱。" + ("公共建筑受损。" if burned != "" else ""),
		"causes": [
			"动荡 %.2f 超过阈值" % float(s.derived.get("unrest", 0.0)),
			"组织度不足（%.2f），无法形成改革或革命力量" % float(g.get("org", 0.0)),
		],
		"effects": (["%s 被毁，需要重建" % burned] if burned != "" else []) + ["稳定度下降"],
	}, 2)

func _revolution(s, ws) -> void:
	var g = s.groups["laborer"]
	var loss := int(round(float(s.population) * GameConfig.REVOLT_POP_LOSS))
	s.population = max(8, s.population - loss)
	# 财富与制度剧变
	s.groups["elite"]["stock"] = float(s.groups["elite"].get("stock", 10.0)) * 0.25
	s.groups["laborer"]["stock"] = float(s.groups["laborer"].get("stock", 10.0)) * 1.8
	s.inst["forced"] = 0.0
	s.inst["bonded"] = clamp(float(s.inst.get("bonded", 0.0)) * 0.2, 0.0, 1.0)
	s.inst["land_concentration"] = clamp(float(s.inst.get("land_concentration", 0.0)) * 0.3, 0.0, 0.9)
	s.inst["private"] = clamp(float(s.inst.get("private", 0.0)) * 0.4, 0.0, 1.0)
	s.inst["communal"] = clamp(1.0 - float(s.inst.get("private", 0.0)) - float(s.inst.get("state", 0.0)), 0.0, 1.0)
	s.inst["participation"] = clamp(float(s.inst.get("participation", 0.0)) + 0.2, 0.0, 0.95)
	g["grievance"] = 0.1
	g["org"] = clamp(float(g.get("org", 0.0)) + 0.1, 0.0, 1.0)
	_sim.fire_event("reform", s, {
		"title": "革命：%s" % s.display_name(),
		"desc": "组织起来的人民以暴力推翻了旧秩序。强制劳动被废除，财产被重新分配，但代价是流血与破坏。",
		"causes": [
			"民众力量 %.2f 压过秩序力量" % (float(g.get("org", 0.0)) * 0.6 + float(s.derived.get("unrest", 0.0)) * 0.5),
			"改革渠道失效，镇压不可行",
			"组织度 %.2f" % float(g.get("org", 0.0)),
		],
		"effects": ["人口损失 %d" % loss, "强制/依附劳动清零", "权贵财富缩水", "土地重新分配", "政治参与大幅扩大"],
	}, 3)

# ==================== 聚落间战争 ====================
func war_pass(ws) -> void:
	var rng: RNGService = _sim.rng
	for i in ws.settlements.size():
		for j in range(i + 1, ws.settlements.size()):
			var a = ws.settlements[i]
			var b = ws.settlements[j]
			var dist: float = sqrt(pow(a.cx - b.cx, 2.0) + pow(a.cy - b.cy, 2.0))
			if dist > 18.0:
				continue
			var pa: float = float(a.derived.get("resource_pressure", 0.0))
			var pb: float = float(b.derived.get("resource_pressure", 0.0))
			var wa: float = float(a.inst.get("warlike", 0.1))
			var wb: float = float(b.inst.get("warlike", 0.1))
			var trade_tie: bool = (float(a.derived.get("trade_income", 0.0)) + float(b.derived.get("trade_income", 0.0))) > 6.0
			var prob := (pa + pb) * 0.5 * (wa + wb) * 0.5 * GameConfig.WAR_PRESSURE_BASE * 8.0
			if trade_tie:
				prob *= 0.35
			if float(a.derived.get("trade_income", 0.0)) > 4.0 and float(b.derived.get("trade_income", 0.0)) > 4.0:
				prob *= 0.5
			if int(a.event_cooldowns.get("war_cooldown", 0)) > 0 or int(b.event_cooldowns.get("war_cooldown", 0)) > 0:
				prob = 0.0
			if rng.chance("event", prob):
				_fight(ws, a, b)

func _fight(ws, a, b) -> void:
	var rng: RNGService = _sim.rng
	var a_force: float = float(a.population) / 300.0 * (0.5 + float(a.derived.get("defense", 0.1)) + (0.3 if a.knows("bronze") else 0.0) + (0.4 if a.knows("iron") else 0.0))
	var b_force: float = float(b.population) / 300.0 * (0.5 + float(b.derived.get("defense", 0.1)) + (0.3 if b.knows("bronze") else 0.0) + (0.4 if b.knows("iron") else 0.0))
	a_force *= rng.randf_range("event", 0.7, 1.3)
	b_force *= rng.randf_range("event", 0.7, 1.3)
	var winner = a if a_force >= b_force else b
	var loser = b if winner == a else a
	var wloss := int(round(float(winner.population) * 0.03))
	var lloss := int(round(float(loser.population) * 0.1))
	winner.population = max(8, winner.population - wloss)
	loser.population = max(6, loser.population - lloss)
	var loot_food: float = min(loser.food_store * 0.4, 60.0)
	loser.food_store -= loot_food
	winner.food_store += loot_food
	# 俘虏成为强制劳动
	var captives := int(round(float(loser.population) * 0.04))
	if captives > 3 and float(winner.inst.get("forced", 0.0)) < 0.55:
		winner.inst["captive_inflow"] = clamp(float(captives) / max(40.0, float(winner.population)) * 0.5, 0.0, 0.08)
	winner.inst["warlike"] = clamp(float(winner.inst.get("warlike", 0.1)) + 0.05, 0.0, 0.8)
	a.event_cooldowns["war_cooldown"] = 12
	b.event_cooldowns["war_cooldown"] = 12
	_sim.fire_event("war", winner, {
		"title": "战争：%s 进攻 %s" % [a.display_name(), b.display_name()],
		"desc": "资源压力与尚武传统把两个共同体推向战场。%s 战胜，掳掠了物资%s。" % [winner.display_name(), ("，并将俘虏变为强制劳动者" if captives > 3 else "")],
		"causes": [
			"双方资源压力 %.2f / %.2f" % [float(a.derived.get("resource_pressure", 0.0)), float(b.derived.get("resource_pressure", 0.0))],
			"尚武程度 %.2f / %.2f" % [float(a.inst.get("warlike", 0.0)), float(b.inst.get("warlike", 0.0))],
			"距离 %.0f 格，贸易纽带%s" % [sqrt(pow(a.cx - b.cx, 2.0) + pow(a.cy - b.cy, 2.0)), "抑制了冲突" if float(a.derived.get("trade_income", 0.0)) > 4.0 else "薄弱"],
		],
		"effects": [
			"%s 人口 -%d" % [winner.display_name(), wloss],
			"%s 人口 -%d" % [loser.display_name(), lloss],
			"%s 损失存粮 %.0f" % [loser.display_name(), loot_food],
		],
	}, 3)

func _count(s, key: String) -> int:
	var n := 0
	for b in s.buildings:
		if b.get("done", false) and str(b.get("key", "")) == key:
			n += 1
	return n
