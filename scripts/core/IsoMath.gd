class_name IsoMath
## 等距投影换算（世界网格 <-> 屏幕坐标）
## 屏幕约定：tile (0,0) 中心位于 (0,0)；x 向右下，y 向左下

static func tile_to_world(tx: float, ty: float) -> Vector2:
	return Vector2((tx - ty) * GameConfig.TILE_W * 0.5, (tx + ty) * GameConfig.TILE_H * 0.5)

static func world_to_tile(p: Vector2) -> Vector2i:
	var a := p.x / (GameConfig.TILE_W * 0.5)
	var b := p.y / (GameConfig.TILE_H * 0.5)
	return Vector2i(int(floor((a + b) * 0.5)), int(floor((b - a) * 0.5)))

static func tile_center(tx: int, ty: int) -> Vector2:
	return tile_to_world(float(tx), float(ty))

## 地图整体居中偏移（让 (0,0)..(N-1,N-1) 的中心位于原点）
static func map_origin(size: int) -> Vector2:
	return tile_to_world((size - 1) * 0.5, (size - 1) * 0.5) * -1.0

static func map_bounds_world(size: int) -> Rect2:
	var o := map_origin(size)
	var min := o - Vector2(GameConfig.TILE_W, GameConfig.TILE_H)
	var max := o + Vector2(size * GameConfig.TILE_W * 0.5 + GameConfig.TILE_W,
			size * GameConfig.TILE_H * 0.5 + GameConfig.TILE_H)
	return Rect2(min, max - min)

## 深度排序键：用于建筑/道具/居民的绘制顺序
static func depth(tx: int, ty: int) -> float:
	return float(tx + ty) * 10.0 + float(tx) * 0.1
