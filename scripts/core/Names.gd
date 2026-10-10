## 聚落与世界命名生成器（中文组合，可复现：走 "viz" 之外的独立通道）
class_name Names

const PREFIX := ["青", "河", "苍", "云", "金", "石", "林", "风", "阳", "月", "白", "远", "长", "平", "新", "临", "曲", "丰"]
const CORE := ["阳", "川", "原", "谷", "泽", "岭", "岸", "丘", "野", "曲", "沃", "源", "汀", "塬", "埠", "集"]
const WORLD_PRE := ["新", "晨", "星", "大", "青", "远", "初", "曙", "微", "群"]
const WORLD_SUF := ["陆", "洲", "境", "域", "世界", "纪", "原"]

static func settlement_base(rng: RNGService) -> String:
	return rng.pick("sim", PREFIX) + rng.pick("sim", CORE)

static func world_name(rng: RNGService) -> String:
	return rng.pick("sim", WORLD_PRE) + rng.pick("sim", WORLD_SUF)

## 带时代后缀的显示名
static func display_name(base: String, stage: int) -> String:
	var suffix: String = (Database.STAGES.get(stage, {}) as Dictionary).get("suffix", "")
	if stage <= 0:
		return base + suffix
	return base + suffix
