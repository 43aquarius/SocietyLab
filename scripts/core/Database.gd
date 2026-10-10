class_name Database
## 静态数据表：建筑 / 技术 / 社会形态 / 群体 / 阶段 / 神力
## 所有条目使用 String id 索引，图标键对应 assets/manifest.json。

# ========================= 建筑 =========================
## 通用字段：
##   name 名称 / cat 类别 / cap 住房容量 / cost 建造成本 {wood,stone,metal}
##   years 建造年数 / req 前置（tech id 或 pop 门槛）/ fx 模拟效果标签
const BUILDINGS := {
	"camp_tent": {"name": "营地帐篷", "cat": "housing", "cap": 10, "cost": {}, "years": 1, "req": {}, "fx": {}},
	"hut": {"name": "茅屋", "cat": "housing", "cap": 18, "cost": {"wood": 6}, "years": 1, "req": {}, "fx": {}},
	"house_wood": {"name": "木屋", "cat": "housing", "cap": 34, "cost": {"wood": 14}, "years": 1, "req": {"tech": "knapped_tools"}, "fx": {}},
	"house_brick": {"name": "砖房", "cat": "housing", "cap": 70, "cost": {"wood": 10, "stone": 16}, "years": 2, "req": {"tech": "masonry"}, "fx": {}},
	"house_town": {"name": "联排宅", "cat": "housing", "cap": 150, "cost": {"wood": 20, "stone": 30, "metal": 6}, "years": 2, "req": {"tech": "masonry", "commerce": 25}, "fx": {}},
	"apartment": {"name": "公寓楼", "cat": "housing", "cap": 520, "cost": {"stone": 60, "metal": 30}, "years": 3, "req": {"tech": "electricity"}, "fx": {}},
	"farm": {"name": "农田", "cat": "farm", "cap": 0, "cost": {}, "years": 1, "req": {"tech": "early_agri"}, "fx": {}},
	"farm_irrigated": {"name": "灌溉田", "cat": "farm", "cap": 0, "cost": {"wood": 4}, "years": 1, "req": {"tech": "irrigation"}, "fx": {}},
	"farm_modern": {"name": "现代农业区", "cat": "farm", "cap": 0, "cost": {"wood": 10, "metal": 8}, "years": 2, "req": {"tech": "electricity"}, "fx": {}},
	"granary": {"name": "谷仓", "cat": "storage", "cap": 0, "cost": {"wood": 12}, "years": 1, "req": {"tech": "pottery"}, "fx": {"food_cap": 500, "spoil_reduce": 0.3}},
	"warehouse": {"name": "货栈", "cat": "storage", "cap": 0, "cost": {"wood": 18, "stone": 8}, "years": 1, "req": {"tech": "currency"}, "fx": {"res_cap": 400, "trade": 0.05}},
	"well": {"name": "水井", "cat": "water", "cap": 0, "cost": {"stone": 10}, "years": 1, "req": {}, "fx": {"health": 0.03}},
	"workshop": {"name": "工坊", "cat": "craft", "cap": 0, "cost": {"wood": 16, "stone": 6}, "years": 1, "req": {"tech": "knapped_tools"}, "fx": {"craft": 0.18, "tools": 0.05}},
	"market": {"name": "集市", "cat": "trade", "cap": 0, "cost": {"wood": 14}, "years": 1, "req": {"pop": 120, "tech": "currency"}, "fx": {"market": 0.08, "trade": 0.08}},
	"admin_hall": {"name": "议事厅", "cat": "admin", "cap": 0, "cost": {"stone": 30, "wood": 10}, "years": 2, "req": {"pop": 220, "tech": "writing"}, "fx": {"state": 0.06, "tax_eff": 0.05}},
	"manor": {"name": "庄园府邸", "cat": "admin", "cap": 6, "cost": {"stone": 40, "wood": 20}, "years": 2, "req": {"pop": 260, "tech": "masonry"}, "fx": {"state": 0.05, "elite_power": 0.10}},
	"castle": {"name": "城堡", "cat": "defense", "cap": 30, "cost": {"stone": 80, "wood": 30}, "years": 3, "req": {"pop": 400, "tech": "masonry"}, "fx": {"defense": 0.30, "stability": 0.05}},
	"wall_tower": {"name": "哨塔", "cat": "defense", "cap": 8, "cost": {"stone": 25}, "years": 1, "req": {"tech": "masonry"}, "fx": {"defense": 0.15}},
	"temple": {"name": "神庙", "cat": "public", "cap": 0, "cost": {"stone": 36, "wood": 12}, "years": 2, "req": {"pop": 300, "tech": "writing"}, "fx": {"trust": 0.05, "stability": 0.04}},
	"assembly": {"name": "公共会堂", "cat": "public", "cap": 0, "cost": {"stone": 40, "wood": 16}, "years": 2, "req": {"tech": "printing"}, "fx": {"participation": 0.08, "trust": 0.03}},
	"school": {"name": "学堂", "cat": "edu", "cap": 0, "cost": {"wood": 20, "stone": 10}, "years": 1, "req": {"tech": "writing"}, "fx": {"education": 0.08, "research": 0.10}},
	"hospital": {"name": "医馆", "cat": "health", "cap": 0, "cost": {"stone": 30, "wood": 10}, "years": 1, "req": {"tech": "hygiene"}, "fx": {"health": 0.08, "death_mult": 0.92}},
	"factory": {"name": "工厂", "cat": "industry", "cap": 0, "cost": {"stone": 50, "wood": 30, "metal": 25}, "years": 3, "req": {"tech": "steam_engine"}, "fx": {"industry": 0.45, "pollution": 0.05}},
	"cooperative": {"name": "合作社", "cat": "public", "cap": 0, "cost": {"wood": 22, "stone": 12}, "years": 1, "req": {"tech": "cooperatives"}, "fx": {"coop_share": 0.06, "public_service": 0.05}},
}

