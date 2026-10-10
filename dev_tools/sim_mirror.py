# -*- coding: utf-8 -*-
"""Society Lab 核心模拟的 Python 镜像（用于无 Godot 环境下的调参验证）。
复刻 GDScript 的经济/人口/技术/制度公式（简化建筑选址），跑多种子 300 年，
检查：不灭绝、增长弧线、技术发现、形态迁移、饥荒可触发。
"""
import math, random

# ---- 常量（与 GameConfig 一致） ----
WORKER_RATIO = 0.55
FOOD_PER_CAP = 1.0
BASE_FARM_YIELD = 15.0
FARM_WORKERS = 1.6
GATHER_YIELD = 3.0
STORAGE_BASE = 260.0
SPOILAGE = 0.06
RESEARCH_BASE = 0.70
FA = 0.036  # 未用
TECH_MAX = 100.0

class S:
    def __init__(s, pop, seed):
        s.rng = random.Random(seed)
        s.pop = pop
        s.food = pop * 3.0
        s.wood = 20.0; s.stone = 0.0; s.metal = 0.0
        s.tech = {k: 0.0 for k in ["agriculture","tools","construction","health","organization","commerce","industry"]}
        s.disc = []
        s.hunger = 0; s.famine = False
        s.housing = 20.0       # 简化：住房容量数值（帐篷）
        s.farms = 0            # 简化：农田数量
        s.granaries = 0
        s.inst = dict(communal=1.0, private=0.0, state=0.0, forced=0.0, bonded=0.0,
                      wage=0.0, coop=0.0, market=0.0, state_cap=0.02, public=0.0,
                      tax=0.18, land_conc=0.0, education=0.0, part=0.05, trust=0.35,
                      spec=0.0, ps=0.0, warlike=0.1)
        s.groups = {"laborer": dict(size=.82, wealth=.30, org=.05, grie=.10, stock=10.0),
                    "elite": dict(size=.06, wealth=.42, org=.10, grie=.05, stock=10.0),
                    "merchant": dict(size=.06, wealth=.16, org=.05, grie=.08, stock=4.0),
                    "admin": dict(size=.06, wealth=.12, org=.15, grie=.05, stock=4.0)}
        s.derived = {}
        s.fx = {}
        s.weather = 1.0
        s.form = "primitive"
        s.fert = 0.85          # 领地平均肥力（简化）
        s.forest_tiles = 6
        s.ore = 1              # 领地有矿
        s.stat = []

    def knows(s, t): return t in s.disc

def recompute_fx(s):
    # 简化建筑 fx：granary 0.3 spoil_reduce each; hospital later
    fx = {}
    fx["spoil_reduce"] = 0.3 * s.granaries
    fx["food_cap"] = 500.0 * s.granaries
    fx["death_mult"] = 1.0
    fx["health"] = 0.05 + 0.08 * (1 if s.knows("hygiene") else 0) + 0.04*(1 if s.pop>250 and s.knows("medicine") else 0)
    fx["research"] = 0.10 * (1 if s.pop > 180 and s.knows("writing") else 0)
    fx["state"] = 0.06 * (1 if s.pop > 220 and s.knows("writing") else 0)
    fx["education"] = 0.08 * (1 if s.pop > 180 and s.knows("writing") else 0)
    s.fx = fx

def health_score(s):
    h = 0.42 + s.tech["health"]*0.004 + s.fx.get("health",0.0)
    if s.knows("hygiene"): h += 0.05
    if s.knows("medicine"): h += 0.06
    if s.knows("sanitation"): h += 0.07
    h -= s.derived.get("starving",0.0)*0.18
    return max(0.15, min(0.95, h))

