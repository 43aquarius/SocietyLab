## 聚落状态：一个共同体的全部经济/社会/制度数据。
## 模拟细节由各 System 逐年更新；本类只负责存取、派生量与序列化。
extends RefCounted

var id: int = 0
var base_name: String = "无名"
var stage: int = 0
var cx: int = 0
var cy: int = 0
var claim_radius: int = 3

# ---- 人口与生计 ----
var population: int = 20
var food_store: float = 60.0
var wood: float = 20.0
var stone: float = 0.0
var metal: float = 0.0
var hunger_years: int = 0          # 连续摄入不足年数
var famine_active: bool = false
var migration_timer: int = 0

# ---- 建筑：Array[Dictionary]{key,tx,ty,progress,done,year_built} ----
var buildings: Array = []

# ---- 技术 ----
var tech: Dictionary = {}          # domain -> level(0..100)
var discovered: Array = []         # 已发现技术 id
var research_buffer: float = 0.0   # 一次性研究加成池（神力注入）

# ---- 制度与政治 ----
var inst: Dictionary = {
	"communal": 1.0, "private": 0.0, "state": 0.0,      # 生产资料所有制构成
	"forced": 0.0, "bonded": 0.0, "wage": 0.0, "coop": 0.0,  # 劳动关系构成
	"market_dev": 0.0, "state_capacity": 0.02, "public_service": 0.0,
	"tax_rate": GameConfig.TAX_RATE_DEFAULT, "land_concentration": 0.0,
	"education": 0.0, "participation": 0.05, "trust": 0.35,
	"specialization": 0.0, "planned_share": 0.0, "warlike": 0.1,
}

# ---- 社会群体 ----
var groups: Dictionary = {
	"laborer": {"size": 0.82, "wealth": 0.30, "org": 0.05, "grievance": 0.10},
	"elite": {"size": 0.06, "wealth": 0.42, "org": 0.10, "grievance": 0.05},
	"merchant": {"size": 0.06, "wealth": 0.16, "org": 0.05, "grievance": 0.08},
	"admin": {"size": 0.06, "wealth": 0.12, "org": 0.15, "grievance": 0.05},
}

# ---- 派生量（每年由系统重算，供分类器/UI/事件读取） ----
var derived: Dictionary = {
	"food_prod": 0.0, "food_need": 0.0, "intake_ratio": 1.0, "surplus_ratio": 0.0,
	"productivity": 1.0, "gini": 0.25, "health": 0.35, "unrest": 0.0,
	"stability": 0.6, "defense": 0.1, "pollution": 0.0, "resource_pressure": 0.0,
	"housing_cap": 0, "farm_count": 0, "craft_output": 0.0, "trade_income": 0.0,
	"wage_level": 0.0, "elite_power": 0.2, "pop_growth": 0.0, "starving": 0.0,
}

# ---- 形态识别结果 ----
var form: String = "primitive"
var form_scores: Dictionary = {}
var form_years: int = 0            # 当前形态持续年数

# ---- 杂项 ----
var event_cooldowns: Dictionary = {}
var last_divine_year: int = -999
var divine_marks: Array = []       # 最近神力痕迹（决定事件 player_involved）
var stat_log: Array = []           # 每年快照（观察者图表）
var _claim_cache: Array = []
var _claim_radius_cached: int = -1

# ==================== 领地 ====================
func claims_tile(x: int, y: int) -> bool:
	var dx: int = abs(x - cx)
	var dy: int = abs(y - cy)
	return dx <= claim_radius and dy <= claim_radius

func claimed_tiles() -> Array:
	if _claim_radius_cached == claim_radius and not _claim_cache.is_empty():
		return _claim_cache
	_claim_cache = []
	_claim_radius_cached = claim_radius
	for x in range(cx - claim_radius, cx + claim_radius + 1):
		for y in range(cy - claim_radius, cy + claim_radius + 1):
			_claim_cache.append(Vector2i(x, y))
	return _claim_cache

