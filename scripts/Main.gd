## 根节点 Main：主菜单 / 游戏会话的流程切换。
extends Node

const SimManager = preload("res://scripts/sim/SimulationManager.gd")
const SaveManager = preload("res://scripts/sim/SaveManager.gd")

var save_manager
var menu
var game: Node2D

func _ready() -> void:
	save_manager = SaveManager.new()
	_show_menu()

func _show_menu() -> void:
	_clear_game()
	menu = load("res://scripts/ui/MainMenu.gd").new(self)
	add_child(menu)
	menu.build()

func _clear_game() -> void:
	if game != null and is_instance_valid(game):
		remove_child(game)
		game.queue_free()
		game = null

func _clear_menu() -> void:
	if menu != null and is_instance_valid(menu):
		remove_child(menu)
		menu.queue_free()
		menu = null

func start_new_game(opts: Dictionary) -> void:
	_clear_menu()
	var sim = SimManager.new()
	sim.new_game(opts)
	_launch(sim)

func load_from_file(path: String) -> void:
	var payload: Dictionary = save_manager.load_game(path)
	if payload.is_empty():
		push_error("读取失败：%s" % path)
		return
	_clear_menu()
	var sim = SimManager.new()
	sim.load_game(payload)
	_launch(sim)

## 从历史快照分支：恢复快照的世界+随机数状态，并截断快照年之前的历史
func launch_branch(year: int) -> void:
	var snap: Dictionary = game.sim.history.get_snapshot(year)
	if snap.is_empty():
		push_error("找不到第 %d 年的快照" % year)
		return
	var payload := {
		"version": 1,
		"meta": {"name": "%s(分支)" % str(snap.get("world", {}).get("name", "")), "seed": int(snap.get("world", {}).get("seed", 0))},
		"world": snap.get("world", {}),
		"rng": snap.get("rng", {}),
		"history": {"entries": [], "snapshots": []},
	}
	var sim = SimManager.new()
	sim.load_game(payload)
	# 载入后补上截断的历史与快照
	sim.history.from_dict({
		"entries": _entries_up_to(game.sim.history.entries, year),
		"snapshots": [snap],
	})
	_clear_game()
	_launch(sim)

static func _entries_up_to(entries: Array, year: int) -> Array:
	var out: Array = []
	for e in entries:
		if int(e.get("year", 0)) <= year:
			out.append(e)
	return out

func _launch(sim) -> void:
	_clear_game()
	var GameWorldScript = load("res://scripts/game/GameWorld.gd")
	game = GameWorldScript.new(self, sim, save_manager)
	add_child(game)
	Audio.play_ambient()

func return_to_menu() -> void:
	_clear_game()
	_clear_menu()
	_show_menu()
	Audio.play("click")