def econ(s, year):
    recompute_fx(s)
    workers = s.pop * WORKER_RATIO
    # ---- 食物 ----
    if s.farms > 0 and s.knows("early_agri"):
        need_labor = s.farms * FARM_WORKERS
        agri_used = min(workers*0.78, need_labor)
        lr = min(1.0, agri_used/need_labor)
        ty = 1 + s.tech["agriculture"]*0.012 + (0.15 if s.knows("crop_rotation") else 0)
        tm = 1 + s.tech["tools"]*0.006 + (0.05 if s.knows("bronze") else 0) + (0.07 if s.knows("iron") else 0)
        prod = s.farms * BASE_FARM_YIELD * s.fert * lr * ty * tm * s.weather
        if s.tech["agriculture"] < 40:
            prod += max(0.0, workers-agri_used) * 0.5 * GATHER_YIELD * (1+s.tech["agriculture"]*0.004)
        agri_share = agri_used
    else:
        prod = workers*0.85 * GATHER_YIELD * (1+s.tech["agriculture"]*0.004) * s.weather
        agri_used = workers*0.85
    # ---- 消费 ----
    need = s.pop * FOOD_PER_CAP
    avail = s.food + prod
    intake = min(need, avail)
    s.food = max(0.0, avail-intake)
    ratio = intake/max(1.0, need)
    cap = STORAGE_BASE + s.fx.get("food_cap",0.0)
    spoil = SPOILAGE * (0.7 if s.knows("pottery") else 1.0) * (1-min(0.85, s.fx.get("spoil_reduce",0.0)))
    s.food = min(s.food*(1-spoil), cap)
    if ratio < 0.82: s.hunger += 1
    else: s.hunger = max(0, s.hunger-1)
    s.famine = s.hunger >= 2 and ratio < 0.82
    s.derived["intake"] = ratio
    s.derived["surplus"] = max(0.0, min(1.5, (avail-need)/max(1.0,need)))
    s.derived["starving"] = max(0.0, min(1.0,(0.82-ratio)/0.82))
    s.derived["prod"] = prod
    s.derived["need"] = need
    # ---- 手工业/资源 ----
    craft_w = max(0.0, workers-agri_used)
    craft = craft_w * 2.2 * (1+s.tech["tools"]*0.008)
    s.derived["craft"] = craft
    wood_gain = min(s.forest_tiles*3.0, craft_w*1.2)
    s.wood = max(0.0, s.wood + wood_gain - s.pop*0.02 - 0.5)
    s.metal += min(s.ore*1.8, craft_w*1.2) * (1.0 if s.knows("bronze") else 0.4)
    # 住房（自动建设）
    if s.pop > s.housing*0.88:
        if s.knows("electricity"): key, cost, cap_add, yrs = "apartment", dict(wood=0,stone=60,metal=30), 520, 3
        elif s.knows("masonry") and s.pop>600: key, cost, cap_add, yrs = "house_town", dict(wood=20,stone=30,metal=6), 150, 2
        elif s.knows("masonry"): key, cost, cap_add, yrs = "house_brick", dict(wood=10,stone=16,metal=0), 70, 2
        elif s.knows("knapped_tools"): key, cost, cap_add, yrs = "house_wood", dict(wood=14,stone=0,metal=0), 34, 1
        else: key, cost, cap_add, yrs = "hut", dict(wood=6,stone=0,metal=0), 18, 1
        if s.wood >= cost["wood"] and s.stone >= cost["stone"] and s.metal >= cost["metal"]:
            s.wood -= cost["wood"]; s.stone -= cost["stone"]; s.metal -= cost["metal"]
            s.housing += cap_add
    # 农田建设（有农业后）
    if s.knows("early_agri"):
        want = math.ceil(s.pop/38.0)
        if s.farms < want:
            s.farms += 1  # 每年最多一块
    # 谷仓
    if s.knows("pottery") and s.food > (STORAGE_BASE + 500*s.granaries)*0.9 and s.wood >= 12:
        s.wood -= 12; s.granaries += 1
    s.derived["agri_used"] = agri_used

def demo(s):
    workers = s.pop * WORKER_RATIO
    fs = s.derived.get("intake",1.0)
    fs = max(0.0, min(1.0,(fs-0.70)/0.30))  # 出生用保障曲线
    h = health_score(s)
    surplus = min(1.0, s.derived.get("surplus",0.0))
    birth = 0.055*(0.5+0.5*fs)*(0.6+0.4*h)*(0.85+0.3*surplus)
    # 拥挤
    over = s.pop/max(1.0,s.housing) - 1.0
    if over > 0: birth *= max(0.25, 1.0/(1.0+over*1.6))
    death = 0.030*(2.05-1.75*h)*(1+3.2*s.derived.get("starving",0.0))
    if s.famine: death *= 1.25
    g = birth - death
    delta = round(g*s.pop)
    if s.famine: delta -= round(s.pop*0.012)
    s.pop = max(6, s.pop+int(delta))
    s.derived["growth"] = g

