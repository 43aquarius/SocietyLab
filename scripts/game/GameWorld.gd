## 游戏会话节点：粘合模拟、渲染、相机、HUD 与存档。
extends Node2D

const HUDScript = preload("res://scripts/ui/GameHUD.gd")

var main
var sim
var world
var save_manager
var visual: Node2D
var camera
var hud
var speed_index := 1          # -2 暂停 / 0..3 速度
var paused := true
var _year_accum := 0.0
var tool_active := false
var current_tool_id := ""
var hud_locked := false
var _press_pos := Vector2.ZERO
var _press_moved := false
var _hover_tile := Vector2i(-99, -99)

func _init(p_main, p_sim, p_save_manager) -> void:
	main = p_main
	sim = p_sim
	world = sim.world
	save_manager = p_save_manager

func _ready() -> void:
	visual = load("res://scripts/render/VisualWorld.gd").new()
	add_child(visual)
	visual.build(world)
	camera = load("res://scripts/render/CameraController.gd").new()
	add_child(camera)
	camera.setup(world.size)
	camera.reset_view()
	camera.make_current()
	hud = HUDScript.new(self)
	add_child(hud)
	hud.build()
	hud.tool_selected.connect(_on_tool_selected)
	hud.card_action.connect(_on_card_action)
	sim.year_advanced.connect(_on_year)
	sim.event_fired.connect(_on_event)
	sim.form_changed.connect(_on_form_changed)
	sim.power_applied.connect(_on_power)
	set_speed(1)
	hud._refresh_top()
	hud.set_hint("滚轮缩放 · 拖动平移 · 单击选择 · 左侧选择神力后点击地图施放 · 空格开始/暂停")
	Audio.play_ambient()

# ==================== 时间控制 ====================
func set_speed(idx: int) -> void:
	if idx == -2:
		paused = true
		speed_index = -2
	else:
		paused = false
		speed_index = clamp(idx, 0, 3)
	_year_accum = 0.0

func step_year() -> void:
	var was_paused := paused
	paused = true
	sim.tick()
	paused = was_paused

func _process(delta: float) -> void:
	if paused:
		return
	var secs_per_year: float = GameConfig.YEAR_SECONDS[speed_index + 1]
	if secs_per_year <= 0.01:
		return
	_year_accum += delta
	while _year_accum >= secs_per_year:
		_year_accum -= secs_per_year
		sim.tick()
		if not is_instance_valid(self):
			return

# ==================== 信号 ====================
func _on_year(year: int) -> void:
	world = sim.world
	visual.on_year_advanced()
	hud._refresh_top()
	hud._highlight_speed()
	if year > 0 and year % GameConfig.AUTOSAVE_EVERY == 0:
		save_manager.save_game(sim.session_payload(), "autosave")
		hud.toast("第 %d 年 · 已自动保存" % year)

func _on_event(entry: Dictionary) -> void:
	hud.refresh_ticker(sim.history.entries)
	hud.push_event_card(entry)
	visual.event_visual(entry)
	var imp := int(entry.get("importance", 1))
	if imp >= 3:
		Audio.play("thud")
	elif imp == 2:
		match str(entry.get("cat", "")):
			"discovery", "city", "reform", "golden":
				Audio.play("chime")

func _on_form_changed(s, old_form: String, new_form: String) -> void:
	hud.toast("%s 进入%s" % [s.display_name(), Database.form_name(new_form)], "good")
	Audio.play("celebrate")

func _on_power(power_id: String, x: int, y: int, sid: int) -> void:
	visual.flash_power(power_id, x, y, sid)
	hud.toast("%s —— 神力已生效" % Database.POWERS.get(power_id, {}).get("name", power_id), "good")
	Audio.play("build")

# ==================== 神力 ====================
func _on_tool_selected(tool_id: String) -> void:
	current_tool_id = tool_id
	tool_active = tool_id != ""
	camera.pan_enabled = not tool_active
	if tool_id == "":
		visual.set_brush({})
		hud.set_hint("滚轮缩放 · 拖动平移 · 单击选择 · 左侧选择神力后点击地图施放")
	else:
		var info: Dictionary = Database.POWERS.get(tool_id, {})
		hud.set_hint("【%s】%s —— 点击地图目标（Esc 取消）" % [info.get("name", ""), info.get("desc", "")])

func _cancel_tool() -> void:
	tool_active = false
	current_tool_id = ""
	camera.pan_enabled = true
	visual.set_brush({})
	if hud != null:
		hud.current_tool = ""
		hud._update_toolbar()
		hud.set_hint("滚轮缩放 · 拖动平移 · 单击选择 · 空格开始/暂停")

func _on_card_action(power_id: String, sid: int) -> void:
	var s = world.settlement_by_id(sid)
	if s == null:
		return
	var res: Dictionary = sim.god_powers.apply_to_settlement(power_id, s)
	if res.get("ok", false):
		Audio.play("build")
		hud.toast(str(res.get("msg", "")), "good")
		hud._refresh_top()
	else:
		hud.toast(str(res.get("msg", "失败")), "bad")

# ==================== 输入 ====================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_press_pos = mb.position
				_press_moved = false
			else:
				if not _press_moved:
					_handle_click()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _press_pos != Vector2.ZERO and mm.position.distance_to(_press_pos) > 7.0:
			_press_moved = true
		_update_hover()

