## 游戏 HUD：顶栏 / 神力工具栏 / 右侧信息面板 / 事件卡 / 跑马灯 / 提示 / 帮助。
extends Control

signal tool_selected(tool_id)
signal card_action(power_id, sid)

var game
var top_bar: PanelContainer
var toolbar: PanelContainer
var right_panel: PanelContainer
var right_content: Control
var ticker: HBoxContainer
var hint_label: Label
var event_box: VBoxContainer
var toast_box: VBoxContainer
var help_overlay: Control

var info_label := {}
var speed_buttons := {}
var tool_buttons := {}
var current_tool: String = ""
var cards: Array = []

func _init(p_game) -> void:
	game = p_game

func build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.theme()
	_build_top_bar()
	_build_toolbar()
	_build_right_panel()
	_build_ticker()
	_build_hint()
	_build_event_area()
	_build_toasts()
	_build_help()
	_refresh_top()
	_update_toolbar()

# ==================== 顶栏 ====================
func _build_top_bar() -> void:
	top_bar = PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_top = 6
	top_bar.offset_left = 8
	top_bar.offset_right = -8
	top_bar.offset_bottom = 62
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(top_bar)
	UITheme.panel_style(top_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_bar.add_child(row)
	var wname := UITheme.label("世界", 17, UITheme.COL.accent, "title")
	wname.custom_minimum_size.x = 130
	info_label["world"] = wname
	row.add_child(wname)
	row.add_child(_sep_v())
	info_label["year"] = UITheme.label("第1年", 17, UITheme.COL.text, "title")
	row.add_child(info_label["year"])
	var pop_icon := _icon("res_pop")
	row.add_child(pop_icon)
	info_label["pop"] = UITheme.label("0", 16, UITheme.COL.text, "mono")
	row.add_child(info_label["pop"])
	var food_icon := _icon("res_food")
	row.add_child(food_icon)
	info_label["food"] = UITheme.label("--", 15, UITheme.COL.text, "mono")
	row.add_child(info_label["food"])
	info_label["form_icon"] = _icon("form_primitive")
	row.add_child(info_label["form_icon"])
	info_label["form"] = UITheme.label("原始社会", 15, UITheme.COL.text_dim)
	row.add_child(info_label["form"])
	info_label["faith_icon"] = _icon("res_faith")
	row.add_child(info_label["faith_icon"])
	info_label["faith"] = UITheme.label("∞", 15, UITheme.COL.accent, "mono")
	row.add_child(info_label["faith"])
	# 弹性间隔
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	# 速度控制
	var vb := HBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	var pause_b := UITheme.icon_button("ui_pause", "暂停（空格）", Callable(self, "_on_speed").bind(-2), 34)
	speed_buttons[-2] = pause_b
	vb.add_child(pause_b)
	var speeds := [["1×", 0, "正常速度（1）"], ["2×", 1, "快进（2）"], ["3×", 2, "更快（3）"], ["4×", 3, "极速（4）"]]
	for sdata in speeds:
		var b := Button.new()
		b.text = sdata[0]
		b.tooltip_text = sdata[2]
		b.custom_minimum_size = Vector2(42, 34)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(Callable(self, "_on_speed").bind(sdata[1]))
		speed_buttons[sdata[1]] = b
		vb.add_child(b)
	var step_b := UITheme.icon_button("ui_step", "单步推进一年（.）", Callable(self, "_on_step"), 34)
	vb.add_child(step_b)
	row.add_child(vb)
	row.add_child(_sep_v())
	var ob := HBoxContainer.new()
	ob.add_theme_constant_override("separation", 4)
	ob.add_child(UITheme.icon_button("ui_chronicle", "编年史（H）", Callable(self, "_open_chronicle"), 34))
	ob.add_child(UITheme.icon_button("ui_observer", "观察者模式（O）", Callable(self, "_open_observer"), 34))
	ob.add_child(UITheme.icon_button("ui_help", "帮助（F1）", Callable(self, "_toggle_help"), 34))
	ob.add_child(UITheme.icon_button("ui_gear", "菜单（Esc）", Callable(self, "_open_menu"), 34))
	row.add_child(ob)

func _sep_v() -> VSeparator:
	var vs := VSeparator.new()
	vs.add_theme_constant_override("separation", 8)
	return vs

func _icon(key: String) -> TextureRect:
	var t := ArtCache.tex(key)
	var tr := TextureRect.new()
	if t != null:
		tr.texture = t
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(22, 22)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

func _on_speed(idx: int) -> void:
	game.set_speed(idx)
	_highlight_speed()

func _on_step() -> void:
	game.step_year()
	Audio.play("click")

func _highlight_speed() -> void:
	var active := game.speed_index
	for k in speed_buttons:
		var b: Button = speed_buttons[k]
		if b is Button:
			if int(k) == active:
				b.add_theme_color_override("font_color", UITheme.COL.accent)
				b.add_theme_stylebox_override("normal", _sb_active())
			else:
				b.remove_theme_color_override("font_color")
				b.remove_theme_stylebox_override("normal")

func _sb_active() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.COL.accent_soft
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	return sb

# ==================== 神力工具栏 ====================
func _build_toolbar() -> void:
	toolbar = PanelContainer.new()
	toolbar.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	toolbar.offset_left = 8
	toolbar.offset_top = 80
	toolbar.offset_bottom = -46
	toolbar.offset_right = 92
	toolbar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(toolbar)
	UITheme.panel_style(toolbar)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	toolbar.add_child(v)
	var title := UITheme.label("神力", 15, UITheme.COL.accent, "title")
	v.add_child(title)
	var groups := {"地形": ["forest", "fertile", "water", "ore"], "天气": ["rain", "drought"], "赐福": ["bless"], "启蒙": ["enlight", "idea"]}
	for gname in groups:
		var gh := UITheme.label(gname, 12, UITheme.COL.text_dim)
		v.add_child(gh)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		v.add_child(grid)
		for pid in groups[gname]:
			var info: Dictionary = Database.POWERS.get(pid, {})
			var b := UITheme.icon_button(str(info.get("icon", "pow_forest")), "%s\n%s" % [info.get("name", ""), info.get("desc", "")], Callable(self, "_pick_tool").bind(pid), 38)
			b.tooltip_text = "%s —— %s（信仰 %d）" % [info.get("name", ""), info.get("desc", ""), int(info.get("cost", 0))]
			tool_buttons[pid] = b
			grid.add_child(b)
	_update_toolbar()

func _pick_tool(pid: String) -> void:
	Audio.play("click")
	if current_tool == pid:
		current_tool = ""
	else:
		current_tool = pid
	_update_toolbar()
	emit_signal("tool_selected", current_tool)

func _update_toolbar() -> void:
	for pid in tool_buttons:
		var b: Button = tool_buttons[pid]
		var affordable := true
		if game.world.god_mode == GameConfig.MODE_LIMITED:
			affordable = game.world.faith >= float(Database.POWERS.get(pid, {}).get("cost", 0))
		b.disabled = not affordable
		if pid == current_tool:
			var sb := StyleBoxFlat.new()
			sb.bg_color = UITheme.COL.accent_soft
			sb.border_color = UITheme.COL.accent
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(9)
			b.add_theme_stylebox_override("normal", sb)
			b.add_theme_stylebox_override("hover", sb)
		else:
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")

# ==================== 右侧信息面板 ====================
func _build_right_panel() -> void:
	right_panel = PanelContainer.new()
	right_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	right_panel.offset_left = -352
	right_panel.offset_right = -8
	right_panel.offset_top = 80
	right_panel.offset_bottom = -120
	right_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(right_panel)
	UITheme.panel_style(right_panel)
	right_content = VBoxContainer.new()
	right_panel.add_child(right_content)

func show_settlement(s) -> void:
	_clear_right()
	var SettlementPanelScript = load("res://scripts/ui/SettlementPanel.gd")
	right_panel.add_child(SettlementPanelScript.new().build(game, s))

func show_building(s, b) -> void:
	_clear_right()
	var SettlementPanelScript = load("res://scripts/ui/SettlementPanel.gd")
	right_panel.add_child(SettlementPanelScript.new().build_building(game, s, b))

func show_tile(x: int, y: int) -> void:
	_clear_right()
	var SettlementPanelScript = load("res://scripts/ui/SettlementPanel.gd")
	right_panel.add_child(SettlementPanelScript.new().build_tile(game, x, y))

func _clear_right() -> void:
	for c in right_panel.get_children():
		right_panel.remove_child(c)
		c.queue_free()
	right_content = VBoxContainer.new()
	right_panel.add_child(right_content)

# ==================== 跑马灯 ====================
func _build_ticker() -> void:
	ticker = HBoxContainer.new()
	ticker.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ticker.offset_bottom = -8
	ticker.offset_left = 8
	ticker.offset_top = -42
	ticker.add_theme_constant_override("separation", 6)
	ticker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ticker)
	_refresh_ticker()

