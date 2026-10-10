# -*- coding: utf-8 -*-
"""建筑素材第二部分：生产/公共/防御/工业建筑"""
import os, sys
from PIL import ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asset_common import (P, SS, canvas, finish, save, diamond, speckles,
                           outline_poly, rrect, REGISTRY)
from gen_buildings_a import _win, _door, _banner

def well():
    W, H = 42, 44
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    d.ellipse([cx - 15 * SS, gy - 10 * SS, cx + 15 * SS, gy + 6 * SS], fill=P["stone_b"], outline=P["ink"], width=2 * SS)
    d.ellipse([cx - 10 * SS, gy - 8 * SS, cx + 10 * SS, gy + 2 * SS], fill=(46, 84, 120, 255), outline=P["ink"], width=1.6)
    d.line([(cx - 12 * SS, gy - 26 * SS), (cx, gy - 38 * SS)], fill=P["wood_lo"], width=3 * SS)
    d.line([(cx + 12 * SS, gy - 26 * SS), (cx, gy - 38 * SS)], fill=P["wood_lo"], width=3 * SS)
    d.line([(cx - 14 * SS, gy - 27 * SS), (cx + 14 * SS, gy - 27 * SS)], fill=P["trunk"], width=3 * SS)
    d.line([(cx, gy - 27 * SS), (cx, gy - 14 * SS)], fill=(110, 84, 60, 255), width=2)
    d.rectangle([cx - 5 * SS, gy - 14 * SS, cx + 5 * SS, gy - 8 * SS], fill=P["wood"], outline=P["ink"], width=1.4)
    save(finish(img, W, H), "buildings", "well", foot=8)

def workshop():
    W, H = 68, 62
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    d.rectangle([cx - 24 * SS, gy - 28 * SS, cx + 24 * SS, gy], fill=P["wood"], outline=P["ink"], width=2 * SS)
    outline_poly(d, [(cx - 2 * SS, gy - 50 * SS), (cx - 30 * SS, gy - 26 * SS), (cx + 26 * SS, gy - 26 * SS)],
                 P["roof_red"], edge=P["ink"], edge_w=2)
    d.polygon([(cx - 2 * SS, gy - 50 * SS), (cx - 30 * SS, gy - 26 * SS), (cx - 2 * SS, gy - 26 * SS)], fill=P["roof_red_hi"])
    d.rectangle([cx + 4 * SS, gy - 44 * SS, cx + 10 * SS, gy - 26 * SS], fill=P["stone_b"], outline=P["ink"], width=1.6)
    rrect(d, [cx - 22 * SS, gy - 22 * SS, cx + 6 * SS, gy], 2, (58, 50, 46, 255), edge=P["ink"], edge_w=1.6)  # 敞开操作间
    d.rectangle([cx - 16 * SS, gy - 16 * SS, cx - 10 * SS, gy - 4 * SS], fill=P["metal_c"], outline=P["ink"], width=1.4)  # 铁砧
    d.line([(cx - 16 * SS, gy - 16 * SS), (cx - 10 * SS, gy - 16 * SS)], fill=P["metal_hi"], width=2)
    for k, dx in enumerate([-4, 2]):
        d.ellipse([cx + dx * SS + 14 * SS, gy - 18 * SS - k * 3 * SS, cx + dx * SS + 22 * SS, gy - 10 * SS - k * 3 * SS],
                  fill=(198, 92, 70, 240))  # 炉火
    d.rectangle([cx + 12 * SS, gy - 10 * SS, cx + 20 * SS, gy - 6 * SS], fill=P["wood_lo"], outline=P["ink"], width=1.2)
    save(finish(img, W, H), "buildings", "workshop", foot=6)

