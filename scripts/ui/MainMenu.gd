## 主菜单：标题 + 新世界（种子/地形/资源/聚落数/模式）+ 读取 + 说明。
extends Control

var main

func _init(p_main) -> void:
	main = p_main

func build() -> Control:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.theme()
	# 背景：横幅 + 渐变
	var banner := TextureRect.new()
	var bt := ArtCache.tex("ui/banner_main")
	if bt != null:
		banner.texture = bt
		banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		banner.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(banner)
	var grad := ColorRect.new()
	grad.color = Color(0.04, 0.05, 0.09, 0.45)
	grad.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(grad)
	# 标题区
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_top = -120
	center.add_theme_constant_override("separation", 10)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(center)
	var t1 := UITheme.label("人类社会实验室", 54, UITheme.COL.accent, "title")
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(t1)
	var t2 := UITheme.label("SOCIETY LAB —— 创造世界 · 施加神力 · 见证历史", 17, UITheme.COL.text_dim)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(t2)
	# 按钮区
	var btns := VBoxContainer.new()
	btns.set_anchors_preset(Control.PRESET_CENTER)
	btns.offset_top = 60
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 10)
	add_child(btns)
	_mk_menu_btn(btns, "新的世界", func(): _open_new_world())
	_mk_menu_btn(btns, "继续 / 读取存档", func(): _open_load())
	_mk_menu_btn(btns, "玩法与模型说明", func(): _open_help())
	var quit := Button.new()
	quit.text = "退出"
	quit.custom_minimum_size = Vector2(240, 44)
	quit.pressed.connect(func(): main.get_tree().quit())
	btns.add_child(quit)
	# 版本脚注
	var foot := UITheme.label("v0.1 垂直切片 · Godot 4.2+ · 所有模拟均由规则驱动，非脚本剧情", 12, UITheme.COL.text_dim)
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_bottom = -10
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(foot)
	return self

func _mk_menu_btn(parent: Control, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 44)
	b.pressed.connect(cb)
	parent.add_child(b)

func _clear() -> void:
	for c in get_children():
		if c is PanelContainer:
			remove_child(c)
			c.queue_free()

func _panel(title: String) -> VBoxContainer:
	_clear()
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.offset_left = -290
	pc.offset_right = 290
	pc.offset_top = -240
	pc.offset_bottom = 240
	add_child(pc)
	UITheme.panel_style(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	v.add_child(UITheme.label(title, 24, UITheme.COL.accent, "title"))
	v.add_child(UITheme.sep())
	return v

# ==================== 新世界 ====================
func _open_new_world() -> void:
	Audio.play("click")
	var v := _panel("创造新世界")
	var seed_val := randi() % 1000000
	var opts := {
		"seed": seed_val,
		"size": 48,
		"relief": 1,
		"richness": 1,
		"settlements": 3,
		"god_mode": GameConfig.MODE_FREE,
	}
	v.add_child(UITheme.label("世界种子（相同种子=相同初始地形）", 14, UITheme.COL.text_dim))
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 8)
	var seed_edit := LineEdit.new()
	seed_edit.text = str(seed_val)
	seed_edit.custom_minimum_size = Vector2(200, 32)
	seed_row.add_child(seed_edit)
	var rand_b := Button.new()
	rand_b.text = "随机"
	rand_b.pressed.connect(func():
		seed_edit.text = str(randi() % 1000000)
		)
	seed_row.add_child(rand_b)
	v.add_child(seed_row)
	v.add_child(UITheme.label("地形起伏", 14, UITheme.COL.text_dim))
	var relief_row := HBoxContainer.new()
	relief_row.add_theme_constant_override("separation", 6)
	var relief_opts := [["平缓", 0], ["标准", 1], ["崎岖", 2]]
	for ro in relief_opts:
		var b := Button.new()
		b.text = ro[0]
		b.toggle_mode = true
		b.button_pressed = ro[1] == 1
		b.pressed.connect(func():
			opts["relief"] = ro[1]
			for c in relief_row.get_children():
				(c as Button).button_pressed = false
			b.button_pressed = true
			)
		relief_row.add_child(b)
	v.add_child(relief_row)
	v.add_child(UITheme.label("资源丰度", 14, UITheme.COL.text_dim))
	var rich_row := HBoxContainer.new()
	rich_row.add_theme_constant_override("separation", 6)
	for ro in [["贫瘠", 0], ["标准", 1], ["富饶", 2]]:
		var b := Button.new()
		b.text = ro[0]
		b.toggle_mode = true
		b.button_pressed = ro[1] == 1
		b.pressed.connect(func():
			opts["richness"] = ro[1]
			for c in rich_row.get_children():
				(c as Button).button_pressed = false
			b.button_pressed = true
			)
		rich_row.add_child(b)
	v.add_child(rich_row)
	v.add_child(UITheme.label("初始聚落数量", 14, UITheme.COL.text_dim))
	var settle_slider := HSlider.new()
	settle_slider.min_value = 1
	settle_slider.max_value = 4
	settle_slider.step = 1
	settle_slider.value = 3
	settle_slider.custom_minimum_size = Vector2(320, 20)
	var settle_label := UITheme.label("3", 14, UITheme.COL.text, "mono")
	settle_slider.value_changed.connect(func(val):
		opts["settlements"] = int(val)
		settle_label.text = str(int(val))
		)
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 10)
	srow.add_child(settle_slider)
	srow.add_child(settle_label)
	v.add_child(srow)
	v.add_child(UITheme.label("神力模式", 14, UITheme.COL.text_dim))
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 6)
	var mode_txt := UITheme.label("", 12, UITheme.COL.text_dim)
	for mo in [["自由上帝", GameConfig.MODE_FREE, "神力无消耗，适合探索与创造"], ["有限干预", GameConfig.MODE_LIMITED, "神力消耗信仰（每年+2），需要权衡时机"]]:
		var b := Button.new()
		b.text = mo[0]
		b.toggle_mode = true
		b.button_pressed = mo[1] == GameConfig.MODE_FREE
		b.pressed.connect(func():
			opts["god_mode"] = mo[1]
			mode_txt.text = mo[2]
			for c in mode_row.get_children():
				if c is Button:
					(c as Button).button_pressed = false
			b.button_pressed = true
			)
		mode_row.add_child(b)
	v.add_child(mode_row)
	v.add_child(mode_txt)
	v.add_child(UITheme.sep())
	var start := Button.new()
	start.text = "▶ 创世"
	start.custom_minimum_size = Vector2(320, 46)
	start.pressed.connect(func():
		opts["seed"] = int(seed_edit.text.to_int())
		Audio.play("celebrate")
		main.start_new_game(opts)
		)
	v.add_child(start)
	var back := Button.new()
	back.text = "返回"
	back.pressed.connect(func():
		Audio.play("click")
		_clear()
		)
	v.add_child(back)