func refresh_ticker(events: Array) -> void:
	for c in ticker.get_children():
		ticker.remove_child(c)
		c.queue_free()
	var recent: Array = events.slice(max(0, events.size() - 3), events.size())
	recent.reverse()
	for e in recent:
		var cat: String = str(e.get("cat", "inst"))
		var icon_key: String = str((Database.EVENT_CATS.get(cat, {}) as Dictionary).get("icon", "ev_inst"))
		var b := Button.new()
		var imp := int(e.get("importance", 1))
		var prefix := "◆ " if imp >= 3 else ("· " if imp == 2 else "· ")
		b.text = prefix + str(e.get("title", ""))
		b.tooltip_text = "%s\n%s" % [str(e.get("desc", "")), str(" / ".join(PackedStringArray(e.get("causes", []))))]
		b.custom_minimum_size = Vector2(30, 30)
		var sb := StyleBoxFlat.new()
		if imp >= 3:
			sb.bg_color = Color(0.3, 0.16, 0.12, 0.92)
			sb.border_color = UITheme.COL.danger * Color(1, 1, 1, 0.7)
		elif imp == 2:
			sb.bg_color = Color(0.14, 0.16, 0.22, 0.92)
			sb.border_color = Color(1, 1, 1, 0.12)
		else:
			sb.bg_color = Color(0.10, 0.11, 0.16, 0.85)
			sb.border_color = Color(1, 1, 1, 0.07)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		b.add_theme_stylebox_override("normal", sb)
		var t := ArtCache.tex(icon_key)
		if t != null:
			var tr := TextureRect.new()
			tr.texture = t
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(20, 20)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(tr)
		b.pressed.connect(Callable(self, "_open_chronicle"))
		ticker.add_child(b)

