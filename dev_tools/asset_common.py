# -*- coding: utf-8 -*-
"""
Society Lab 资产生成 — 公共模块
设计语言：明亮风格化 2.5D 微缩沙盘；4x 超采样绘制后 LANCZOS 缩小，
统一暖色板 + 深色描边 + 顶光高光，保证整套素材视觉一致。
"""
import os, json
from PIL import Image, ImageDraw, ImageFilter


def _i(v):
    return int(round(v)) if isinstance(v, float) else int(v)


def _wrap_draw():
    """PIL 的绘图方法要求整型坐标/宽度；这里统一包装强制取整。"""
    import PIL.ImageDraw as _ID

    def mk(name):
        orig = getattr(_ID.ImageDraw, name)

        def w(self, *args, **kw):
            args = list(args)
            if args and isinstance(args[0], (list, tuple)):
                a = args[0]
                if a and isinstance(a[0], (list, tuple)):
                    args[0] = [(_i(p[0]), _i(p[1])) for p in a]
                else:
                    args[0] = [_i(v) for v in a]
                    if len(args[0]) == 4:  # box 归一化 x0<=x1, y0<=y1
                        b = args[0]
                        if b[0] > b[2]:
                            b[0], b[2] = b[2], b[0]
                        if b[1] > b[3]:
                            b[1], b[3] = b[3], b[1]
            args = [_i(x) if isinstance(x, float) else x for x in args]
            if kw.get("width") is not None:
                kw["width"] = _i(kw["width"])
            if kw.get("radius") is not None:
                kw["radius"] = _i(kw["radius"])
            return orig(self, *args, **kw)

        setattr(_ID.ImageDraw, name, w)

    for nm in ("rectangle", "line", "ellipse", "arc", "polygon", "rounded_rectangle"):
        mk(nm)

    _t = _ID.ImageDraw.text

    def wt(self, xy, text, *a, **kw):
        try:
            xy = (_i(xy[0]), _i(xy[1]))
        except Exception:
            pass
        return _t(self, xy, text, *a, **kw)

    _ID.ImageDraw.text = wt


_wrap_draw()

ROOT = "/home/z/my-project/society-lab"
ASSETS = os.path.join(ROOT, "assets")
SS = 4  # supersample factor

# ---------- 调色板（统一暖色 · 风格化） ----------
P = {
    "ink": (43, 42, 51, 235),          # 描边
    "ink_soft": (43, 42, 51, 90),
    "white": (255, 255, 255, 255),
    # 地形
    "grass": (128, 186, 92, 255), "grass_hi": (152, 208, 110, 255), "grass_lo": (104, 166, 78, 255),
    "grass_spk": (96, 158, 70, 255), "grass_spk2": (176, 224, 124, 255),
    "forest": (92, 148, 72, 255), "forest_hi": (112, 170, 88, 255), "forest_lo": (74, 122, 58, 255),
    "water_deep": (52, 130, 188, 255), "water_mid": (76, 158, 214, 255),
    "water_hi": (146, 218, 240, 255), "water_lo": (40, 104, 158, 255),
    "fertile": (198, 158, 92, 255), "fertile_hi": (218, 182, 112, 255), "fertile_lo": (168, 128, 72, 255),
    "furrow": (150, 112, 62, 255),
    "rock": (170, 162, 150, 255), "rock_hi": (194, 188, 176, 255), "rock_lo": (140, 132, 122, 255),
    "rock_spk": (120, 112, 104, 255),
    "mount": (152, 142, 130, 255), "mount_hi": (188, 178, 166, 255), "mount_lo": (118, 108, 98, 255),
    "snow": (246, 249, 253, 255),
    "sand": (234, 216, 162, 255), "sand_lo": (208, 186, 134, 255),
    # 植物
    "pine_d": (56, 116, 72, 255), "pine_m": (76, 142, 88, 255), "pine_l": (104, 170, 106, 255),
    "oak_d": (86, 146, 74, 255), "oak_m": (108, 174, 92, 255), "oak_l": (140, 200, 112, 255),
    "trunk": (122, 88, 58, 255), "trunk_d": (94, 66, 42, 255),
    # 建筑
    "wood": (196, 148, 96, 255), "wood_hi": (222, 178, 122, 255), "wood_lo": (156, 112, 70, 255),
    "plank": (210, 172, 122, 255),
    "stone_b": (186, 182, 174, 255), "stone_b_hi": (214, 210, 202, 255), "stone_b_lo": (148, 144, 136, 255),
    "roof_red": (206, 92, 68, 255), "roof_red_hi": (232, 122, 92, 255), "roof_red_lo": (168, 70, 52, 255),
    "roof_blue": (92, 130, 176, 255), "roof_blue_hi": (120, 160, 205, 255), "roof_blue_lo": (68, 100, 142, 255),
    "roof_straw": (228, 204, 130, 255), "roof_straw_hi": (244, 226, 158, 255), "roof_straw_lo": (198, 172, 98, 255),
    "cloth": (238, 230, 214, 255), "cloth_lo": (205, 196, 178, 255),
    "cloth_red": (214, 96, 84, 255),
    "metal_c": (150, 170, 190, 255), "metal_hi": (196, 214, 232, 255), "metal_lo": (108, 126, 148, 255),
    "gold": (238, 188, 92, 255), "gold_hi": (255, 222, 140, 255),
    "window": (255, 232, 150, 255), "window_off": (70, 82, 100, 255),
    "greenery": (110, 176, 96, 255),
    "brick": (188, 108, 84, 255), "brick_hi": (216, 138, 110, 255), "brick_lo": (152, 84, 66, 255),
    "glass": (168, 220, 240, 200), "glass_hi": (216, 244, 255, 230),
    "white_b": (244, 246, 250, 255), "white_b_lo": (205, 210, 220, 255),
    "accent": (232, 180, 74, 255),   # 琥珀主强调色
    "accent2": (111, 177, 224, 255), # 天蓝辅助
    "danger": (224, 108, 90, 255),
    "ok": (127, 191, 106, 255),
    "banner_red": (198, 82, 76, 255),
    # 矿物
    "iron": (128, 168, 208, 255), "iron_hi": (210, 236, 255, 255),
    "ore_gold": (240, 196, 80, 255), "ore_gold_hi": (255, 240, 180, 255),
    # 村民
    "skin": (238, 196, 158, 255),
    "laborer_c": (166, 122, 78, 255), "laborer_c_lo": (128, 92, 58, 255),
    "elite_c": (148, 94, 168, 255), "elite_c_lo": (112, 68, 130, 255),
    "merchant_c": (224, 176, 84, 255), "merchant_c_lo": (180, 136, 54, 255),
    "admin_c": (108, 138, 180, 255), "admin_c_lo": (80, 104, 142, 255),
    "hair_d": (58, 44, 38, 255),
}

