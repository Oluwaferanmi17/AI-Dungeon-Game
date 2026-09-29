extends Control

@onready var speaker_label: Label = $Content/SpeakerName
@onready var text_label: Label = $Content/DialogueText
@onready var choices_container: VBoxContainer = $Content/ChoicesContainer

var current_npc_id: String = ""
var current_node_id: String = ""

func start_dialogue(npc_id: String, start_node: String = "start") -> void:
	AudioManager.play_sfx("dialogue_open")
	current_npc_id = npc_id
	current_node_id = start_node
	visible = true
	GameManager.set_state(GameManager.State.DIALOGUE)
	_show_node(current_node_id)

func _show_node(node_id: String) -> void:
	var npc_dialogue: Dictionary = DialogueData.dialogues[current_npc_id]
	var node: Dictionary = npc_dialogue[node_id]

	speaker_label.text = node["speaker"]
	text_label.text = node["text"]

	# Clear old choice buttons
	for child in choices_container.get_children():
		child.queue_free()

	# Create a button per choice
	for choice in node["choices"]:
		var button: Button = Button.new()
		button.text = choice["text"]
		button.pressed.connect(_on_choice_selected.bind(choice["next_node"]))
		choices_container.add_child(button)

func _on_choice_selected(next_node) -> void:
	if next_node == "quest_accept":
		var quest: QuestData = load("res://assets/quests/missing_merchant.tres")
		GameState.start_quest(quest)

	if next_node == null:
		_end_dialogue()
	else:
		current_node_id = next_node
		_show_node(current_node_id)
		
func _end_dialogue() -> void:
	visible = false
	GameManager.set_state(GameManager.State.PLAYING)
