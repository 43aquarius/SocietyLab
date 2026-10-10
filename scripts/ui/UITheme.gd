class_name UITheme
## 统一视觉主题：暖琥珀强调 + 深板岩底 + 衬线标题（编年史/博物馆气质）。
## 所有 UI 控件通过 add_theme_*_override 或共享 Theme 使用这里的定义。

const COL := {
	"bg": Color(0.10, 0.12, 0.16, 1.0),
	"panel": Color(0.11, 0.13, 0.18, 0.94),
	"panel_deep": Color(0.08, 0.09, 0.13, 0.97),
	"panel_line": Color(1, 1, 1, 0.10),
	"text": Color(0.95, 0.93, 0.88, 1.0),
	"text_dim": Color(0.62, 0.66, 0.72, 1.0),
	"accent": Color(0.92, 0.71, 0.29, 1.0),
	"accent_soft": Color(0.92, 0.71, 0.29, 0.16),
	"blue": Color(0.44, 0.69, 0.88, 1.0),
	"danger": Color(0.88, 0.42, 0.35, 1.0),
	"ok": Color(0.50, 0.75, 0.42, 1.0),
	"btn": Color(0.16, 0.19, 0.25, 1.0),
	"btn_hover": Color(0.24, 0.28, 0.36, 1.0),
	"btn_press": Color(0.12, 0.14, 0.19, 1.0),
}

static var _theme: Theme
static var _fonts: Dictionary = {}

static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var path := ""
	match kind:
		"title": path = "res://assets/fonts/NotoSerifSC-Black.subset.ttf"
		"body": path = "res://assets/fonts/NotoSerifSC-Regular.subset.ttf"
		"mono": path = "res://assets/fonts/SarasaMonoSC-Regular.subset.ttf"
	var f: Font = null
	if ResourceLoader.exists(path):
		f = load(path)
	if f == null:
		push_warning("UITheme: 字体未导入，回退默认字体（中文可能显示为方块）")
		f = ThemeDB.fallback_font
	# 系统字体回退链：覆盖子集外字符（如玩家输入的生僻字）
	if f != null and f != ThemeDB.fallback_font:
		f.fallbacks = [_sys_cjk()]
	_fonts[kind] = f
	return f

static var _sys: SystemFont

static func _sys_cjk() -> SystemFont:
	if _sys != null:
		return _sys
	_sys = SystemFont.new()
	_sys.font_names = PackedStringArray([
		"Noto Serif SC", "Noto Sans SC", "Source Han Serif SC", "Source Han Sans SC",
		"Microsoft YaHei", "SimSun", "SimHei", "WenQuanYi Zen Hei", "WenQuanYi Micro Hei",
	])
	return _sys

