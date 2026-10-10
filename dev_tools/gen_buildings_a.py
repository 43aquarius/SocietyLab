# -*- coding: utf-8 -*-
"""建筑素材第一部分：住房/农田/仓储/公共设施（时代分层）"""
import os, sys
from PIL import ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asset_common import (P, SS, canvas, finish, save, diamond, speckles,
                           outline_poly, rrect, grad_overlay, REGISTRY)

def _win(d, x, y, w=7, h=9, lit=True):
    col = P["window"] if lit else P["window_off"]
    rrect(d, [x, y, x + w * SS, y + h * SS], 1.6, col, edge=P["ink"], edge_w=1.6)

def _door(d, x, y, w=12, h=16):
    rrect(d, [x, y, x + w * SS, y + h * SS], 6, P["wood_lo"], edge=P["ink"], edge_w=1.6)
    d.ellipse([x + w * SS - 4 * SS, y + h * SS * 0.45, x + w * SS - 2 * SS, y + h * SS * 0.62], fill=P["gold"])

def _banner(d, x, y, w=10, h=26, col=P["banner_red"]):
    d.line([(x, y), (x, y - h * SS)], fill=P["wood_lo"], width=2 * SS)
    outline_poly(d, [(x + 1 * SS, y - h * SS), (x + (1 + w) * SS, y - h * SS + 3 * SS),
                     (x + (1 + w) * SS, y - h * SS + 16 * SS), (x + 1 * SS, y - h * SS + 13 * SS)],
                 col, edge=P["ink"], edge_w=1.6)

# ---------- 住房（时代分层） ----------
def camp_tent():
    W, H = 52, 46
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    for dx, s in [(-14, 1), (13, -1)]:
        base = cx + dx * SS
        pts = [(base, gy - 30 * SS), (base + 16 * SS * s, gy), (base - 16 * SS * s, gy)]
        outline_poly(d, pts, P["cloth"], edge=P["ink"], edge_w=2)
        d.polygon([(base, gy - 30 * SS), (base + 16 * SS * s, gy), (base + 6 * SS * s, gy)], fill=P["cloth_lo"])
        d.line([(base, gy - 30 * SS), (base, gy)], fill=P["ink_soft"], width=2 * SS)
    # 篝火
    d.ellipse([cx - 9 * SS, gy - 4 * SS, cx + 9 * SS, gy + 4 * SS], fill=P["stone_b_lo"], outline=P["ink"], width=2 * SS)
    for fx in (-5, 0, 5):
        d.polygon([(cx + fx * SS, gy - 2 * SS), (cx + fx * SS - 3 * SS, gy - 9 * SS), (cx + fx * SS + 3 * SS, gy - 9 * SS)],
                  fill=(238, 150, 70, 235))
    d.polygon([(cx, gy - 8 * SS), (cx - 4 * SS, gy - 18 * SS), (cx + 4 * SS, gy - 18 * SS)], fill=(255, 210, 110, 240))
    save(finish(img, W, H), "buildings", "camp_tent", foot=6)

def hut():
    W, H = 46, 48
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    d.rectangle([cx - 14 * SS, gy - 20 * SS, cx + 14 * SS, gy], fill=(201, 168, 124, 255), outline=P["ink"], width=2 * SS)
    d.rectangle([cx - 14 * SS, gy - 8 * SS, cx + 14 * SS, gy], fill=(178, 142, 100, 255))
    outline_poly(d, [(cx, gy - 40 * SS), (cx - 20 * SS, gy - 18 * SS), (cx + 20 * SS, gy - 18 * SS)],
                 P["roof_straw"], edge=P["ink"], edge_w=2)
    d.polygon([(cx, gy - 40 * SS), (cx - 20 * SS, gy - 18 * SS), (cx, gy - 18 * SS)], fill=P["roof_straw_hi"])
    for k in range(4):
        d.line([(cx - 16 * SS + k * 10 * SS, gy - 22 * SS), (cx - 8 * SS + k * 8 * SS, gy - 38 * SS)],
               fill=(198, 172, 98, 200), width=2)
    _door(d, cx - 6 * SS, gy - 15 * SS)
    save(finish(img, W, H), "buildings", "hut", foot=6)

