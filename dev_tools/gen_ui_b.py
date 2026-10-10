# -*- coding: utf-8 -*-
"""UI 图标 B：社会形态 + 界面按钮 + 事件图标"""
import os, sys, math
from PIL import ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asset_common import P, SS, canvas, finish, save, outline_poly, rrect, REGISTRY
from gen_ui_a import chip, L, g_food

# ---------- 社会形态 ----------
def f_primitive(d, cx, cy, s):
    # 石矛尖
    outline_poly(d, [(cx, cy - L(18)), (cx + L(8), cy - L(6)), (cx + L(5), cy + L(8)), (cx - L(5), cy + L(8)), (cx - L(8), cy - L(6))],
                 (188, 178, 164, 255), edge=P["ink"], edge_w=1.8)
    d.polygon([(cx, cy - L(18)), (cx - L(8), cy - L(6)), (cx - L(5), cy + L(8)), (cx, cy + L(8))], fill=(214, 206, 194, 255))
    d.rectangle([cx - L(3), cy + L(8), cx + L(3), cy + L(19)], fill=P["wood_lo"], outline=P["ink"], width=L(1.5))

def f_slave(d, cx, cy, s):
    # 断裂的锁链环
    d.ellipse([cx - L(22), cy - L(10), cx - L(6), cy + L(10)], outline=(198, 108, 90, 255), width=L(6))
    d.ellipse([cx - L(19), cy - L(7), cx - L(9), cy + L(7)], fill=CHIPB(), outline=(198, 108, 90, 255), width=L(3))
    d.ellipse([cx + L(6), cy - L(10), cx + L(22), cy + L(10)], outline=(198, 108, 90, 255), width=L(6))
    d.ellipse([cx + L(9), cy - L(7), cx + L(19), cy + L(7)], fill=CHIPB(), outline=(198, 108, 90, 255), width=L(3))
    for a in (-0.5, 0.5):
        d.line([(cx + a * L(8), cy - L(14)), (cx, cy - L(18))], fill=(255, 236, 170, 255), width=L(3))

def CHIPB():
    return (38, 42, 54, 255)

def f_feudal(d, cx, cy, s):
    # 城塔 + 冠
    d.rectangle([cx - L(10), cy - L(6), cx + L(10), cy + L(18)], fill=(188, 168, 200, 255), outline=P["ink"], width=L(1.8))
    for k in range(3):
        d.rectangle([cx - L(10) + k * L(8), cy - L(12), cx - L(4) + k * L(8), cy - L(6)], fill=(188, 168, 200, 255), outline=P["ink"], width=L(1.4))
    d.polygon([(cx - L(13), cy - L(12)), (cx, cy - L(24)), (cx + L(13), cy - L(12))], fill=(148, 94, 168, 255), outline=P["ink"], width=L(1.6))
    d.polygon([(cx - L(13), cy - L(12)), (cx, cy - L(24)), (cx, cy - L(12))], fill=(188, 168, 200, 255))
    d.rectangle([cx - L(3), cy + L(2), cx + L(3), cy + L(10)], fill=P["window"])

def f_capital(d, cx, cy, s):
    # 工厂 + 烟
    d.rectangle([cx - L(18), cy - L(2), cx + L(6), cy + L(16)], fill=(120, 160, 205, 255), outline=P["ink"], width=L(1.8))
    for k in range(3):
        d.polygon([(cx - L(16) + k * L(8), cy - L(2)), (cx - L(12) + k * L(8), cy - L(10)), (cx - L(8) + k * L(8), cy - L(2))], fill=(168, 220, 240, 235))
    d.rectangle([cx + L(2), cy - L(18), cx + L(7), cy - L(2)], fill=(214, 210, 202, 255), outline=P["ink"], width=L(1.5))
    for k, (dx, dy, r) in enumerate([(8, -20, 5), (13, -26, 4), (6, -28, 3)]):
        d.ellipse([cx + L(dx - r), cy + L(dy - r), cx + L(dx + r), cy + L(dy + r)], fill=(226, 232, 240, 200))

