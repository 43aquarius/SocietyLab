# -*- coding: utf-8 -*-
"""资产生成总入口：按依赖顺序执行所有生成器并输出拼图供审查"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.chdir(os.path.dirname(os.path.abspath(__file__)))
import asset_common as AC
import gen_terrain, gen_buildings_a, gen_buildings_b, gen_villagers, gen_ui_a, gen_ui_b, gen_banner, gen_audio

if __name__ == "__main__":
    gen_terrain.gen_tiles()
    gen_terrain._pine(0); gen_terrain._pine(1); gen_terrain._pine(2)
    gen_terrain._oak(0); gen_terrain._oak(1)
    gen_terrain._peak(False); gen_terrain._peak(True)
    gen_terrain._rock(0); gen_terrain._rock(1)
    gen_terrain._ore("iron"); gen_terrain._ore("gold")
    gen_terrain._bush(); gen_terrain._reeds()
    gen_buildings_a.camp_tent(); gen_buildings_a.hut(); gen_buildings_a.house_wood()
    gen_buildings_a.house_brick(); gen_buildings_a.house_town(); gen_buildings_a.apartment()
    gen_buildings_a._farm(0); gen_buildings_a._farm(1); gen_buildings_a._farm(2)
    gen_buildings_a.farm_irrigated(); gen_buildings_a.farm_modern()
    gen_buildings_a.warehouse(); gen_buildings_a.granary()
    gen_buildings_b.well(); gen_buildings_b.workshop(); gen_buildings_b.factory()
    gen_buildings_b.market(); gen_buildings_b.admin_hall(); gen_buildings_b.manor()
    gen_buildings_b.castle(); gen_buildings_b.wall_tower()
    gen_buildings_b.temple(); gen_buildings_b.assembly()
    gen_buildings_b.school(); gen_buildings_b.hospital()
    gen_buildings_b.cooperative(); gen_buildings_b.construction()
    import gen_villagers as GV
    for gid, g in GV.GROUPS.items():
        for frame in ("idle", "walk_a", "walk_b", "carry_a", "carry_b"):
            GV._villager(gid, g, frame)
    import gen_ui_a as UA, gen_ui_b as UB
    for key, fn in [("pow_forest", UA.g_forest), ("pow_fertile", UA.g_fertile), ("pow_water", UA.g_water),
                    ("pow_ore", UA.g_ore), ("pow_rain", UA.g_rain), ("pow_drought", UA.g_drought),
                    ("pow_bless", UA.g_bless), ("pow_enlight", UA.g_enlight), ("pow_idea", UA.g_idea),
                    ("res_food", UA.g_food), ("res_wood", UA.g_wood), ("res_stone", UA.g_stone),
                    ("res_metal", UA.g_metal), ("res_pop", UA.g_pop), ("res_know", UA.g_know),
                    ("res_faith", UA.g_faith), ("res_coin", UA.g_coin)]:
        UA.chip(key, fn)
    for key, fn in [("form_primitive", UB.f_primitive), ("form_slave", UB.f_slave), ("form_feudal", UB.f_feudal),
                    ("form_capital", UB.f_capital), ("form_social", UB.f_social), ("form_mixed", UB.f_mixed),
                    ("ui_play", UB.b_play), ("ui_pause", UB.b_pause), ("ui_step", UB.b_step), ("ui_ff", UB.b_ff),
                    ("ui_home", UB.b_home), ("ui_help", UB.b_help), ("ui_gear", UB.b_gear),
                    ("ui_chronicle", UB.b_chronicle), ("ui_observer", UB.b_observer),
                    ("ui_close", UB.b_close), ("ui_branch", UB.b_branch), ("ui_focus", UB.b_focus),
                    ("ev_harvest", UB.e_harvest), ("ev_famine", UB.e_famine), ("ev_disease", UB.e_disease),
                    ("ev_discovery", UB.e_discovery), ("ev_migration", UB.e_migration), ("ev_trade", UB.e_trade),
                    ("ev_conflict", UB.e_conflict), ("ev_reform", UB.e_reform), ("ev_war", UB.e_war),
                    ("ev_idea", UB.e_idea), ("ev_boom", UB.e_boom), ("ev_golden", UB.e_golden),
                    ("ev_degrade", UB.e_degrade), ("ev_city", UB.e_city), ("ev_inst", UB.e_inst)]:
        UB.chip(key, fn)
    gen_banner.gen_banner()
    gen_audio.gen_sfx(); gen_audio.gen_loops()
    AC.write_manifest()
    # 拼图审查
    sheets = {
        "review_tiles.png": [k for k in AC.REGISTRY if k.startswith(("tiles/", "props/"))],
        "review_buildings.png": [k for k in AC.REGISTRY if k.startswith("buildings/")],
        "review_villagers.png": [k for k in AC.REGISTRY if k.startswith("villagers/")],
        "review_icons.png": [k for k in AC.REGISTRY if k.startswith("ui/") and k != "ui/banner_main"],
    }
    for out, keys in sheets.items():
        AC.contact_sheet(sorted(keys), "/home/z/my-project/society-lab/assets/" + out)
    print("ALL ASSETS DONE:", len(AC.REGISTRY), "entries")
