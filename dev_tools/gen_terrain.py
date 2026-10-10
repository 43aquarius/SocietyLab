# -*- coding: utf-8 -*-
"""地形图块(64x32)与地表物件（树/山/岩/矿/灌木/芦苇）"""
import os
from PIL import ImageDraw
from asset_common import (P, SS, canvas, finish, save, diamond, speckles,
                           outline_poly, rrect, grad_overlay, REGISTRY)

TW, TH = 64, 32

def _tile_base(key, base, hi, lo, seed, speck=None, speck_n=5, speck2=None):
    img = canvas(TW, TH)
    d = ImageDraw.Draw(img)
    cx, cy = TW * SS / 2, TH * SS / 2
    diamond(d, cx, cy, TW * SS, TH * SS, base, hi=hi, lo=lo)
    if speck:
        speckles(d, cx, cy, TW * SS * 0.9, TH * SS * 0.9, speck, n=speck_n, seed=seed, r=(2, 5))
    if speck2:
        speckles(d, cx, cy - TH * SS * 0.1, TW * SS * 0.5, TH * SS * 0.5, speck2, n=3, seed=seed + 7, r=(2, 3))
    save(finish(img, TW, TH), "tiles", key)

def gen_tiles():
    for i in range(3):
        _tile_base("grass_%d" % i, P["grass"], P["grass_hi"], P["grass_lo"], 11 + i * 31,
                   speck=P["grass_spk"], speck_n=6, speck2=P["grass_spk2"])
    for i in range(2):
        _tile_base("forest_%d" % i, P["forest"], P["forest_hi"], P["forest_lo"], 5 + i * 17,
                   speck=P["forest_lo"], speck_n=5)
    # 水面：中蓝基底 + 深色中央 + 亮缘波浪
    for i in range(3):
        img = canvas(TW, TH)
        d = ImageDraw.Draw(img)
        cx, cy = TW * SS / 2, TH * SS / 2
        diamond(d, cx, cy, TW * SS, TH * SS, P["water_mid"], hi=P["water_hi"], lo=P["water_lo"])
        # 中央深水
        d.polygon([(cx, cy - 34), (cx + 72, cy), (cx, cy + 34), (cx - 72, cy)], fill=P["water_deep"])
        # 波光短线
        for k, (dx, dy) in enumerate([(-40, -8), (10, 2), (44, 10), (-6, -16), (30, -10)]):
            col = P["water_hi"] if (k + i) % 2 == 0 else (210, 236, 250, 230)
            d.line([(cx + dx * SS, cy + dy * SS), (cx + dx * SS + 30, cy + dy * SS - 8)],
                   fill=col, width=4 * 2)
        save(finish(img, TW, TH), "tiles", "water_%d" % i)
    for i in range(2):
        _tile_base("rock_%d" % i, P["rock"], P["rock_hi"], P["rock_lo"], 23 + i * 13,
                   speck=P["rock_spk"], speck_n=6)
    for i in range(2):
        _tile_fertile(i)
    for i in range(2):
        _tile_base("sand_%d" % i, P["sand"], (248, 234, 190, 255), P["sand_lo"], 83 + i * 7,
                   speck=P["sand_lo"], speck_n=5)
    print("tiles done:", len(REGISTRY))


def _tile_fertile(i):
    """耕地图块：暖金色 + 等距田垄纹"""
    img = canvas(TW, TH)
    d = ImageDraw.Draw(img)
    cx, cy = TW * SS / 2, TH * SS / 2
    diamond(d, cx, cy, TW * SS, TH * SS, P["fertile"], hi=P["fertile_hi"], lo=P["fertile_lo"])
    # 田垄纹：两组沿等距方向的平行线
    for s in range(-3, 4):
        o = s * 30
        d.line([(cx + o, cy), (cx + o * 0.4, cy - 56)], fill=P["furrow"], width=5)
        d.line([(cx + o, cy), (cx + o * 0.4, cy + 56)], fill=(222, 192, 132, 220), width=5)
    save(finish(img, TW, TH), "tiles", "fertile_%d" % i)

