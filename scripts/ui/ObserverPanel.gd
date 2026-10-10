## 观察者面板：曲线 / 结构 / 形态时间线 / 数据表 / 模型假设。
## 高级工具默认隐藏，不影响普通游玩。
extends Control

var game
var tab := 0
var tab_bar: HBoxContainer
var content: Control
var chart_holder: VBoxContainer
var series_select: HBoxContainer

const TABS := ["总览曲线", "社会结构", "形态时间线", "数据总表", "模型假设"]

func _init(p_game) -> void:
	game = p_game

func build() -> Control:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			close()
		)
	add_child(dim)
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.offset_left = -500
	pc.offset_right = 500
	pc.offset_top = -310
	pc.offset_bottom = 310
	add_child(pc)
	UITheme.panel_style(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var head := HBoxContainer.new()
	head.add_child(UITheme.label("观察者模式", 24, UITheme.COL.accent, "title"))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(sp)
	var close_b := UITheme.icon_button("ui_close", "关闭（O）", Callable(self, "close"), 30)
	head.add_child(close_b)
	v.add_child(head)
	tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 4)
	v.add_child(tab_bar)
	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(content)
	_refresh_tabs()
	_show_tab()
	return self

func _refresh_tabs() -> void:
	for c in tab_bar.get_children():
		tab_bar.remove_child(c)
		c.queue_free()
	for i in TABS.size():
		var b := Button.new()
		b.text = TABS[i]
		b.toggle_mode = true
		b.button_pressed = tab == i
		b.pressed.connect(func():
			tab = i
			_refresh_tabs()
			_show_tab()
			)
		tab_bar.add_child(b)

func _clear_content() -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()

func _show_tab() -> void:
	_clear_content()
	match tab:
		0: _tab_charts()
		1: _tab_structure()
		2: _tab_timeline()
		3: _tab_table()
		4: _tab_assumptions()

# ---------- 曲线 ----------
func _tab_charts() -> void:
	var sv := ScrollContainer.new()
	sv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(sv)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.add_child(box)
	var stats: Array = game.world.stats
	if stats.size() < 2:
		box.add_child(UITheme.label("数据不足（至少推进 2 年）", 14, UITheme.COL.text_dim))
		return
	var defs := [
		["人口", "pop", UITheme.COL.blue, "人"],
		["粮食存量", "food", Color(0.9, 0.75, 0.4), "单位"],
		["生产与贸易", "prod", Color(0.55, 0.8, 0.5), "单位/年"],
		["平均技术", "tech", UITheme.COL.accent, "等级"],
		["贫富差距（基尼）", "gini", UITheme.COL.danger, "0-1"],
		["平均动荡", "unrest", Color(1.0, 0.6, 0.4), "0-1"],
	]
	for d in defs:
		box.add_child(UITheme.label("%s（%s）" % [d[0], d[3]], 15, d[2]))
		var ch := Chart.new()
		ch.custom_minimum_size = Vector2(940, 130)
		ch.show_legend = false
		var pts: Array = []
		for st in stats:
			pts.append({"x": int(st.get("year", 0)), "y": float(st.get(d[1], 0.0))})
		ch.set_series([{"name": d[0], "color": d[2], "points": pts, "seed": randf() * 10.0}])
		box.add_child(ch)

# ---------- 结构 ----------
func _tab_structure() -> void:
	var sv := ScrollContainer.new()
	sv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(sv)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.add_child(box)
	for s in game.world.settlements:
		box.add_child(UITheme.label("%s —— 当前结构" % s.display_name(), 17, UITheme.COL.accent, "title"))
		# 所有制堆叠条
		box.add_child(UITheme.label("生产资料所有制", 14, UITheme.COL.text))
		_stack_bar(box, [
			["公有/共同体", float(s.inst.get("communal", 0.0)), "#A89F93"],
			["私有", float(s.inst.get("private", 0.0)), "#6FA8DC"],
			["国有", float(s.inst.get("state", 0.0)), "#D66058"],
		])
		box.add_child(UITheme.label("劳动关系构成", 14, UITheme.COL.text))
		_stack_bar(box, [
			["强制劳动", float(s.inst.get("forced", 0.0)), "#C66C5A"],
			["依附劳动", float(s.inst.get("bonded", 0.0)), "#9470AA"],
			["雇佣劳动", float(s.inst.get("wage", 0.0)), "#6FA8DC"],
			["合作劳动", float(s.inst.get("coop", 0.0)), "#D66058"],
		])
		box.add_child(UITheme.label("群体财富份额", 14, UITheme.COL.text))
		_stack_bar(box, [
			["劳动者", float(s.groups["laborer"].get("wealth", 0.0)), "#A67A4E"],
			["权贵", float(s.groups["elite"].get("wealth", 0.0)), "#945EA8"],
			["商人", float(s.groups["merchant"].get("wealth", 0.0)), "#E0B054"],
			["官吏", float(s.groups["admin"].get("wealth", 0.0)), "#6C8AB4"],
		])
		# 基尼曲线
		var ch := Chart.new()
		ch.custom_minimum_size = Vector2(940, 120)
		ch.show_legend = false
		var pts: Array = []
		for st in s.stat_log:
			pts.append({"x": int(st.get("year", 0)), "y": float(st.get("gini", 0.0))})
		box.add_child(UITheme.label("基尼系数轨迹（警戒线 0.55）", 13, UITheme.COL.text_dim))
		ch.set_series([{"name": "基尼", "color": UITheme.COL.danger, "points": pts, "seed": 3.0}])
		box.add_child(ch)
		box.add_child(UITheme.sep())