# ==================== 读取 ====================
func _open_load() -> void:
	Audio.play("click")
	var v := _panel("读取存档")
	var sm = main.save_manager
	var sv := ScrollContainer.new()
	sv.custom_minimum_size = Vector2(500, 330)
	v.add_child(sv)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.add_child(list)
	var saves: Array = sm.list_saves()
	if saves.is_empty():
		list.add_child(UITheme.label("（没有找到存档。游戏内按 Esc → 保存世界）", 14, UITheme.COL.text_dim))
	for item in saves:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UITheme.label(str(item.get("world_name", "?")), 16, UITheme.COL.text))
		info.add_child(UITheme.label("第%d年 · %d 聚落 · 种子 %d" % [int(item.get("year", 0)), int(item.get("settlements", 0)), int(item.get("seed", 0))], 12, UITheme.COL.text_dim))
		row.add_child(info)
		var load_b := Button.new()
		load_b.text = "进入世界"
		load_b.pressed.connect(func():
			main.load_from_file(str(item.get("path", "")))
			)
		row.add_child(load_b)
		var del_b := UITheme.icon_button("ui_close", "删除", func():
			sm.delete_save(str(item.get("path", "")))
			_open_load()
			, 26)
		row.add_child(del_b)
		list.add_child(row)
	var back := Button.new()
	back.text = "返回"
	back.pressed.connect(func():
		Audio.play("click")
		_clear()
		)
	v.add_child(back)

# ==================== 帮助 ====================
func _open_help() -> void:
	Audio.play("click")
	var v := _panel("玩法与模型说明")
	var sv := ScrollContainer.new()
	sv.custom_minimum_size = Vector2(560, 380)
	v.add_child(sv)
	var box := VBoxContainer.new()
	sv.add_child(box)
	var lines := [
		["你是一位俯瞰世界的神。", UITheme.COL.accent],
		["1. 创造世界：选择种子、地形与资源条件，文明在肥沃的河谷更容易兴起。", null],
		["2. 观察演化：聚落会自主发展——采集、农耕、分工、制度、冲突、变革，都由模拟规则驱动，而非剧本。", null],
		["3. 施加神力：改变地形与天气、赐予丰收或智慧、播撒思想火种。神力修改的是真实变量，不能直接命令历史。", null],
		["4. 见证历史：编年史记录每个重大事件的起因与后果；重大事件卡上你可以选择介入或旁观。", null],
		["5. 分支重玩：从历史节点分出平行世界线，对比不同干预策略的后果。", null],
		["", null],
		["快捷键：空格暂停 · 1/2/3/4 变速 · 句号单步 · H 编年史 · O 观察者 · F1 帮助 · Home 复位视角 · Esc 取消/菜单", UITheme.COL.text_dim],
		["", null],
		["模型说明：游戏中的所有社会演化（生产力、所有制、分配、冲突、形态）都来自可查看的规则与参数（scripts/core/GameConfig.gd 与 docs/核心模型假设说明.md）。它们是可玩的模型假设，不是对现实历史的断言。", UITheme.COL.text_dim],
	]
	for line in lines:
		var l := UITheme.label(line[0], 15, line[1] if line[1] != null else UITheme.COL.text)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(530, 0)
		box.add_child(l)
	var back := Button.new()
	back.text = "返回"
	back.pressed.connect(func():
		Audio.play("click")
		_clear()
		)
	v.add_child(back)