func expand_claim() -> void:
	claim_radius = int(min(claim_radius + 1, 8))
	_claim_cache = []
	_claim_radius_cached = -1

func has_building(key: String) -> bool:
	for b in buildings:
		if b.get("key", "") == key and b.get("done", false):
			return true
	return false

func count_building(key: String) -> int:
	var n := 0
	for b in buildings:
		if b.get("key", "") == key and b.get("done", false):
			n += 1
	return n

func done_buildings() -> Array:
	var out: Array = []
	for b in buildings:
		if b.get("done", false):
			out.append(b)
	return out

func building_at(x: int, y: int):
	for b in buildings:
		if int(b.get("tx", -1)) == x and int(b.get("ty", -1)) == y:
			return b
	return null

func tech_level(domain: String) -> float:
	return float(tech.get(domain, 0.0))

func knows(tech_id: String) -> bool:
	return discovered.has(tech_id)

func display_name() -> String:
	return Names.display_name(base_name, stage)

func stage_name() -> String:
	return (Database.STAGES.get(stage, {}) as Dictionary).get("name", "营地")

func set_form(new_form: String) -> bool:
	if new_form != form:
		form = new_form
		form_years = 0
		return true
	form_years += 1
	return false

# ==================== 序列化 ====================
func to_dict() -> Dictionary:
	return {
		"id": id, "base_name": base_name, "stage": stage, "cx": cx, "cy": cy,
		"claim_radius": claim_radius, "population": population,
		"food_store": food_store, "wood": wood, "stone": stone, "metal": metal,
		"hunger_years": hunger_years, "famine_active": famine_active,
		"migration_timer": migration_timer,
		"buildings": buildings.duplicate(true),
		"tech": tech.duplicate(true), "discovered": discovered.duplicate(true),
		"research_buffer": research_buffer,
		"inst": inst.duplicate(true), "groups": groups.duplicate(true),
		"derived": derived.duplicate(true),
		"form": form, "form_scores": form_scores.duplicate(true), "form_years": form_years,
		"event_cooldowns": event_cooldowns.duplicate(true),
		"last_divine_year": last_divine_year,
		"divine_marks": divine_marks.duplicate(true),
		"stat_log": stat_log.duplicate(true),
	}

static func from_dict(d: Dictionary) -> Settlement:
	var SettlementScript = load("res://scripts/sim/Settlement.gd")
	var s: Settlement = SettlementScript.new()
	s.id = int(d.get("id", 0))
	s.base_name = str(d.get("base_name", ""))
	s.stage = int(d.get("stage", 0))
	s.cx = int(d.get("cx", 0))
	s.cy = int(d.get("cy", 0))
	s.claim_radius = int(d.get("claim_radius", 3))
	s.population = int(d.get("population", 20))
	s.food_store = float(d.get("food_store", 0.0))
	s.wood = float(d.get("wood", 0.0))
	s.stone = float(d.get("stone", 0.0))
	s.metal = float(d.get("metal", 0.0))
	s.hunger_years = int(d.get("hunger_years", 0))
	s.famine_active = bool(d.get("famine_active", false))
	s.migration_timer = int(d.get("migration_timer", 0))
	s.buildings = d.get("buildings", [])
	s.tech = d.get("tech", {})
	s.discovered = []
	for t in d.get("discovered", []):
		s.discovered.append(str(t))
	s.research_buffer = float(d.get("research_buffer", 0.0))
	s.inst = d.get("inst", s.inst)
	s.groups = d.get("groups", s.groups)
	s.derived = d.get("derived", s.derived)
	s.form = str(d.get("form", "primitive"))
	s.form_scores = d.get("form_scores", {})
	s.form_years = int(d.get("form_years", 0))
	s.event_cooldowns = d.get("event_cooldowns", {})
	s.last_divine_year = int(d.get("last_divine_year", -999))
	s.divine_marks = d.get("divine_marks", [])
	s.stat_log = d.get("stat_log", [])
	return s
