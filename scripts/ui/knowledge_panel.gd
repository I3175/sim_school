extends CanvasLayer
var panel: PanelContainer
var column: VBoxContainer
var prompt: Label
var answers: VBoxContainer
var explanation: Label
var footer: HBoxContainer
var questions: Array[Dictionary] = []
var subject: String = "math"
var index: int = 0
var correct_count: int = 0
var wrong_streak: int = 0
var practice: bool = false
var answered: bool = false
var ordered: Array = []
var matches: Dictionary = {}
var grid_selection: Array = []
var tier: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = PanelContainer.new()
	panel.position = Vector2(8, 4)
	panel.custom_minimum_size = Vector2(304, 172)
	panel.theme = preload("res://assets/art/ui/inventory_theme.tres")
	add_child(panel)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	panel.add_child(column)
	prompt = Label.new()
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.custom_minimum_size = Vector2(296, 26)
	column.add_child(prompt)
	answers = VBoxContainer.new()
	column.add_child(answers)
	explanation = Label.new()
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.custom_minimum_size = Vector2(296, 24)
	column.add_child(explanation)
	footer = HBoxContainer.new()
	column.add_child(footer)
	panel.hide()
	EventBus.study_requested.connect(open)
	EventBus.map_entered.connect(_add_station)

func _add_station(map_id: String) -> void:
	if map_id not in ["school", "library", "player_house", "observatory"]:
		return
	var map: Node = SceneManager.cache[map_id]
	if map.has_node("StudyDesk"):
		return
	var desk := Interactable.new()
	desk.name = "StudyDesk"
	desk.prompt = "Học tập"
	desk.position = Vector2(256, 120)
	desk.action = func() -> void: open(false)
	map.add_child(desk)

func open(practice_mode: bool = false) -> void:
	if panel.visible:
		return
	practice = practice_mode
	panel.show()
	EventBus.pause_requested.emit("study", true)
	get_tree().paused = true
	_choose_subject()

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _button(parent: Node, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(action)
	parent.add_child(button)

func _choose_subject() -> void:
	_clear(answers)
	_clear(footer)
	prompt.text = "Phòng học · chọn môn"
	explanation.text = "Gợi ý và bỏ qua luôn có sẵn."
	for position in range(KnowledgeManager.model.rules.subjects.size()):
		var id: String = str(KnowledgeManager.model.rules.subjects[position])
		_button(answers, str(KnowledgeManager.model.rules.subject_names[position]), func() -> void: _start(id))
	_button(footer, "Đóng", _close)

func _start(id: String) -> void:
	subject = id
	tier = KnowledgeManager.model.pinned_difficulty if KnowledgeManager.model.pinned_difficulty > 0 else int(KnowledgeManager.model.difficulty[id])
	questions = KnowledgeManager.model.select_session(id, hash("%s:%d:%d" % [id, GameClock.model.day_index(), Time.get_ticks_msec()]))
	index = 0
	correct_count = 0
	wrong_streak = 0
	_show_question()

func _show_question() -> void:
	_clear(answers)
	_clear(footer)
	answered = false
	ordered = []
	matches = {}
	grid_selection = []
	explanation.text = ""
	if index >= questions.size():
		var result := KnowledgeManager.finish(subject, correct_count, questions.size(), tier, practice)
		prompt.text = "Hoàn thành: %d/%d · %d sao" % [correct_count, questions.size(), int(result.stars)]
		explanation.text = "Cảm ơn bạn đã học hôm nay!"
		_button(footer, "Chọn môn", _choose_subject)
		_button(footer, "Đóng", _close)
		return
	var question := questions[index]
	prompt.text = "%d/%d · %s" % [index + 1, questions.size(), tr(question.prompt_key)]
	match str(question.type):
		"multiple_choice":
			for option: String in question.options:
				_button(answers, option, func() -> void: _submit(option))
		"numeric_input", "fill_blank":
			var entry := LineEdit.new()
			entry.placeholder_text = "Nhập câu trả lời"
			answers.add_child(entry)
			entry.text_submitted.connect(func(value: String) -> void: _submit(value))
			_button(answers, "Trả lời", func() -> void: _submit(entry.text))
		"ordering", "drag_to_sort":
			var row := HBoxContainer.new()
			answers.add_child(row)
			for option: String in question.options:
				_button(row, option, func() -> void:
					if option not in ordered:
						ordered.append(option)
						explanation.text = " → ".join(ordered))
			_button(answers, "Làm lại thứ tự", func() -> void: ordered.clear(); explanation.text = "")
			_button(answers, "Trả lời", func() -> void: _submit(ordered))
		"matching":
			for left: String in question.left:
				var row := HBoxContainer.new()
				answers.add_child(row)
				var caption := Label.new()
				caption.text = left
				row.add_child(caption)
				var choices := OptionButton.new()
				for right: String in question.right:
					choices.add_item(right)
				choices.select(-1)
				choices.item_selected.connect(func(selected: int) -> void: matches[left] = question.right[selected])
				row.add_child(choices)
			_button(answers, "Trả lời", func() -> void: _submit(matches))
		"grid_puzzle":
			var grid := GridContainer.new()
			grid.columns = int(question.columns)
			answers.add_child(grid)
			for cell_index in range(question.cells.size()):
				var button := Button.new()
				button.text = str(question.cells[cell_index])
				button.toggle_mode = true
				button.toggled.connect(func(enabled: bool) -> void:
					if enabled: grid_selection.append(str(cell_index))
					else: grid_selection.erase(str(cell_index)))
				grid.add_child(button)
			_button(answers, "Trả lời", func() -> void: _submit(grid_selection))
	_button(footer, "Gợi ý", func() -> void: explanation.text = tr(question.hint_key))
	_button(footer, "Bỏ qua", func() -> void: _submit(null))
	_button(footer, "Đóng", _close)

func _submit(response: Variant) -> void:
	if answered or index >= questions.size():
		return
	answered = true
	var question := questions[index]
	var success: bool = response != null and KnowledgeManager.model.correct(question, response)
	correct_count += 1 if success else 0
	wrong_streak = 0 if success else wrong_streak + 1
	if not practice:
		KnowledgeManager.model.record_answer(str(question.id), success)
	explanation.text = ("Đúng! " if success else "Cùng xem lại: ") + tr(question.explanation_key)
	if wrong_streak >= 3:
		explanation.text += "\nBạn có thể xem gợi ý và học lại bài này."
	_clear(footer)
	_button(footer, "Tiếp", func() -> void: index += 1; _show_question())
	_button(footer, "Đóng", _close)

func _close() -> void:
	panel.hide()
	EventBus.pause_requested.emit("study", false)
	get_tree().paused = not GameClock.model.pauses.is_empty()

func _unhandled_key_input(event: InputEvent) -> void:
	if panel.visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()