# ---------------- 地表物件 ----------------
def _pine(seed):
    W, H = 40, 56
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    cx = W * SS / 2
    gy = H * SS - 6 * SS  # foot=6（1x）
    # 树干
    d.rectangle([cx - 5 * SS, gy - 18 * SS, cx + 5 * SS, gy], fill=P["trunk"], outline=P["trunk_d"], width=2 * SS)
    # 三层树冠（左亮右暗）
    tiers = [(gy - 12 * SS, 15, 40), (gy - 28 * SS, 13, 33), (gy - 42 * SS, 10, 24)]
    for ty, hh, ww in tiers:
        pts = [(cx, ty - hh * SS), (cx + ww * SS / 2, ty), (cx, ty + 9 * SS), (cx - ww * SS / 2, ty)]
        outline_poly(d, pts, P["pine_m"], edge=P["ink"], edge_w=2)
        d.polygon([(cx, ty - hh * SS), (cx - ww * SS / 2, ty), (cx, ty + 9 * SS)], fill=P["pine_d"])
        d.polygon([(cx, ty - hh * SS), (cx + ww * SS / 2, ty), (cx, ty + 9 * SS)], fill=P["pine_l"])
    save(finish(img, W, H), "props", "pine_%d" % seed, foot=6)

def _oak(seed):
    W, H = 44, 48
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    cx = W * SS / 2
    gy = H * SS - 6 * SS
    d.rectangle([cx - 5 * SS, gy - 14 * SS, cx + 5 * SS, gy], fill=P["trunk"], outline=P["trunk_d"], width=2 * SS)
    blobs = [(cx - 14 * SS, gy - 34 * SS, 16), (cx + 13 * SS, gy - 32 * SS, 15),
             (cx, gy - 44 * SS, 18), (cx - 4 * SS, gy - 26 * SS, 14)]
    for bx, by, br in blobs:
        d.ellipse([bx - br * SS, by - br * SS, bx + br * SS, by + br * SS], fill=P["oak_m"], outline=P["ink"], width=2 * SS)
    # 高光小圆
    d.ellipse([cx - 18 * SS, gy - 48 * SS, cx + 2 * SS, gy - 30 * SS], fill=P["oak_l"])
    if seed % 2 == 1:
        speckles(d, cx, gy - 36 * SS, 60 * SS, 30 * SS, P["oak_l"], n=4, seed=seed, r=(2, 3))
    save(finish(img, W, H), "props", "oak_%d" % seed, foot=6)

def _peak(snow):
    W, H = 104, 96
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    cx = W * SS / 2
    gy = H * SS - 8 * SS
    # 主峰：左面亮右面暗
    pts = [(cx, gy - 84 * SS), (cx + 46 * SS, gy), (cx - 46 * SS, gy)]
    outline_poly(d, pts, P["mount"], edge=P["ink"], edge_w=2)
    d.polygon([(cx, gy - 84 * SS), (cx - 46 * SS, gy), (cx, gy)], fill=P["mount_hi"])
    d.polygon([(cx, gy - 84 * SS), (cx + 46 * SS, gy), (cx + 10 * SS, gy)], fill=P["mount_lo"])
    if snow:
        d.polygon([(cx, gy - 84 * SS), (cx - 22 * SS, gy - 44 * SS), (cx - 8 * SS, gy - 38 * SS),
                   (cx + 4 * SS, gy - 46 * SS), (cx + 20 * SS, gy - 40 * SS)], fill=P["snow"])
    # 副峰
    pts2 = [(cx - 40 * SS, gy - 34 * SS), (cx - 12 * SS, gy), (cx - 62 * SS, gy)]
    outline_poly(d, pts2, P["mount_lo"], edge=P["ink"], edge_w=2)
    pts3 = [(cx + 38 * SS, gy - 28 * SS), (cx + 60 * SS, gy), (cx + 14 * SS, gy)]
    outline_poly(d, pts3, P["mount"], edge=P["ink"], edge_w=2)
    save(finish(img, W, H), "props", ("peak_snow" if snow else "peak"), foot=8)