def f_social(d, cx, cy, s):
    # 麦穗 + 齿轮
    import math
    d.ellipse([cx - L(15), cy - L(15), cx + L(15), cy + L(15)], outline=(214, 96, 84, 255), width=L(5))
    d.ellipse([cx - L(9), cy - L(9), cx + L(9), cy + L(9)], fill=CHIPB(), outline=(214, 96, 84, 255), width=L(3))
    for k in range(8):
        a = k * math.pi / 4 + 0.39
        x0, y0 = cx + math.cos(a) * L(15), cy + math.sin(a) * L(15)
        x1, y1 = cx + math.cos(a) * L(20), cy + math.sin(a) * L(20)
        d.line([(x0, y0), (x1, y1)], fill=(214, 96, 84, 255), width=L(5))
    # 麦穗芯
    d.line([(cx, cy + L(12)), (cx, cy - L(12))], fill=(255, 232, 150, 255), width=L(4))
    for k in range(3):
        yy = cy - L(8) + k * L(8)
        d.ellipse([cx - L(8), yy - L(3), cx - L(1), yy + L(3)], fill=(255, 232, 150, 255))
        d.ellipse([cx + L(1), yy - L(3), cx + L(8), yy + L(3)], fill=(255, 232, 150, 255))

def f_mixed(d, cx, cy, s):
    # 天平
    d.line([(cx, cy - L(18)), (cx, cy + L(14))], fill=(150, 160, 180, 255), width=L(4))
    d.line([(cx - L(16), cy - L(10)), (cx + L(16), cy - L(10))], fill=(150, 160, 180, 255), width=L(4))
    for dx in (-16, 16):
        d.line([(cx + L(dx), cy - L(10)), (cx + L(dx), cy - L(2))], fill=(150, 160, 180, 255), width=L(3))
        d.line([(cx + L(dx - 7), cy - L(2)), (cx + L(dx + 7), cy - L(2))], fill=(255, 226, 140, 255), width=L(3))
        d.line([(cx + L(dx - 7), cy - L(2)), (cx + L(dx), cy + L(10))], fill=(255, 226, 140, 255), width=L(2.5))
        d.line([(cx + L(dx + 7), cy - L(2)), (cx + L(dx), cy + L(10))], fill=(255, 226, 140, 255), width=L(2.5))
    d.line([(cx - L(14), cy + L(16)), (cx + L(14), cy + L(16))], fill=(150, 160, 180, 255), width=L(5))

# ---------- 界面按钮 ----------
def b_play(d, cx, cy, s):
    d.polygon([(cx - L(7), cy - L(14)), (cx + L(15), cy), (cx - L(7), cy + L(14))], fill=(238, 230, 214, 255))

def b_pause(d, cx, cy, s):
    d.rectangle([cx - L(10), cy - L(14), cx - L(2), cy + L(14)], fill=(238, 230, 214, 255))
    d.rectangle([cx + L(2), cy - L(14), cx + L(10), cy + L(14)], fill=(238, 230, 214, 255))

def b_step(d, cx, cy, s):
    d.rectangle([cx - L(16), cy - L(14), cx - L(8), cy + L(14)], fill=(238, 230, 214, 255))
    d.polygon([(cx - L(2), cy - L(14)), (cx + L(16), cy), (cx - L(2), cy + L(14))], fill=(238, 230, 214, 255))

def b_ff(d, cx, cy, s):
    for dx in (-9, 9):
        d.polygon([(cx + L(dx - 6), cy - L(12)), (cx + L(dx + 7), cy), (cx + L(dx - 6), cy + L(12))], fill=(238, 230, 214, 255))

def b_home(d, cx, cy, s):
    d.polygon([(cx - L(18), cy - L(2)), (cx, cy - L(18)), (cx + L(18), cy - L(2))], fill=(238, 230, 214, 255))
    d.rectangle([cx - L(12), cy - L(2), cx + L(12), cy + L(14)], fill=(238, 230, 214, 255))
    d.rectangle([cx - L(5), cy + L(2), cx + L(5), cy + L(14)], fill=(38, 42, 54, 255))

