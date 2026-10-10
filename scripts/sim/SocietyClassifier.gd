class_name SocietyClassifier
## 社会形态识别器：根据所有制、劳动关系、生产力、市场、国家能力、
## 财富结构等实际变量打分判断形态 —— 不依赖年份，不预设单线路径。
## 输出主形态 + 各形态得分 + 特征列表；得分接近时判为过渡/混合。

const MIN_PRIMARY := 0.34      # 成为明确主形态的最低分
const MIXED_GAP := 0.13        # 前两名差距小于此值 → 混合形态

static func classify(s) -> Dictionary:
	var scores := {
		"primitive": _score_primitive(s),
		"slave": _score_slave(s),
		"feudal": _score_feudal(s),
		"capitalist": _score_capitalist(s),
		"socialist": _score_socialist(s),
	}
	var ranked := scores.keys()
	ranked.sort_custom(func(a, b): return scores[a] > scores[b])
	var top: String = ranked[0]
	var second: String = ranked[1]
	var form := "mixed"
	if scores[top] >= MIN_PRIMARY and (scores[top] - scores[second]) >= MIXED_GAP:
		form = top
	elif scores[top] >= MIN_PRIMARY and (scores[top] - scores[second]) < MIXED_GAP:
		form = "mixed"
	# 特例：极小规模且未掌握农业 → 原始
	if s.population < 60 and not s.knows("early_agri"):
		form = "primitive"
	# 特例：完全无剩余 → 不可能维持奴隶/封建等形态
	if s.derived.get("surplus_ratio", 0.0) < 0.03 and s.population < 120:
		form = "primitive"
	var traits := _traits(s, scores)
	return {"form": form, "scores": scores, "traits": traits}

static func _clamp01(v: float) -> float:
	return clamp(v, 0.0, 1.0)

static func _score_primitive(s) -> float:
	var surplus: float = _clamp01(float(s.derived.get("surplus_ratio", 0.0)) * 4.0)
	var sc := 0.0
	sc += (1.0 - surplus) * 0.30
	sc += float(s.inst.get("communal", 0.0)) * 0.25
	sc += (1.0 - _clamp01(float(s.inst.get("specialization", 0.0)) * 3.0)) * 0.18
	sc += (1.0 - _clamp01(float(s.inst.get("state_capacity", 0.0)) * 4.0)) * 0.12
	sc += _clamp01(120.0 / max(1.0, float(s.population))) * 0.10
	if not s.knows("early_agri"):
		sc += 0.15
	return _clamp01(sc)

static func _score_slave(s) -> float:
	var sc := 0.0
	sc += float(s.inst.get("forced", 0.0)) * 0.45
	var gini: float = float(s.derived.get("gini", 0.2))
	if gini > 0.5:
		sc += (gini - 0.5) * 2.0 * 0.2
	sc += _clamp01(float(s.inst.get("warlike", 0.0)) * 2.0) * 0.10
	sc += _clamp01(float(s.inst.get("specialization", 0.0)) * 2.0) * 0.08
	# 必须有一定剩余才能供养非劳动者
	if float(s.derived.get("surplus_ratio", 0.0)) < 0.05:
		sc *= 0.45
	return _clamp01(sc)

static func _score_feudal(s) -> float:
	var sc := 0.0
	sc += float(s.inst.get("bonded", 0.0)) * 0.35
	sc += float(s.inst.get("land_concentration", 0.0)) * 0.28
	sc += float(s.derived.get("elite_power", 0.0)) * 0.14
	sc += (1.0 - _clamp01(float(s.tech.get("industry", 0.0)) / 45.0)) * 0.10
	var stc := float(s.inst.get("state_capacity", 0.0))
	if stc > 0.2 and stc < 0.75:
		sc += 0.08
	return _clamp01(sc)

static func _score_capitalist(s) -> float:
	var sc := 0.0
	sc += float(s.inst.get("wage", 0.0)) * 0.34
	sc += float(s.inst.get("market_dev", 0.0)) * 0.24
	sc += float(s.inst.get("private", 0.0)) * 0.20
	sc += _clamp01(float(s.tech.get("industry", 0.0)) / 100.0) * 0.14
	if s.knows("steam_engine"):
		sc += 0.05
	if s.knows("banking"):
		sc += 0.04
	return _clamp01(sc)

static func _score_socialist(s) -> float:
	var sc := 0.0
	sc += float(s.inst.get("state", 0.0)) * 0.28
	sc += float(s.inst.get("coop", 0.0)) * 0.20
	sc += float(s.inst.get("public_service", 0.0)) * 0.20
	sc += float(s.inst.get("participation", 0.0)) * 0.16
	sc += float(s.inst.get("planned_share", 0.0)) * 0.16
	return _clamp01(sc)

static func _traits(s, scores: Dictionary) -> Array:
	var out: Array = []
	if float(s.inst.get("forced", 0.0)) > 0.12:
		out.append("存在强制劳动")
	if float(s.inst.get("bonded", 0.0)) > 0.15:
		out.append("人身依附显著")
	if float(s.inst.get("land_concentration", 0.0)) > 0.45:
		out.append("土地高度集中")
	if float(s.inst.get("wage", 0.0)) > 0.25:
		out.append("雇佣劳动普及")
	if float(s.inst.get("market_dev", 0.0)) > 0.45:
		out.append("市场发达")
	if float(s.inst.get("state", 0.0)) > 0.35:
		out.append("公有经济显著")
	if float(s.inst.get("coop", 0.0)) > 0.2:
		out.append("合作生产兴起")
	if float(s.inst.get("public_service", 0.0)) > 0.35:
		out.append("公共服务完善")
	if float(s.derived.get("gini", 0.0)) > GameConfig.GINI_WARNING:
		out.append("财富分化严重")
	if float(s.inst.get("communal", 0.0)) > 0.5:
		out.append("共同劳动传统")
	return out