func _update_hover() -> void:
	if visual == null or camera == null:
		return
	var tile := _tile_at_mouse()
	if tile != _hover_tile:
		_hover_tile = tile
		visual.set_hover(tile.x, tile.y)
		if tool_active and current_tool_id != "":
			visual.set_brush(_brush_preview(current_tool_id, tile))

func _tile_at_mouse() -> Vector2i:
	if camera == null or world == null:
		return Vector2i(-99, -99)
	var wp := camera.get_global_mouse_position()
	var origin := IsoMath.map_origin(world.size)
	var p := wp - origin
	var a := p.x / (GameConfig.TILE_W * 0.5)
	var b := p.y / (GameConfig.TILE_H * 0.5)
	var tx := int(floor((a + b) * 0.5))
	var ty := int(floor((b - a) * 0.5))
	if tx < 0 or ty < 0 or tx >= world.size or ty >= world.size:
		return Vector2i(-99, -99)
	return Vector2i(tx, ty)

func _brush_preview(tool_id: String, tile: Vector2i) -> Dictionary:
	var ok := true
	var tiles: Array = []
	if ["rain", "drought"].has(tool_id):
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				tiles.append(Vector2i(tile.x + dx, tile.y + dy))
	else:
		tiles.append(tile)
	match tool_id:
		"forest", "fertile", "water":
			var t: int = world.get_terrain(tile.x, tile.y)
			var occupied := world.has_building_at(tile.x, tile.y)
			if tool_id == "forest":
				ok = (t == GameConfig.T_GRASS or t == GameConfig.T_SAND) and not occupied
			elif tool_id == "fertile":
				ok = t == GameConfig.T_GRASS and not occupied
			else:
				ok = (t != GameConfig.T_MOUNTAIN and t != GameConfig.T_WATER) and not occupied
		"ore":
			var t2: int = world.get_terrain(tile.x, tile.y)
			ok = (t2 == GameConfig.T_ROCK or t2 == GameConfig.T_MOUNTAIN) and world.get_resource(tile.x, tile.y) == 0
		"bless", "enlight", "idea":
			ok = world.settlement_at_tile(tile.x, tile.y) != null
	return {"power": tool_id, "x": tile.x, "y": tile.y, "valid": ok, "tiles": tiles}

func _handle_click() -> void:
	if hud_locked or camera == null:
		return
	var tile := _tile_at_mouse()
	if tile.x < 0:
		return
	if tool_active and current_tool_id != "":
		var preview := _brush_preview(current_tool_id, tile)
		if not preview.get("valid", false):
			hud.toast("此处无法施放「%s」" % Database.POWERS.get(current_tool_id, {}).get("name", ""), "warn")
			return
		var res: Dictionary = sim.god_powers.apply(current_tool_id, tile.x, tile.y)
		if res.get("ok", false):
			Audio.play("build")
			hud.toast(str(res.get("msg", "")), "good")
			hud._refresh_top()
			visual.on_objects_changed()
		else:
			hud.toast(str(res.get("msg", "失败")), "bad")
		return
	_select_at(tile)

func _select_at(tile: Vector2i) -> void:
	for st in world.settlements:
		var b = st.building_at(tile.x, tile.y)
		if b != null:
			visual.set_selection({"type": "building", "ref": b})
			hud.show_building(st, b)
			Audio.play("hover")
			return
	var s = world.settlement_at_tile(tile.x, tile.y)
	if s != null and abs(s.cx - tile.x) <= 2 and abs(s.cy - tile.y) <= 2:
		visual.set_selection({"type": "settlement", "ref": s})
		hud.show_settlement(s)
		Audio.play("hover")
		return
	visual.set_selection({"type": "tile"})
	hud.show_tile(tile.x, tile.y)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		match key:
			KEY_ESCAPE:
				if tool_active:
					_cancel_tool()
				elif hud.help_overlay.visible:
					hud._toggle_help()
				else:
					open_pause_menu()
			KEY_SPACE:
				if paused and speed_index == -2:
					set_speed(1)
				else:
					set_speed(-2)
				hud._highlight_speed()
			KEY_PERIOD:
				step_year()
			KEY_H:
				open_chronicle()
			KEY_O:
				open_observer()
			KEY_F1:
				hud._toggle_help()
			KEY_HOME:
				camera.reset_view()
			KEY_F:
				_focus_selected()

func _focus_selected() -> void:
	var sel: Dictionary = visual.dynamic_layer.selection
	if sel.get("type", "") == "settlement":
		var s = sel.get("ref")
		camera.focus_tile(s.cx, s.cy)
	elif sel.get("type", "") == "building":
		var b = sel.get("ref")
		camera.focus_tile(int(b.get("tx", 0)), int(b.get("ty", 0)))

# ==================== 面板 ====================
func open_chronicle() -> void:
	if hud_locked:
		return
	hud_locked = true
	set_speed(-2)
	var p = load("res://scripts/ui/ChroniclePanel.gd").new(self)
	add_child(p.build())

func open_observer() -> void:
	if hud_locked:
		return
	hud_locked = true
	var p = load("res://scripts/ui/ObserverPanel.gd").new(self)
	add_child(p.build())

func open_pause_menu() -> void:
	if hud_locked:
		return
	hud_locked = true
	set_speed(-2)
	hud._highlight_speed()
	var d = load("res://scripts/ui/Dialogs.gd").new(self)
	add_child(d.open_pause_menu())

## 从历史快照分支（编年史里触发）
func branch_from(year: int) -> void:
	save_manager.save_game(sim.session_payload(), "%s_分支前_第%d年" % [world.world_name, world.year])
	hud_locked = false
	main.launch_branch(year)