def b_help(d, cx, cy, s):
    d.arc([cx - L(10), cy - L(16), cx + L(10), cy + L(4)], 90, 290, fill=(238, 230, 214, 255), width=L(5))
    d.line([(cx + L(3), cy - L(2)), (cx + L(3), cy + L(4))], fill=(238, 230, 214, 255), width=L(5))
    d.line([(cx - L(8), cy + L(8)), (cx + L(2), cy + L(8))], fill=(238, 230, 214, 255), width=L(5))
    d.ellipse([cx + L(3) - L(3), cy + L(15) - L(3), cx + L(3) + L(3), cy + L(15) + L(3)], fill=(238, 230, 214, 255))

def b_gear(d, cx, cy, s):
    import math
    d.ellipse([cx - L(10), cy - L(10), cx + L(10), cy + L(10)], fill=(238, 230, 214, 255))
    for k in range(8):
        a = k * math.pi / 4
        x0, y0 = cx + math.cos(a) * L(10), cy + math.sin(a) * L(10)
        x1, y1 = cx + math.cos(a) * L(16), cy + math.sin(a) * L(16)
        d.line([(x0, y0), (x1, y1)], fill=(238, 230, 214, 255), width=L(7))
    d.ellipse([cx - L(5), cy - L(5), cx + L(5), cy + L(5)], fill=(38, 42, 54, 255))

def b_chronicle(d, cx, cy, s):
    d.rounded_rectangle([cx - L(13), cy - L(16), cx + L(13), cy + L(16)], L(3), fill=(238, 230, 214, 255))
    d.ellipse([cx - L(17), cy - L(20), cx - L(7), cy - L(12)], fill=(206, 196, 178, 255), outline=P["ink"], width=L(1.4))
    d.ellipse([cx + L(7), cy - L(20), cx + L(17), cy - L(12)], fill=(206, 196, 178, 255), outline=P["ink"], width=L(1.4))
    for k in range(3):
        d.line([(cx - L(8), cy - L(6) + k * L(8)), (cx + L(8), cy - L(6) + k * L(8))], fill=(120, 110, 96, 255), width=L(2.5))

def b_observer(d, cx, cy, s):
    d.line([(cx - L(16), cy - L(16)), (cx - L(16), cy + L(16))], fill=(238, 230, 214, 255), width=L(3))
    d.line([(cx - L(16), cy + L(16)), (cx + L(18), cy + L(16))], fill=(238, 230, 214, 255), width=L(3))
    d.line([(cx - L(14), cy + L(8)), (cx - L(4), cy - L(2)), (cx + L(4), cy + L(4)), (cx + L(16), cy - L(12))],
           fill=(255, 226, 140, 255), width=L(4))
    for dx, dy in [(-14, 8), (-4, -2), (4, 4), (16, -12)]:
        d.ellipse([cx + L(dx - 3), cy + L(dy - 3), cx + L(dx + 3), cy + L(dy + 3)], fill=(255, 226, 140, 255))

def b_close(d, cx, cy, s):
    for a in (1, -1):
        d.line([(cx - a * L(12), cy - L(12)), (cx + a * L(12), cy + L(12))], fill=(238, 230, 214, 255), width=L(6))

def b_branch(d, cx, cy, s):
    d.line([(cx - L(18), cy + L(12)), (cx - L(2), cy + L(12))], fill=(238, 230, 214, 255), width=L(4))
    d.line([(cx - L(2), cy + L(12)), (cx - L(2), cy - L(2))], fill=(238, 230, 214, 255), width=L(4))
    d.line([(cx - L(2), cy - L(2)), (cx + L(8), cy - L(14))], fill=(238, 230, 214, 255), width=L(4))
    d.line([(cx - L(2), cy - L(2)), (cx + L(8), cy + L(12))], fill=(238, 230, 214, 255), width=L(4))
    for dy in (-14, 12):
        d.polygon([(cx + L(4), cy + L(dy)), (cx + L(14), cy + L(dy - 4)), (cx + L(14), cy + L(dy + 4))], fill=(255, 226, 140, 255))

