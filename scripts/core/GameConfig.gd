class_name GameConfig
## Society Lab 全局配置中心 —— 所有可调参数集中于此。
## 修改本文件即可调整模拟行为，禁止把魔法数字散落到其他脚本。

# ========================= 地图 =========================
const MAP_SIZE := 48            # 48x48 等距网格
const TILE_W := 64.0            # 图块像素宽
const TILE_H := 32.0            # 图块像素高

# 地形枚举
const T_GRASS := 0
const T_FOREST := 1
const T_WATER := 2
const T_ROCK := 3
const T_MOUNTAIN := 4
const T_FERTILE := 5
const T_SAND := 6

## 地形静态属性：可否通行 / 基础肥力 / 名称 / 是否可建设
const TERRAIN_INFO := {
	T_GRASS: {"name": "草地", "walk": true, "build": true, "fert": 0.30, "color": "#80BA5C"},
	T_FOREST: {"name": "森林", "walk": true, "build": true, "fert": 0.35, "color": "#5C9448"},
	T_WATER: {"name": "水域", "walk": false, "build": false, "fert": 0.0, "color": "#4C9ED6"},
	T_ROCK: {"name": "石地", "walk": true, "build": true, "fert": 0.10, "color": "#AAA296"},
	T_MOUNTAIN: {"name": "山地", "walk": false, "build": false, "fert": 0.05, "color": "#988E82"},
	T_FERTILE: {"name": "沃土", "walk": true, "build": true, "fert": 0.90, "color": "#C69E5C"},
	T_SAND: {"name": "沙地", "walk": true, "build": true, "fert": 0.08, "color": "#EAD8A2"},
}

# 资源点类型（叠加在地形之上）：0 无 1 铁矿 2 金矿 3 优质石料
const RES_NONE := 0
const RES_IRON := 1
const RES_GOLD := 2
const RES_STONE := 3
const RESOURCE_INFO := {
	RES_IRON: {"name": "铁矿", "icon": "props/ore_iron"},
	RES_GOLD: {"name": "金矿", "icon": "props/ore_gold"},
	RES_STONE: {"name": "石料", "icon": "props/rock_0"},
}

# ========================= 人口与生存 =========================
const WORKER_RATIO := 0.55          # 劳动年龄人口比例
const FOOD_PER_CAPITA := 1.0        # 人均年粮食需求（单位）
const BASE_BIRTH_RATE := 0.036      # 基础出生率
const BASE_DEATH_RATE := 0.028      # 基础死亡率
const HUNGER_DEATH_MULT := 3.2      # 饥饿时死亡倍率（上限）
const FAMINE_DEFICIT_YEARS := 2     # 连续不足年数 → 饥荒事件
const FAMINE_TRIGGER_RATIO := 0.82  # 摄入/需求 低于此值累计饥饿
const MIGRATION_PRESSURE := 0.55    # 不满阈值触发移民倾向
const MAX_POP_PER_SETTLEMENT := 6000
const MIN_FOUNDING_POP := 26        # 分裂新聚落所需人口

# ========================= 农业与经济 =========================
const BASE_FARM_YIELD := 15.0       # 每块田在肥力1.0/技术0/劳动力充足时的产出
const FARM_WORKERS := 1.6           # 每块田理想劳力
const GATHER_YIELD := 3.0           # 采集/狩猎人均产出（无农业时）
const WOOD_PER_FOREST_TILE := 3.0   # 每森林格年伐木（有劳力时）
const STONE_PER_ROCK_TILE := 2.6
const METAL_PER_ORE_TILE := 1.8
const STORAGE_PER_GRANARY := 500.0
const STORAGE_BASE := 260.0         # 无谷仓时的储量上限
const SPOILAGE_BASE := 0.06         # 年损耗率
const TRADE_BASE_INCOME := 0.0      # 贸易收入基数（按市场发育结算）
const HOUSING_BOOTH_MULT := 0.35    # 无住房惩罚：超容人口对增长率的压力

# ========================= 技术研究 =========================
const RESEARCH_BASE := 0.70        # 基础年研究点（温饱时）
const RESEARCH_SURPLUS_MULT := 2.2  # 富余消费对研究的放大上限
const TECH_DIFFUSION_RATE := 0.25   # 相邻聚落技术追赶系数/年
const TECH_LEVEL_MAX := 100.0

# ========================= 制度与社会 =========================
const TAX_RATE_DEFAULT := 0.18
const REFORM_TRUST_GAIN := 0.08
const REVOLT_POP_LOSS := 0.16       # 革命暴力损失人口比例
const WAR_PRESSURE_BASE := 0.04     # 相邻聚落年冲突概率基数
const UNREST_TO_ACTION := 0.62      # 动荡→集体行动阈值
const GINI_WARNING := 0.55
const STATE_CAPACITY_MAX := 1.0

# ========================= 神力 =========================
const FAITH_START := 30.0
const FAITH_REGEN := 2.0            # 有限干预模式每年回复
const MODE_FREE := 0                # 自由上帝模式
const MODE_LIMITED := 1             # 有限干预模式

# ========================= 界面/通用 =========================
const YEAR_SECONDS := [0.0, 2.0, 1.0, 0.45, 0.18]  # 暂停/1x/2x/3x/4x 每年秒数
const AUTOSAVE_EVERY := 25          # 年
const SNAPSHOT_EVERY := 20          # 历史快照间隔（年）

static func terrain_name(t: int) -> String:
	return (TERRAIN_INFO.get(t, {}) as Dictionary).get("name", "未知")

static func terrain_walkable(t: int) -> bool:
	return bool((TERRAIN_INFO.get(t, {}) as Dictionary).get("walk", false))

static func terrain_buildable(t: int) -> bool:
	return bool((TERRAIN_INFO.get(t, {}) as Dictionary).get("build", false))

static func terrain_fert(t: int) -> float:
	return float((TERRAIN_INFO.get(t, {}) as Dictionary).get("fert", 0.0))

## 大数中文格式化：12345 -> 1.2万
static func fmt_num(x: float) -> String:
	if x >= 10000.0:
		var w := x / 10000.0
		if w >= 100.0:
			return "%d万" % int(w)
		return "%.1f万" % w
	if x >= 1000.0:
		return "%d" % int(round(x))
	if x >= 100.0:
		return "%.0f" % x
	return "%.1f" % x

static func fmt_pct(x: float) -> String:
	return "%d%%" % int(round(clamp(x, 0.0, 10.0) * 100.0))

static func fmt_year(y: int) -> String:
	return "第%d年" % y

## 颜色工具
static func hex(c: String) -> Color:
	return Color.from_string(c, Color.WHITE)