def factory():
    W, H = 116, 100
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 8 * SS; cx = W * SS / 2
    d.rectangle([cx - 44 * SS, gy - 46 * SS, cx + 20 * SS, gy], fill=P["brick"], outline=P["ink"], width=2 * SS)
    for yy in range(-40, -4, 6):
        d.line([(cx - 44 * SS, gy + yy * SS), (cx + 20 * SS, gy + yy * SS)], fill=P["brick_lo"], width=2)
    # 锯齿形天窗
    for k in range(3):
        x0 = cx - 40 * SS + k * 22 * SS
        outline_poly(d, [(x0, gy - 46 * SS), (x0 + 14 * SS, gy - 58 * SS), (x0 + 22 * SS, gy - 46 * SS)],
                     P["glass"], edge=P["ink"], edge_w=2)
        d.line([(x0 + 14 * SS, gy - 58 * SS), (x0 + 22 * SS, gy - 46 * SS)], fill=P["white_b"], width=2)
    # 双烟囱
    for dx, hgt in [(-30, 78), (-12, 70)]:
        d.rectangle([cx + dx * SS - 7 * SS, gy - hgt * SS, cx + dx * SS + 7 * SS, gy - 46 * SS],
                    fill=P["stone_b"], outline=P["ink"], width=2 * SS)
        d.rectangle([cx + dx * SS - 7 * SS, gy - hgt * SS, cx + dx * SS + 7 * SS, gy - hgt * SS + 8 * SS], fill=P["danger"])
        d.rectangle([cx + dx * SS - 7 * SS, gy - hgt * SS + 22 * SS, cx + dx * SS + 7 * SS, gy - hgt * SS + 30 * SS], fill=P["stone_b_hi"])
    _win(d, cx - 36 * SS, gy - 34 * SS, 10, 12); _win(d, cx - 20 * SS, gy - 34 * SS, 10, 12)
    rrect(d, [cx - 10 * SS, gy - 24 * SS, cx + 10 * SS, gy], 2, (70, 60, 56, 255), edge=P["ink"], edge_w=1.6)
    # 侧厂房
    d.rectangle([cx + 24 * SS, gy - 34 * SS, cx + 46 * SS, gy], fill=P["metal_lo"], outline=P["ink"], width=2 * SS)
    d.rectangle([cx + 24 * SS, gy - 40 * SS, cx + 46 * SS, gy - 34 * SS], fill=P["metal_c"], outline=P["ink"], width=2 * SS)
    d.polygon([(cx + 24 * SS, gy - 40 * SS), (cx + 35 * SS, gy - 50 * SS), (cx + 46 * SS, gy - 40 * SS)], fill=P["metal_hi"])
    _win(d, cx + 30 * SS, gy - 26 * SS, 8, 10, lit=False)
    save(finish(img, W, H), "buildings", "factory", foot=8)

def market():
    W, H = 80, 64
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    stalls = [(-24, P["cloth_red"], (238, 230, 214)), (2, (92, 130, 176), (238, 230, 214)), (26, (128, 178, 106), (238, 230, 214))]
    for dx, c1, c2 in stalls:
        x0 = cx + dx * SS
        d.rectangle([x0 - 2 * SS, gy - 16 * SS, x0 + 18 * SS, gy], fill=P["plank"], outline=P["ink"], width=1.6)  # 摊台
        # 条纹篷
        for k in range(5):
            col = c1 if k % 2 == 0 else c2
            d.polygon([(x0 - 6 * SS + k * 6 * SS, gy - 30 * SS), (x0 - 6 * SS + k * 6 * SS + 6 * SS, gy - 30 * SS),
                       (x0 - 8 * SS + k * 7 * SS, gy - 22 * SS), (x0 - 10 * SS + k * 7 * SS, gy - 22 * SS)], fill=col)
        d.line([(x0 - 4 * SS, gy - 30 * SS), (x0 - 7 * SS, gy - 16 * SS)], fill=P["wood_lo"], width=2)
        d.line([(x0 + 20 * SS, gy - 30 * SS), (x0 + 24 * SS, gy - 16 * SS)], fill=P["wood_lo"], width=2)
        # 货品
        d.ellipse([x0 + 2 * SS, gy - 22 * SS, x0 + 8 * SS, gy - 16 * SS], fill=(238, 198, 96, 255), outline=P["ink"], width=1.2)
        d.ellipse([x0 + 9 * SS, gy - 21 * SS, x0 + 14 * SS, gy - 16 * SS], fill=(198, 92, 70, 255), outline=P["ink"], width=1.2)
    d.ellipse([cx - 10 * SS, gy - 2 * SS, cx - 2 * SS, gy + 5 * SS], fill=P["iron"], outline=P["ink"], width=1.2)  # 地上货箱
    save(finish(img, W, H), "buildings", "market", foot=6)

