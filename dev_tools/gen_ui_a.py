# -*- coding: utf-8 -*-
"""UI 图标 A：神力 + 资源（44x44 圆角芯片风格，粗描摹图形）"""
import os, sys
from PIL import ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asset_common import P, SS, canvas, finish, save, outline_poly, rrect, REGISTRY

CHIP = (38, 42, 54, 255)
CHIP_EDGE = (255, 255, 255, 30)
S = 44

def chip(key, glyph, accent=None):
    img = canvas(S, S)
    d = ImageDraw.Draw(img)
    cx, cy = S * SS / 2, S * SS / 2
    rrect(d, [3 * SS, 3 * SS, (S - 3) * SS, (S - 3) * SS], 11, CHIP, edge=CHIP_EDGE, edge_w=1.6)
    glyph(d, cx, cy, 1.0)
    save(finish(img, S, S), "ui", key)

def L(x):  # helper: 1x -> 4x
    return x * SS

# ---------- 神力 ----------
def g_forest(d, cx, cy, s):
    for k, (dy, w, h) in enumerate([(-2, 26, 16), (-12, 20, 13), (-20, 14, 10)]):
        col = P["pine_l"] if k == 2 else P["pine_m"]
        outline_poly(d, [(cx, cy + L(dy - h)), (cx + L(w / 2), cy + L(dy)), (cx, cy + L(dy + 5)), (cx - L(w / 2), cy + L(dy))],
                     col, edge=P["ink"], edge_w=1.6)
    d.rectangle([cx - L(3), cy + L(2), cx + L(3), cy + L(12)], fill=P["trunk"], outline=P["ink"], width=L(1.4))

def g_fertile(d, cx, cy, s):
    d.line([(cx, cy + L(14)), (cx, cy - L(14))], fill=P["gold"], width=L(4))
    for k in range(4):
        yy = cy - L(10) + k * L(7)
        d.ellipse([cx - L(9), yy - L(3), cx - L(1), yy + L(3)], fill=P["gold_hi"], outline=P["ink"], width=L(1))
        d.ellipse([cx + L(1), yy - L(3), cx + L(9), yy + L(3)], fill=P["gold"], outline=P["ink"], width=L(1))

def g_water(d, cx, cy, s):
    outline_poly(d, [(cx, cy - L(16)), (cx + L(11), cy + L(2)), (cx, cy + L(15)), (cx - L(11), cy + L(2))],
                 (92, 158, 214, 255), edge=P["ink"], edge_w=1.8)
    d.ellipse([cx - L(6), cy - L(8), cx - L(1), cy - L(2)], fill=(190, 232, 250, 255))

def g_ore(d, cx, cy, s):
    outline_poly(d, [(cx, cy - L(10)), (cx + L(9), cy + L(2)), (cx, cy + L(8)), (cx - L(9), cy + L(2))],
                 P["iron"], edge=P["ink"], edge_w=1.8)
    d.line([(cx - L(2), cy - L(6)), (cx - L(4), cy - L(8))], fill=P["iron_hi"], width=L(2))
    d.line([(cx + L(4), cy - L(16)), (cx - L(14), cy + L(14))], fill=(222, 176, 110, 255), width=L(5))
    d.line([(cx - L(16), cy + L(8)), (cx - L(10), cy + L(16))], fill=(160, 120, 76, 255), width=L(5))

def g_rain(d, cx, cy, s):
    for dx, r in [(-9, 9), (0, 11), (10, 8)]:
        d.ellipse([cx + L(dx - r), cy + L(-16 - r), cx + L(dx + r), cy + L(-6)], fill=(168, 206, 232, 255), outline=P["ink"], width=L(1.5))
    d.rounded_rectangle([cx - L(20), cy + L(-10), cx + L(22), cy + L(-2)], L(6), fill=(168, 206, 232, 255), outline=P["ink"], width=L(1.5))
    for k in (-12, -4, 4, 12):
        d.line([(cx + L(k), cy + L(4)), (cx + L(k - 3), cy + L(14))], fill=(92, 158, 214, 255), width=L(4))