def b_focus(d, cx, cy, s):
    d.ellipse([cx - L(12), cy - L(12), cx + L(12), cy + L(12)], outline=(238, 230, 214, 255), width=L(3))
    for a in (0, 90, 180, 270):
        import math as _m
        rad = _m.radians(a)
        x0 = cx + _m.cos(rad) * L(12); y0 = cy + _m.sin(rad) * L(12)
        x1 = cx + _m.cos(rad) * L(19); y1 = cy + _m.sin(rad) * L(19)
        d.line([(x0, y0), (x1, y1)], fill=(255, 226, 140, 255), width=L(4))
    d.ellipse([cx - L(3), cy - L(3), cx + L(3), cy + L(3)], fill=(255, 226, 140, 255))

# ---------- 事件图标 ----------
def e_harvest(d, cx, cy, s):
    import math
    for a in range(-70, 71, 35):
        rad = math.radians(a - 90)
        d.line([(cx + math.cos(rad) * L(16), cy + math.sin(rad) * L(16)), (cx + math.cos(rad) * L(20), cy + math.sin(rad) * L(20))],
               fill=(255, 226, 140, 235), width=L(3))
    g_food(d, cx, cy + L(2), s)

def e_famine(d, cx, cy, s):
    d.polygon([(cx - L(18), cy - L(8)), (cx + L(18), cy - L(8)), (cx + L(10), cy + L(10)), (cx - L(10), cy + L(10))],
              fill=(206, 196, 178, 255), outline=P["ink"], width=L(1.8))
    d.ellipse([cx - L(13), cy - L(10), cx + L(13), cy - L(4)], fill=(160, 148, 132, 255))
    d.line([(cx - L(4), cy + L(12)), (cx + L(2), cy + L(2))], fill=(120, 110, 96, 255), width=L(3))
    d.line([(cx + L(2), cy + L(2)), (cx + L(6), cy + L(8))], fill=(120, 110, 96, 255), width=L(3))

def e_disease(d, cx, cy, s):
    import math
    for k in range(6):
        a = k * math.pi / 3
        x0 = cx + math.cos(a) * L(7); y0 = cy + math.sin(a) * L(7)
        x1 = cx + math.cos(a) * L(17); y1 = cy + math.sin(a) * L(17)
        d.line([(x0, y0), (x1, y1)], fill=(150, 190, 130, 255), width=L(5))
    d.ellipse([cx - L(10), cy - L(10), cx + L(10), cy + L(10)], fill=(150, 190, 130, 255), outline=P["ink"], width=L(1.6))
    d.ellipse([cx - L(13), cy - L(13), cx + L(13), cy + L(13)], fill=None, outline=(150, 190, 130, 120), width=L(2))

def e_discovery(d, cx, cy, s):
    d.polygon([(cx - L(4), cy - L(16)), (cx + L(4), cy - L(16)), (cx + L(14), cy + L(12)), (cx - L(14), cy + L(12))],
              fill=(168, 220, 240, 235), outline=P["ink"], width=L(1.8))
    d.rectangle([cx - L(3), cy - L(20), cx + L(3), cy - L(16)], fill=(214, 210, 202, 255), outline=P["ink"], width=L(1.4))
    for k, (dx, dy, r) in enumerate([(-4, 4, 3), (5, 0, 2), (1, -3, 2)]):
        d.ellipse([cx + L(dx - r), cy + L(dy - r), cx + L(dx + r), cy + L(dy + r)], fill=(255, 255, 255, 220))

def e_migration(d, cx, cy, s):
    pts = [(-14, 10), (-4, 4), (6, 10), (-8, -2), (2, -8), (12, -2)]
    for dx, dy in pts:
        d.ellipse([cx + L(dx - 4), cy + L(dy - 6), cx + L(dx + 4), cy + L(dy + 6)], fill=(196, 148, 96, 255), outline=P["ink"], width=L(1.2))
        d.ellipse([cx + L(dx - 2), cy + L(dy - 4), cx + L(dx + 2), cy + L(dy)], fill=(150, 104, 64, 255))