# ========================= 技术 =========================
## domain: agriculture / tools / construction / health / organization / commerce / industry
## level: 需要的领域累计值; tech: 前置技术; res: 需要的资源点类型
const TECHS := {
	"knapped_tools": {"name": "石器打磨", "domain": "tools", "level": 8, "pre": {}, "res": 0,
		"desc": "打磨石器让劳作效率明显提升。"},
	"pottery": {"name": "陶器", "domain": "agriculture", "level": 10, "pre": {}, "res": 0,
		"desc": "陶罐让存粮不再轻易腐坏。"},
	"early_agri": {"name": "农业起源", "domain": "agriculture", "level": 15, "pre": {}, "res": 0,
		"desc": "从采集走向耕种，粮食第一次可以被计划。"},
	"irrigation": {"name": "灌溉", "domain": "agriculture", "level": 30, "pre": {"construction": 12}, "res": 0,
		"desc": "沟渠把水送往田地，收成不再全凭天意。"},
	"writing": {"name": "文字", "domain": "organization", "level": 25, "pre": {}, "res": 0,
		"desc": "记录让经验跨越生死相传。"},
	"currency": {"name": "货币", "domain": "commerce", "level": 30, "pre": {}, "res": 0,
		"desc": "统一的交换媒介催生了集市。"},
	"bronze": {"name": "青铜冶炼", "domain": "tools", "level": 35, "pre": {}, "res": 1,
		"desc": "金属工具与武器出现（需要接触矿藏）。"},
	"masonry": {"name": "建筑学", "domain": "construction", "level": 40, "pre": {}, "res": 0,
		"desc": "砖石让大型工程成为可能。"},
	"iron": {"name": "铁器", "domain": "tools", "level": 55, "pre": {}, "res": 1,
		"desc": "更坚硬的工具进一步解放生产力。"},
	"crop_rotation": {"name": "轮作与肥料", "domain": "agriculture", "level": 55, "pre": {}, "res": 0,
		"desc": "地力得以恢复，田的产出显著提高。"},
	"hygiene": {"name": "卫生与医道", "domain": "health", "level": 35, "pre": {}, "res": 0,
		"desc": "清洁的水与隔离降低了疫病。"},
	"mathematics": {"name": "数学", "domain": "organization", "level": 45, "pre": {}, "res": 0,
		"desc": "丈量与记账让复杂组织运转。"},
	"guilds": {"name": "行会与商帮", "domain": "commerce", "level": 45, "pre": {}, "res": 0,
		"desc": "商人们组织起来保护共同利益。"},
	"printing": {"name": "印刷术", "domain": "organization", "level": 55, "pre": {"commerce": 25}, "res": 0,
		"desc": "文字不再昂贵，思想开始大规模传播。"},
	"medicine": {"name": "医学体系", "domain": "health", "level": 65, "pre": {}, "res": 0,
		"desc": "系统医学显著延长了寿命。"},
	"steam_engine": {"name": "蒸汽机", "domain": "industry", "level": 45, "pre": {"construction": 50}, "res": 1,
		"desc": "机器开始替代人力，工业时代到来（需要矿藏）。"},
	"roads": {"name": "道路网络", "domain": "commerce", "level": 55, "pre": {"construction": 35}, "res": 0,
		"desc": "道路延伸到哪里，贸易就到哪里。"},
	"cooperatives": {"name": "合作组织", "domain": "organization", "level": 60, "pre": {}, "res": 0,
		"desc": "劳动者学会以合作方式组织生产。"},
	"sanitation": {"name": "现代给排水", "domain": "health", "level": 55, "pre": {"construction": 45}, "res": 0,
		"desc": "清洁城市让疫病大幅退却。"},
	"mass_education": {"name": "大众教育", "domain": "organization", "level": 70, "pre": {}, "res": 0,
		"desc": "识字的大众改变社会的可能性。"},
	"banking": {"name": "金融与信贷", "domain": "commerce", "level": 65, "pre": {}, "res": 0,
		"desc": "资本加速积累，波动也随之放大。"},
	"electricity": {"name": "电力", "domain": "industry", "level": 75, "pre": {"construction": 60}, "res": 1,
		"desc": "黑夜被点亮，新的生产方式出现。"},
}

