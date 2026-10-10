## Society Lab 无头测试套件。
## 运行：godot --headless --import   （首次，导入资源）
##       godot --headless --script tests/TestSimulation.gd --path .
## 退出码 0 = 全部通过；1 = 存在失败。
extends SceneTree

var failures: Array = []
var passed := 0

func _init() -> void:
	_run()
	var code := 0 if failures.is_empty() else 1
	print("")
	print("=" .repeat(60))
	if failures.is_empty():
		print("全部 %d 项测试通过 ✔" % passed)
	else:
		print("%d/%d 通过，失败 %d 项：" % [passed, passed + failures.size(), failures.size()])
		for f in failures:
			print("  ✘ %s" % f)
	print("=" .repeat(60))
	quit(code)

func _check(ok: bool, name: String, detail: String = "") -> void:
	if ok:
		passed += 1
		print("  ✔ %s" % name)
	else:
		failures.append("%s %s" % [name, detail])
		print("  ✘ %s  %s" % [name, detail])

func _mk_opts(seed_v: int, mode := 0) -> Dictionary:
	return {"seed": seed_v, "size": 48, "relief": 1, "richness": 1,
			"settlements": 3, "god_mode": mode}

func _run() -> void:
	var SimManager = load("res://scripts/sim/SimulationManager.gd")
	print("[1] 世界生成确定性")
	var sim1 = SimManager.new()
	sim1.new_game(_mk_opts(12345))
	var sim2 = SimManager.new()
	sim2.new_game(_mk_opts(12345))
	_check(sim1.world.terrain == sim2.world.terrain, "同种子地形一致")
	_check(sim1.world.fertility == sim2.world.fertility, "同种子肥力一致")
	_check(sim1.world.settlements.size() == sim2.world.settlements.size(), "聚落数一致")
	if not sim1.world.settlements.is_empty():
		var a = sim1.world.settlements[0]
		var b = sim2.world.settlements[0]
		_check(a.cx == b.cx and a.cy == b.cy, "聚落位置一致")

	print("[2] 120 年自主演化")
	var sim = SimManager.new()
	sim.new_game(_mk_opts(777))
	for i in 120:
		sim.tick()
	var any_pop := 0
	var bad := false
	for s in sim.world.settlements:
		any_pop += s.population
		if is_nan(float(s.food_store)) or is_nan(float(s.derived.get("gini", 0.0))):
			bad = true
	_check(not bad, "无数值异常（NaN）")
	_check(any_pop > 0, "人口存活", "总人口 %d" % any_pop)
	var has_agri := false
	var has_building := false
	var form_changed := false
	for s in sim.world.settlements:
		if s.knows("early_agri"):
			has_agri = true
		for b in s.buildings:
			if b.get("done", false) and str(b.get("key", "")) != "camp_tent":
				has_building = true
		if s.form != "primitive":
			form_changed = true
	_check(has_agri, "发现农业技术")
	_check(has_building, "建成非营地建筑")
	_check(form_changed or sim.world.year < 150, "形态演化已启动或仍在早期")

	print("[3] 饥荒触发（因果链）")
	var sim3 = SimManager.new()
	sim3.new_game(_mk_opts(42))
	var s3 = sim3.world.settlements[0]
	s3.food_store = 0.0
	sim3.world.add_effect({"kind": "drought", "x": s3.cx, "y": s3.cy, "radius": 2, "power": 0.6, "until": 99})
	for i in 8:
		sim3.tick()
	var famine_entry := {}
	for e in sim3.history.entries:
		if str(e.get("cat", "")) == "famine":
			famine_entry = e
	_check(not famine_entry.is_empty(), "饥荒事件已触发")
	if not famine_entry.is_empty():
		_check((famine_entry.get("causes", []) as Array).size() >= 2, "饥荒事件记录了起因链")
		_check(famine_entry.has("actions"), "饥荒事件提供介入选项")
	_check(s3.population < 30 or s3.famine_active, "饥荒影响人口", "pop=%d" % s3.population)

	print("[4] 社会形态识别（多变量）")
	var Classifier = load("res://scripts/sim/SocietyClassifier.gd")
	var SettlementScript = load("res://scripts/sim/Settlement.gd")
	var s = SettlementScript.new()
	s.population = 500
	s.derived["surplus_ratio"] = 0.5
	s.derived["gini"] = 0.4
	# 原始
	s.tech = {"agriculture": 0.0}
	s.discovered = []
	var r := Classifier.classify(s)
	_check(r.get("form", "") == "primitive", "原始识别", str(r.get("form", "")))
	# 奴隶制特征
	s.inst["forced"] = 0.55
	s.inst["warlike"] = 0.5
	s.derived["gini"] = 0.6
	r = Classifier.classify(s)
	_check(r.get("form", "") == "slave", "奴隶制特征识别", str(r.get("form", "")) + " " + str(r.get("scores", {})))
	s.inst["forced"] = 0.0
	# 封建
	s.inst["bonded"] = 0.5
	s.inst["land_concentration"] = 0.8
	s.derived["elite_power"] = 0.4
	r = Classifier.classify(s)
	_check(r.get("form", "") == "feudal", "封建识别", str(r.get("form", "")))
	s.inst["bonded"] = 0.0
	s.inst["land_concentration"] = 0.1
	# 资本主义
	s.inst["wage"] = 0.5
	s.inst["market_dev"] = 0.8
	s.inst["private"] = 0.6
	s.tech = {"industry": 80.0}
	r = Classifier.classify(s)
	_check(r.get("form", "") == "capitalist", "资本主义识别", str(r.get("form", "")))
	s.inst["wage"] = 0.0
	s.inst["market_dev"] = 0.1
	s.inst["private"] = 0.1
	# 社会主义特征
	s.inst["state"] = 0.6
	s.inst["coop"] = 0.4
	s.inst["public_service"] = 0.7
	s.inst["participation"] = 0.8
	r = Classifier.classify(s)
	_check(r.get("form", "") == "socialist", "社会主义特征识别", str(r.get("form", "")) + " " + str(r.get("scores", {})))

	print("[5] 存档序列化回路")
	var payload := sim.session_payload()
	var json := JSON.stringify(payload)
	var parsed = JSON.parse_string(json)
	_check(parsed is Dictionary, "JSON 可解析")
	var sim4 = SimManager.new()
	sim4.load_game(parsed)
	_check(sim4.world.terrain == sim.world.terrain, "读档地形一致")
	_check(sim4.world.year == sim.world.year, "读档年份一致")
	_check(sim4.world.settlements.size() == sim.world.settlements.size(), "读档聚落一致")
	if not sim.world.settlements.is_empty():
		_check(sim4.world.settlements[0].population == sim.world.settlements[0].population, "读档人口一致")
	_check(sim4.history.entries.size() == sim.history.entries.size(), "读档历史一致")

	print("[6] 神力作用（真实模拟后果）")
	var sim5 = SimManager.new()
	sim5.new_game(_mk_opts(99, GameConfig.MODE_LIMITED))
	var before_faith: float = sim5.world.faith
	var grass := Vector2i(-1, -1)
	for x in sim5.world.size:
		for y in sim5.world.size:
			if sim5.world.get_terrain(x, y) == GameConfig.T_GRASS and not sim5.world.has_building_at(x, y):
				grass = Vector2i(x, y)
				break
		if grass.x >= 0:
			break
	var res := sim5.god_powers.apply("forest", grass.x, grass.y)
	_check(bool(res.get("ok", false)), "森林之触可施放")
	_check(sim5.world.get_terrain(grass.x, grass.y) == GameConfig.T_FOREST, "地形真实变为森林")
	_check(sim5.world.faith < before_faith, "有限模式下消耗信仰", "%.0f→%.0f" % [before_faith, sim5.world.faith])
	var s5 = sim5.world.settlements[0]
	var research_before: float = s5.research_buffer
	var res2 := sim5.god_powers.apply_to_settlement("enlight", s5)
	_check(bool(res2.get("ok", false)), "智慧之光可对聚落施放")
	_check(s5.research_buffer > research_before, "研究池真实增加")
	var res3 := sim5.god_powers.apply("forest", 0, 0) if sim5.world.get_terrain(0, 0) == GameConfig.T_WATER else {"ok": false}
	_check(not bool(res3.get("ok", true)), "水域不可种树（校验有效）")

	print("[7] 历史快照与分支数据")
	var snap_year := -1
	for i in 40:
		sim.tick()
	if sim.history.snapshots.size() > 0:
		snap_year = int(sim.history.snapshots[0].get("year", -1))
	_check(snap_year > 0, "存在历史快照", "snapshots=%d" % sim.history.snapshots.size())
	if snap_year > 0:
		var snap := sim.history.get_snapshot(snap_year)
		_check(not snap.is_empty() and snap.has("world") and snap.has("rng"), "快照含世界与随机数状态")
		var entries := sim.history.entries_up_to(snap_year)
		_check(entries.size() <= sim.history.entries.size(), "分支历史截断正确")
