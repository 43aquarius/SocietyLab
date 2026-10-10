class_name Chart
## 轻量折线图：多序列、图例、网格、末值标注。纯 _draw 绘制。
extends Control

var series: Array = []   # [{name, color, points:[{x,y}]}]
var y_label := ""
var x_label := "年"
var show_legend := true
var _pad_l := 46.0
var _pad_r := 14.0
var _pad_t := 10.0
var _pad_b := 24.0

func set_series(data: Array, p_y_label: String = "") -> void:
	series = data
	if p_y_label != "":
		y_label = p_y_label
	queue_redraw()

func _has_data() -> bool:
	for s in series:
		if (s.get("points", []) as Array).size() >= 1:
			return true
	return false

func _bounds() -> Dictionary:
	var min_x := 1e18
	var max_x := -1e18
	var min_y := 1e18
	var max_y := -1e18
	for s in series:
		for p in s.get("points", []):
			min_x = min(min_x, float(p.get("x", 0.0)))
			max_x = max(max_x, float(p.get("x", 0.0)))
			min_y = min(min_y, float(p.get("y", 0.0)))
			max_y = max(max_y, float(p.get("y", 0.0)))
	if min_x > max_x:
		min_x = 0.0
		max_x = 1.0
	if min_y > max_y:
		min_y = 0.0
		max_y = 1.0
	if absf(max_y - min_y) < 1e-6:
		max_y = min_y + 1.0
	# 留 8% 余量
	var my := (max_y - min_y) * 0.08
	min_y = max(0.0, min_y - my)
	max_y += my
	if max_x - min_x < 1.0:
		max_x = min_x + 1.0
	return {"min_x": min_x, "max_x": max_x, "min_y": min_y, "max_y": max_y}

func _draw() -> void:
	var size_vec := size
	draw_rect(Rect2(Vector2.ZERO, size_vec), Color(0.06, 0.075, 0.10, 0.9))
	if not _has_data():
		draw_string(UITheme.font("body"), Vector2(14, size_vec.y * 0.5), "（暂无数据）",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UITheme.COL.text_dim)
		return
	var b := _bounds()
	var plot := Rect2(Vector2(_pad_l, _pad_t), size_vec - Vector2(_pad_l + _pad_r, _pad_t + _pad_b))
	# 网格
	var grid_y := 4
	for i in grid_y + 1:
		var gy: float = plot.position.y + plot.size.y * float(i) / float(grid_y)
		draw_line(Vector2(plot.position.x, gy), Vector2(plot.end.x, gy), Color(1, 1, 1, 0.06), 1.0)
		var val: float = b.get("max_y", 1.0) - (b.get("max_y", 1.0) - b.get("min_y", 0.0)) * float(i) / float(grid_y)
		draw_string(UITheme.font("mono"), Vector2(4, gy + 5), GameConfig.fmt_num(val),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UITheme.COL.text_dim)
	var grid_x := 4
	for i in grid_x + 1:
		var gx: float = plot.position.x + plot.size.x * float(i) / float(grid_x)
		draw_line(Vector2(gx, plot.position.y), Vector2(gx, plot.end.y), Color(1, 1, 1, 0.05), 1.0)
		var xval: float = b.get("min_x", 0.0) + (b.get("max_x", 0.0) - b.get("min_x", 0.0)) * float(i) / float(grid_x)
		draw_string(UITheme.font("mono"), Vector2(gx - 14, plot.end.y + 17), "%d" % int(xval),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UITheme.COL.text_dim)
	# 序列
	var t := Time.get_ticks_msec() / 1000.0
	for s in series:
		var pts: Array = s.get("points", [])
		if pts.is_empty():
			continue
		var col: Color = s.get("color", UITheme.COL.accent)
		var prev: Vector2 = Vector2(-1, -1)
		for p in pts:
			var px: float = (float(p.get("x", 0.0)) - b.get("min_x", 0.0)) / max(0.001, b.get("max_x", 1.0) - b.get("min_x", 0.0))
			var py: float = (float(p.get("y", 0.0)) - b.get("min_y", 0.0)) / max(0.001, b.get("max_y", 1.0) - b.get("min_y", 0.0))
			var pt := Vector2(plot.position.x + px * plot.size.x, plot.end.y - py * plot.size.y)
			if prev.x >= 0.0:
				draw_line(prev, pt, col * Color(1, 1, 1, 0.85), 2.2, true)
			prev = pt
		# 末点光晕
		var last := pts[pts.size() - 1]
		var lpx: float = (float(last.get("x", 0.0)) - b.get("min_x", 0.0)) / max(0.001, b.get("max_x", 1.0) - b.get("min_x", 0.0))
		var lpy: float = (float(last.get("y", 0.0)) - b.get("min_y", 0.0)) / max(0.001, b.get("max_y", 1.0) - b.get("min_y", 0.0))
		var lp := Vector2(plot.position.x + lpx * plot.size.x, plot.end.y - lpy * plot.size.y)
		var pulse := 0.5 + 0.5 * absf(sin(t * 2.0 + float(s.get("seed", 0.0))))
		draw_circle(lp, 4.5 + pulse * 2.0, Color(col.r, col.g, col.b, 0.25))
		draw_circle(lp, 3.0, col)
	# 图例
	if show_legend:
		var lx := _pad_l + 4.0
		var ly := _pad_t + 6.0
		for s in series:
			var col: Color = s.get("color", UITheme.COL.accent)
			draw_rect(Rect2(lx, ly + 3, 14, 4), col)
			var name_s: String = str(s.get("name", ""))
			var last_y := 0.0
			var pts: Array = s.get("points", [])
			if not pts.is_empty():
				last_y = float(pts[pts.size() - 1].get("y", 0.0))
			var txt := "%s %s" % [name_s, GameConfig.fmt_num(last_y)]
			draw_string(UITheme.font("body"), Vector2(lx + 20, ly + 10), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
			lx += 26 + txt.length() * 8.0 + GameConfig.fmt_num(last_y).length() * 8.0
	draw_string(UITheme.font("body"), Vector2(plot.end.x - 24, plot.end.y + 17), x_label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UITheme.COL.text_dim)