const TECH_DOMAINS := {
	"agriculture": "农耕",
	"tools": "工具",
	"construction": "营造",
	"health": "医卫",
	"organization": "组织",
	"commerce": "商贸",
	"industry": "工业",
}

# ========================= 社会形态 =========================
const FORMS := {
	"primitive": {"name": "原始社会", "icon": "form_primitive", "color": "#A89F93",
		"desc": "小规模共同体，共同劳动，几乎没有剩余。"},
	"slave": {"name": "奴隶制特征社会", "icon": "form_slave", "color": "#C66C5A",
		"desc": "强制劳动支撑着剩余生产与统治集团的财富。"},
	"feudal": {"name": "封建社会", "icon": "form_feudal", "color": "#9470AA",
		"desc": "土地与依附关系决定了谁劳动、谁收租。"},
	"capitalist": {"name": "资本主义社会", "icon": "form_capital", "color": "#6FA8DC",
		"desc": "资本积累与雇佣劳动主导生产。"},
	"socialist": {"name": "社会主义特征社会", "icon": "form_social", "color": "#D66058",
		"desc": "公有与合作组织在资源配置中占据重要位置。"},
	"mixed": {"name": "过渡/混合形态", "icon": "form_mixed", "color": "#96A2B4",
		"desc": "多种制度要素并存，正处在转折之中。"},
}

# ========================= 社会群体 =========================
const GROUPS := {
	"laborer": {"name": "劳动者", "icon": "res_pop", "color": "#A67A4E",
		"desc": "直接从事生产的人口。"},
	"elite": {"name": "权贵阶层", "icon": "res_coin", "color": "#945EA8",
		"desc": "凭借土地或资本占有取得收入的阶层。"},
	"merchant": {"name": "商人", "icon": "ev_trade", "color": "#E0B054",
		"desc": "以交换与流通牟利，推动市场发育。"},
	"admin": {"name": "官吏与组织者", "icon": "res_know", "color": "#6C8AB4",
		"desc": "维系公共机构运转的人。"},
}

