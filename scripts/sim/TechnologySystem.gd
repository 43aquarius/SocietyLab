## 技术系统：研究点积累 → 领域等级 → 满足前置后"发现"技术。
## 假设：
##  - 研究能力来自剩余产品（养得起不直接生产的人）与教育；
##  - 技术发现需要满足前置（领域等级、前置技术、资源接触）；
##  - 邻近更先进聚落产生扩散（追赶效应）；
##  - 神力"智慧之光"注入一次性研究池，但不能跳过前置。
extends RefCounted

var _sim

func _init(sim) -> void:
	_sim = sim

func process(s, ws) -> void:
	var surplus: float = clamp(float(s.derived.get("surplus_ratio", 0.0)), 0.0, 1.0)
	var ed: float = float(s.inst.get("education", 0.0))
	var fx: Dictionary = s.derived.get("fx", {})
	var base: float = GameConfig.RESEARCH_BASE
	base *= 1.0 + GameConfig.RESEARCH_SURPLUS_MULT * surplus
	base *= 1.0 + ed * 2.5
	base *= 1.0 + float(fx.get("research", 0.0)) * 2.0
	if s.knows("writing"):
		base *= 1.2
	if s.knows("printing"):
		base *= 1.15
	if s.knows("mathematics"):
		base *= 1.1
	# 神力/效果修正（智慧之光是一次性池 + 期间倍率）
	var mult: float = ws.settlement_research_mod(s.id)
	if s.research_buffer > 0.0:
		var inject: float = min(s.research_buffer, 6.0)
		s.research_buffer -= inject
		base += inject
	base *= max(0.2, mult)
	# 分配到领域
	var weights := _domain_weights(s)
	var wsum := 0.0
	for k in weights:
		wsum += weights[k]
	if wsum <= 0.0:
		wsum = 1.0
	for domain in weights:
		var add: float = base * weights[domain] / wsum
		s.tech[domain] = clamp(float(s.tech.get(domain, 0.0)) + add, 0.0, GameConfig.TECH_LEVEL_MAX)
	# 检查发现
	for tid in Database.TECHS:
		if s.knows(tid):
			continue
		if _try_discover(s, ws, tid):
			_announce(s, tid)

func _domain_weights(s) -> Dictionary:
	var w := {
		"agriculture": 1.0,
		"tools": 1.0,
		"construction": 0.6,
		"health": 0.5,
		"organization": 0.6,
		"commerce": 0.2,
		"industry": 0.1,
	}
	var fs: float = float(s.derived.get("intake_ratio", 1.0))
	if fs < 0.95:
		w["agriculture"] = 2.2
		w["health"] = 0.8
	if s.population > 150:
		w["organization"] += 0.4
	if float(s.inst.get("market_dev", 0.0)) > 0.2 or s.knows("currency"):
		w["commerce"] = 0.8
	if s.knows("writing"):
		w["organization"] += 0.4
		w["construction"] += 0.2
	if s.knows("steam_engine") or float(s.tech.get("industry", 0.0)) > 25.0:
		w["industry"] = 0.9
	if s.population > 400:
		w["health"] += 0.4
	return w

func _try_discover(s, ws, tid: String) -> bool:
	var info: Dictionary = Database.TECHS.get(tid, {})
	if info.is_empty():
		return false
	var domain: String = str(info.get("domain", "tools"))
	var lvl: float = float(s.tech.get(domain, 0.0))
	var need_lvl: float = float(info.get("level", 50.0))
	if lvl < need_lvl:
		return false
	# 前置技术
	var pre: Dictionary = info.get("pre", {})
	for pre_domain in pre:
		if str(pre_domain) == "tech":
			continue
		var pd_lvl: float = float(s.tech.get(str(pre_domain), 0.0))
		if pd_lvl < float(pre[pre_domain]):
			return false
	for pre_tid in pre.get("tech", []):
		if not s.knows(str(pre_tid)):
			return false
	# 资源接触（金属类技术）
	if int(info.get("res", 0)) == 1:
		if not _has_metal_contact(s, ws):
			return false
	s.discovered.append(tid)
	return true

func _has_metal_contact(s, ws) -> bool:
	if float(s.metal) > 1.0:
		return true
	if bool(s.derived.get("metal_contact", false)):
		return true
	for tile in s.claimed_tiles():
		if ws.in_bounds(tile.x, tile.y):
			var r: int = ws.resource[ws.idx(tile.x, tile.y)]
			if r == GameConfig.RES_IRON or r == GameConfig.RES_GOLD:
				return true
	return false

func _count(s, key: String) -> int:
	var n := 0
	for b in s.buildings:
		if b.get("done", false) and str(b.get("key", "")) == key:
			n += 1
	return n

func _announce(s, tid: String) -> void:
	var info: Dictionary = Database.TECHS.get(tid, {})
	_sim.fire_event("discovery", s, {
		"title": "发现：%s" % str(info.get("name", tid)),
		"desc": str(info.get("desc", "")),
		"causes": [
			"%s 领域积累 %.0f / 需要 %.0f" % [str(Database.TECH_DOMAINS.get(str(info.get("domain", "")), "?")), float(s.tech.get(str(info.get("domain", "")), 0.0)), float(info.get("level", 50.0))],
			"剩余产品支撑了研究" if float(s.derived.get("surplus_ratio", 0.0)) > 0.15 else "研究在匮乏中进行",
		],
		"effects": ["解锁相关建筑与生产加成"],
	}, 2)

## 邻近聚落间的技术扩散
func diffusion_pass(ws) -> void:
	for i in ws.settlements.size():
		for j in range(i + 1, ws.settlements.size()):
			var a = ws.settlements[i]
			var b = ws.settlements[j]
			var dist: float = sqrt(pow(a.cx - b.cx, 2.0) + pow(a.cy - b.cy, 2.0))
			if dist > 14.0:
				continue
			for domain in ["agriculture", "tools", "construction", "health", "organization", "commerce", "industry"]:
				var la: float = float(a.tech.get(domain, 0.0))
				var lb: float = float(b.tech.get(domain, 0.0))
				var diff: float = la - lb
				if abs(diff) < 4.0:
					continue
				if diff > 0.0:
					b.tech[domain] = clamp(lb + diff * 0.02, 0.0, GameConfig.TECH_LEVEL_MAX)
					# 随带技术传播
					for tid in a.discovered:
						if not b.discovered.has(tid) and _try_discover(b, ws, tid):
							_sim.fire_event("discovery", b, {
								"title": "传入：%s" % Database.tech_name(tid),
								"desc": "经由与 %s 的接触，%s 学会了这项技术。" % [a.display_name(), Database.tech_name(tid)],
								"causes": ["邻近的 %s 已掌握该技术" % a.display_name(), "两地距离 %.0f 格" % dist],
								"effects": ["%s 进入 %s 的技术体系" % [b.display_name(), Database.tech_name(tid)]],
							}, 1)
							break
				else:
					a.tech[domain] = clamp(la + (-diff) * 0.02, 0.0, GameConfig.TECH_LEVEL_MAX)