def admin_hall():
    W, H = 100, 96
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 8 * SS; cx = W * SS / 2
    d.rectangle([cx - 34 * SS, gy - 44 * SS, cx + 34 * SS, gy - 6 * SS], fill=P["stone_b"], outline=P["ink"], width=2 * SS)
    for xx in range(-30, 30, 8):
        d.line([(cx + xx * SS, gy - 44 * SS), (cx + xx * SS, gy - 6 * SS)], fill=P["stone_b_lo"], width=2)
    outline_poly(d, [(cx, gy - 74 * SS), (cx - 42 * SS, gy - 44 * SS), (cx + 42 * SS, gy - 44 * SS)],
                 P["roof_blue"], edge=P["ink"], edge_w=2)
    d.polygon([(cx, gy - 74 * SS), (cx - 42 * SS, gy - 44 * SS), (cx, gy - 44 * SS)], fill=P["roof_blue_hi"])
    d.polygon([(cx, gy - 74 * SS), (cx + 8 * SS, gy - 64 * SS), (cx - 8 * SS, gy - 64 * SS)], fill=P["gold"])
    # 柱廊
    for dx in (-24, -12, 0, 12, 24):
        d.rectangle([cx + dx * SS - 4 * SS, gy - 38 * SS, cx + dx * SS + 4 * SS, gy - 6 * SS],
                    fill=P["stone_b_hi"], outline=P["ink"], width=1.6)
    d.rectangle([cx - 36 * SS, gy - 6 * SS, cx + 36 * SS, gy], fill=P["stone_b_lo"], outline=P["ink"], width=1.6)
    for s in range(3):
        d.line([(cx - 30 * SS + s * 24 * SS, gy), (cx - 18 * SS + s * 12 * SS, gy - 8 * SS)], fill=(150, 144, 136, 255), width=4)
    _banner(d, cx + 40 * SS, gy - 6 * SS, 9, 30)
    save(finish(img, W, H), "buildings", "admin_hall", foot=8)

def manor():
    W, H = 108, 100
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 8 * SS; cx = W * SS / 2
    # 主楼
    d.rectangle([cx - 26 * SS, gy - 48 * SS, cx + 26 * SS, gy], fill=(222, 198, 170, 255), outline=P["ink"], width=2 * SS)
    outline_poly(d, [(cx, gy - 78 * SS), (cx - 34 * SS, gy - 46 * SS), (cx + 34 * SS, gy - 46 * SS)],
                 P["roof_red"], edge=P["ink"], edge_w=2)
    d.polygon([(cx, gy - 78 * SS), (cx - 34 * SS, gy - 46 * SS), (cx, gy - 46 * SS)], fill=P["roof_red_hi"])
    _win(d, cx - 20 * SS, gy - 40 * SS, 9, 12); _win(d, cx + 10 * SS, gy - 40 * SS, 9, 12)
    _win(d, cx - 5 * SS, gy - 40 * SS, 9, 12)
    _door(d, cx - 8 * SS, gy - 20 * SS, 16, 20)
    # 侧塔
    d.rectangle([cx - 48 * SS, gy - 60 * SS, cx - 26 * SS, gy], fill=(222, 198, 170, 255), outline=P["ink"], width=2 * SS)
    d.polygon([(cx - 50 * SS, gy - 60 * SS), (cx - 37 * SS, gy - 82 * SS), (cx - 24 * SS, gy - 60 * SS)], fill=P["roof_red"])
    d.polygon([(cx - 50 * SS, gy - 60 * SS), (cx - 37 * SS, gy - 82 * SS), (cx - 37 * SS, gy - 60 * SS)], fill=P["roof_red_hi"])
    _win(d, cx - 40 * SS, gy - 50 * SS, 7, 10); _win(d, cx - 40 * SS, gy - 32 * SS, 7, 10, lit=False)
    d.rectangle([cx + 26 * SS, gy - 34 * SS, cx + 44 * SS, gy], fill=(206, 182, 152, 255), outline=P["ink"], width=2 * SS)
    d.polygon([(cx + 24 * SS, gy - 34 * SS), (cx + 35 * SS, gy - 52 * SS), (cx + 46 * SS, gy - 34 * SS)], fill=P["roof_red_lo"])
    _banner(d, cx - 2 * SS, gy - 78 * SS, 9, 26, col=(214, 96, 84, 255))
    save(finish(img, W, H), "buildings", "manor", foot=8)

