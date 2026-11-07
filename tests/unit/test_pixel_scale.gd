extends GutTest
const ScaleCalculator = preload("res://scripts/utils/pixel_scale.gd")

func test_integer_scaling_and_letterboxing() -> void:
	assert_eq(ScaleCalculator.for_window(Vector2i(1280, 720)), 4)
	assert_eq(ScaleCalculator.for_window(Vector2i(1920, 1080)), 6)
	assert_eq(ScaleCalculator.for_window(Vector2i(1366, 768)), 4)
	assert_eq(ScaleCalculator.for_window(Vector2i(800, 600)), 2)

func test_small_and_invalid_dimensions() -> void:
	assert_eq(ScaleCalculator.for_window(Vector2i(200, 100)), 1)
	assert_eq(ScaleCalculator.for_window(Vector2i(1280, 720), Vector2i.ZERO), 1)

func test_project_boot_and_autoloads() -> void:
	var scene: PackedScene = load("res://scenes/core/boot.tscn")
	assert_not_null(scene)
	for singleton in ["EventBus", "GameClock", "SeasonSystem", "WeatherSystem", "SceneManager", "InventoryManager", "QuestManager", "KnowledgeManager", "SaveManager", "AudioManager", "ItemDatabase", "SettingsManager"]:
		assert_not_null(get_tree().root.get_node_or_null(singleton), singleton)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 320)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 180)