def tech_pass(s):
    surplus = min(1.0, s.derived.get("surplus",0.0))
    ed = s.inst["education"]
    base = RESEARCH_BASE*(1+2.2*surplus)*(1+ed*2.5)*(1+s.fx.get("research",0.0)*2)
    if s.knows("writing"): base *= 1.2
    if s.knows("printing"): base *= 1.15
    if s.knows("mathematics"): base *= 1.1
    w = dict(agriculture=1.0,tools=1.0,construction=0.6,health=0.5,organization=0.6,commerce=0.2,industry=0.1)
    if s.derived.get("intake",1.0) < 0.95:
        w["agriculture"] = 2.2; w["health"] = 0.8
    if s.pop > 150: w["organization"] += 0.4
    if s.knows("currency"): w["commerce"] = 0.8
    if s.knows("writing"): w["organization"] += 0.4; w["construction"] += 0.2
    if s.tech["industry"] > 25: w["industry"] = 0.9
    tw = sum(w.values())
    for k in w: s.tech[k] = min(TECH_MAX, s.tech[k] + base*w[k]/tw)
    # 发现
    TECHS = [
        ("knapped_tools","tools",8,{}), ("pottery","agriculture",10,{}),
        ("early_agri","agriculture",15,{}), ("writing","organization",25,{}),
        ("irrigation","agriculture",30,{"construction":12}), ("currency","commerce",30,{}),
        ("bronze","tools",35,{}), ("masonry","construction",40,{}),
        ("hygiene","health",35,{}), ("iron","tools",55,{}),
        ("crop_rotation","agriculture",55,{}), ("mathematics","organization",45,{}),
        ("printing","organization",55,{"commerce":25}), ("medicine","health",65,{}),
        ("steam_engine","industry",45,{"construction":50}), ("sanitation","health",55,{"construction":45}),
        ("cooperatives","organization",60,{}), ("mass_education","organization",70,{}),
        ("banking","commerce",65,{}), ("electricity","industry",75,{"construction":60}),
    ]
    for tid, dom, lvl, pre in TECHS:
        if tid in s.disc: continue
        if s.tech[dom] < lvl: continue
        okp = True
        for pd, pv in pre.items():
            if s.tech.get(pd,0.0) < pv: okp = False
        if not okp: continue
        if tid in ("bronze","iron","steam_engine","electricity"):
            if s.metal < 1.0 and s.ore == 0: continue
        s.disc.append(tid)

def inst_pass(s):
    i = s.inst
    i["private"] = min(0.75, i["private"] + 0.0035*(i["spec"]*1.4 + i["market"]*0.8))
    i["communal"] = max(0.0, 1.0 - i["private"] - i["state"])
    i["forced"] = max(0.0, i["forced"]-0.0028)
    bond_t = min(0.5, i["land_conc"]*0.55)
    if s.tech["industry"] > 30 or s.tech["commerce"] > 45: bond_t *= 0.5
    i["bonded"] = i["bonded"] + (bond_t-i["bonded"])*0.05
    wage_t = min(0.55, 0.1 + (s.tech["industry"]+s.tech["commerce"])*0.004)
    i["wage"] = i["wage"] + (wage_t-i["wage"])*0.06
    coop_t = 0.12+i["part"]*0.35 if s.knows("cooperatives") else 0.0
    i["coop"] = i["coop"] + (coop_t-i["coop"])*0.05
    tot = i["forced"]+i["bonded"]+i["wage"]+i["coop"]
    if tot > 1.0:
        for k in ("forced","bonded","wage","coop"): i[k] /= tot
    stc = 0.0035*(1+s.fx.get("state",0.0))
    if s.knows("writing"): stc *= 1.35
    if s.knows("mathematics"): stc *= 1.2
    i["state_cap"] = min(1.0, i["state_cap"]+stc)
    ed_t = 0.05 + s.fx.get("education",0.0)*3.0 + (0.12 if s.knows("printing") else 0) + (0.25 if s.knows("mass_education") else 0) + (0.06 if s.knows("writing") else 0)
    i["education"] = i["education"] + (min(0.95,ed_t)-i["education"])*0.06
    part_t = 0.05 + (0.1 if s.knows("printing") else 0) + (0.15 if s.knows("mass_education") else 0)
    i["part"] = i["part"] + (min(0.9,part_t)-i["part"])*0.05
    if s.famine: i["trust"] -= 0.01
    i["trust"] = max(0.05, min(0.95, i["trust"]+0.002*i["public"]))
    ps_t = min(0.9, i["state_cap"]*(0.5+i["education"]))
    i["public"] = i["public"] + (ps_t-i["public"])*0.05
    # 专业化
    if s.knows("early_agri") and s.farms>0:
        workers = s.pop*WORKER_RATIO
        agri_share = min(workers*0.78, s.farms*FARM_WORKERS)/max(1.0,workers)
    else:
        agri_share = 0.85
    spec_t = max(0.0, min(0.95, 1.0-agri_share))
    i["spec"] = i["spec"] + (spec_t-i["spec"])*0.12
    i["land_conc"] = min(0.85, i["land_conc"] + 0.0025*(i["private"]*1.2 + i["market"]*0.6))

