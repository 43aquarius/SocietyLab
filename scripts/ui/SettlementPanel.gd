## 右侧信息面板：聚落 / 建筑 / 地格 三种视图。
extends RefCounted

func build(game, s) -> Control:
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 6)
        # ---- 头部 ----
        var head := HBoxContainer.new()
        var icon := _icon(str((Database.FORMS.get(s.form, {}) as Dictionary).get("icon", "form_mixed")), 30)
        head.add_child(icon)
        var title_box := VBoxContainer.new()
        title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var t1 := UITheme.label(s.display_name(), 20, UITheme.COL.accent, "title")
        title_box.add_child(t1)
        var t2 := UITheme.label("%s · %s · %d 人" % [s.stage_name(), Database.form_name(s.form), s.population], 13, UITheme.COL.text_dim)
        title_box.add_child(t2)
        head.add_child(title_box)
        var focus_b := UITheme.icon_button("ui_focus", "聚焦（F）", Callable(self, "_focus").bind(game, s.cx, s.cy), 30)
        head.add_child(focus_b)
        v.add_child(head)
        v.add_child(UITheme.sep())
        # ---- 关键指标（少量） ----
        var d: Dictionary = s.derived
        var intake: float = float(d.get("intake_ratio", 1.0))
        var food_col := UITheme.COL.ok
        if s.famine_active:
                food_col = UITheme.COL.danger
        elif intake < 0.85:
                food_col = Color(1.0, 0.8, 0.4, 1)
        var grid := GridContainer.new()
        grid.columns = 2
        grid.add_theme_constant_override("h_separation", 10)
        grid.add_theme_constant_override("v_separation", 4)
        _stat(grid, "人口", "%d（%+.1f%%/年）" % [s.population, float(d.get("pop_growth", 0.0)) * 100.0], UITheme.COL.text)
        var years_food: float = s.food_store / max(1.0, float(s.population))
        _stat(grid, "存粮", "%.0f（%.1f 年）" % [s.food_store, years_food], food_col)
        _stat(grid, "粮食保障", "%d%%" % int(intake * 100.0), food_col)
        _stat(grid, "住房", "%d/%d" % [s.population, game.sim.pop_system.housing_cap(s)], Color(1, 0.8, 0.4) if s.population > game.sim.pop_system.housing_cap(s) else UITheme.COL.text)
        var gini: float = float(d.get("gini", 0.0))
        var gini_col := UITheme.COL.ok if gini < 0.45 else (UITheme.COL.danger if gini > 0.55 else Color(1.0, 0.8, 0.4))
        _stat(grid, "贫富差距", "%.2f" % gini, gini_col)
        var unrest: float = float(d.get("unrest", 0.0))
        _stat(grid, "动荡", "%d%%" % int(unrest * 100.0), UITheme.COL.danger if unrest > 0.5 else UITheme.COL.text)
        v.add_child(grid)
        # ---- 技术摘要 ----
        var tech_txt := ""
        for tid in ["early_agri", "writing", "masonry", "steam_engine", "electricity"]:
                if s.knows(tid):
                        tech_txt += Database.tech_name(tid) + " · "
        tech_txt = tech_txt.substr(0, max(0, tech_txt.length() - 3))
        if tech_txt == "":
                tech_txt = "尚未掌握关键技术"
        v.add_child(UITheme.label("技术：" + tech_txt, 13, UITheme.COL.text_dim))
        # ---- 群体 ----
        v.add_child(UITheme.label("社会群体", 15, UITheme.COL.accent))
        for gid in ["laborer", "elite", "merchant", "admin"]:
                var g: Dictionary = s.groups[gid]
                var row := HBoxContainer.new()
                row.add_theme_constant_override("separation", 8)
                var gcol := GameConfig.hex(str(Database.GROUPS.get(gid, {}).get("color", "#888888")))
                var dot := ColorRect.new()
                dot.custom_minimum_size = Vector2(10, 10)
                dot.color = gcol
                row.add_child(dot)
                row.add_child(UITheme.label(Database.group_name(gid), 14, gcol))
                var wealth: float = float(g.get("wealth", 0.0))
                var griev: float = float(g.get("grievance", 0.0))
                var org: float = float(g.get("org", 0.0))
                var txt := "财富 %d%% · 不满 %d%% · 组织 %d%%" % [int(wealth * 100), int(griev * 100), int(org * 100)]
                var l := UITheme.label(txt, 13, UITheme.COL.text_dim)
                l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                row.add_child(l)
                v.add_child(row)
        # ---- 建筑 ----
        v.add_child(UITheme.label("建筑（%d）" % s.buildings.size(), 15, UITheme.COL.accent))
        var counts := {}
        for b in s.buildings:
                var k: String = str(b.get("key", ""))
                var nm: String = Database.building_name(k)
                if not b.get("done", false):
                        nm += "（建造中 %d%%）" % int(float(b.get("progress", 0.0)) / max(1.0, float(Database.BUILDINGS.get(k, {}).get("years", 1))) * 100.0)
                counts[nm] = int(counts.get(nm, 0)) + 1
        var blist := ""
        for nm in counts:
                blist += "%s ×%d；" % [nm, counts[nm]]
        blist = blist.substr(0, max(0, blist.length() - 1))
        var bl := UITheme.label(blist if blist != "" else "仅有营地", 13, UITheme.COL.text_dim)
        bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        bl.custom_minimum_size = Vector2(320, 0)
        v.add_child(bl)
        # ---- 资源 ----
        var res_txt := "木 %.0f · 石 %.0f · 金属 %.0f" % [s.wood, s.stone, s.metal]
        v.add_child(UITheme.label(res_txt, 13, UITheme.COL.text_dim))
        # ---- 神力痕迹 ----
        if s.last_divine_year > 0 and game.world.year - s.last_divine_year <= 8:
                v.add_child(UITheme.label("✦ 此地近年间接受过神迹", 13, UITheme.COL.accent))
        # ---- 详情开关 ----
        var detail := Button.new()
        detail.text = "展开全部数据 ▸"
        var detail_box := VBoxContainer.new()
        detail_box.visible = false
        var expanded := false
        detail.pressed.connect(func():
                expanded = not expanded
                detail_box.visible = expanded
                detail.text = "收起全部数据 ▸" if expanded else "展开全部数据 ▸"
                )
        v.add_child(detail)
        _build_details(detail_box, s)
        v.add_child(detail_box)
        return v