def house_wood():
    W, H = 54, 54
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    d.rectangle([cx - 17 * SS, gy - 24 * SS, cx + 17 * SS, gy], fill=P["wood"], outline=P["ink"], width=2 * SS)
    for yy in range(-18, -2, 5):
        d.line([(cx - 17 * SS, gy + yy * SS), (cx + 17 * SS, gy + yy * SS)], fill=P["wood_lo"], width=2)
    outline_poly(d, [(cx, gy - 44 * SS), (cx - 23 * SS, gy - 22 * SS), (cx + 23 * SS, gy - 22 * SS)],
                 P["roof_red"], edge=P["ink"], edge_w=2)
    d.polygon([(cx, gy - 44 * SS), (cx - 23 * SS, gy - 22 * SS), (cx, gy - 22 * SS)], fill=P["roof_red_hi"])
    d.line([(cx, gy - 44 * SS), (cx, gy - 22 * SS)], fill=P["ink_soft"], width=2)
    _door(d, cx - 24 * SS, gy - 16 * SS)
    _win(d, cx + 6 * SS, gy - 20 * SS)
    save(finish(img, W, H), "buildings", "house_wood", foot=6)

def house_brick():
    W, H = 58, 66
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    d.rectangle([cx - 18 * SS, gy - 34 * SS, cx + 18 * SS, gy], fill=P["brick"], outline=P["ink"], width=2 * SS)
    for yy in range(-30, -2, 4):
        d.line([(cx - 18 * SS, gy + yy * SS), (cx + 18 * SS, gy + yy * SS)], fill=P["brick_lo"], width=2)
    d.rectangle([cx - 18 * SS, gy - 34 * SS, cx + 18 * SS, gy - 30 * SS], fill=P["brick_hi"])
    outline_poly(d, [(cx, gy - 56 * SS), (cx - 25 * SS, gy - 32 * SS), (cx + 25 * SS, gy - 32 * SS)],
                 P["roof_red"], edge=P["ink"], edge_w=2)
    d.polygon([(cx, gy - 56 * SS), (cx - 25 * SS, gy - 32 * SS), (cx, gy - 32 * SS)], fill=P["roof_red_hi"])
    d.rectangle([cx + 8 * SS, gy - 52 * SS, cx + 13 * SS, gy - 32 * SS], fill=P["stone_b"], outline=P["ink"], width=1.6 * SS)
    _door(d, cx - 25 * SS, gy - 18 * SS, 14, 18)
    _win(d, cx - 8 * SS, gy - 27 * SS); _win(d, cx + 4 * SS, gy - 27 * SS)
    _win(d, cx - 8 * SS, gy - 14 * SS); _win(d, cx + 4 * SS, gy - 14 * SS, lit=False)
    save(finish(img, W, H), "buildings", "house_brick", foot=6)

def house_town():
    W, H = 66, 92
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    d.rectangle([cx - 22 * SS, gy - 66 * SS, cx + 22 * SS, gy], fill=(214, 196, 168, 255), outline=P["ink"], width=2 * SS)
    d.rectangle([cx - 22 * SS, gy - 70 * SS, cx + 22 * SS, gy - 62 * SS], fill=P["roof_blue"], outline=P["ink"], width=2 * SS)
    d.rectangle([cx - 22 * SS, gy - 62 * SS, cx + 22 * SS, gy - 60 * SS], fill=P["roof_blue_lo"])
    for f in range(3):
        yy = gy - (56 - f * 20) * SS
        for k in range(-2, 3):
            if f == 2 and k == 0:
                _door(d, cx - 8 * SS, yy, 16, 18)
            else:
                _win(d, cx + k * 11 * SS - 4 * SS, yy, lit=(f + k) % 3 != 1)
    d.rectangle([cx - 26 * SS, gy - 4 * SS, cx + 26 * SS, gy], fill=P["stone_b"], outline=P["ink"], width=1.6 * SS)
    save(finish(img, W, H), "buildings", "house_town", foot=6)

