class_name PixelScale
extends RefCounted
## Integer scale for a fixed logical viewport. Windows below base size use 1.
static func for_window(window_size: Vector2i, base_size: Vector2i = Vector2i(320, 180)) -> int:
	if base_size.x <= 0 or base_size.y <= 0:
		return 1
	var width_scale: int = floori(float(window_size.x) / float(base_size.x))
	var height_scale: int = floori(float(window_size.y) / float(base_size.y))
	return maxi(1, mini(width_scale, height_scale))
