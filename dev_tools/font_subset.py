# -*- coding: utf-8 -*-
"""字体子集化：从所有 .gd 源码中提取实际使用的字符 + 常用字表，
生成只含所需字形的小体积字体（保证游戏内中文显示，缩小包体）。
同时在子集中保留拉丁字符与常用标点。"""
import os, re, subprocess

ROOT = "/home/z/my-project/society-lab"
FONTS = [
    ("assets/fonts/NotoSerifSC-Regular.ttf", "assets/fonts/NotoSerifSC-Regular.subset.ttf"),
    ("assets/fonts/NotoSerifSC-Black.ttf", "assets/fonts/NotoSerifSC-Black.subset.ttf"),
    ("assets/fonts/SarasaMonoSC-Regular.ttf", "assets/fonts/SarasaMonoSC-Regular.subset.ttf"),
]

# 额外保险字符：数字/字母/常用符号/高频繁用字（覆盖动态模板可能出现的字）
EXTRA = ("0123456789"
         "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
         " ，。、；：？！“”‘’（）《》·—…％×÷≥≤±→℃°∞◆◇·"
         "的人口年粮食木石金属与地在中为有产出到不我是你他她它们个这那也就会被从向"
         "把给定做要用学着想过和分个 lvl 之一二是三四五六七八九十百千万亿"
         "春夏秋冬风雨雷电雪旱涝丰歉治乱兴衰存亡起落升降进出往返开闭生死"
         "东西南北中前后左右上下内外远近高低深浅快慢强弱大小多少新旧"
         "聚落城镇村都会营地帐篷屋舍宫殿市集坊仓井泉山水田园圃圈栏墙塔门"
         "工商农兵学医教文法政财税贸借贷买卖雇佣依附强制合作公共私有国有"
         "组织信任参与动荡革命改革镇压骚乱迁徙通涨衰退繁荣黄金时代黑暗"
         "神力祝福启蒙思想火种甘霖酷旱沃土森林清泉矿脉显现"
         "原始社会奴隶制封建资本主义社会主义混合过渡形态识别"
         "世界实验室编年史观察者曲线结构时间线数据总表模型假设说明"
         "起因结果介入玩家是否所有如至今后每其中经由而且但是因此于是"
         "第达到超过低于缺少不足过剩饱和警戒临界阈值系数倍率百分比"
         "出生死亡疾病疫病战争袭击分裂流动积累扩散传播发现发明"
         "行进速度时间暂停止快进单步复位聚焦选中悬停笔刷预览"
         "保存读取自动成功失败警告错误版本日期作者版权许可来源")

def extract_chars():
    chars = set(EXTRA)
    for dp, _, fs in os.walk(os.path.join(ROOT, "scripts")):
        for f in fs:
            if f.endswith(".gd"):
                src = open(os.path.join(dp, f), encoding="utf-8").read()
                for ch in src:
                    if not ch.isspace():
                        chars.add(ch)
    # 测试与文档字符也纳入（docs/*.md 在包内）
    for dp, _, fs in os.walk(ROOT):
        if "scripts" in dp or ".git" in dp:
            continue
        for f in fs:
            if f.endswith(".md"):
                try:
                    src = open(os.path.join(dp, f), encoding="utf-8").read()
                    for ch in src:
                        if not ch.isspace():
                            chars.add(ch)
                except Exception:
                    pass
    chars.update(" \n\t")
    return chars

def subset_font(src, dst, chars):
    text_file = "/tmp/subset_chars.txt"
    with open(text_file, "w", encoding="utf-8") as f:
        f.write("".join(sorted(chars)))
    cmd = ["pyftsubset", os.path.join(ROOT, src), "--text-file=" + text_file,
           "--output-file=" + os.path.join(ROOT, dst),
           "--layout-features=*", "--glyph-names", "--notdef-outline",
           "--recalc-bounds", "--drop-tables+=DSIG"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print("FAIL", src, r.stderr[:300])
        return False
    old = os.path.getsize(os.path.join(ROOT, src))
    new = os.path.getsize(os.path.join(ROOT, dst))
    print("%-46s %8.1f MB -> %6.1f KB" % (os.path.basename(dst), old / 1048576, new / 1024))
    return True

if __name__ == "__main__":
    chars = extract_chars()
    print("需要的字符数（去重）:", len(chars))
    ok = all(subset_font(s, d, chars) for s, d, in FONTS)
    print("子集化:", "OK" if ok else "FAILED")