# ========================= 聚落阶段 =========================
const STAGES := {
	0: {"name": "营地", "suffix": "营地", "pop": 0, "needs": {}},
	1: {"name": "村落", "suffix": "村", "pop": 60, "needs": {"tech": "early_agri"}},
	2: {"name": "镇", "suffix": "镇", "pop": 200, "needs": {"buildings": ["granary", "market"]}},
	3: {"name": "城市", "suffix": "城", "pop": 600, "needs": {"buildings": ["admin_hall"]}},
	4: {"name": "都会", "suffix": "都会", "pop": 2000, "needs": {"tech": "steam_engine"}},
}

# ========================= 神力 =========================
const POWERS := {
	"forest": {"name": "森林之触", "cat": "地形", "cost": 5, "icon": "pow_forest",
		"desc": "在草地上种下森林（+木材、周围土地更肥）。"},
	"fertile": {"name": "沃土化", "cat": "地形", "cost": 6, "icon": "pow_fertile",
		"desc": "把一块草地变为可耕的沃土。"},
	"water": {"name": "清泉涌现", "cat": "地形", "cost": 8, "icon": "pow_water",
		"desc": "在地面造出水源，相邻土地变得湿润肥沃。"},
	"ore": {"name": "矿脉显现", "cat": "地形", "cost": 10, "icon": "pow_ore",
		"desc": "在山地或石地显出矿脉（铁或金）。"},
	"rain": {"name": "甘霖", "cat": "天气", "cost": 6, "icon": "pow_rain",
		"desc": "为一片区域带来数年风调雨顺（3x3 范围）。"},
	"drought": {"name": "酷旱", "cat": "天气", "cost": 4, "icon": "pow_drought",
		"desc": "使一片区域陷入数年干旱（3x3 范围）。"},
	"bless": {"name": "丰饶祝福", "cat": "赐福", "cost": 10, "icon": "pow_bless",
		"desc": "选定聚落数年内产出提升（范围有限、有期限）。"},
	"enlight": {"name": "智慧之光", "cat": "启蒙", "cost": 12, "icon": "pow_enlight",
		"desc": "向一个聚落注入知识火花，加快其研究。"},
	"idea": {"name": "思想火种", "cat": "启蒙", "cost": 9, "icon": "pow_idea",
		"desc": "传播新思想：提升群体组织力与参与度，为变革积蓄力量。"},
}

# ========================= 事件类别 =========================
const EVENT_CATS := {
	"harvest": {"name": "丰歉", "icon": "ev_harvest"},
	"famine": {"name": "饥荒", "icon": "ev_famine"},
	"disease": {"name": "疫病", "icon": "ev_disease"},
	"discovery": {"name": "技术", "icon": "ev_discovery"},
	"migration": {"name": "迁徙", "icon": "ev_migration"},
	"trade": {"name": "商贸", "icon": "ev_trade"},
	"conflict": {"name": "冲突", "icon": "ev_conflict"},
	"reform": {"name": "变革", "icon": "ev_reform"},
	"war": {"name": "战争", "icon": "ev_war"},
	"idea": {"name": "思想", "icon": "ev_idea"},
	"boom": {"name": "兴衰", "icon": "ev_boom"},
	"golden": {"name": "治世", "icon": "ev_golden"},
	"degrade": {"name": "环境", "icon": "ev_degrade"},
	"city": {"name": "聚落", "icon": "ev_city"},
	"inst": {"name": "制度", "icon": "ev_inst"},
}

static func building_name(id: String) -> String:
	return (BUILDINGS.get(id, {}) as Dictionary).get("name", id)

static func tech_name(id: String) -> String:
	return (TECHS.get(id, {}) as Dictionary).get("name", id)

static func form_name(id: String) -> String:
	return (FORMS.get(id, {}) as Dictionary).get("name", "未知形态")

static func group_name(id: String) -> String:
	return (GROUPS.get(id, {}) as Dictionary).get("name", id)
