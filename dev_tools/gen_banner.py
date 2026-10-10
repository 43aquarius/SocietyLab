# -*- coding: utf-8 -*-
"""主菜单横幅 1280x420：用已生成素材合成微缩沙盘场景"""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw, ImageFilter
from asset_common import (P, SS, canvas, finish, save, diamond, outline_poly, rrect,
                           REGISTRY, ASSETS)

W, H = 1280, 420
TILE_W, TILE_H = 128, 64  # 2x 图块

def _get(key):
    return Image.open(os.path.join(ASSETS, REGISTRY[key]["file"]))

def place(base, key, tx, ty, scale=2.0, extra=1.0, offset=(0, 0)):
    """按等距坐标摆放素材（锚点=foot）"""
    info = REGISTRY[key]
    spr = _get(key)
    w, h = int(info["w"] * scale), int(info["h"] * scale)
    spr = spr.resize((w, h), Image.LANCZOS)
    sx = (tx - ty) * TILE_W / 2.0 + W / 2 + offset[0]
    sy = (tx + ty) * TILE_H / 2.0 + 120 + offset[1]
    gy = sy + 16  # 菱形中心下移为地面
    px, py = int(sx - w / 2), int(gy - (h - info["foot"] * scale))
    if extra < 1.0:
        alpha = spr.split()[3].point(lambda a: int(a * extra))
        spr.putalpha(alpha)
    base.paste(spr, (px, py), spr)
    return (px + w / 2, py)

def gen_banner():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # 天空渐变
    sky = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(sky)
    for y in range(H):
        t = y / H
        r = int(38 + t * 30); g = int(52 + t * 46); b = int(84 + t * 66)
        d.rectangle([(0, y), (W, y + 1)], fill=(r, g, b, 255))
    img = Image.alpha_composite(img, sky)
    d = ImageDraw.Draw(img)
    # 光晕（右上）
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r in range(420, 40, -24):
        a = int(10 + (420 - r) * 0.10)
        gd.ellipse([W - 260 - r, -180 - r, W - 260 + r, -180 + r], fill=(255, 226, 140, a))
    glow = glow.filter(ImageFilter.GaussianBlur(18))
    img = Image.alpha_composite(img, glow)
    # 远景小岛群（低饱和剪影）
    d = ImageDraw.Draw(img)
    for cx, cy, rw in [(150, 210, 120), (1130, 190, 90), (640, 150, 70)]:
        d.polygon([(cx, cy - 26), (cx + rw, cy), (cx, cy + 26), (cx - rw, cy)], fill=(58, 76, 108, 235), outline=(80, 100, 136, 255))
    # 主岛水域底盘：铺满整个 9x9，避免边角露空隙
    for tx in range(-4, 5):
        for ty in range(-4, 5):
            sx = (tx - ty) * TILE_W / 2.0 + W / 2
            sy = (tx + ty) * TILE_H / 2.0 + 120
            t2 = _get("tiles/water_%d" % (abs(tx + ty) % 3)).resize((TILE_W, TILE_H), Image.LANCZOS)
            img.paste(t2, (int(sx - TILE_W / 2), int(sy - TILE_H / 2)), t2)
    # 岛屿草地
    layout = {}
    def island(tx, ty, key):
        sx = (tx - ty) * TILE_W / 2.0 + W / 2
        sy = (tx + ty) * TILE_H / 2.0 + 120
        t2 = _get(key).resize((TILE_W, TILE_H), Image.LANCZOS)
        img.paste(t2, (int(sx - TILE_W / 2), int(sy - TILE_H / 2)), t2)
        layout[(tx, ty)] = True
    for tx in range(-2, 3):
        for ty in range(-2, 3):
            if abs(tx) + abs(ty) <= 3:
                if abs(tx) + abs(ty) == 3 and (tx + ty) % 3 == 0:
                    island(tx, ty, "tiles/sand_%d" % (abs(tx) % 2))
                else:
                    island(tx, ty, "tiles/grass_%d" % (abs(tx * 3 + ty) % 3))
    island(-1, 1, "tiles/fertile_0")
    island(0, 1, "tiles/fertile_1")
    # 河湾
    island(2, -1, "tiles/water_0")
    island(1, -2, "tiles/water_1")
    # ---- 摆放物件（按深度排序：ty 大在后）----
    items = [
        ("props/peak_snow", -3, -3, 1.1), ("props/peak", -2, -3, 1.0),
        ("props/pine_0", -2, 0, 1.0), ("props/oak_1", -1, -2, 1.0),
        ("props/pine_1", 1, -1, 1.0), ("props/oak_0", 2, 0, 0.95),
        ("props/bush", -2, 2, 1.0), ("props/reeds", 3, -1, 1.0),
        ("props/ore_iron", 3, -2, 1.0), ("props/pine_2", -3, 0, 1.0),
        ("buildings/camp_tent", -1, 0, 1.1), ("buildings/hut", 0, -1, 1.1),
        ("buildings/farm_c", -1, 1, 1.15), ("buildings/farm_a", 0, 2, 1.15),
        ("buildings/granary", 1, 1, 1.1), ("buildings/market", 1, 0, 1.15),
        ("buildings/house_wood", 2, 1, 1.05), ("buildings/well", 0, 0, 1.0),
        ("villagers/laborer_idle", -0.5, 0.4, 1.0),
        ("villagers/laborer_carry_a", 0.5, 0.6, 1.0),
        ("villagers/laborer_walk_a", -0.2, 1.5, 1.0),
        ("villagers/elite_idle", 1.3, 0.3, 1.0),
        ("villagers/merchant_carry_b", 0.2, -0.5, 1.0),
        ("villagers/laborer_walk_b", 1.8, 1.2, 1.0),
        ("villagers/admin_idle", -0.8, -0.4, 1.0),
    ]
    for key, tx, ty, sc in sorted(items, key=lambda it: it[1] + it[2]):
        place(img, key, tx, ty, scale=sc)
    # 神光斜线
    rays = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rays)
    for k in range(7):
        x0 = 980 + k * 26
        rd.polygon([(x0, 0), (x0 + 34, 0), (x0 - 300 + k * 40, H), (x0 - 340 + k * 40, H)],
                   fill=(255, 240, 190, 14))
    rays = rays.filter(ImageFilter.GaussianBlur(6))
    img = Image.alpha_composite(img, rays)
    # 暗角
    vig = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig)
    for k in range(120):
        a = int(80 * (1 - k / 120.0))
        vd.rectangle([k * 3, k, W - k * 3, H - k], outline=(10, 14, 24, a), width=4)
    img = Image.alpha_composite(img, vig)
    path = os.path.join(ASSETS, "ui")
    img.save(os.path.join(path, "banner_main.png"))
    REGISTRY["ui/banner_main"] = {"file": "ui/banner_main.png", "foot": 0, "w": W, "h": H}
    print("banner done")

if __name__ == "__main__":
    gen_banner()
