# -*- coding: utf-8 -*-
"""居民小人素材 v2：放大比例保证可读性（28x38，大头厚肢体）
4 社会群体 × 5 帧（idle/walk_a/walk_b/carry_a/carry_b）"""
import os, sys
from PIL import ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asset_common import P, SS, canvas, finish, save, outline_poly, rrect, REGISTRY

GROUPS = {
    "laborer": {"body": P["laborer_c"], "lo": P["laborer_c_lo"], "robe": False, "hat": "none"},
    "elite": {"body": P["elite_c"], "lo": P["elite_c_lo"], "robe": True, "hat": "band"},
    "merchant": {"body": P["merchant_c"], "lo": P["merchant_c_lo"], "robe": False, "hat": "cap", "pack": True},
    "admin": {"body": P["admin_c"], "lo": P["admin_c_lo"], "robe": True, "hat": "tall"},
}

W, H = 30, 40
HEAD_R = 8       # 头半径(1x)
BODY_W = 17
LEG_H = 9

def _villager(gid, g, frame):
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    cx = W * SS / 2
    gy = H * SS - 4 * SS  # foot=4
    robe = g["robe"]
    body_h = 23 if robe else 15
    # --- 腿（非袍）---
    if not robe:
        la = 6 if frame in ("walk_a", "carry_a") else 2
        lb = 2 if frame in ("walk_a", "carry_a") else 6
        if frame == "idle":
            la = lb = 3
        d.line([(cx - 4 * SS, gy - LEG_H * SS), (cx - 4 * SS - la * SS, gy)], fill=(58, 44, 38, 255), width=6 * SS)
        d.line([(cx + 4 * SS, gy - LEG_H * SS), (cx + 4 * SS + lb * SS, gy)], fill=(74, 58, 50, 255), width=6 * SS)
    # --- 躯干 ---
    rrect(d, [cx - BODY_W / 2 * SS, gy - (LEG_H + body_h) * SS, cx + BODY_W / 2 * SS,
              gy - (2 if robe else 3) * SS], 5, g["body"], edge=P["ink"], edge_w=2)
    d.rectangle([cx - BODY_W / 2 * SS, gy - (10 if robe else 9) * SS, cx + BODY_W / 2 * SS,
                 gy - (2 if robe else 3) * SS], fill=g["lo"])
    # --- 手臂 ---
    if frame in ("carry_a", "carry_b"):
        d.line([(cx - BODY_W / 2 * SS, gy - (LEG_H + body_h - 4) * SS), (cx - 6 * SS, gy - (LEG_H + body_h + 9) * SS)], fill=g["lo"], width=6 * SS)
        d.line([(cx + BODY_W / 2 * SS, gy - (LEG_H + body_h - 4) * SS), (cx + 6 * SS, gy - (LEG_H + body_h + 9) * SS)], fill=g["lo"], width=6 * SS)
    else:
        sw = 5 if frame == "walk_a" else (-5 if frame == "walk_b" else 0)
        d.line([(cx - BODY_W / 2 * SS, gy - (LEG_H + body_h - 4) * SS), (cx - (BODY_W / 2 + 4) * SS, gy - (LEG_H + 8) * SS + sw * SS)], fill=g["lo"], width=6 * SS)
        d.line([(cx + BODY_W / 2 * SS, gy - (LEG_H + body_h - 4) * SS), (cx + (BODY_W / 2 + 4) * SS, gy - (LEG_H + 8) * SS - sw * SS)], fill=g["lo"], width=6 * SS)
    # --- 头 ---
    hy = gy - (LEG_H + body_h + HEAD_R) * SS + 2 * SS
    d.ellipse([cx - HEAD_R * SS, hy - HEAD_R * SS, cx + HEAD_R * SS, hy + HEAD_R * SS],
              fill=P["skin"], outline=P["ink"], width=2)
    # 眼睛（朝向感）
    d.ellipse([cx - 5 * SS, hy + 1 * SS, cx - 3 * SS, hy + 3 * SS], fill=(45, 40, 38, 255))
    d.ellipse([cx + 3 * SS, hy + 1 * SS, cx + 5 * SS, hy + 3 * SS], fill=(45, 40, 38, 255))
    # --- 帽/发 ---
    if g["hat"] == "band":
        d.rectangle([cx - HEAD_R * SS, hy - HEAD_R * SS, cx + HEAD_R * SS, hy - HEAD_R * SS + 4 * SS], fill=P["gold"])
    elif g["hat"] == "cap":
        d.arc([cx - (HEAD_R + 2) * SS, hy - (HEAD_R + 7) * SS, cx + (HEAD_R + 2) * SS, hy + HEAD_R * SS], 180, 360, fill=P["hair_d"], width=0)
        d.rectangle([cx - (HEAD_R + 1) * SS, hy - 3 * SS, cx + (HEAD_R + 1) * SS, hy], fill=P["hair_d"])
    elif g["hat"] == "tall":
        d.rectangle([cx - 6 * SS, hy - (HEAD_R + 12) * SS, cx + 6 * SS, hy - HEAD_R * SS + 2 * SS],
                    fill=(90, 74, 60, 255), outline=P["ink"], width=2)
        d.rectangle([cx - 6 * SS, hy - (HEAD_R + 4) * SS, cx + 6 * SS, hy - (HEAD_R + 1) * SS], fill=(58, 74, 60, 255))
    else:
        d.arc([cx - (HEAD_R + 1) * SS, hy - (HEAD_R + 5) * SS, cx + (HEAD_R + 1) * SS, hy + HEAD_R * SS], 180, 360, fill=P["hair_d"], width=0)
        d.rectangle([cx - (HEAD_R + 1) * SS, hy - 3 * SS, cx + (HEAD_R + 1) * SS, hy + 1 * SS], fill=P["hair_d"])
    # --- 货箱（搬运帧：举过头顶）---
    if frame in ("carry_a", "carry_b"):
        bob = 3 if frame == "carry_a" else 4
        ty = hy - HEAD_R * SS - 16 * SS + bob * SS
        rrect(d, [cx - 10 * SS, ty, cx + 10 * SS, ty + 13 * SS], 3, (196, 148, 96, 255), edge=P["ink"], edge_w=2)
        d.line([(cx - 10 * SS, ty + 7 * SS), (cx + 10 * SS, ty + 7 * SS)], fill=(150, 104, 64, 255), width=3)
        d.line([(cx - 4 * SS, ty), (cx + 4 * SS, ty + 13 * SS)], fill=(150, 104, 64, 255), width=2)
    # --- 背包（商人）---
    if g.get("pack"):
        rrect(d, [cx + BODY_W / 2 * SS - 2 * SS, gy - (LEG_H + body_h - 2) * SS, cx + (BODY_W / 2 + 9) * SS, gy - (LEG_H + 6) * SS],
              3, (150, 104, 64, 255), edge=P["ink"], edge_w=2)
    save(finish(img, W, H), "villagers", "%s_%s" % (gid, frame), foot=4)

if __name__ == "__main__":
    for gid, g in GROUPS.items():
        for frame in ("idle", "walk_a", "walk_b", "carry_a", "carry_b"):
            _villager(gid, g, frame)
    print("villagers:", len(REGISTRY))