func _build_details(box: VBoxContainer, s) -> void:
        # 所有制
        box.add_child(UITheme.label("生产资料所有制", 14, UITheme.COL.accent))
        var o := HBoxContainer.new()
        for kind in ["communal", "private", "state"]:
                var val: float = float(s.inst.get(kind, 0.0))
                var col := GameConfig.hex({"communal": "#A89F93", "private": "#6FA8DC", "state": "#D66058"}.get(kind, "#888"))
                var cb := ColorRect.new()
                cb.color = col
                cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                cb.custom_minimum_size = Vector2(20, 12)
                cb.size_flags_stretch_ratio = max(0.02, val)
                o.add_child(cb)
        box.add_child(o)
        box.add_child(UITheme.label("公有 %.0f%% · 私有 %.0f%% · 国有 %.0f%%" % [float(s.inst.get("communal", 0.0)) * 100.0, float(s.inst.get("private", 0.0)) * 100.0, float(s.inst.get("state", 0.0)) * 100.0], 12, UITheme.COL.text_dim))
        # 劳动关系
        box.add_child(UITheme.label("劳动关系", 14, UITheme.COL.accent))
        var l := HBoxContainer.new()
        for kind in ["forced", "bonded", "wage", "coop"]:
                var val: float = float(s.inst.get(kind, 0.0))
                var col := GameConfig.hex({"forced": "#C66C5A", "bonded": "#9470AA", "wage": "#6FA8DC", "coop": "#D66058"}.get(kind, "#888"))
                var cb := ColorRect.new()
                cb.color = col
                cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                cb.custom_minimum_size = Vector2(20, 12)
                cb.size_flags_stretch_ratio = max(0.02, val)
                l.add_child(cb)
        box.add_child(l)
        box.add_child(UITheme.label("强制 %.0f%% · 依附 %.0f%% · 雇佣 %.0f%% · 合作 %.0f%%" % [float(s.inst.get("forced", 0.0)) * 100.0, float(s.inst.get("bonded", 0.0)) * 100.0, float(s.inst.get("wage", 0.0)) * 100.0, float(s.inst.get("coop", 0.0)) * 100.0], 12, UITheme.COL.text_dim))
        # 制度数值
        var rows := [
                ["市场发育", float(s.inst.get("market_dev", 0.0)), 1.0],
                ["国家能力", float(s.inst.get("state_capacity", 0.0)), 1.0],
                ["公共服务", float(s.inst.get("public_service", 0.0)), 1.0],
                ["教育", float(s.inst.get("education", 0.0)), 1.0],
                ["政治参与", float(s.inst.get("participation", 0.0)), 1.0],
                ["制度信任", float(s.inst.get("trust", 0.0)), 1.0],
                ["土地集中", float(s.inst.get("land_concentration", 0.0)), 1.0],
                ["税率", float(s.inst.get("tax_rate", 0.0)), 0.5],
                ["专业化", float(s.inst.get("specialization", 0.0)), 1.0],
        ]
        for r in rows:
                var hb := HBoxContainer.new()
                hb.add_child(UITheme.label(r[0], 13, UITheme.COL.text_dim))
                var sp := Control.new()
                sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
                hb.add_child(sp)
                hb.add_child(UITheme.label("%d%%" % int(float(r[1]) / float(r[2]) * 100.0), 13, UITheme.COL.text, "mono"))
                box.add_child(hb)
        # 技术领域
        var tt := ""
        for dom in Database.TECH_DOMAINS:
                tt += "%s %d " % [str(Database.TECH_DOMAINS[dom]), int(float(s.tech.get(dom, 0.0)))]
        box.add_child(UITheme.label("领域等级：" + tt, 13, UITheme.COL.text_dim))
        var dd := ""
        for k in ["food_prod", "craft_output", "trade_income", "health", "stability", "defense", "pollution"]:
                dd += "%s %.2f；" % [k, float(s.derived.get(k, 0.0))]
        box.add_child(UITheme.label("派生量：" + dd, 12, UITheme.COL.text_dim))