def castle():
    W, H = 132, 124
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 8 * SS; cx = W * SS / 2
    # 城墙
    d.rectangle([cx - 56 * SS, gy - 30 * SS, cx + 56 * SS, gy], fill=P["stone_b_lo"], outline=P["ink"], width=2 * SS)
    for xx in range(-52, 52, 10):
        d.line([(cx + xx * SS, gy - 30 * SS), (cx + xx * SS, gy)], fill=(160, 152, 144, 255), width=2)
    for xx in range(-56, 56, 14):  # 雉堞
        d.rectangle([cx + xx * SS, gy - 40 * SS, cx + xx * SS + 8 * SS, gy - 30 * SS], fill=P["stone_b"], outline=P["ink"], width=1.6)
    # 主楼（keep）
    d.rectangle([cx - 20 * SS, gy - 84 * SS, cx + 20 * SS, gy - 30 * SS], fill=P["stone_b"], outline=P["ink"], width=2 * SS)
    for yy in range(-78, -34, 9):
        d.line([(cx - 20 * SS, gy + yy * SS), (cx + 20 * SS, gy + yy * SS)], fill=P["stone_b_lo"], width=2)
    d.polygon([(cx - 24 * SS, gy - 84 * SS), (cx, gy - 112 * SS), (cx + 24 * SS, gy - 84 * SS)], fill=P["roof_blue"])
    d.polygon([(cx - 24 * SS, gy - 84 * SS), (cx, gy - 112 * SS), (cx, gy - 84 * SS)], fill=P["roof_blue_hi"])
    for k in range(3):
        d.rectangle([cx - 16 * SS + k * 12 * SS, gy - 80 * SS, cx - 10 * SS + k * 12 * SS, gy - 68 * SS], fill=P["window"])
    # 双塔
    for dx in (-44, 44):
        d.rectangle([cx + dx * SS - 12 * SS, gy - 70 * SS, cx + dx * SS + 12 * SS, gy - 26 * SS], fill=P["stone_b_hi"], outline=P["ink"], width=2 * SS)
        d.polygon([(cx + dx * SS - 16 * SS, gy - 70 * SS), (cx + dx * SS, gy - 96 * SS), (cx + dx * SS + 16 * SS, gy - 70 * SS)], fill=P["roof_red"])
        d.polygon([(cx + dx * SS - 16 * SS, gy - 70 * SS), (cx + dx * SS, gy - 96 * SS), (cx + dx * SS, gy - 70 * SS)], fill=P["roof_red_hi"])
        d.rectangle([cx + dx * SS - 3 * SS, gy - 58 * SS, cx + dx * SS + 3 * SS, gy - 46 * SS], fill=P["window"])
    # 门楼
    d.rectangle([cx - 12 * SS, gy - 46 * SS, cx + 12 * SS, gy - 30 * SS], fill=P["stone_b"], outline=P["ink"], width=2)
    d.arc([cx - 9 * SS, gy - 24 * SS, cx + 9 * SS, gy], 180, 360, fill=(58, 50, 46, 255), width=0)
    d.rectangle([cx - 9 * SS, gy - 18 * SS, cx + 9 * SS, gy], fill=(58, 50, 46, 255), outline=P["ink"], width=1.6)
    _banner(d, cx + 20 * SS, gy - 46 * SS, 9, 24)
    save(finish(img, W, H), "buildings", "castle", foot=8)