def g_drought(d, cx, cy, s):
    d.ellipse([cx - L(10), cy - L(10), cx + L(10), cy + L(10)], fill=(240, 160, 84, 255), outline=P["ink"], width=L(1.8))
    for k in range(8):
        import math
        a = k * math.pi / 4
        x0 = cx + math.cos(a) * L(14)
        y0 = cy + math.sin(a) * L(14)
        x1 = cx + math.cos(a) * L(19)
        y1 = cy + math.sin(a) * L(19)
        d.line([(x0, y0), (x1, y1)], fill=(240, 160, 84, 255), width=L(4))

def g_bless(d, cx, cy, s):
    import math
    for a in (math.pi * 0.75, math.pi * 1.25):
        for rr in (12, 16):
            d.line([(cx - L(22), cy + L(16)), (cx, cy - L(20))], fill=(255, 236, 170, 0), width=L(1))
    # 放射光
    for a in range(-60, 61, 30):
        rad = math.radians(a - 90)
        d.line([(cx + math.cos(rad) * L(15), cy + math.sin(rad) * L(15)),
                (cx + math.cos(rad) * L(20), cy + math.sin(rad) * L(20))], fill=(255, 226, 140, 235), width=L(3))
    d.ellipse([cx - L(15), cy - L(15), cx + L(15), cy + L(15)], fill=(255, 226, 140, 90))
    # 谷穗
    d.line([(cx, cy + L(13)), (cx, cy - L(10))], fill=(238, 188, 92, 255), width=L(4))
    for k in range(3):
        yy = cy - L(8) + k * L(7)
        d.ellipse([cx - L(8), yy - L(3), cx - L(1), yy + L(3)], fill=(255, 232, 150, 255))
        d.ellipse([cx + L(1), yy - L(3), cx + L(8), yy + L(3)], fill=(255, 232, 150, 255))

def g_enlight(d, cx, cy, s):
    d.ellipse([cx - L(12), cy - L(14), cx + L(12), cy + L(8)], fill=(255, 226, 140, 255), outline=P["ink"], width=L(1.8))
    d.rounded_rectangle([cx - L(7), cy + L(6), cx + L(7), cy + L(14)], L(2), fill=(200, 170, 100, 255), outline=P["ink"], width=L(1.5))
    d.line([(cx - L(4), cy + L(9)), (cx + L(4), cy + L(9))], fill=(120, 100, 70, 255), width=L(2))
    for dx, dy in [(-16, -8), (16, -8), (-13, 4), (13, 4), (0, -20)]:
        d.line([(cx + L(dx), cy + L(dy)), (cx + L(dx * 1.3), cy + L(dy * 1.3 - 2))], fill=(255, 226, 140, 220), width=L(3))

def g_idea(d, cx, cy, s):
    # 火炬
    outline_poly(d, [(cx, cy - L(18)), (cx + L(9), cy - L(4)), (cx, cy + L(4)), (cx - L(9), cy - L(4))],
                 (240, 150, 70, 255), edge=P["ink"], edge_w=1.6)
    d.polygon([(cx, cy - L(14)), (cx + L(5), cy - L(6)), (cx, cy + L(2)), (cx - L(5), cy - L(6))], fill=(255, 210, 110, 235))
    d.rectangle([cx - L(3), cy + L(4), cx + L(3), cy + L(18)], fill=P["wood_lo"], outline=P["ink"], width=L(1.5))
    d.line([(cx - L(6), cy + L(9)), (cx + L(6), cy + L(9))], fill=(150, 104, 64, 255), width=L(2.5))

# ---------- 资源 ----------
def g_food(d, cx, cy, s):
    g_fertile(d, cx, cy, s)

def g_wood(d, cx, cy, s):
    for dy in (-5, 5):
        d.rounded_rectangle([cx - L(16), cy + L(dy - 5), cx + L(10), cy + L(dy + 5)], L(5), fill=P["wood"], outline=P["ink"], width=L(1.6))
        d.ellipse([cx + L(4), cy + L(dy - 5), cx + L(12), cy + L(dy + 5)], fill=(222, 178, 122, 255), outline=P["ink"], width=L(1.4))
        d.ellipse([cx + L(7), cy + L(dy - 2), cx + L(9), cy + L(dy + 2)], fill=(150, 104, 64, 255))