func _refresh_ticker() -> void:
	if game and game.sim:
		refresh_ticker(game.sim.history.entries)

# ==================== 底部提示 ====================
func _build_hint() -> void:
	hint_label = UITheme.label("", 13, UITheme.COL.text_dim)
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_label.offset_left = -520
	hint_label.offset_right = -12
	hint_label.offset_top = -36
	hint_label.offset_bottom = -10
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint_label)
	set_hint("")

func set_hint(text: String) -> void:
	hint_label.text = text

# ==================== 事件卡 ====================
func _build_event_area() -> void:
	event_box = VBoxContainer.new()
	event_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	event_box.offset_left = -430
	event_box.offset_right = -10
	event_box.offset_top = 84
	event_box.add_theme_constant_override("separation", 8)
	event_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(event_box)

func push_event_card(entry: Dictionary) -> void:
	if int(entry.get("importance", 1)) < 2:
		return
	if cards.size() >= 2:
		_dismiss_card(cards[0])
	var cat: String = str(entry.get("cat", "inst"))
	var icon_key: String = str((Database.EVENT_CATS.get(cat, {}) as Dictionary).get("icon", "ev_inst"))
	var card := PanelContainer.new()
	UITheme.panel_style(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	var head := HBoxContainer.new()
	var t1 := TextureRect.new()
	var tex := ArtCache.tex(icon_key)
	if tex != null:
		t1.texture = tex
		t1.custom_minimum_size = Vector2(30, 30)
		t1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(t1)
	var title := UITheme.label("第%d年 · %s" % [int(entry.get("year", 0)), str(entry.get("title", ""))], 16, UITheme.COL.accent, "title")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close_b := UITheme.icon_button("ui_close", "关闭", Callable(self, "_dismiss_by_ref").bind(card), 24)
	head.add_child(close_b)
	v.add_child(head)
	var desc := UITheme.label(str(entry.get("desc", "")), 14, UITheme.COL.text)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 380
	v.add_child(desc)
	var causes: Array = entry.get("causes", [])
	if not causes.is_empty():
		var ctext := "起因：" + "；".join(PackedStringArray(causes))
		var cl := UITheme.label(ctext, 13, UITheme.COL.text_dim)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cl.custom_minimum_size.x = 380
		v.add_child(cl)
	var effects: Array = entry.get("effects", [])
	if not effects.is_empty():
		var etext := "→ " + "；".join(PackedStringArray(effects))
		var el := UITheme.label(etext, 13, UITheme.COL.ok)
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		el.custom_minimum_size.x = 380
		v.add_child(el)
	var actions: Array = entry.get("actions", [])
	if not actions.is_empty():
		var ab := HBoxContainer.new()
		ab.add_theme_constant_override("separation", 6)
		v.add_child(ab)
		for a in actions:
			var power_id: String = str(a.get("power", ""))
			var cost := int(a.get("cost", 0))
			var lbl := str(a.get("label", "介入"))
			if game.world.god_mode == GameConfig.MODE_FREE:
				lbl = "%s（免费）" % lbl
			else:
				lbl = "%s（%d 信仰）" % [lbl, cost]
			var act_b := Button.new()
			act_b.text = lbl
			act_b.pressed.connect(Callable(self, "_card_action").bind(power_id, int(entry.get("sid", -1))))
			ab.add_child(act_b)
		var skip := UITheme.label("……或静观其变", 12, UITheme.COL.text_dim)
		v.add_child(skip)
	event_box.add_child(card)
	cards.append(card)
	# 入场动画
	card.modulate.a = 0.0
	var tw := card.create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.25)
	var ttl := 12.0 if int(entry.get("importance", 2)) == 2 else 16.0
	var tt := card.create_tween()
	tt.tween_interval(ttl)
	tt.tween_callback(Callable(self, "_dismiss_by_ref").bind(card))

