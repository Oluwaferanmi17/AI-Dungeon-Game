extends CharacterBody2D

@export var move_speed: float = 120.0
@export var max_health: int = 100
@export var current_health: int = 100
@export var max_mana: int = 50
@export var current_mana: int = 50
var footstep_timer: float = 0.0

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()

	velocity = input_vector * move_speed
	move_and_slide()

	if velocity.length() > 0.0:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			AudioManager.play_sfx("footstep")
			footstep_timer = 0.35
	else:
		footstep_timer = 0.0
var nearby_interactables: Array[Node] = []

@onready var http_request: HTTPRequest = $HTTPRequest

func _ready() -> void:
	http_request.request_completed.connect(_on_ai_response_received)
	$InteractionArea.area_entered.connect(_on_interaction_area_entered)
	$InteractionArea.area_exited.connect(_on_interaction_area_exited)
	GameState.add_npc_memory("wizard", "The player threatened me and demanded my secrets")
	#GameState.change_reputation(-15)
	print("InteractionArea signals connected")
func send_ai_action(action_text: String) -> void:
	var url: String = "http://127.0.0.1:8000/action"
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var body: String = JSON.stringify({ "action_text": action_text })
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_ai_response_received(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var json_string: String = body.get_string_from_utf8()
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result == OK:
		var response_data: Dictionary = json.data

		if response_data.has("narration"):
			print("Narration: ", response_data["narration"])
			print("Event: ", response_data["event"])
			if response_data.has("callback_reference") and response_data["callback_reference"] != null:
				print("Callback: ", response_data["callback_reference"])
			var evt: String = response_data["event"]
			if evt == "VILLAGE_ATTACKED" or evt == "VILLAGE_SAVED":
				GameState.trigger_world_event(evt)
		elif response_data.has("dialogue"):
			print("NPC says: ", response_data["dialogue"])
			print("Relationship change: ", response_data["relationship_change"])
			var rel_change: int = int(response_data["relationship_change"])
			if rel_change < 0:
				GameState.change_reputation(rel_change)
		elif response_data.has("quest"):
			_handle_ai_quest(response_data["quest"])
		elif response_data.has("random_event"):
			_handle_ai_event(response_data["random_event"])
		elif response_data.has("encounter"):
			_handle_ai_encounter(response_data["encounter"])
	else:
		print("Failed to parse AI response")

func _handle_ai_event(event_dict: Variant) -> void:
	if event_dict == null:
		print("AI event generation failed to produce valid JSON")
		return
	print("Random event: ", event_dict["title"])
	print("Description: ", event_dict["description"])
	print("Type: ", event_dict["event_type"])

func _handle_ai_encounter(encounter_dict: Variant) -> void:
	if encounter_dict == null:
		print("AI encounter generation failed to produce valid JSON")
		return
	print("Encounter: ", encounter_dict["enemy_name"])
	print("Description: ", encounter_dict["description"])
	print("Enemy HP: ", encounter_dict["enemy_health"], " | Attack: ", encounter_dict["enemy_attack"])
	
func _handle_ai_quest(quest_dict: Variant) -> void:
	if quest_dict == null:
		print("AI quest generation failed to produce valid JSON")
		return

	var quest: QuestData = QuestData.new()
	quest.id = quest_dict["id"]
	quest.title = quest_dict["title"]
	quest.description = quest_dict["description"]

	var objectives: Array[String] = []
	for obj in quest_dict["objectives"]:
		objectives.append(obj)
	quest.objectives = objectives

	quest.reward_gold = quest_dict["reward_gold"]

	print("AI-generated quest: ", quest.title)
	print("Objectives: ", quest.objectives)
	GameState.start_quest(quest)
		
func _on_interaction_area_entered(area: Area2D) -> void:
	print("Area entered: ", area.name)
	if area.is_in_group("interactable"):
		nearby_interactables.append(area)
		print("Added to nearby_interactables. Count: ", nearby_interactables.size())
func _on_interaction_area_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and nearby_interactables.size() > 0:
		var target: Node = nearby_interactables[0]
		if target.has_meta("npc_id"):
			var npc_id: String = target.get_meta("npc_id")
			var dialogue_box = get_tree().current_scene.get_node("DialogueBox")
			var start_node: String = "start"
			if npc_id == "guard" and GameState.is_wanted:
				start_node = "hostile"
			print("Opening dialogue for: ", npc_id)
			dialogue_box.start_dialogue(npc_id, start_node)
	else:
		print("Target has no npc_id meta")

	if event.is_action_pressed("inventory"):
		var inv_screen = get_tree().current_scene.get_node("InventoryScreen")
		inv_screen.toggle()

	if event.is_action_pressed("quest_log"):
		var quest_screen = get_tree().current_scene.get_node("QuestLog")
		quest_screen.toggle()
	if event.is_action_pressed("save_game"):
		GameState.save_game()
	if event.is_action_pressed("load_game"):
		GameState.load_game()	
	#if event.is_action_pressed("test_ai"):
		#send_ai_action("I look around the room")
	if event.is_action_pressed("test_ai"):
		#send_npc_dialogue("wizard", "Let's start over, I'm sorry about earlier")
		#send_ai_action("I set fire to the village storehouse")
		send_director_action("I walk into the tavern and ask if anyone's heard news about me")
	if event.is_action_pressed("test_ai_quest"):
		request_ai_quest("a dangerous creature terrorizing the village")
	if event.is_action_pressed("test_ai_event"):
		request_ai_event("a quiet forest path")
	if event.is_action_pressed("test_ai_encounter"):
		request_ai_encounter("medium")
	if event.is_action_pressed("test_world_event"):
		GameState.trigger_world_event("VILLAGE_ATTACKED")
				
func take_damage(amount: int) -> void:
	var mitigated: int = max(1, amount - GameState.get_total_defense())
	current_health -= mitigated
	current_health = max(0, current_health)
	print("Took ", mitigated, " damage. HP: ", current_health, "/", max_health)
	if current_health <= 0:
		print("Player died!")

func attack_target(target) -> void:
	var damage: int = GameState.get_total_attack()
	if target.has_method("take_damage"):
		target.take_damage(damage)		

func send_npc_dialogue(npc_id: String, player_message: String) -> void:
	var context: Dictionary = GameState.get_npc_context(npc_id)
	print("Sending context - Personality: ", context["personality"], " | Memories: ", context["memories"])
	var url: String = "http://127.0.0.1:8000/npc_dialogue"
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var body: String = JSON.stringify({
		"npc_id": npc_id,
		"personality": context["personality"],
		"memories": context["memories"],
		"player_message": player_message
	})
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

func request_ai_quest(theme_hint: String = "") -> void:
	var url: String = "http://127.0.0.1:8000/generate_quest"
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var body: String = JSON.stringify({ "theme_hint": theme_hint })
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	
func request_ai_event(location_context: String = "a small village") -> void:
	var url: String = "http://127.0.0.1:8000/generate_event"
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var body: String = JSON.stringify({ "location_context": location_context })
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

func request_ai_encounter(danger_level: String = "low") -> void:
	var url: String = "http://127.0.0.1:8000/generate_encounter"
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var body: String = JSON.stringify({ "danger_level": danger_level })
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

func send_director_action(action_text: String) -> void:
	var summary: String = GameState.build_world_summary()
	print("--- World Summary ---\n", summary, "\n---")
	var url: String = "http://127.0.0.1:8000/director_action"
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var body: String = JSON.stringify({
		"world_summary": summary,
		"player_action": action_text
	})
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)
