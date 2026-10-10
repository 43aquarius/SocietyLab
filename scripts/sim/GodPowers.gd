## 神力系统：玩家的核心工具。9 种神力 + 自由/有限干预双模式。
## 所有神力：可见图标 → 鼠标交互 → 作用区域提示 → 即时反馈 → 真实模拟后果。
extends RefCounted

var _sim

func _init(sim) -> void:
	_sim = sim

## 统一入口：power_id + 目标图格。返回 {ok, msg}
func apply(power_id: String, x: int, y: int) -> Dictionary:
	var ws = _sim.world
	if not ws.in_bounds(x, y):
		return {"ok": false, "msg": "目标在世界之外"}
	var info: Dictionary = Database.POWERS.get(power_id, {})
	if info.is_empty():
		return {"ok": false, "msg": "未知神力"}
	# 消耗结算
	var cost := _cost(power_id)
	if cost > 0.0 and ws.faith < cost:
		return {"ok": false, "msg": "信仰不足（需要 %d，现有 %d）" % [int(cost), int(ws.faith)]}
	# 集落类神力需要目标聚落
	if ["bless", "enlight", "idea"].has(power_id):
		var s = ws.settlement_at_tile(x, y)
		if s == null:
			# 容错：找最近聚落（点击其领地附近）
			s = _nearest_settlement(ws, x, y)
		if s == null:
			return {"ok": false, "msg": "附近没有聚落"}
		return _apply_to_settlement(power_id, s, cost)
	# 地格类神力
	var t: int = ws.get_terrain(x, y)
	var res: int = ws.get_resource(x, y)
	match power_id:
		"forest":
			if t != GameConfig.T_GRASS and t != GameConfig.T_SAND:
				return {"ok": false, "msg": "只能在草地或沙地上种下森林"}
			if ws.has_building_at(x, y):
				return {"ok": false, "msg": "那里已有建筑"}
			ws.set_terrain(x, y, GameConfig.T_FOREST)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if ws.in_bounds(x + d.x, y + d.y) and ws.get_terrain(x + d.x, y + d.y) == GameConfig.T_GRASS:
					ws.set_fertility(x + d.x, y + d.y, ws.get_fertility(x + d.x, y + d.y) + 0.05)
			_finish(power_id, cost, x, y, null)
			return {"ok": true, "msg": "森林之触：林地出现，周边土地更肥沃"}
		"fertile":
			if t != GameConfig.T_GRASS:
				return {"ok": false, "msg": "只能对草地施法"}
			if ws.has_building_at(x, y):
				return {"ok": false, "msg": "那里已有建筑"}
			ws.set_terrain(x, y, GameConfig.T_FERTILE)
			_finish(power_id, cost, x, y, null)
			return {"ok": true, "msg": "沃土化：这块土地适于耕作"}
		"water":
			if t == GameConfig.T_MOUNTAIN or t == GameConfig.T_WATER:
				return {"ok": false, "msg": "山地无法涌泉，那里已是水域"}
			if ws.has_building_at(x, y):
				return {"ok": false, "msg": "那里已有建筑"}
			ws.set_terrain(x, y, GameConfig.T_WATER)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if ws.in_bounds(x + d.x, y + d.y) and ws.get_terrain(x + d.x, y + d.y) == GameConfig.T_GRASS:
					ws.set_fertility(x + d.x, y + d.y, ws.get_fertility(x + d.x, y + d.y) + 0.12)
			_finish(power_id, cost, x, y, null)
			return {"ok": true, "msg": "清泉涌现：水源与湿润的土地出现了"}
		"ore":
			if t != GameConfig.T_ROCK and t != GameConfig.T_MOUNTAIN:
				return {"ok": false, "msg": "矿脉只显现于山地或石地"}
			if res != 0:
				return {"ok": false, "msg": "那里已有矿脉"}
			var kind := GameConfig.RES_IRON
			if _sim.rng.chance("event", 0.3):
				kind = GameConfig.RES_GOLD
			ws.set_resource(x, y, kind)
			ws.objects_dirty = true
			_finish(power_id, cost, x, y, null)
			return {"ok": true, "msg": "矿脉显现：%s" % ("金矿" if kind == GameConfig.RES_GOLD else "铁矿")}
		"rain":
			ws.add_effect({"kind": "rain", "x": x, "y": y, "radius": 1, "power": 0.3, "until": ws.year + 5})
			_finish(power_id, cost, x, y, null)
			return {"ok": true, "msg": "甘霖：这片区域将风调雨顺五年"}
		"drought":
			ws.add_effect({"kind": "drought", "x": x, "y": y, "radius": 1, "power": 0.45, "until": ws.year + 5})
			_finish(power_id, cost, x, y, null)
			return {"ok": true, "msg": "酷旱：这片区域将干旱五年"}
	return {"ok": false, "msg": "未实现的神力"}