# ==================== 建筑视图 ====================
func build_building(game, s, b) -> Control:
        var v := VBoxContainer.new()
        var key: String = str(b.get("key", ""))
        var info: Dictionary = Database.BUILDINGS.get(key, {})
        var head := HBoxContainer.new()
        head.add_child(_icon(_building_icon(key), 34))
        var tb := VBoxContainer.new()
        tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tb.add_child(UITheme.label(info.get("name", key), 19, UITheme.COL.accent, "title"))
        var status := ""
        if b.get("done", false):
                status = "建成于第%d年" % int(b.get("year_built", 0))
        else:
                var years: float = max(1.0, float(info.get("years", 1)))
                var prog: float = float(b.get("progress", 0.0))
                if not b.get("paid", false):
                        status = "等待资源（木%d 石%d 金属%d）" % [int(info.get("cost", {}).get("wood", 0)), int(info.get("cost", {}).get("stone", 0)), int(info.get("cost", {}).get("metal", 0))]
                else:
                        status = "建造中 %d%%" % int(prog / years * 100.0)
        tb.add_child(UITheme.label(status, 13, UITheme.COL.text_dim))
        head.add_child(tb)
        var focus_b := UITheme.icon_button("ui_focus", "聚焦", Callable(self, "_focus").bind(game, int(b.get("tx", 0)), int(b.get("ty", 0))), 30)
        head.add_child(focus_b)
        v.add_child(head)
        v.add_child(UITheme.sep())
        var fx: Dictionary = info.get("fx", {})
        var fx_txt := ""
        for k in fx:
                fx_txt += "%s：%s；" % [k, str(fx[k])]
        v.add_child(UITheme.label("游戏效果：" + (fx_txt if fx_txt != "" else "住房容量 %d" % int(info.get("cap", 0))), 13, UITheme.COL.text_dim))
        v.add_child(UITheme.label("所属：%s（人口 %d）" % [s.display_name(), s.population], 13, UITheme.COL.text_dim))
        if s.form != "":
                v.add_child(UITheme.label("社会形态：" + Database.form_name(s.form), 13, UITheme.COL.text_dim))
        return v