def apartment():
    W, H = 90, 124
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    d.rectangle([cx - 36 * SS, gy - 104 * SS, cx + 36 * SS, gy], fill=P["white_b"], outline=P["ink"], width=2 * SS)
    d.rectangle([cx - 38 * SS, gy - 110 * SS, cx + 38 * SS, gy - 102 * SS], fill=(120, 160, 205, 255), outline=P["ink"], width=2 * SS)
    d.rectangle([cx - 38 * SS, gy - 102 * SS, cx + 38 * SS, gy - 99 * SS], fill=P["roof_blue_lo"])
    for f in range(5):
        yy = gy - (94 - f * 19) * SS
        for k in range(-3, 4):
            if f == 4 and k == 0:
                rrect(d, [cx - 9 * SS, yy - 2 * SS, cx + 9 * SS, yy + 18 * SS], 3, P["glass"], edge=P["ink"], edge_w=1.6)
            else:
                rrect(d, [cx + k * 10 * SS - 4 * SS, yy, cx + k * 10 * SS + 5 * SS, yy + 12 * SS], 2,
                      P["glass"] if (k + f) % 4 != 2 else P["glass_hi"], edge=P["ink"], edge_w=1.2)
    d.rectangle([cx + 10 * SS, gy - 118 * SS, cx + 20 * SS, gy - 110 * SS], fill=P["white_b_lo"], outline=P["ink"], width=1.6 * SS)
    save(finish(img, W, H), "buildings", "apartment", foot=6)

# ---------- 农田（三阶段 + 灌溉 + 现代） ----------
def _farm(stage):
    W, H = 64, 44
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 10 * SS; cx = W * SS / 2
    diamond(d, cx, gy, 108 * SS / 2 * 2 * 0.86, 52 * SS * 0.9, (168, 124, 72, 255), hi=(192, 148, 92, 255), lo=(140, 102, 60, 255))
    for s in range(-2, 3):
        o = s * 22
        d.line([(cx + o, gy), (cx + o * 0.45, gy - 40)], fill=(120, 88, 52, 235), width=5)
        d.line([(cx + o, gy), (cx + o * 0.45, gy + 40)], fill=(210, 178, 128, 210), width=5)
    if stage >= 1:
        col = (110, 178, 96, 255) if stage == 1 else (238, 198, 96, 255)
        hi = (150, 214, 130, 255) if stage == 1 else (255, 228, 150, 255)
        for s in range(-2, 3):
            for t in (0.3, 0.55, 0.8):
                x = cx + s * 22 * (1 - t) - t * 10
                y = gy - 40 * t + 52 * t * 0.5
                d.ellipse([x - 3 * SS, y - 3 * SS, x + 3 * SS, y + 3 * SS], fill=col)
                if (s + int(t * 10)) % 3 == 0:
                    d.ellipse([x - 2 * SS, y - 5 * SS, x + 2 * SS, y - 1 * SS], fill=hi)
    if stage == 2:
        for s in range(-2, 3):
            d.line([(cx + s * 22 * 0.9, gy - 6), (cx + s * 22 * 0.2, gy - 34)], fill=(255, 232, 150, 190), width=3)
    save(finish(img, W, H), "buildings", "farm_" + "abc"[stage], foot=10)

def farm_irrigated():
    W, H = 72, 50
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 10 * SS; cx = W * SS / 2
    diamond(d, cx, gy, 118 * SS * 0.8, 58 * SS * 0.8, (168, 124, 72, 255), hi=(196, 154, 98, 255), lo=(140, 102, 60, 255))
    d.line([(cx - 44 * SS, gy), (cx + 44 * SS, gy)], fill=P["water_mid"], width=7 * SS)
    d.line([(cx - 44 * SS, gy - 3 * SS), (cx + 44 * SS, gy - 3 * SS)], fill=P["water_hi"], width=2)
    for s in (-1, 1):
        for t in (0.35, 0.6, 0.85):
            x = cx + s * 40 * (1 - t)
            y = gy - 42 * t + 24 * t
            d.rectangle([x - 2 * SS, y - 4 * SS, x + 2 * SS, y + 26 * SS], fill=(52, 130, 188, 235), outline=P["ink_soft"], width=1)
            d.ellipse([x - 4 * SS, y - 8 * SS, x + 4 * SS, y - 2 * SS], fill=(110, 178, 96, 255))
    save(finish(img, W, H), "buildings", "farm_irrigated", foot=10)