def wall_tower():
    W, H = 44, 78
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    d.rectangle([cx - 14 * SS, gy - 56 * SS, cx + 14 * SS, gy], fill=P["stone_b_hi"], outline=P["ink"], width=2 * SS)
    for yy in range(-50, -6, 9):
        d.line([(cx - 14 * SS, gy + yy * SS), (cx + 14 * SS, gy + yy * SS)], fill=P["stone_b_lo"], width=2)
    for xx in range(-14, 14, 10):
        d.rectangle([cx + xx * SS, gy - 66 * SS, cx + xx * SS + 8 * SS, gy - 56 * SS], fill=P["stone_b"], outline=P["ink"], width=1.6)
    d.rectangle([cx - 3 * SS, gy - 44 * SS, cx + 3 * SS, gy - 34 * SS], fill=P["window_off"], outline=P["ink"], width=1.4)
    d.polygon([(cx - 18 * SS, gy - 66 * SS), (cx, gy - 86 * SS), (cx + 18 * SS, gy - 66 * SS)], fill=P["roof_red"])
    d.polygon([(cx - 18 * SS, gy - 66 * SS), (cx, gy - 86 * SS), (cx, gy - 66 * SS)], fill=P["roof_red_hi"])
    save(finish(img, W, H), "buildings", "wall_tower", foot=6)

def temple():
    W, H = 100, 98
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 8 * SS; cx = W * SS / 2
    d.rectangle([cx - 34 * SS, gy - 40 * SS, cx + 34 * SS, gy - 6 * SS], fill=P["white_b"], outline=P["ink"], width=2 * SS)
    for dx in (-24, -12, 0, 12, 24):
        d.rectangle([cx + dx * SS - 4 * SS, gy - 36 * SS, cx + dx * SS + 4 * SS, gy - 6 * SS], fill=P["white_b"], outline=P["ink"], width=1.6)
        d.rectangle([cx + dx * SS - 4 * SS, gy - 36 * SS, cx + dx * SS + 4 * SS, gy - 32 * SS], fill=P["white_b_lo"])
    # 圆顶
    d.ellipse([cx - 26 * SS, gy - 84 * SS, cx + 26 * SS, gy - 36 * SS], fill=P["gold"], outline=P["ink"], width=2 * SS)
    d.ellipse([cx - 26 * SS, gy - 84 * SS, cx - 6 * SS, gy - 56 * SS], fill=P["gold_hi"])
    d.rectangle([cx - 2 * SS, gy - 92 * SS, cx + 2 * SS, gy - 80 * SS], fill=P["gold_hi"], outline=P["ink"], width=1.4)
    d.rectangle([cx - 36 * SS, gy - 6 * SS, cx + 36 * SS, gy], fill=P["stone_b_lo"], outline=P["ink"], width=1.6)
    for s in range(3):
        d.line([(cx - 30 * SS + s * 24 * SS, gy), (cx - 18 * SS + s * 12 * SS, gy - 8 * SS)], fill=(150, 144, 136, 255), width=4)
    _win(d, cx - 8 * SS, gy - 34 * SS, 16, 18)
    save(finish(img, W, H), "buildings", "temple", foot=8)

def assembly():
    W, H = 94, 80
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 8 * SS; cx = W * SS / 2
    d.rectangle([cx - 36 * SS, gy - 38 * SS, cx + 36 * SS, gy - 4 * SS], fill=(214, 196, 168, 255), outline=P["ink"], width=2 * SS)
    d.rectangle([cx - 40 * SS, gy - 50 * SS, cx + 40 * SS, gy - 38 * SS], fill=P["brick_lo"], outline=P["ink"], width=2 * SS)
    d.rectangle([cx - 40 * SS, gy - 56 * SS, cx + 40 * SS, gy - 50 * SS], fill=P["stone_b_hi"], outline=P["ink"], width=2 * SS)
    for k in range(7):  # 檐口棱
        d.rectangle([cx - 38 * SS + k * 12 * SS, gy - 56 * SS, cx - 32 * SS + k * 12 * SS, gy - 50 * SS], fill=P["white_b"])
    # 红旗 + 麦穗徽记
    _banner(d, cx - 34 * SS, gy - 56 * SS, 10, 22)
    d.ellipse([cx - 6 * SS, gy - 34 * SS, cx + 6 * SS, gy - 22 * SS], fill=None, outline=P["gold"], width=2)  # 麦穗环
    d.ellipse([cx - 2 * SS, gy - 31 * SS, cx + 2 * SS, gy - 25 * SS], fill=P["gold"])
    for k in range(-1, 2):  # 门廊
        d.rectangle([cx - 22 * SS + k * 20 * SS, gy - 30 * SS, cx - 14 * SS + k * 20 * SS, gy - 4 * SS], fill=(198, 92, 70, 235), outline=P["ink"], width=1.4)
    d.rectangle([cx - 42 * SS, gy - 4 * SS, cx + 42 * SS, gy], fill=P["stone_b_lo"], outline=P["ink"], width=1.6)
    save(finish(img, W, H), "buildings", "assembly", foot=8)

