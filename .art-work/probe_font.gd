extends SceneTree

func _initialize() -> void:
	call_deferred("probe")

func probe() -> void:
	var theme := load("res://assets/art/sao_mai/ui/ui_theme.tres") as Theme
	print("default ", theme.default_font_size)
	var panel := Control.new()
	panel.theme = theme
	root.add_child(panel)
	for value in ["Tiếp tục", "ABCD", "08:40", "Dì Năm", "Giảm nhấp nháy"]:
		var label := Label.new()
		label.text = value
		label.add_theme_font_size_override("font_size", 8)
		panel.add_child(label)
		print("label ", value, " ", label.get_minimum_size(), " size ", label.get_theme_font_size("font_size"), " uses font ", label.get_theme_font("font").resource_path)
		var button := Button.new()
		button.text = value
		button.add_theme_font_size_override("font_size", 8)
		panel.add_child(button)
		print("button ", value, " ", button.get_minimum_size(), " size ", button.get_theme_font_size("font_size"), " uses font ", button.get_theme_font("font").resource_path)
	quit()