def dist(s):
    pool = max(0.0, s.derived.get("prod",0.0)-s.derived.get("need",0.0)) + s.derived.get("craft",0.0)
    i = s.inst
    st = min(0.5, i["tax"])
    rest = pool*(1-st)
    elite_sh = max(0.06, min(0.74, 0.26 + i["land_conc"]*0.22 + i["private"]*0.14 + i["market"]*0.08))
    merch_sh = max(0.02, min(0.34, 0.08 + i["market"]*0.30))
    admin_sh = max(0.05, min(0.30, 0.10 + i["state_cap"]*0.22))
    lab_sh = max(0.1, min(0.8, 1.0-elite_sh-merch_sh-admin_sh))
    lab_sh = max(0.1, min(0.85, lab_sh - i["forced"]*0.18 - i["bonded"]*0.12 + i["coop"]*0.10))
    elite_sh = max(0.05, min(0.8, 1.0-lab_sh-merch_sh-admin_sh))
    g = s.groups
    g["laborer"]["stock"] += rest*lab_sh + pool*st*0.35
    g["elite"]["stock"] += rest*elite_sh
    g["merchant"]["stock"] += rest*merch_sh
    g["admin"]["stock"] += rest*admin_sh + pool*st*0.65
    tot = sum(g[k]["stock"] for k in g)
    for k in g: g[k]["wealth"] = g[k]["stock"]/max(1e-6, tot)
    # gini 加权
    ps = [g[k]["size"] for k in g]; ws = [g[k]["wealth"] for k in g]
    acc = sum(abs(ws[i]/max(1e-4,ps[i]) - ws[j]/max(1e-4,ps[j]))*ps[i]*ps[j] for i in range(4) for j in range(4))
    s.derived["gini"] = min(1.0, acc*0.5/max(1e-6, sum(ps)**2))
    # 不满
    target = 0.05
    ratio = s.derived.get("intake",1.0)
    if ratio < 0.9: target += (0.9-ratio)*1.2
    gin = s.derived["gini"]
    if gin > 0.42: target += (gin-0.42)*1.5
    if i["land_conc"] > 0.5: target += (i["land_conc"]-0.5)*0.8
    if i["part"] < 0.1: target += 0.08
    g["laborer"]["grie"] += (max(0.0,min(1.0,target))-g["laborer"]["grie"])*0.09
    # 组织度
    org_gain = 0.006*(1+i["education"]*3)*(1.5 if s.knows("printing") else 1)*(1.6 if s.knows("mass_education") else 1)
    urban = min(1.0, s.pop/800.0)
    g["laborer"]["org"] = min(1.0, g["laborer"]["org"] + org_gain*(0.5+urban*0.8))
    s.derived["wage"] = rest*lab_sh/max(1.0, s.pop*g["laborer"]["size"])