def farm_modern():
    W, H = 92, 58
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 10 * SS; cx = W * SS / 2
    for k in range(3):
        x0 = cx + (k - 1) * 30 * SS
        outline_poly(d, [(x0 - 13 * SS, gy - 14 * SS), (x0 - 9 * SS, gy - 34 * SS), (x0 + 9 * SS, gy - 34 * SS), (x0 + 13 * SS, gy - 14 * SS)],
                     (188, 226, 244, 235), edge=P["white_b"], edge_w=2)
        d.line([(x0 - 11 * SS, gy - 22 * SS), (x0 + 11 * SS, gy - 22 * SS)], fill=(255, 255, 255, 200), width=2)
        for t in range(3):
            d.ellipse([x0 - 7 * SS + t * 7 * SS, gy - 20 * SS, x0 - 3 * SS + t * 7 * SS, gy - 16 * SS], fill=(238, 198, 96, 235))
    d.rectangle([cx - 42 * SS, gy - 12 * SS, cx + 42 * SS, gy - 6 * SS], fill=(120, 88, 52, 220), outline=P["ink_soft"], width=1.6)
    save(finish(img, W, H), "buildings", "farm_modern", foot=10)

# ---------- 仓储 ----------
def warehouse():
    W, H = 70, 60
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    d.rectangle([cx - 26 * SS, gy - 30 * SS, cx + 26 * SS, gy], fill=P["wood"], outline=P["ink"], width=2 * SS)
    for xx in range(-22, 22, 6):
        d.line([(cx + xx * SS, gy - 30 * SS), (cx + xx * SS, gy)], fill=P["wood_lo"], width=2)
    outline_poly(d, [(cx, gy - 52 * SS), (cx - 32 * SS, gy - 28 * SS), (cx + 32 * SS, gy - 28 * SS)],
                 P["roof_blue"], edge=P["ink"], edge_w=2)
    d.polygon([(cx, gy - 52 * SS), (cx - 32 * SS, gy - 28 * SS), (cx, gy - 28 * SS)], fill=P["roof_blue_hi"])
    rrect(d, [cx - 10 * SS, gy - 24 * SS, cx + 10 * SS, gy], 3, P["plank"], edge=P["ink"], edge_w=1.6)
    d.line([(cx - 10 * SS, gy - 12 * SS), (cx + 10 * SS, gy - 12 * SS)], fill=P["wood_lo"], width=2)
    save(finish(img, W, H), "buildings", "warehouse", foot=6)

def granary():
    W, H = 58, 62
    img = canvas(W, H); d = ImageDraw.Draw(img); gy = H * SS - 6 * SS; cx = W * SS / 2
    for dx in (-14, -5, 5, 14):
        d.rectangle([cx + dx * SS - 2 * SS, gy - 12 * SS, cx + dx * SS + 2 * SS, gy], fill=P["trunk_d"], outline=P["ink"], width=1.4)
    d.rectangle([cx - 20 * SS, gy - 14 * SS, cx + 20 * SS, gy - 12 * SS], fill=P["plank"], outline=P["ink"], width=1.6)
    d.rectangle([cx - 16 * SS, gy - 36 * SS, cx + 16 * SS, gy - 12 * SS], fill=(232, 214, 178, 255), outline=P["ink"], width=2 * SS)
    outline_poly(d, [(cx, gy - 56 * SS), (cx - 22 * SS, gy - 34 * SS), (cx + 22 * SS, gy - 34 * SS)],
                 P["roof_straw"], edge=P["ink"], edge_w=2)
    d.polygon([(cx, gy - 56 * SS), (cx - 22 * SS, gy - 34 * SS), (cx, gy - 34 * SS)], fill=P["roof_straw_hi"])
    for k in range(3):
        d.ellipse([cx - 10 * SS + k * 9 * SS, gy - 26 * SS, cx - 4 * SS + k * 9 * SS, gy - 20 * SS], fill=(120, 88, 52, 200))
    d.line([(cx + 18 * SS, gy), (cx + 13 * SS, gy - 12 * SS)], fill=P["wood_lo"], width=3 * SS)
    save(finish(img, W, H), "buildings", "granary", foot=6)

if __name__ == "__main__":
    camp_tent(); hut(); house_wood(); house_brick(); house_town(); apartment()
    _farm(0); _farm(1); _farm(2); farm_irrigated(); farm_modern()
    warehouse(); granary()
    print("buildings A:", len(REGISTRY))
