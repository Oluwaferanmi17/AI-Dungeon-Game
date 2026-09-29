extends Control

@onready var quest_list: VBoxContainer = $QuestList

func _ready() -> void:
	visible = false

func refresh() -> void:
	for child in quest_list.get_children():
		child.queue_free()

	for quest_id in GameState.active_quests:
		var entry = GameState.active_quests[quest_id]
		var quest: QuestData = entry["quest"]
		var label: Label = Label.new()
		label.text = quest.title
		quest_list.add_child(label)

		for i in range(quest.objectives.size()):
			var obj_label: Label = Label.new()
			var done: String = "[x]" if i in entry["completed_objectives"] else "[ ]"
			obj_label.text = "  %s %s" % [done, quest.objectives[i]]
			quest_list.add_child(obj_label)

func toggle() -> void:
	visible = not visible
	if visible:
		refresh()