def school():
    W, H = 84, 84
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    d.rectangle([cx - 28 * SS, gy - 38 * SS, cx + 28 * SS, gy], fill=(232, 214, 178, 255), outline=P["ink"], width=2 * SS)
    outline_poly(d, [(cx, gy - 64 * SS), (cx - 36 * SS, gy - 38 * SS), (cx + 36 * SS, gy - 38 * SS)],
                 P["roof_red"], edge=P["ink"], edge_w=2)
    d.polygon([(cx, gy - 64 * SS), (cx - 36 * SS, gy - 38 * SS), (cx, gy - 38 * SS)], fill=P["roof_red_hi"])
    d.rectangle([cx - 6 * SS, gy - 86 * SS, cx + 6 * SS, gy - 64 * SS], fill=P["white_b"], outline=P["ink"], width=1.6)
    d.polygon([(cx - 8 * SS, gy - 86 * SS), (cx, gy - 96 * SS), (cx + 8 * SS, gy - 86 * SS)], fill=P["roof_red"])
    d.arc([cx - 5 * SS, gy - 80 * SS, cx + 5 * SS, gy - 70 * SS], 180, 360, fill=P["gold"], width=0)  # 钟铃
    d.line([(cx, gy - 80 * SS), (cx, gy - 72 * SS)], fill=P["ink_soft"], width=2)
    _win(d, cx - 22 * SS, gy - 32 * SS); _win(d, cx + 12 * SS, gy - 32 * SS)
    _win(d, cx - 22 * SS, gy - 18 * SS, lit=False); _door(d, cx - 8 * SS, gy - 16 * SS, 16, 16)
    d.rectangle([cx + 24 * SS, gy - 14 * SS, cx + 34 * SS, gy - 8 * SS], fill=(120, 88, 52, 255), outline=P["ink"], width=1.2)  # 告示板
    save(finish(img, W, H), "buildings", "school", foot=6)

def hospital():
    W, H = 88, 88
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    d.rectangle([cx - 32 * SS, gy - 44 * SS, cx + 32 * SS, gy], fill=P["white_b"], outline=P["ink"], width=2 * SS)
    d.rectangle([cx - 36 * SS, gy - 52 * SS, cx + 36 * SS, gy - 44 * SS], fill=(120, 160, 205, 255), outline=P["ink"], width=2 * SS)
    for f in range(2):
        yy = gy - (38 - f * 18) * SS
        for k in range(-3, 4):
            if f == 1 and k == 0:
                rrect(d, [cx - 10 * SS, yy - 2 * SS, cx + 10 * SS, yy + 18 * SS], 3, P["glass"], edge=P["ink"], edge_w=1.6)
            else:
                _win(d, cx + k * 10 * SS - 4 * SS, yy, 8, 10, lit=(k + f) % 3 != 1)
    # 红十字
    d.rectangle([cx - 3 * SS, gy - 74 * SS, cx + 3 * SS, gy - 62 * SS], fill=P["danger"], outline=P["ink"], width=1.4)
    d.rectangle([cx - 8 * SS, gy - 70 * SS, cx + 8 * SS, gy - 66 * SS], fill=P["danger"], outline=P["ink"], width=1.4)
    d.line([(cx, gy - 62 * SS), (cx, gy - 52 * SS)], fill=P["ink_soft"], width=2)
    d.rectangle([cx - 22 * SS, gy - 8 * SS, cx + 22 * SS, gy - 2 * SS], fill=P["stone_b"], outline=P["ink"], width=1.6)
    save(finish(img, W, H), "buildings", "hospital", foot=6)

