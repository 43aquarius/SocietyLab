## 游戏内对话框集合：暂停菜单 / 保存 / 读取 / 设置。
extends Control

var game
var main_list: VBoxContainer
var name_edit: LineEdit

func _init(p_game) -> void:
        game = p_game

func open_pause_menu() -> Control:
        _build_shell("暂停菜单", 300, 360)
        _add_btn("继续游戏（Esc）", func(): close())
        _add_btn("保存世界", func():
                _open_save()
                )
        _add_btn("读取存档", func():
                _open_load()
                )
        _add_btn("设置", func():
                _open_settings()
                )
        _add_sep()
        _add_btn("回到主菜单", func():
                game.main.return_to_menu()
                )
        _add_btn("退出游戏", func():
                game.get_tree().quit()
                )
        return self

func _build_shell(title: String, w: int, h: int) -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        var dim := ColorRect.new()
        dim.color = Color(0, 0, 0, 0.55)
        dim.set_anchors_preset(Control.PRESET_FULL_RECT)
        dim.mouse_filter = Control.MOUSE_FILTER_STOP
        dim.gui_input.connect(func(ev):
                if ev is InputEventMouseButton and ev.pressed:
                        close()
                )
        add_child(dim)
        var pc := PanelContainer.new()
        pc.set_anchors_preset(Control.PRESET_CENTER)
        pc.offset_left = -w / 2.0
        pc.offset_right = w / 2.0
        pc.offset_top = -h / 2.0
        pc.offset_bottom = h / 2.0
        add_child(pc)
        UITheme.panel_style(pc)
        main_list = VBoxContainer.new()
        main_list.add_theme_constant_override("separation", 8)
        pc.add_child(main_list)
        main_list.add_child(UITheme.label(title, 24, UITheme.COL.accent, "title"))
        main_list.add_child(UITheme.sep())

func _add_btn(text: String, cb: Callable) -> void:
        var b := Button.new()
        b.text = text
        b.custom_minimum_size = Vector2(230, 38)
        b.pressed.connect(cb)
        main_list.add_child(b)

func _add_sep() -> void:
        main_list.add_child(UITheme.sep())

func _clear_shell() -> void:
        for c in main_list.get_children():
                main_list.remove_child(c)
                c.queue_free()

func _shell_replace(title: String) -> void:
        for c in get_children():
                if c is PanelContainer:
                        remove_child(c)
                        c.queue_free()
        var pc := PanelContainer.new()
        pc.set_anchors_preset(Control.PRESET_CENTER)
        pc.offset_left = -210
        pc.offset_right = 210
        pc.offset_top = -215
        pc.offset_bottom = 215
        add_child(pc)
        UITheme.panel_style(pc)
        main_list = VBoxContainer.new()
        main_list.add_theme_constant_override("separation", 8)
        pc.add_child(main_list)
        main_list.add_child(UITheme.label(title, 22, UITheme.COL.accent, "title"))
        main_list.add_child(UITheme.sep())

# ==================== 保存 ====================
func _open_save() -> void:
        _shell_replace("保存世界")
        var hint := UITheme.label("存档名：", 14, UITheme.COL.text_dim)
        main_list.add_child(hint)
        name_edit = LineEdit.new()
        name_edit.text = "%s_第%d年" % [game.world.world_name, game.world.year]
        name_edit.custom_minimum_size = Vector2(280, 32)
        main_list.add_child(name_edit)
        var ok := Button.new()
        ok.text = "保存"
        ok.custom_minimum_size = Vector2(280, 38)
        ok.pressed.connect(func():
                var payload := game.sim.session_payload()
                var ok2 := game.save_manager.save_game(payload, name_edit.text)
                if ok2:
                        game.hud.toast("已保存：%s" % name_edit.text, "good")
                        Audio.play("chime")
                        close()
                else:
                        game.hud.toast("保存失败（检查 user://saves 可写）", "bad")
                )
        main_list.add_child(ok)
        _add_btn("返回", func(): close())

# ==================== 读取 ====================
func _open_load() -> void:
        _shell_replace("读取存档")
        var sv := ScrollContainer.new()
        sv.custom_minimum_size = Vector2(360, 300)
        main_list.add_child(sv)
        var list := VBoxContainer.new()
        sv.add_child(list)
        var saves: Array = game.save_manager.list_saves()
        if saves.is_empty():
                list.add_child(UITheme.label("（没有找到存档）", 14, UITheme.COL.text_dim))
        for item in saves:
                var row := HBoxContainer.new()
                row.add_theme_constant_override("separation", 8)
                var info := VBoxContainer.new()
                info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                info.add_child(UITheme.label(str(item.get("world_name", "?")), 15, UITheme.COL.text))
                info.add_child(UITheme.label("第%d年 · %d 聚落 · 种子 %d" % [int(item.get("year", 0)), int(item.get("settlements", 0)), int(item.get("seed", 0))], 12, UITheme.COL.text_dim))
                row.add_child(info)
                var load_b := Button.new()
                load_b.text = "读取"
                load_b.pressed.connect(func():
                        game.main.load_from_file(str(item.get("path", "")))
                        close()
                        )
                row.add_child(load_b)
                var del_b := UITheme.icon_button("ui_close", "删除", func():
                        game.save_manager.delete_save(str(item.get("path", "")))
                        _open_load()
                        , 26)
                row.add_child(del_b)
                list.add_child(row)
        _add_btn("返回", func(): close())

# ==================== 设置 ====================
func _open_settings() -> void:
        _shell_replace("设置")
        main_list.add_child(UITheme.label("主音量", 14, UITheme.COL.text_dim))
        var vol := UITheme.hslider(0, 100, int(Audio.master_volume * 100.0))
        vol.value_changed.connect(func(v):
                Audio.set_master_volume(float(v) / 100.0)
                )
        main_list.add_child(vol)
        main_list.add_child(UITheme.label("环境氛围", 14, UITheme.COL.text_dim))
        var amb := CheckButton.new()
        amb.button_pressed = Audio.ambient_on
        amb.toggled.connect(func(on):
                Audio.ambient_on = on
                if on:
                        Audio.play_ambient()
                else:
                        Audio.stop_ambient()
                )
        main_list.add_child(amb)
        main_list.add_child(UITheme.label("操作方式：滚轮缩放 · 拖动平移 · 空格暂停 · H 编年史 · O 观察者 · F1 帮助", 12, UITheme.COL.text_dim))
        _add_btn("返回", func(): close())

func close() -> void:
        game.hud_locked = false
        queue_free()
