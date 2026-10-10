## 人口系统：出生/死亡/迁移与群体组织度演化。
## 模型假设（重要）：
##  - 出生率受食物保障、健康水平、剩余消费与住房拥挤正向影响；
##  - 死亡率基线随健康改善下降，饥荒时显著上升（饥饿倍率）；
##  - 人口不会永远正增长：住房不足、饥荒、战争都会压低甚至逆转增长；
##  - 迁移由不满与饥荒驱动，可能流向其他聚落或分裂出新聚落。
extends RefCounted

var _sim

func _init(sim) -> void:
	_sim = sim

func process(s, ws) -> void:
	var d: Dictionary = s.derived
	var intake_ratio: float = float(d.get("intake_ratio", 1.0))
	var fs: float = clamp((intake_ratio - 0.70) / 0.30, 0.0, 1.0)  # 食物保障 0..1
	var health: float = health_score(s)
	d["health"] = health
	var surplus: float = clamp(float(d.get("surplus_ratio", 0.0)), 0.0, 1.0)
	var hunger_sev: float = float(d.get("starving", 0.0))

	# ---- 出生 ----
	var birth := 0.055 * (0.5 + 0.5 * fs) * (0.6 + 0.4 * health) * (0.85 + 0.3 * surplus)
	birth *= _crowding_birth_mult(s)
	# ---- 死亡 ----
	var death := 0.030 * (2.05 - 1.75 * health)
	death *= 1.0 + GameConfig.HUNGER_DEATH_MULT * hunger_sev
	if s.famine_active:
		death *= 1.25
	var fx: Dictionary = d.get("fx", {})
	death *= float(fx.get("death_mult", 1.0))

	var growth := birth - death
	if s.population >= GameConfig.MAX_POP_PER_SETTLEMENT:
		growth = min(growth, 0.0)
	var delta := int(round(growth * float(s.population)))
	if s.famine_active:
		delta -= int(round(float(s.population) * 0.012))  # 饥荒直接损失
	s.population = max(6, s.population + delta)
	d["pop_growth"] = growth

	# ---- 群体组织度 ----
	var ed: float = float(s.inst.get("education", 0.0))
	var org_gain := 0.006 * (1.0 + ed * 3.0)
	if s.knows("printing"):
		org_gain *= 1.5
	if s.knows("mass_education"):
		org_gain *= 1.6
	var urban := clamp(float(s.population) / 800.0, 0.0, 1.0)
	var g = s.groups["laborer"]
	g["org"] = clamp(float(g.get("org", 0.05)) + org_gain * (0.5 + urban * 0.8), 0.0, 1.0)

	# ---- 迁移 ----
	_migration(s, ws)

func health_score(s) -> float:
	var h := 0.42
	h += s.tech_level("health") * 0.004
	var fx: Dictionary = s.derived.get("fx", {})
	h += float(fx.get("health", 0.0))
	if s.knows("hygiene"):
		h += 0.05
	if s.knows("medicine"):
		h += 0.06
	if s.knows("sanitation"):
		h += 0.07
	if s.has_building("hospital"):
		h += 0.04
	# 饥荒损害健康
	h -= float(s.derived.get("starving", 0.0)) * 0.18
	# 污染
	h -= float(s.derived.get("pollution", 0.0)) * 0.12
	return clamp(h, 0.15, 0.95)

func _crowding_birth_mult(s) -> float:
	var cap := 1
	for b in s.buildings:
		if b.get("done", false):
			var info: Dictionary = Database.BUILDINGS.get(str(b.get("key", "")), {})
			cap += int(info.get("cap", 0))
	if cap < 1:
		cap = 1
	var over: float = float(s.population) / float(cap) - 1.0
	if over <= 0.0:
		return 1.0
	return clamp(1.0 / (1.0 + over * 1.6), 0.25, 1.0)

func housing_cap(s) -> int:
	var cap := 0
	for b in s.buildings:
		if b.get("done", false):
			var info: Dictionary = Database.BUILDINGS.get(str(b.get("key", "")), {})
			cap += int(info.get("cap", 0))
	return cap

## 迁移：不满或饥荒驱动；目的地为更优聚落，或分裂建立新聚落
func _migration(s, ws) -> void:
	var griev: float = float(s.groups["laborer"].get("grievance", 0.0))
	var pressure := 0.0
	if griev > GameConfig.MIGRATION_PRESSURE:
		pressure += (griev - GameConfig.MIGRATION_PRESSURE) * 2.0
	if s.famine_active:
		pressure += 0.8
	if s.derived.get("intake_ratio", 1.0) < 0.6:
		pressure += 0.5
	if pressure <= 0.0:
		s.migration_timer = 0
		return
	s.migration_timer += 1
	# 每 3~5 年一批人离开
	if s.migration_timer < 3:
		return
	s.migration_timer = 0
	var rng: RNGService = _sim.rng
	var leave_frac := clamp(pressure * 0.06, 0.03, 0.18)
	var leavers := int(round(float(s.population) * leave_frac))
	if leavers < 4:
		return
	leavers = min(leavers, s.population - 12)
	if leavers < 4:
		return
	# 找目的地：就近且条件更好的聚落
	var best = null
	var best_score := -1e9
	for other in ws.settlements:
		if other.id == s.id:
			continue
		var dist: float = sqrt(pow(other.cx - s.cx, 2.0) + pow(other.cy - s.cy, 2.0))
		if dist > 22.0:
			continue
		var score := float(other.derived.get("intake_ratio", 1.0)) * 10.0 - dist * 0.4
		score -= float(other.groups["laborer"].get("grievance", 0.0)) * 8.0
		if other.famine_active:
			score -= 20.0
		if score > best_score:
			best_score = score
			best = other
	if best != null and best_score > 6.0:
		s.population -= leavers
		best.population += leavers
		_sim.fire_event("migration", s, {
			"title": "%s 的迁徙" % s.display_name(),
			"desc": "约 %d 人因%s离开，前往 %s。" % [leavers, ("饥荒" if s.famine_active else "不满与困境"), best.display_name()],
			"causes": _migration_causes(s),
			"effects": ["%s 人口 -%d" % [s.display_name(), leavers], "%s 人口 +%d" % [best.display_name(), leavers]],
		}, 1)
		return
	# 分裂建立新聚落
	if s.population >= GameConfig.MIN_FOUNDING_POP * 2 and ws.settlements.size() < 6:
		var site = _sim.find_found_site(ws, s)
		if site != null:
			var founders := min(leavers, s.population - GameConfig.MIN_FOUNDING_POP)
			if founders >= GameConfig.MIN_FOUNDING_POP:
				s.population -= founders
				_sim.found_settlement(ws, site, founders, s)
				return
	# 无法迁移：不满继续累积（由冲突系统处理）

func _migration_causes(s) -> Array:
	var out: Array = []
	if s.famine_active:
		out.append("饥荒持续")
	if float(s.groups["laborer"].get("grievance", 0.0)) > GameConfig.MIGRATION_PRESSURE:
		out.append("劳动者不满 %.2f" % float(s.groups["laborer"].get("grievance", 0.0)))
	if s.derived.get("intake_ratio", 1.0) < 0.7:
		out.append("粮食摄入不足（%.0f%%）" % (float(s.derived.get("intake_ratio", 1.0)) * 100.0))
	return out