func _stack_bar(parent: Control, rows: Array) -> void:
	var hb := HBoxContainer.new()
	hb.custom_minimum_size = Vector2(940, 22)
	parent.add_child(hb)
	for r in rows:
		var col := GameConfig.hex(r[2])
		var cb := ColorRect.new()
		cb.color = col
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.size_flags_stretch_ratio = max(0.008, float(r[1]))
		cb.tooltip_text = "%s：%.0f%%" % [r[0], float(r[1]) * 100.0]
		hb.add_child(cb)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 12)
	parent.add_child(legend)
	for r in rows:
		var l := HBoxContainer.new()
		l.add_theme_constant_override("separation", 4)
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(9, 9)
		dot.color = GameConfig.hex(r[2])
		l.add_child(dot)
		l.add_child(UITheme.label("%s %.0f%%" % [r[0], float(r[1]) * 100.0], 12, UITheme.COL.text_dim))
		legend.add_child(l)

# ---------- 时间线 ----------
func _tab_timeline() -> void:
	var sv := ScrollContainer.new()
	sv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(sv)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.add_child(box)
	box.add_child(UITheme.label("各聚落社会形态时间线（颜色=形态）", 16, UITheme.COL.accent))
	var forms := ["primitive", "slave", "feudal", "capitalist", "socialist", "mixed"]
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 12)
	for f in forms:
		var l := HBoxContainer.new()
		l.add_theme_constant_override("separation", 4)
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(9, 9)
		dot.color = GameConfig.hex(str(Database.FORMS.get(f, {}).get("color", "#888")))
		l.add_child(dot)
		l.add_child(UITheme.label(Database.form_name(f), 12, UITheme.COL.text_dim))
		legend.add_child(l)
	box.add_child(legend)
	for s in game.world.settlements:
		box.add_child(UITheme.label(s.display_name(), 14, UITheme.COL.text))
		if s.stat_log.is_empty():
			box.add_child(UITheme.label("（无记录）", 12, UITheme.COL.text_dim))
			continue
		var hb := HBoxContainer.new()
		hb.custom_minimum_size = Vector2(940, 18)
		box.add_child(hb)
		var logs: Array = s.stat_log
		var start_year := int(logs[0].get("year", 0))
		var end_year := int(logs[logs.size() - 1].get("year", 1)) + 1
		var span := max(1, end_year - start_year)
		# 按年份分段着色
		var i := 0
		while i < logs.size():
			var fy := int(logs[i].get("year", 0))
			var fform: String = str(logs[i].get("form", "primitive"))
			var j := i
			while j < logs.size() and str(logs[j].get("form", "")) == fform:
				j += 1
			var ny := int(logs[min(j, logs.size() - 1)].get("year", fy)) + 1
			var seg := ColorRect.new()
			seg.color = GameConfig.hex(str(Database.FORMS.get(fform, {}).get("color", "#888")))
			seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			seg.size_flags_stretch_ratio = max(0.5, float(ny - fy) / float(span))
			seg.tooltip_text = "第%d年起：%s（约 %d 年）" % [fy, Database.form_name(fform), ny - fy]
			hb.add_child(seg)
			i = j

