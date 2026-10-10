# 开发工具（素材/字体/验证再生成）

- `gen_all.py`：重新生成全部美术+音频+manifest（需要 python3 + Pillow + numpy）
- `font_subset.py`：从 scripts/*.gd 提取字符，再生成字体子集（需要 fonttools）
- `sim_mirror.py`：核心模拟的 Python 数值镜像（300 年多种子验证，改公式时先用它调参）

用法：
    python3 gen_all.py        # 在本目录执行，输出到 ../assets/
    python3 font_subset.py
    python3 sim_mirror.py
