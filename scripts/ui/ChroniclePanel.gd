## 编年史面板：事件列表 + 分类过滤 + 历史节点分支。
extends Control

var game
var filter := "all"
var list_box: VBoxContainer
var branch_box: HBoxContainer
var filter_row: HBoxContainer

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
	pc.offset_left = -470
	pc.offset_right = 470
	pc.offset_top = -300
	pc.offset_bottom = 300
	add_child(pc)
	UITheme.panel_style(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var head := HBoxContainer.new()
	head.add_child(UITheme.label("历史编年史", 24, UITheme.COL.accent, "title"))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(sp)
	var total := game.sim.history.entries.size()
	head.add_child(UITheme.label("共 %d 条记录" % total, 13, UITheme.COL.text_dim))
	var close_b := UITheme.icon_button("ui_close", "关闭（H）", Callable(self, "close"), 30)
	head.add_child(close_b)
	v.add_child(head)
	# 过滤行
	filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 4)
	v.add_child(filter_row)
	_refresh_filters()
	# 列表
	var sv := ScrollContainer.new()
	sv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sv.custom_minimum_size = Vector2(920, 420)
	v.add_child(sv)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 4)
	sv.add_child(list_box)
	# 分支区
	v.add_child(UITheme.sep())
	v.add_child(UITheme.label("历史节点 —— 选择一个年份，从那里分出另一条历史线", 14, UITheme.COL.accent))
	branch_box = HBoxContainer.new()
	branch_box.add_theme_constant_override("separation", 6)
	v.add_child(branch_box)
	_refresh_branch()
	_refresh_list()
	return self

func _refresh_filters() -> void:
	for c in filter_row.get_children():
		filter_row.remove_child(c)
		c.queue_free()
	var cats := [["all", "全部"]]
	for k in Database.EVENT_CATS:
		cats.append([k, str(Database.EVENT_CATS[k].get("name", k))])
	for cdata in cats:
		var b := Button.new()
		b.text = cdata[1]
		b.toggle_mode = true
		b.button_pressed = filter == cdata[0]
		b.pressed.connect(func():
			filter = cdata[0]
			_refresh_filters()
			_refresh_list()
			)
		filter_row.add_child(b)

func _refresh_list() -> void:
	for c in list_box.get_children():
		list_box.remove_child(c)
		c.queue_free()
	var entries: Array = game.sim.history.entries
	var shown: Array = []
	for e in entries:
		if filter != "all" and str(e.get("cat", "")) != filter:
			continue
		shown.append(e)
	shown.reverse()
	var max_show := 80
	var n := 0
	for e in shown:
		if n >= max_show:
			break
		n += 1
		list_box.add_child(_entry_row(e))
	if shown.is_empty():
		list_box.add_child(UITheme.label("（暂无此类记录）", 13, UITheme.COL.text_dim))

func _entry_row(e: Dictionary) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.10, 0.15, 0.85)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	var imp := int(e.get("importance", 1))
	if imp >= 3:
		sb.border_color = UITheme.COL.danger * Color(1, 1, 1, 0.55)
		sb.set_border_width_all(1)
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	pc.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var cat: String = str(e.get("cat", "inst"))
	var icon_key: String = str((Database.EVENT_CATS.get(cat, {}) as Dictionary).get("icon", "ev_inst"))
	var t := ArtCache.tex(icon_key)
	if t != null:
		var tr := TextureRect.new()
		tr.texture = t
		tr.custom_minimum_size = Vector2(22, 22)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(tr)
	head.add_child(UITheme.label("第%d年" % int(e.get("year", 0)), 14, UITheme.COL.accent, "mono"))
	head.add_child(UITheme.label(str(e.get("place", "")), 13, UITheme.COL.text_dim))
	var title := UITheme.label(str(e.get("title", "")), 15, UITheme.COL.text)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	if bool(e.get("player_involved", false)):
		var pi := UITheme.label("✦神迹介入", 12, UITheme.COL.accent)
		head.add_child(pi)
	v.add_child(head)
	var causes: Array = e.get("causes", [])
	if not causes.is_empty():
		var cl := UITheme.label("起因：" + "；".join(PackedStringArray(causes)), 12, UITheme.COL.text_dim)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cl.custom_minimum_size = Vector2(860, 0)
		v.add_child(cl)
	var effects: Array = e.get("effects", [])
	if not effects.is_empty():
		var el := UITheme.label("结果：" + "；".join(PackedStringArray(effects)), 12, UITheme.COL.ok)
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		el.custom_minimum_size = Vector2(860, 0)
		v.add_child(el)
	return pc

func _refresh_branch() -> void:
	for c in branch_box.get_children():
		branch_box.remove_child(c)
		c.queue_free()
	var years: Array = game.sim.history.snapshot_years()
	if years.is_empty():
		branch_box.add_child(UITheme.label("（暂无历史节点快照——每 20 年自动生成）", 13, UITheme.COL.text_dim))
		return
	var latest: Array = years.slice(max(0, years.size() - 10), years.size())
	for y in latest:
		var b := Button.new()
		b.text = "第%d年" % int(y)
		b.pressed.connect(_confirm_branch.bind(int(y)))
		branch_box.add_child(b)

func _confirm_branch(year: int) -> void:
	var dlg := AcceptDialog.new()
	dlg.dialog_text = "将从第 %d 年创建历史分支。\n当前世界会被先自动保存，然后载入该节点的世界状态。\n继续？" % year
	dlg.ok_button_text = "创建分支"
	dlg.cancel_button_text = "取消"
	add_child(dlg)
	dlg.confirmed.connect(func():
		dlg.queue_free()
		game.branch_from(year)
		close()
		)
	dlg.canceled.connect(func(): dlg.queue_free())
	dlg.popup_centered()

func close() -> void:
	game.hud_locked = false
	queue_free()
