## 相机控制：滚轮缩放（锚定鼠标）、拖拽平移、聚焦聚落、复位全景。
extends Camera2D

const ZOOM_MIN := 0.34
const ZOOM_MAX := 3.2
const PAN_KEY_SPEED := 620.0

var map_size: int = 48
var pan_enabled: bool = true
var _dragging: bool = false
var _drag_last := Vector2.ZERO
var _focus_tween: Tween

func setup(p_map_size: int) -> void:
        map_size = p_map_size
        position = Vector2.ZERO
        zoom = Vector2.ONE
        reset_view()

func reset_view() -> void:
        var vp := get_viewport_rect().size
        var b := IsoMath.map_bounds_world(map_size)
        var zx := vp.x / max(1.0, b.size.x * 1.12)
        var zy := vp.y / max(1.0, b.size.y * 1.28)
        var z: float = clamp(min(zx, zy), ZOOM_MIN, 1.0)
        z = min(z, 1.0)
        zoom = Vector2(z, z)
        position = b.get_center()
        position_smoothing_enabled = false

func focus_tile(tx: int, ty: int, target_zoom: float = 1.25) -> void:
        var world_pos := IsoMath.tile_center(tx, ty)
        _focus_tween = create_tween()
        _focus_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        _focus_tween.tween_property(self, "position", world_pos, 0.5)
        var z: float = clamp(target_zoom, ZOOM_MIN, ZOOM_MAX)
        if absf(zoom.x - z) > 0.05:
                _focus_tween.parallel().tween_property(self, "zoom", Vector2(z, z), 0.5)

func clamp_to_map() -> void:
        var b := IsoMath.map_bounds_world(map_size)
        b = b.grow(160.0)
        var vp := get_viewport_rect().size / zoom
        var half := vp * 0.5
        var min_p := b.position + half
        var max_p := b.position + b.size - half
        if min_p.x > max_p.x:
                position.x = b.get_center().x
        else:
                position.x = clamp(position.x, min_p.x, max_p.x)
        if min_p.y > max_p.y:
                position.y = b.get_center().y
        else:
                position.y = clamp(position.y, min_p.y, max_p.y)

func _process(delta: float) -> void:
        # 键盘平移
        var dir := Vector2.ZERO
        if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
                dir.x -= 1.0
        if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
                dir.x += 1.0
        if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
                dir.y -= 1.0
        if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
                dir.y += 1.0
        if dir != Vector2.ZERO and pan_enabled:
                position += dir * PAN_KEY_SPEED * delta / zoom
                clamp_to_map()

func _unhandled_input(event: InputEvent) -> void:
        if event is InputEventMouseButton:
                var mb := event as InputEventMouseButton
                if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
                        _zoom_at(mb.position, 1.18)
                elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
                        _zoom_at(mb.position, 1.0 / 1.18)
                elif mb.button_index == MOUSE_BUTTON_MIDDLE:
                        _dragging = mb.pressed
                        _drag_last = mb.position
                elif mb.button_index == MOUSE_BUTTON_LEFT and pan_enabled:
                        if mb.pressed:
                                _dragging = true
                                _drag_last = mb.position
                        else:
                                _dragging = false
                elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
                        pass
        elif event is InputEventMouseMotion:
                var mm := event as InputEventMouseMotion
                if _dragging and pan_enabled:
                        # 神力工具激活时，左键拖拽不作为平移（交给 GameWorld 施法）
                        var tool_drag: bool = _tool_active() and bool(mm.button_mask & MOUSE_BUTTON_MASK_LEFT)
                        if not tool_drag:
                                var d := (mm.position - _drag_last) / zoom
                                position -= d
                                _drag_last = mm.position
                                position_smoothing_enabled = false
                                clamp_to_map()

func _tool_active() -> bool:
        var p := get_parent()
        return p != null and p.get("tool_active") == true

func _zoom_at(screen_pos: Vector2, factor: float) -> void:
        var old_zoom := zoom.x
        var new_z: float = clamp(old_zoom * factor, ZOOM_MIN, ZOOM_MAX)
        if absf(new_z - old_zoom) < 0.0005:
                return
        var before := get_global_mouse_position()
        zoom = Vector2(new_z, new_z)
        var after := get_global_mouse_position()
        position += before - after
        position_smoothing_enabled = false
        clamp_to_map()