def e_trade(d, cx, cy, s):
    for dx in (-10, 10):
        d.ellipse([cx + L(dx - 8), cy - L(8), cx + L(dx + 8), cy + L(8)], fill=(238, 188, 92, 255), outline=P["ink"], width=L(1.6))
        d.text((cx + L(dx - 3), cy - L(4)), "¥", fill=(150, 110, 50, 255))
    d.line([(cx - L(4), cy - L(18)), (cx + L(4), cy - L(18))], fill=(120, 130, 150, 255), width=L(3))
    d.polygon([(cx + L(4), cy - L(20)), (cx + L(10), cy - L(18)), (cx + L(4), cy - L(16))], fill=(120, 130, 150, 255))
    d.line([(cx + L(4), cy + L(18)), (cx - L(4), cy + L(18))], fill=(120, 130, 150, 255), width=L(3))
    d.polygon([(cx - L(4), cy + L(20)), (cx - L(10), cy + L(18)), (cx - L(4), cy + L(16))], fill=(120, 130, 150, 255))

def e_conflict(d, cx, cy, s):
    for a, dx in [(1, -12), (-1, 12)]:
        d.line([(cx + L(dx), cy + L(14)), (cx + L(-a * dx), cy - L(14))], fill=(224, 108, 90, 255), width=L(5))
    for k in range(8):
        import math as _m
        a = k * _m.pi / 4
        x0 = cx + _m.cos(a) * L(8); y0 = cy + _m.sin(a) * L(8)
        x1 = cx + _m.cos(a) * L(13); y1 = cy + _m.sin(a) * L(13)
        d.line([(x0, y0), (x1, y1)], fill=(255, 226, 140, 235), width=L(3))

def e_reform(d, cx, cy, s):
    d.rounded_rectangle([cx - L(12), cy - L(16), cx + L(12), cy + L(16)], L(3), fill=(238, 230, 214, 255), outline=P["ink"], width=L(1.6))
    for k in range(3):
        d.line([(cx - L(8), cy - L(10) + k * L(8)), (cx + L(8), cy - L(10) + k * L(8))], fill=(120, 110, 96, 255), width=L(2.2))
    d.line([(cx - L(14), cy + L(12)), (cx - L(4), cy + L(20)), (cx + L(16), cy - L(6))], fill=(127, 191, 106, 255), width=L(5))

def e_war(d, cx, cy, s):
    for a in (1, -1):
        d.line([(cx - a * L(16), cy - L(14)), (cx + a * L(16), cy + L(14))], fill=(224, 108, 90, 255), width=L(5))
        d.rectangle([cx - a * L(20), cy - L(18), cx - a * L(13), cy - L(11)], fill=(238, 230, 214, 255), outline=P["ink"], width=L(1.2))
    d.ellipse([cx - L(8), cy - L(8), cx + L(8), cy + L(8)], fill=(255, 226, 140, 200))

def e_idea(d, cx, cy, s):
    from gen_ui_a import g_enlight
    g_enlight(d, cx, cy, s)

def e_boom(d, cx, cy, s):
    d.rectangle([cx - L(14), cy - L(2), cx - L(4), cy + L(16)], fill=(120, 160, 205, 255), outline=P["ink"], width=L(1.5))
    d.rectangle([cx + L(2), cy - L(10), cx + L(14), cy + L(16)], fill=(150, 190, 130, 255), outline=P["ink"], width=L(1.5))
    for k in range(3):
        d.rectangle([cx + L(5) + k * L(4), cy - L(16), cx + L(7) + k * L(4), cy - L(10)], fill=(168, 220, 240, 235))
    d.polygon([(cx - L(2), cy - L(20)), (cx + L(8), cy - L(28)), (cx + L(5), cy - L(20))], fill=(255, 226, 140, 255))
    d.polygon([(cx + L(6), cy - L(20)), (cx + L(16), cy - L(28)), (cx + L(13), cy - L(20))], fill=(255, 226, 140, 235))

def e_golden(d, cx, cy, s):
    import math
    pts = []
    for k in range(10):
        a = k * math.pi / 5 - math.pi / 2
        r = 20 if k % 2 == 0 else 9
        pts.append((cx + math.cos(a) * L(r), cy + math.sin(a) * L(r)))
    d.polygon(pts, fill=(255, 226, 140, 255), outline=(198, 148, 60, 255))
    d.polygon([(cx - L(6), cy - L(6)), (cx + L(6), cy - L(6)), (cx, cy + L(8))], fill=(255, 250, 220, 255))

