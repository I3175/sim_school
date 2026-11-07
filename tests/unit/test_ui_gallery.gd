extends GutTest

const GALLERY := preload("res://scenes/ui/ui_gallery.tscn")

func test_gallery_widgets_stay_in_logical_viewport() -> void:
	var gallery = add_child_autofree(GALLERY.instantiate())
	var viewport := Rect2(0, 0, 320, 180)
	for page: String in gallery.PAGES:
		gallery._open(page)
		await get_tree().process_frame
		for widget: Node in gallery.world.get_children():
			if widget is Control:
				assert_true(viewport.encloses(widget.get_rect()), "%s: %s" % [page, widget.get_rect()])

func test_vietnamese_font_coverage_and_learning_examples() -> void:
	var gallery = add_child_autofree(GALLERY.instantiate())
	for font_size: int in gallery.FONTS:
		var font: FontFile = gallery.FONTS[font_size]
		assert_true(font.has_char(0x110), "Vietnamese capital Đ at %d px" % font_size)
		for character in range(0x1ea0, 0x1efa):
			assert_true(font.has_char(character), "%04x at %d px" % [character, font_size])
	gallery._open("learning")
	for question: int in gallery.QUESTIONS.size():
		assert_eq(gallery.question_index, question)
		gallery._change_question(1)
		await get_tree().process_frame
	assert_eq(gallery.question_index, 0)