## 集落定向神力（事件卡按钮/选中面板调用）
func apply_to_settlement(power_id: String, s) -> Dictionary:
	var cost := _cost(power_id)
	return _apply_to_settlement(power_id, s, cost)

func _apply_to_settlement(power_id: String, s, cost: float) -> Dictionary:
	var ws = _sim.world
	if cost > 0.0 and ws.faith < cost:
		return {"ok": false, "msg": "信仰不足（需要 %d，现有 %d）" % [int(cost), int(ws.faith)]}
	match power_id:
		"bless":
			ws.add_effect({"kind": "bless", "settlement": s.id, "prod_kind": "food", "power": 0.25, "until": ws.year + 5})
			_finish(power_id, cost, s.cx, s.cy, s)
			return {"ok": true, "msg": "丰饶祝福：%s 五年内产出提升" % s.display_name()}
		"enlight":
			s.research_buffer += 10.0
			_finish(power_id, cost, s.cx, s.cy, s)
			return {"ok": true, "msg": "智慧之光：知识的火花注入 %s（前置条件仍需满足）" % s.display_name()}
		"idea":
			var g = s.groups["laborer"]
			g["org"] = clamp(float(g.get("org", 0.0)) + 0.1, 0.0, 1.0)
			s.inst["participation"] = clamp(float(s.inst.get("participation", 0.0)) + 0.08, 0.0, 0.95)
			g["grievance"] = clamp(float(g.get("grievance", 0.0)) - 0.06, 0.0, 1.0)
			s.inst["trust"] = clamp(float(s.inst.get("trust", 0.3)) + 0.02, 0.0, 0.95)
			_finish(power_id, cost, s.cx, s.cy, s)
			return {"ok": true, "msg": "思想火种：%s 的组织力与参与意识觉醒" % s.display_name()}
	return {"ok": false, "msg": "未知神力"}

func _cost(power_id: String) -> float:
	if _sim.world.god_mode == GameConfig.MODE_FREE:
		return 0.0
	return float(Database.POWERS.get(power_id, {}).get("cost", 0))

func _finish(power_id: String, cost: float, x: int, y: int, s) -> void:
	var ws = _sim.world
	ws.faith = max(0.0, ws.faith - cost)
	ws.objects_dirty = true
	if s != null:
		s.last_divine_year = ws.year
		s.divine_marks.append({"year": ws.year, "power": power_id})
		if s.divine_marks.size() > 6:
			s.divine_marks.pop_front()
	_sim.emit_signal("power_applied", power_id, x, y, (s.id if s != null else -1))

func _nearest_settlement(ws, x: int, y: int):
	var best = null
	var best_d := 1e9
	for s in ws.settlements:
		var d: float = pow(s.cx - x, 2.0) + pow(s.cy - y, 2.0)
		if d < best_d:
			best_d = d
			best = s
	if best_d <= 100.0:
		return best
	return null
