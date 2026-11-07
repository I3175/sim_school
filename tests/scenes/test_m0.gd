extends Node2D
## Pixel grid, independent of game content; inspect at integer window sizes.
func _draw() -> void:
	for y in range(180):
		for x in range(320):
			if (x + y) % 2 == 0:
				draw_rect(Rect2(x, y, 1, 1), Color("c6d9a0"))
	draw_rect(Rect2(0, 0, 320, 180), Color("fff0cc"), false, 1.0)