func _dismiss_by_ref(card: Control) -> void:
	_dismiss_card(card)

func _dismiss_card(card: Control) -> void:
	if card == null or not is_instance_valid(card):
		return
	if not cards.has(card):
		return
	cards.erase(card)
	if is_instance_valid(card):
		var tw := card.create_tween()
		tw.tween_property(card, "modulate:a", 0.0, 0.25)
		tw.tween_callback(card.queue_free)

func _card_action(power_id: String, sid: int) -> void:
	emit_signal("card_action", power_id, sid)

# ==================== Toast ====================
func _build_toasts() -> void:
	toast_box = VBoxContainer.new()
	toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_box.offset_top = 70
	toast_box.add_theme_constant_override("separation", 4)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_box)

func toast(msg: String, kind: String = "info") -> void:
	var col := UITheme.COL.text
	match kind:
		"warn": col = Color(1.0, 0.8, 0.4, 1)
		"bad": col = UITheme.COL.danger
		"good": col = UITheme.COL.ok
	var l := UITheme.label(msg, 15, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.13, 0.94)
	sb.border_color = col * Color(1, 1, 1, 0.45)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	l.add_theme_stylebox_override("normal", sb)
	toast_box.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)

# ==================== 帮助 ====================
func _build_help() -> void:
	help_overlay = Control.new()
	help_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_overlay.visible = false
	add_child(help_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_overlay.add_child(dim)
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.offset_left = -380
	pc.offset_right = 380
	pc.offset_top = -260
	pc.offset_bottom = 260
	help_overlay.add_child(pc)
	UITheme.panel_style(pc)
	var sv := ScrollContainer.new()
	sv.custom_minimum_size = Vector2(740, 500)
	pc.add_child(sv)
	var v := VBoxContainer.new()
	sv.add_child(v)
	v.add_child(UITheme.label("快速指南", 24, UITheme.COL.accent, "title"))
	var lines := [
		"【观察】滚轮缩放；按住左键/中键拖动平移；WASD/方向键移动；Home 键复位全景。",
		"【选择】单击聚落建筑查看详情；单击空地查看地形。右侧面板显示信息。",
		"【神力】左侧工具栏选择神力后，在地图上点击施放（红框=无效目标）。Esc 取消。",
		"  地形类：森林/沃土/水源/矿脉 —— 直接改变地块并影响周边。",
		"  天气类：甘霖/酷旱 —— 3×3 区域，持续 5 年，影响产量与生活。",
		"  赐福：丰饶祝福 —— 聚落 5 年产出 +25%。",
		"  启蒙：智慧之光（加速研究）/ 思想火种（提升组织与参与）。",
		"【时间】空格暂停；1/2/3/4 切换速度；句号单步。重大事件卡片可能提供介入选项。",
		"【档案】H 编年史（含历史分支）；O 观察者（曲线/结构/时间线/模型说明）。",
		"【模式】自由上帝：神力无消耗；有限干预：神力消耗信仰（每年 +2）。",
		"",
		"玩法建议：先看世界自然演化（前 50 年），在饥荒/战争卡上尝试介入，",
		"然后在编年史里从历史节点分支，对比不同干预策略的历史路径。",
	]
	for line in lines:
		var l := UITheme.label(line, 15, UITheme.COL.text if line.begins_with("【") else UITheme.COL.text_dim)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 700
		v.add_child(l)
	var close := UITheme.button("开始游戏", Callable(self, "_toggle_help"))
	v.add_child(close)

func _toggle_help() -> void:
	help_overlay.visible = not help_overlay.visible
	Audio.play("click")

func _open_chronicle() -> void:
	Audio.play("click")
	game.open_chronicle()

func _open_observer() -> void:
	Audio.play("click")
	game.open_observer()

func _open_menu() -> void:
	Audio.play("click")
	game.open_pause_menu()

# ==================== 年度刷新 ====================
func _refresh_top() -> void:
	if game == null or game.world == null:
		return
	var w = game.world
	info_label["world"].text = w.world_name
	info_label["year"].text = "第%d年" % w.year
	var pop := 0
	for s in w.settlements:
		pop += s.population
	info_label["pop"].text = GameConfig.fmt_num(pop)
	var food_txt := ""
	for s in w.settlements:
		var years_of := s.food_store / max(1.0, float(s.population))
		var intake: float = float(s.derived.get("intake_ratio", 1.0))
		var mark := ""
		if s.famine_active:
			mark = "!"
		elif intake < 0.85:
			mark = "~"
		food_txt += "%s%.1f年%s " % [s.base_name.left(2), years_of, mark]
	info_label["food"].text = food_txt.substr(0, 26)
	# 形态：取人口最多聚落
	var biggest = null
	for s in w.settlements:
		if biggest == null or s.population > biggest.population:
			biggest = s
	if biggest != null:
		var fk: String = str((Database.FORMS.get(biggest.form, {}) as Dictionary).get("icon", "form_mixed"))
		var tex := ArtCache.tex(fk)
		if tex != null and info_label["form_icon"] is TextureRect:
			(info_label["form_icon"] as TextureRect).texture = tex
		info_label["form"].text = Database.form_name(biggest.form)
	if w.god_mode == GameConfig.MODE_FREE:
		info_label["faith"].text = "∞"
		info_label["faith_icon"].visible = true
	else:
		info_label["faith"].text = "%d" % int(w.faith)
	_refresh_ticker()
	_update_toolbar()
	_highlight_speed()