def cooperative():
    W, H = 92, 80
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 8 * SS; cx = W * SS / 2
    d.rectangle([cx - 34 * SS, gy - 36 * SS, cx + 34 * SS, gy - 2 * SS], fill=P["wood"], outline=P["ink"], width=2 * SS)
    outline_poly(d, [(cx, gy - 62 * SS), (cx - 42 * SS, gy - 34 * SS), (cx + 42 * SS, gy - 34 * SS)],
                 P["roof_straw"], edge=P["ink"], edge_w=2)
    d.polygon([(cx, gy - 62 * SS), (cx - 42 * SS, gy - 34 * SS), (cx, gy - 34 * SS)], fill=P["roof_straw_hi"])
    # 麦捆徽记
    d.ellipse([cx - 9 * SS, gy - 30 * SS, cx + 9 * SS, gy - 14 * SS], outline=P["gold"], width=2, fill=None)
    for k in (-4, 0, 4):
        d.line([(cx + k * SS, gy - 27 * SS), (cx + k * SS, gy - 17 * SS)], fill=P["gold"], width=2)
    # 敞开门廊内的工具与货箱
    rrect(d, [cx - 26 * SS, gy - 12 * SS, cx - 6 * SS, gy - 2 * SS], 2, (120, 88, 52, 255), edge=P["ink"], edge_w=1.4)
    d.rectangle([cx + 8 * SS, gy - 16 * SS, cx + 22 * SS, gy - 2 * SS], fill=P["plank"], outline=P["ink"], width=1.4)
    d.line([(cx + 10 * SS, gy - 20 * SS), (cx + 20 * SS, gy - 20 * SS)], fill=P["metal_c"], width=3)  # 锄具
    _banner(d, cx - 44 * SS, gy - 34 * SS, 8, 20)
    save(finish(img, W, H), "buildings", "cooperative", foot=8)

def construction():
    W, H = 60, 68
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    # 半成品墙
    d.rectangle([cx - 16 * SS, gy - 26 * SS, cx + 8 * SS, gy], fill=(206, 182, 152, 255), outline=P["ink"], width=2 * SS)
    d.rectangle([cx - 16 * SS, gy - 26 * SS, cx + 8 * SS, gy - 20 * SS], fill=(232, 214, 178, 255))
    for k in range(3):
        d.rectangle([cx - 14 * SS + k * 9 * SS, gy - 18 * SS, cx - 9 * SS + k * 9 * SS, gy - 2 * SS], fill=P["brick_lo"])
    # 脚手架
    for dx in (-22, 14):
        d.line([(cx + dx * SS, gy), (cx + dx * SS, gy - 46 * SS)], fill=P["wood_lo"], width=3 * SS)
    d.line([(cx - 22 * SS, gy - 44 * SS), (cx + 14 * SS, gy - 44 * SS)], fill=P["wood_lo"], width=3 * SS)
    d.line([(cx - 22 * SS, gy - 30 * SS), (cx + 14 * SS, gy - 30 * SS)], fill=P["wood_lo"], width=3 * SS)
    d.line([(cx - 22 * SS, gy - 44 * SS), (cx + 14 * SS, gy - 30 * SS)], fill=(196, 148, 96, 200), width=2)
    # 板料堆
    for k in range(3):
        d.rectangle([cx + 18 * SS, gy - 6 * SS - k * 5 * SS, cx + 30 * SS, gy - k * 5 * SS], fill=P["plank"], outline=P["ink"], width=1.4)
    d.ellipse([cx - 8 * SS, gy - 4 * SS, cx + 2 * SS, gy + 5 * SS], fill=P["stone_b_lo"], outline=P["ink"], width=1.2)
    save(finish(img, W, H), "buildings", "construction", foot=6)

if __name__ == "__main__":
    well(); workshop(); factory(); market(); admin_hall(); manor(); castle(); wall_tower()
    temple(); assembly(); school(); hospital(); cooperative(); construction()
    print("buildings B done")