REGISTRY = {}  # key -> {file, foot, w, h}

def canvas(w, h):
    """按 1x 目标尺寸创建 4x 超采样画布"""
    return Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))

def finish(img, w, h):
    return img.resize((w, h), Image.LANCZOS)

def save(img, folder, key, foot=6, register=True):
    """保存 1x 尺寸 PNG 并登记。img 传 1x 尺寸（已 finish）。"""
    path = os.path.join(ASSETS, folder)
    os.makedirs(path, exist_ok=True)
    fname = key + ".png"
    img.save(os.path.join(path, fname))
    if register:
        REGISTRY[folder + "/" + key] = {
            "file": folder + "/" + fname, "foot": foot, "w": img.width, "h": img.height,
        }
    return img

def diamond(draw, cx, cy, w, h, fill, edge=None, edge_w=2, hi=None, lo=None):
    """等距菱形；hi/lo 为顶部/底部内缘色带（增加立体感）"""
    hw, hh = w / 2.0, h / 2.0
    pts = [(cx, cy - hh), (cx + hw, cy), (cx, cy + hh), (cx - hw, cy)]
    draw.polygon(pts, fill=fill)
    if hi:
        draw.polygon([(cx, cy - hh), (cx + hw, cy), (cx, cy + hh * 0.15)], fill=hi)
    if lo:
        draw.polygon([(cx, cy + hh), (cx - hw, cy), (cx, cy + hh * 0.15)], fill=lo)
    if edge:
        draw.line(pts + [pts[0]], fill=edge, width=edge_w * SS, joint="curve")

def speckles(draw, cx, cy, w, h, color, n=5, seed=0, r=(2, 4)):
    """在菱形范围内撒点（伪随机但确定性）"""
    import math
    rnd = seed
    def nx():
        nonlocal rnd
        rnd = (rnd * 1103515245 + 12345) % 2147483648
        return rnd / 2147483648.0
    for i in range(n):
        u, v = nx(), nx()
        x = cx + (u - 0.5) * w * 0.62
        y = cy + (v - 0.5) * h * 0.6
        rr = int((r[0] + nx() * (r[1] - r[0])) * SS)
        draw.ellipse([x - rr, y - rr, x + rr, y + rr], fill=color)

def outline_poly(draw, pts, fill, edge=None, edge_w=2):
    draw.polygon(pts, fill=fill)
    if edge:
        draw.line(pts + [pts[0]], fill=edge, width=edge_w * SS, joint="curve")

def rrect(draw, box, radius, fill, edge=None, edge_w=2):
    draw.rounded_rectangle([int(round(box[0])), int(round(box[1])), int(round(box[2])), int(round(box[3]))],
                           int(round(radius * SS)), fill=fill,
                           outline=edge, width=int(round(edge_w * SS)) if edge else 0)

def grad_overlay(img, top_alpha=26, bottom_alpha=0):
    """给整张图叠加自上而下的白色渐变（顶光）——用 alpha 合成"""
    ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    H = img.size[1]
    for y in range(0, H, 4):
        t = y / max(1, H - 1)
        a = int(top_alpha * (1 - t) + bottom_alpha * t)
        d.rectangle([(0, y), (img.size[0], y + 4)], fill=(255, 255, 255, a))
    return Image.alpha_composite(img, ov)

def contact_sheet(keys, out, cols=8, cell=96):
    """生成拼图供视觉审查"""
    imgs = []
    for k in keys:
        info = REGISTRY.get(k)
        if not info:
            continue
        im = Image.open(os.path.join(ASSETS, info["file"]))
        imgs.append((k, im))
    rows = (len(imgs) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * cell + 16), (34, 38, 48, 255))
    d = ImageDraw.Draw(sheet)
    for i, (k, im) in enumerate(imgs):
        x, y = (i % cols) * cell, (i // cols) * cell
        scale = min(cell - 12, cell - 12) / max(im.width, im.height, 1)
        im2 = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.LANCZOS)
        sheet.paste(im2, (x + (cell - im2.width) // 2, y + (cell - im2.height) // 2), im2)
        d.rectangle([x + 1, y + 1, x + cell - 1, y + cell - 1], outline=(70, 76, 90, 255))
    sheet.convert("RGB").save(out, quality=92)
    print("sheet ->", out, len(imgs), "sprites")

def write_manifest():
    man = {"_meta": "Society Lab asset manifest (generated)", "entries": REGISTRY}
    with open(os.path.join(ASSETS, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(man, f, ensure_ascii=False, indent=1)
    print("manifest written:", len(REGISTRY), "entries")