def e_degrade(d, cx, cy, s):
    d.rectangle([cx - L(3), cy - L(6), cx + L(3), cy + L(18)], fill=(150, 130, 110, 255), outline=P["ink"], width=L(1.5))
    d.line([(cx - L(2), cy - L(6)), (cx - L(14), cy - L(16))], fill=(150, 130, 110, 255), width=L(3))
    d.line([(cx - L(14), cy - L(16)), (cx - L(20), cy - L(22))], fill=(150, 130, 110, 255), width=L(3))
    d.line([(cx + L(2), cy - L(6)), (cx + L(14), cy - L(18))], fill=(150, 130, 110, 255), width=L(3))
    d.line([(cx + L(14), cy - L(18)), (cx + L(20), cy - L(14))], fill=(150, 130, 110, 255), width=L(3))
    for dx, dy, r in [(-10, 2, 4), (8, 6, 3)]:
        d.ellipse([cx + L(dx - r), cy + L(dy - r), cx + L(dx + r), cy + L(dy + r)], fill=(190, 178, 160, 120))

def e_city(d, cx, cy, s):
    d.rectangle([cx - L(18), cy, cx - L(8), cy + L(16)], fill=(120, 160, 205, 255), outline=P["ink"], width=L(1.5))
    d.rectangle([cx - L(4), cy - L(10), cx + L(6), cy + L(16)], fill=(150, 190, 130, 255), outline=P["ink"], width=L(1.5))
    d.rectangle([cx + L(10), cy - L(4), cx + L(18), cy + L(16)], fill=(188, 168, 200, 255), outline=P["ink"], width=L(1.5))
    for k, dx in enumerate([-14, 1, 14]):
        for t in range(3):
            d.rectangle([cx + L(dx - 3) + t * L(4), cy + L(4 + (k % 2) * 6), cx + L(dx - 1) + t * L(4), cy + L(8 + (k % 2) * 6)], fill=(255, 232, 150, 235))

def e_inst(d, cx, cy, s):
    d.rectangle([cx - L(16), cy - L(4), cx + L(16), cy + L(2)], fill=(188, 168, 200, 255), outline=P["ink"], width=L(1.6))
    for dx in (-11, 0, 11):
        d.rectangle([cx + L(dx - 3), cy - L(16), cx + L(dx + 3), cy - L(4)], fill=(214, 196, 178, 255), outline=P["ink"], width=L(1.4))
    d.polygon([(cx - L(19), cy - L(16)), (cx, cy - L(24)), (cx + L(19), cy - L(16))], fill=(188, 168, 200, 255), outline=P["ink"], width=L(1.6))
    d.rectangle([cx - L(20), cy + L(6), cx + L(20), cy + L(12)], fill=(214, 196, 178, 255), outline=P["ink"], width=L(1.6))

if __name__ == "__main__":
    chip("form_primitive", f_primitive)
    chip("form_slave", f_slave)
    chip("form_feudal", f_feudal)
    chip("form_capital", f_capital)
    chip("form_social", f_social)
    chip("form_mixed", f_mixed)
    chip("ui_play", b_play)
    chip("ui_pause", b_pause)
    chip("ui_step", b_step)
    chip("ui_ff", b_ff)
    chip("ui_home", b_home)
    chip("ui_help", b_help)
    chip("ui_gear", b_gear)
    chip("ui_chronicle", b_chronicle)
    chip("ui_observer", b_observer)
    chip("ui_close", b_close)
    chip("ui_branch", b_branch)
    chip("ui_focus", b_focus)
    chip("ev_harvest", e_harvest)
    chip("ev_famine", e_famine)
    chip("ev_disease", e_disease)
    chip("ev_discovery", e_discovery)
    chip("ev_migration", e_migration)
    chip("ev_trade", e_trade)
    chip("ev_conflict", e_conflict)
    chip("ev_reform", e_reform)
    chip("ev_war", e_war)
    chip("ev_idea", e_idea)
    chip("ev_boom", e_boom)
    chip("ev_golden", e_golden)
    chip("ev_degrade", e_degrade)
    chip("ev_city", e_city)
    chip("ev_inst", e_inst)
    print("ui B done:", len(REGISTRY))