# ==================== 地格视图 ====================
func build_tile(game, x: int, y: int) -> Control:
        var v := VBoxContainer.new()
        var w = game.world
        var t: int = w.get_terrain(x, y)
        var r: int = w.get_resource(x, y)
        var head := HBoxContainer.new()
        head.add_child(_icon(_terrain_icon(t), 34))
        var tb := VBoxContainer.new()
        tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tb.add_child(UITheme.label(GameConfig.terrain_name(t), 19, UITheme.COL.accent, "title"))
        var fert: float = w.get_fertility(x, y)
        var moist: float = w.tile_moisture_mod(x, y)
        var moist_txt := "正常"
        if moist > 1.05:
                moist_txt = "丰沛（甘霖）"
        elif moist < 0.95:
                moist_txt = "干旱"
        tb.add_child(UITheme.label("肥力 %d%% · 水气 %s" % [int(fert * 100.0), moist_txt], 13, UITheme.COL.text_dim))
        head.add_child(tb)
        v.add_child(head)
        v.add_child(UITheme.sep())
        if r != 0:
                var rinfo: Dictionary = GameConfig.RESOURCE_INFO.get(r, {})
                v.add_child(UITheme.label("资源：%s" % rinfo.get("name", "?"), 15, UITheme.COL.accent))
        var owner = w.settlement_at_tile(x, y)
        if owner != null:
                v.add_child(UITheme.label("归属：%s 领地" % owner.display_name(), 13, UITheme.COL.text_dim))
                var intake: float = float(owner.derived.get("intake_ratio", 1.0))
                v.add_child(UITheme.label("该聚落粮食保障 %d%%" % int(intake * 100.0), 13, UITheme.COL.text_dim if intake > 0.85 else Color(1.0, 0.7, 0.4)))
        else:
                v.add_child(UITheme.label("无主之地", 13, UITheme.COL.text_dim))
        var effects_txt := ""
        for e in w.effects:
                var ex: int = int(e.get("x", -99))
                var ey: int = int(e.get("y", -99))
                if abs(ex - x) <= int(e.get("radius", 0)) and abs(ey - y) <= int(e.get("radius", 0)):
                        if e.get("kind", "") == "rain":
                                effects_txt += "甘霖（至第%d年）；" % int(e.get("until", 0))
                        elif e.get("kind", "") == "drought":
                                effects_txt += "酷旱（至第%d年）；" % int(e.get("until", 0))
        if effects_txt != "":
                v.add_child(UITheme.label("天象：" + effects_txt, 13, UITheme.COL.blue))
        return v

# ==================== 辅助 ====================
func _stat(grid: GridContainer, name_s: String, val: String, col: Color) -> void:
        grid.add_child(UITheme.label(name_s, 13, UITheme.COL.text_dim))
        grid.add_child(UITheme.label(val, 14, col, "mono"))

func _icon(key: String, size := 26) -> TextureRect:
        var tr := TextureRect.new()
        var t := ArtCache.tex(key)
        if t != null:
                tr.texture = t
        tr.custom_minimum_size = Vector2(size, size)
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return tr

func _focus(game, x: int, y: int) -> void:
        Audio.play("click")
        game.camera.focus_tile(x, y)

func _terrain_icon(t: int) -> String:
        match t:
                GameConfig.T_WATER: return "pow_water"
                GameConfig.T_FOREST: return "pow_forest"
                GameConfig.T_FERTILE: return "pow_fertile"
                GameConfig.T_MOUNTAIN: return "form_primitive"
                GameConfig.T_ROCK: return "res_stone"
                GameConfig.T_SAND: return "ev_degrade"
                _: return "pow_forest"

func _building_icon(key: String) -> String:
        return "ev_city"
