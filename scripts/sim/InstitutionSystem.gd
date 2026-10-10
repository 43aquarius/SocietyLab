## 制度系统：所有制/劳动关系/市场/国家能力/公共服务的缓慢演化。
## 假设（模型化，非历史定律）：
##  - 私有成分随专业化与市场发育缓慢上升；
##  - 强制劳动因效率低下缓慢衰减，战争掳掠可逆转；
##  - 雇佣劳动随工业与商贸上升；合作劳动随组织技术与参与度上升；
##  - 国家能力依赖税收与官僚建筑；公共服务依赖国家能力与教育；
##  - 税率自动微调：财政压力升、动荡高且改革渠道畅通时降。
extends RefCounted

var _sim

func _init(sim) -> void:
	_sim = sim

func process(s, ws) -> void:
	var d: Dictionary = s.derived
	var fx: Dictionary = d.get("fx", {})
	var spec: float = float(s.inst.get("specialization", 0.0))
	var market: float = float(s.inst.get("market_dev", 0.0))

	# ---- 所有制 ----
	var private_gain := 0.0035 * (spec * 1.4 + market * 0.8)
	if s.knows("banking"):
		private_gain *= 1.3
	if float(s.inst.get("participation", 0.0)) > 0.5 and s.knows("cooperatives"):
		private_gain *= 0.6
	s.inst["private"] = clamp(float(s.inst.get("private", 0.0)) + private_gain, 0.0, 0.75)
	var communal_left := 1.0 - float(s.inst.get("private", 0.0)) - float(s.inst.get("state", 0.0))
	s.inst["communal"] = clamp(communal_left, 0.0, 1.0)

	# ---- 劳动关系 ----
	var forced: float = float(s.inst.get("forced", 0.0))
	forced = max(0.0, forced - 0.0028)  # 效率低下自然衰减
	if s.inst.get("captive_inflow", 0.0) > 0.0:
		forced = clamp(forced + float(s.inst["captive_inflow"]), 0.0, 0.6)
		s.inst["captive_inflow"] = 0.0
	s.inst["forced"] = forced
	var bonded: float = float(s.inst.get("bonded", 0.0))
	var bond_target: float = clamp(float(s.inst.get("land_concentration", 0.0)) * 0.55, 0.0, 0.5)
	if float(s.tech.get("industry", 0.0)) > 30.0 or float(s.tech.get("commerce", 0.0)) > 45.0:
		bond_target *= 0.5
	bonded = lerp(bonded, bond_target, 0.05)
	s.inst["bonded"] = bonded
	var wage_target: float = clamp(0.1 + (float(s.tech.get("industry", 0.0)) + float(s.tech.get("commerce", 0.0))) * 0.004, 0.0, 0.55)
	s.inst["wage"] = lerp(float(s.inst.get("wage", 0.0)), wage_target, 0.06)
	var coop_target: float = 0.0
	if s.knows("cooperatives"):
		coop_target = clamp(0.12 + float(s.inst.get("participation", 0.0)) * 0.35, 0.0, 0.45)
	s.inst["coop"] = lerp(float(s.inst.get("coop", 0.0)), coop_target, 0.05)
	# 归一（允许不归一到 1：剩余视为家庭/混合劳动）
	var total_labor: float = float(s.inst.get("forced", 0.0)) + float(s.inst.get("bonded", 0.0)) + float(s.inst.get("wage", 0.0)) + float(s.inst.get("coop", 0.0))
	if total_labor > 1.0:
		for k in ["forced", "bonded", "wage", "coop"]:
			s.inst[k] = float(s.inst[k]) / total_labor

	# ---- 国家能力 ----
	var stc_gain := 0.0
	stc_gain += 0.0035 * (1.0 + float(fx.get("state", 0.0)))
	if s.knows("writing"):
		stc_gain *= 1.35
	if s.knows("mathematics"):
		stc_gain *= 1.2
	# 财政：入不敷出会侵蚀国家能力
	var state_income: float = float(d.get("state_income", 0.0))
	var state_cost: float = float(s.population) * 0.004 + float(s.inst.get("public_service", 0.0)) * float(s.population) * 0.006
	d["state_fiscal"] = state_income - state_cost
	if state_income < state_cost:
		stc_gain -= 0.004
	s.inst["state_capacity"] = clamp(float(s.inst.get("state_capacity", 0.02)) + stc_gain, 0.0, GameConfig.STATE_CAPACITY_MAX)

	# ---- 税率自动调整 ----
	var tax: float = float(s.inst.get("tax_rate", 0.18))
	if d.get("state_fiscal", 0.0) < 0.0:
		tax = clamp(tax + 0.006, 0.05, 0.45)
	var unrest: float = float(d.get("unrest", 0.0))
	if unrest > 0.45 and float(s.inst.get("participation", 0.0)) > 0.12:
		tax = clamp(tax - 0.008, 0.05, 0.45)
	s.inst["tax_rate"] = tax
	d["state_income"] = (float(d.get("craft_output", 0.0)) + float(d.get("trade_income", 0.0)) + max(0.0, float(d.get("food_prod", 0.0)) - float(d.get("food_need", 0.0)))) * tax

	# ---- 公共服务 ----
	var ps_target: float = clamp(float(s.inst.get("state_capacity", 0.0)) * (0.5 + float(s.inst.get("education", 0.0))) + float(fx.get("public_service", 0.0)), 0.0, 0.9)
	if s.form == "socialist":
		ps_target = clamp(ps_target + 0.15, 0.0, 0.95)
	s.inst["public_service"] = lerp(float(s.inst.get("public_service", 0.0)), ps_target, 0.05)

	# ---- 教育 ----
	var ed_target: float = 0.05 + float(fx.get("education", 0.0)) * 3.0
	if s.knows("printing"):
		ed_target += 0.12
	if s.knows("mass_education"):
		ed_target += 0.25
	if s.knows("writing"):
		ed_target += 0.06
	s.inst["education"] = lerp(float(s.inst.get("education", 0.0)), clamp(ed_target, 0.0, 0.95), 0.06)

	# ---- 参与与信任 ----
	var part_target: float = 0.05
	if s.knows("printing"):
		part_target += 0.1
	if s.knows("mass_education"):
		part_target += 0.15
	part_target += float(fx.get("participation", 0.0)) * 4.0
	if s.has_building("assembly"):
		part_target += 0.08
	s.inst["participation"] = lerp(float(s.inst.get("participation", 0.05)), clamp(part_target, 0.0, 0.9), 0.05)
	var trust: float = float(s.inst.get("trust", 0.35))
	trust += 0.002 * float(s.inst.get("public_service", 0.0))
	if s.famine_active:
		trust -= 0.01
	if d.get("intake_ratio", 1.0) < 0.8:
		trust -= 0.004
	s.inst["trust"] = clamp(trust, 0.05, 0.95)

	# ---- 稳定度 ----
	var stability := 0.55
	stability += float(s.inst.get("trust", 0.0)) * 0.3
	stability -= float(d.get("unrest", 0.0)) * 0.5
	stability += float(fx.get("stability", 0.0))
	stability -= float(d.get("pollution", 0.0)) * 0.2
	d["stability"] = clamp(stability, 0.05, 1.0)

func _count(s, key: String) -> int:
	var n := 0
	for b in s.buildings:
		if b.get("done", false) and str(b.get("key", "")) == key:
			n += 1
	return n