def g_stone(d, cx, cy, s):
    for dx, dy in [(-11, 6), (11, 6), (0, -8)]:
        d.rounded_rectangle([cx + L(dx - 9), cy + L(dy - 8), cx + L(dx + 9), cy + L(dy + 8)], L(4),
                            fill=P["stone_b"], outline=P["ink"], width=L(1.6))
        d.line([(cx + L(dx - 6), cy + L(dy - 4)), (cx + L(dx + 6), cy + L(dy - 4))], fill=P["stone_b_hi"], width=L(2))

def g_metal(d, cx, cy, s):
    for dy in (5, -7):
        outline_poly(d, [(cx - L(16), cy + L(dy + 6)), (cx - L(10), cy + L(dy - 6)), (cx + L(10), cy + L(dy - 6)), (cx + L(16), cy + L(dy + 6))],
                     P["metal_c"], edge=P["ink"], edge_w=1.6)
        d.polygon([(cx - L(10), cy + L(dy - 6)), (cx + L(10), cy + L(dy - 6)), (cx + L(4), cy + L(dy - 1))], fill=P["metal_hi"])

def g_pop(d, cx, cy, s):
    d.ellipse([cx - L(8), cy - L(18), cx + L(8), cy - L(2)], fill=(238, 230, 214, 255), outline=P["ink"], width=L(1.6))
    outline_poly(d, [(cx - L(16), cy + L(16)), (cx - L(14), cy + L(2)), (cx, cy - L(2)), (cx + L(14), cy + L(2)), (cx + L(16), cy + L(16))],
                 (238, 230, 214, 255), edge=P["ink"], edge_w=1.6)

def g_know(d, cx, cy, s):
    outline_poly(d, [(cx - L(2), cy - L(12)), (cx - L(18), cy - L(16)), (cx - L(18), cy + L(10)), (cx - L(2), cy + L(14))],
                 (196, 226, 244, 255), edge=P["ink"], edge_w=1.6)
    outline_poly(d, [(cx + L(2), cy - L(12)), (cx + L(18), cy - L(16)), (cx + L(18), cy + L(10)), (cx + L(2), cy + L(14))],
                 (168, 210, 236, 255), edge=P["ink"], edge_w=1.6)
    for k in range(3):
        d.line([(cx - L(14), cy - L(8) + k * L(8)), (cx - L(6), cy - L(6) + k * L(8))], fill=(120, 130, 150, 255), width=L(2))

def g_faith(d, cx, cy, s):
    import math
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        x0, y0 = cx + math.cos(a) * L(4), cy + math.sin(a) * L(4)
        x1, y1 = cx + math.cos(a) * L(18), cy + math.sin(a) * L(18)
        d.line([(x0, y0), (x1, y1)], fill=(255, 226, 140, 255), width=L(5))
        d.line([(x0, y0), (x1, y1)], fill=(255, 250, 220, 255), width=L(2))
    d.ellipse([cx - L(5), cy - L(5), cx + L(5), cy + L(5)], fill=(255, 250, 220, 255))

def g_coin(d, cx, cy, s):
    for dy in (8, 2, -4):
        d.ellipse([cx - L(14), cy + L(dy - 5), cx + L(14), cy + L(dy + 7)], fill=(238, 188, 92, 255), outline=P["ink"], width=L(1.6))
        d.ellipse([cx - L(9), cy + L(dy - 2), cx + L(9), cy + L(dy + 4)], outline=(198, 148, 60, 255), width=L(1.6), fill=None)
    d.ellipse([cx - L(7), cy - L(9), cx + L(7), cy - L(1)], fill=(255, 232, 150, 255), outline=P["ink"], width=L(1.4))

if __name__ == "__main__":
    chip("pow_forest", g_forest)
    chip("pow_fertile", g_fertile)
    chip("pow_water", g_water)
    chip("pow_ore", g_ore)
    chip("pow_rain", g_rain)
    chip("pow_drought", g_drought)
    chip("pow_bless", g_bless)
    chip("pow_enlight", g_enlight)
    chip("pow_idea", g_idea)
    chip("res_food", g_food)
    chip("res_wood", g_wood)
    chip("res_stone", g_stone)
    chip("res_metal", g_metal)
    chip("res_pop", g_pop)
    chip("res_know", g_know)
    chip("res_faith", g_faith)
    chip("res_coin", g_coin)
    print("ui A done:", len(REGISTRY))