static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font("body")
	t.default_font_size = 15
	# ---- Panel ----
	var sb_panel := StyleBoxFlat.new()
	sb_panel.bg_color = COL.panel
	sb_panel.border_color = COL.panel_line
	sb_panel.set_border_width_all(1)
	sb_panel.set_corner_radius_all(12)
	sb_panel.content_margin_left = 14
	sb_panel.content_margin_right = 14
	sb_panel.content_margin_top = 10
	sb_panel.content_margin_bottom = 10
	t.set_stylebox("panel", "Panel", sb_panel)
	t.set_stylebox("panel", "PanelContainer", sb_panel)
	var sb_deep := sb_panel.duplicate()
	sb_deep.bg_color = COL.panel_deep
	sb_deep.set_corner_radius_all(10)
	t.set_stylebox("panel", "AcceptDialog", sb_deep)
	# ---- Button ----
	var sb_btn := StyleBoxFlat.new()
	sb_btn.bg_color = COL.btn
	sb_btn.border_color = Color(1, 1, 1, 0.08)
	sb_btn.set_border_width_all(1)
	sb_btn.set_corner_radius_all(9)
	sb_btn.content_margin_left = 12
	sb_btn.content_margin_right = 12
	sb_btn.content_margin_top = 6
	sb_btn.content_margin_bottom = 6
	t.set_stylebox("normal", "Button", sb_btn)
	var sb_btn_h := sb_btn.duplicate()
	sb_btn_h.bg_color = COL.btn_hover
	sb_btn_h.border_color = COL.accent * Color(1, 1, 1, 0.6)
	t.set_stylebox("hover", "Button", sb_btn_h)
	var sb_btn_p := sb_btn.duplicate()
	sb_btn_p.bg_color = COL.btn_press
	t.set_stylebox("pressed", "Button", sb_btn_p)
	var sb_btn_d := sb_btn.duplicate()
	sb_btn_d.bg_color = Color(0.1, 0.11, 0.15, 0.7)
	t.set_stylebox("disabled", "Button", sb_btn_d)
	t.set_color("font_color", "Button", COL.text)
	t.set_color("font_hover_color", "Button", COL.accent)
	t.set_color("font_pressed_color", "Button", COL.text)
	t.set_color("font_disabled_color", "Button", Color(0.4, 0.42, 0.48, 1))
	# ---- Label ----
	t.set_color("font_color", "Label", COL.text)
	# ---- LineEdit ----
	var sb_le := StyleBoxFlat.new()
	sb_le.bg_color = Color(0.07, 0.08, 0.11, 1)
	sb_le.border_color = Color(1, 1, 1, 0.14)
	sb_le.set_border_width_all(1)
	sb_le.set_corner_radius_all(7)
	sb_le.content_margin_left = 9
	sb_le.content_margin_right = 9
	sb_le.content_margin_top = 5
	sb_le.content_margin_bottom = 5
	t.set_stylebox("normal", "LineEdit", sb_le)
	var sb_le_f := sb_le.duplicate()
	sb_le_f.border_color = COL.accent
	t.set_stylebox("focus", "LineEdit", sb_le_f)
	# ---- Tooltip ----
	var sb_tip := StyleBoxFlat.new()
	sb_tip.bg_color = Color(0.05, 0.06, 0.09, 0.97)
	sb_tip.border_color = COL.accent * Color(1, 1, 1, 0.5)
	sb_tip.set_border_width_all(1)
	sb_tip.set_corner_radius_all(6)
	sb_tip.content_margin_left = 10
	sb_tip.content_margin_right = 10
	sb_tip.content_margin_top = 6
	sb_tip.content_margin_bottom = 6
	t.set_stylebox("panel", "TooltipPanel", sb_tip)
	# ---- HScrollBar/VScrollBar 简化 ----
	_theme = t
	return t

## 通用快捷构造 ------------------------------------------------
static func label(text: String, size: int = 15, color: Color = COL.text, kind: String = "body") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(kind))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b

static func icon_button(icon_key: String, tip: String, cb: Callable, size: int = 40) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(size, size)
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.19, 0.25, 0.85)
	sb.corner_radius_top_left = 9
	sb.corner_radius_top_right = 9
	sb.corner_radius_bottom_left = 9
	sb.corner_radius_bottom_right = 9
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate()
	sbh.bg_color = Color(0.26, 0.30, 0.38, 1.0)
	b.add_theme_stylebox_override("hover", sbh)
	var sbp := sb.duplicate()
	sbp.bg_color = COL.accent_soft
	b.add_theme_stylebox_override("pressed", sbp)
	var t := ArtCache.tex(icon_key)
	if t != null:
		var tex_rect := TextureRect.new()
		tex_rect.texture = t
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.anchor_left = 0.5
		tex_rect.anchor_top = 0.5
		tex_rect.anchor_right = 0.5
		tex_rect.anchor_bottom = 0.5
		tex_rect.offset_left = -size * 0.44
		tex_rect.offset_top = -size * 0.44
		tex_rect.offset_right = size * 0.44
		tex_rect.offset_bottom = size * 0.44
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tex_rect)
	b.pressed.connect(cb)
	return b

static func hslider(minv: float, maxv: float, val: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = minv
	s.max_value = maxv
	s.step = 1
	s.value = val
	s.custom_minimum_size = Vector2(160, 18)
	return s

static func sep() -> HSeparator:
	var hs := HSeparator.new()
	hs.add_theme_constant_override("separation", 6)
	return hs

static func panel_style(cx: Control) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL.panel
	sb.border_color = COL.panel_line
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	cx.add_theme_stylebox_override("panel", sb)