def classify(s):
    i = s.inst; d = s.derived
    surplus = d.get("surplus",0.0)
    prim = (1-min(1.0,surplus*4))*0.30 + i["communal"]*0.25 \
        + (1-min(1.0,i["spec"]*3))*0.18 + (1-min(1.0,i["state_cap"]*4))*0.12 \
        + min(1.0,120.0/max(1,s.pop))*0.10 + (0.15 if not s.knows("early_agri") else 0)
    sl = i["forced"]*0.45 + (max(0.0,(d.get("gini",0)-0.5))*2*0.2 if d.get("gini",0)>0.5 else 0) \
        + i["warlike"]*0.1 + min(1.0,i["spec"]*2)*0.08
    if surplus < 0.05: sl *= 0.45
    fe = i["bonded"]*0.35 + i["land_conc"]*0.28 + (i.get("elite_power",0.2))*0.14 + (1-min(1.0,s.tech["industry"]/45))*0.10
    ca = i["wage"]*0.34 + i["market"]*0.24 + i["private"]*0.20 + min(1.0,s.tech["industry"]/100)*0.14 \
        + (0.05 if s.knows("steam_engine") else 0) + (0.04 if s.knows("banking") else 0)
    so = i["state"]*0.28 + i["coop"]*0.20 + i["public"]*0.20 + i["part"]*0.16 + i.get("planned",0.0)*0.16
    sc = dict(primitive=prim, slave=sl, feudal=fe, capitalist=ca, socialist=so)
    top = max(sc, key=sc.get)
    ranked = sorted(sc.values(), reverse=True)
    form = "mixed"
    if ranked[0] >= 0.34 and ranked[0]-ranked[1] >= 0.13: form = top
    if s.pop < 60 and not s.knows("early_agri"): form = "primitive"
    if surplus < 0.03 and s.pop < 120: form = "primitive"
    s.form = form
    return sc

def run(seed, years=300, drought=False):
    s = S(24, seed)
    events = []
    for y in range(1, years+1):
        s.weather = 0.55 if (drought and y < 40) else 1.0  # 对应神力 0.45 → 产量x0.55
        econ(s, y)
        demo(s)
        tech_pass(s)
        inst_pass(s)
        dist(s)
        classify(s)
        s.stat.append((y, s.pop, round(s.food), s.form, round(s.derived.get("gini",0),2), len(s.disc)))
        if s.famine and (not events or events[-1][0] != "famine"):
            events.append(("famine", y, s.pop, round(s.derived["intake"],2)))
        if s.pop <= 6:
            events.append(("extinct", y))
            break
    return s, events

print("=" * 78)
print("Society Lab 数值镜像 —— 多种子 300 年演化（正常气候 vs 干旱）")
print("=" * 78)
for seed in [1, 7, 42, 2026]:
    s, ev = run(seed)
    marks = [st for st in s.stat if st[0] in (50, 100, 150, 200, 250, 300)]
    print(f"\n种子 {seed}: 终态 form={s.form} pop={s.pop} tech_disc={len(s.disc)}/{20}")
    print("  轨迹(年,人口,存粮,形态,基尼,技术数):")
    for m in marks:
        print("   Y%-4d pop=%-5d food=%-5d %-10s gini=%.2f tech=%d" % m)
    print("  里程碑技术:", [t for t in ["early_agri","writing","masonry","steam_engine","electricity"] if t in s.disc])
    print("  群体财富:", {k: round(v["wealth"],2) for k,v in s.groups.items()},
          " gini=%.2f org=%.2f grie=%.2f" % (s.derived["gini"], s.groups["laborer"]["org"], s.groups["laborer"]["grie"]))
    if ev: print("  事件:", ev[:5])

print("\n" + "=" * 78)
print("干旱压力测试（前 40 年无水，观察饥荒与恢复）")
s, ev = run(99, 300, drought=True)
print("饥荒事件:", ev[:6])
print("终态: form=%s pop=%d 存粮=%.0f 饥荒年计数(终)=%d" % (s.form, s.pop, s.food, s.hunger))
marks = [st for st in s.stat if st[0] in (10, 30, 60, 120, 300)]
for m in marks: print("   Y%-4d pop=%-5d food=%-5d %-10s" % (m[0], m[1], m[2], m[3]))
print("=" * 78)