def _rock(seed):
    W, H = 36, 28
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    gy = H * SS - 5 * SS
    cx = W * SS / 2
    n = 2 + seed % 2
    if n == 2:
        outline_poly(d, [(cx - 16 * SS, gy - 8 * SS), (cx - 4 * SS, gy - 20 * SS), (cx + 14 * SS, gy - 12 * SS),
                         (cx + 16 * SS, gy), (cx - 12 * SS, gy)], P["rock"], edge=P["ink"], edge_w=2)
        d.polygon([(cx - 4 * SS, gy - 20 * SS), (cx - 16 * SS, gy - 8 * SS), (cx - 12 * SS, gy)], fill=P["rock_hi"])
        outline_poly(d, [(cx + 6 * SS, gy), (cx + 16 * SS, gy - 6 * SS), (cx + 24 * SS, gy)], P["rock_lo"], edge=P["ink"], edge_w=2)
    else:
        outline_poly(d, [(cx - 18 * SS, gy - 5 * SS), (cx - 10 * SS, gy - 16 * SS), (cx + 4 * SS, gy - 12 * SS),
                         (cx + 18 * SS, gy), (cx - 14 * SS, gy)], P["rock"], edge=P["ink"], edge_w=2)
        d.polygon([(cx - 10 * SS, gy - 16 * SS), (cx - 18 * SS, gy - 5 * SS), (cx - 14 * SS, gy)], fill=P["rock_hi"])
    save(finish(img, W, H), "props", "rock_%d" % seed, foot=5)

def _ore(kind):
    W, H = 46, 42
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    gy = H * SS - 6 * SS
    cx = W * SS / 2
    outline_poly(d, [(cx - 18 * SS, gy - 6 * SS), (cx - 8 * SS, gy - 22 * SS), (cx + 10 * SS, gy - 16 * SS),
                     (cx + 18 * SS, gy), (cx - 14 * SS, gy)], P["rock_lo"], edge=P["ink"], edge_w=2)
    d.polygon([(cx - 8 * SS, gy - 22 * SS), (cx - 18 * SS, gy - 6 * SS), (cx - 14 * SS, gy)], fill=P["rock"])
    col = P["iron"] if kind == "iron" else P["ore_gold"]
    colhi = P["iron_hi"] if kind == "iron" else P["ore_gold_hi"]
    for bx, by, br, bh in [(cx - 6 * SS, gy - 14 * SS, 5, 16), (cx + 6 * SS, gy - 10 * SS, 4, 12), (cx + 1 * SS, gy - 4 * SS, 3, 9)]:
        pts = [(bx, by - bh * SS), (bx + br * SS, by), (bx, by + 3 * SS), (bx - br * SS, by)]
        outline_poly(d, pts, col, edge=P["ink"], edge_w=2)
        d.polygon([(bx, by - bh * SS), (bx - br * SS, by), (bx, by + 3 * SS)], fill=colhi)
    save(finish(img, W, H), "props", "ore_%s" % kind, foot=6)

def _bush():
    W, H = 30, 24
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    gy = H * SS - 5 * SS
    cx = W * SS / 2
    d.ellipse([cx - 13 * SS, gy - 18 * SS, cx + 13 * SS, gy], fill=P["greenery"], outline=P["ink"], width=2 * SS)
    d.ellipse([cx - 10 * SS, gy - 16 * SS, cx + 2 * SS, gy - 6 * SS], fill=(150, 208, 130, 255))
    for dx, dy in [(-8, -12), (6, -10), (-2, -15), (9, -4), (-11, -6)]:
        d.ellipse([cx + dx * SS - 2.5 * SS, gy + dy * SS - 2.5 * SS, cx + dx * SS + 2.5 * SS, gy + dy * SS + 2.5 * SS],
                  fill=P["danger"])
    save(finish(img, W, H), "props", "bush", foot=5)

def _reeds():
    W, H = 30, 38
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    gy = H * SS - 5 * SS
    cx = W * SS / 2
    for k, (dx, hgt) in enumerate([(-10, 26), (-2, 32), (7, 23), (12, 29)]):
        x0 = cx + dx * SS
        d.line([(x0, gy), (x0 + (2 if k % 2 else -2) * SS, gy - hgt * SS)], fill=P["greenery"], width=3 * SS)
        d.ellipse([x0 - 3 * SS, gy - hgt * SS - 8 * SS, x0 + 3 * SS, gy - hgt * SS], fill=(198, 168, 98, 255), outline=P["ink"], width=1 * SS)
    save(finish(img, W, H), "props", "reeds", foot=5)

if __name__ == "__main__":
    import sys, os
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    gen_tiles()
    _pine(0); _pine(1); _pine(2)
    _oak(0); _oak(1)
    _peak(False); _peak(True)
    _rock(0); _rock(1)
    _ore("iron"); _ore("gold")
    _bush(); _reeds()
    print("terrain/props total:", len(REGISTRY))