# ---------- 数据表 ----------
func _tab_table() -> void:
	var sv := ScrollContainer.new()
	sv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(sv)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.add_child(box)
	for s in game.world.settlements:
		box.add_child(UITheme.label("%s（%s · %d 人）" % [s.display_name(), Database.form_name(s.form), s.population], 16, UITheme.COL.accent, "title"))
		var rows := [
			["人口 / 住房", "%d / %d" % [s.population, game.sim.pop_system.housing_cap(s)]],
			["出生率趋势", "%+.2f%%" % (float(s.derived.get("pop_growth", 0.0)) * 100.0)],
			["粮食产出/需求", "%.0f / %.0f" % [float(s.derived.get("food_prod", 0.0)), float(s.derived.get("food_need", 0.0))]],
			["粮食保障", "%d%%" % int(float(s.derived.get("intake_ratio", 1.0)) * 100.0)],
			["手工业产出", "%.1f" % float(s.derived.get("craft_output", 0.0))],
			["贸易收入", "%.1f" % float(s.derived.get("trade_income", 0.0))],
			["基尼系数", "%.2f" % float(s.derived.get("gini", 0.0))],
			["健康水平", "%.2f" % float(s.derived.get("health", 0.4))],
			["稳定度", "%.2f" % float(s.derived.get("stability", 0.5))],
			["防务", "%.2f" % float(s.derived.get("defense", 0.1))],
			["污染", "%.2f" % float(s.derived.get("pollution", 0.0))],
			["资源压力", "%.2f" % float(s.derived.get("resource_pressure", 0.0))],
			["税率", "%.0f%%" % (float(s.inst.get("tax_rate", 0.0)) * 100.0)],
			["土地集中", "%.2f" % float(s.inst.get("land_concentration", 0.0))],
			["国家能力", "%.2f" % float(s.inst.get("state_capacity", 0.0))],
			["公共服务", "%.2f" % float(s.inst.get("public_service", 0.0))],
			["教育", "%.2f" % float(s.inst.get("education", 0.0))],
			["政治参与", "%.2f" % float(s.inst.get("participation", 0.0))],
			["制度信任", "%.2f" % float(s.inst.get("trust", 0.0))],
			["劳动者组织度", "%.2f" % float(s.groups["laborer"].get("org", 0.0))],
			["劳动者不满", "%.2f" % float(s.groups["laborer"].get("grievance", 0.0))],
		]
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 3)
		for r in rows:
			grid.add_child(UITheme.label(r[0], 13, UITheme.COL.text_dim))
			grid.add_child(UITheme.label(r[1], 13, UITheme.COL.text, "mono"))
		box.add_child(grid)
		box.add_child(UITheme.sep())

# ---------- 模型假设 ----------
func _tab_assumptions() -> void:
	var sv := ScrollContainer.new()
	sv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(sv)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.add_child(box)
	var doc := [
		["本面板的性质", "这里展示的一切数字都来自本游戏的【模型假设】，用于生成可玩的动态。它们可以讨论社会运行的某些机制，但【不构成】对现实历史的普遍结论。改变假设，历史就会不同。"],
		["人口", "出生率 = 基础率 × 食物保障 × 健康 × 剩余消费，并受住房拥挤惩罚；死亡率随健康改善下降，饥荒时大幅上升。人口不会永远正增长。"],
		["农业", "农田产出 = 基数 × 土壤肥力 × 劳动力充足度 × 技术系数(农耕/工具) × 天气(甘霖/酷旱) × 制度系数。采集经济上限低，会自然走向农业。"],
		["分配", "社会产品按所有制与劳动关系在四个群体间分配：劳动者份额被强制/依附劳动压低、被合作劳动抬高；权贵份额随土地集中与私有成分上升；国家取走税率部分投入公共能力。"],
		["不满与集体行动", "不满由摄入不足、差距扩大、土地集中、渠道封闭共同驱动。爆发形式由组织度、国家能力、精英权力与改革渠道共同决定：可能是改革、镇压、骚乱或革命——不是阈值=革命。"],
		["技术", "研究点来自剩余产品与教育；发现需要满足前置（领域等级、前置技术、资源接触）。邻近聚落互相扩散。神力可以加速但不能跳过前置。"],
		["形态识别", "五种形态按实际变量（所有制/劳动关系/土地集中/市场/公有/公共服务）打分识别，不与年份挂钩；得分接近判为过渡/混合。任何形态都不是无条件最优。"],
		["神力", "所有神力修改的都是真实的模拟变量（地形肥力、天气系数、研究池、组织度），范围与期限有限，不能直接命令历史。"],
	]
	for d in doc:
		box.add_child(UITheme.label(d[0], 17, UITheme.COL.accent, "title"))
		var l := UITheme.label(d[1], 14, UITheme.COL.text)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(930, 0)
		box.add_child(l)
		box.add_child(UITheme.sep())
	box.add_child(UITheme.label("—— 以上机制的具体常数可在 scripts/core/GameConfig.gd 中查看与调整 ——", 13, UITheme.COL.text_dim))

func close() -> void:
	game.hud_locked = false
	queue_free()
