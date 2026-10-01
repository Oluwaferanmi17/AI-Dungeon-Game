extends Node

# Global game state — will grow to hold player stats, quest flags,
# relationships, etc. in later phases.

var player_name: String = "Arin"
var current_scene_path: String = ""

var equipped_weapon: ItemData = null
var equipped_armor: ItemData = null

func equip_item(item: ItemData) -> void:
	if item.item_type == "weapon":
		equipped_weapon = item
	elif item.item_type == "armor":
		equipped_armor = item

func get_total_attack() -> int:
	var base_attack: int = 10
	if equipped_weapon:
		base_attack += equipped_weapon.attack_bonus
	return base_attack

func get_total_defense() -> int:
	var base_defense: int = 5
	if equipped_armor:
		base_defense += equipped_armor.defense_bonus
	return base_defense
#func change_scene(path: String) -> void:
	#current_scene_path = path
	#get_tree().change_scene_to_file(path)
func change_scene(path: String) -> void:
	current_scene_path = path
	var result = get_tree().change_scene_to_file(path)
	if result != OK:
		print("Scene change FAILED with error code: ", result)
	else:
		print("Scene change succeeded")	

var inventory: Array[Dictionary] = []  # [{ "item": ItemData, "quantity": int }]
var gold: int = 35

func add_item(item: ItemData, quantity: int = 1) -> void:
	for entry in inventory:
		if entry["item"].id == item.id:
			entry["quantity"] += quantity
			return
	inventory.append({ "item": item, "quantity": quantity })

func remove_item(item_id: String, quantity: int = 1) -> void:
	for i in range(inventory.size()):
		if inventory[i]["item"].id == item_id:
			inventory[i]["quantity"] -= quantity
			if inventory[i]["quantity"] <= 0:
				inventory.remove_at(i)
			return
func _ready() -> void:
	init_npc_memory("wizard", ["wise", "cautious", "secretive"])
	# Temporary starting items for testing
	var sword: ItemData = load("res://assets/items/iron_sword.tres")
	add_item(sword, 1)
	pass
	
var active_quests: Dictionary = {}   # quest_id -> { "quest": QuestData, "completed_objectives": Array[int] }
var completed_quests: Array[String] = []

func start_quest(quest: QuestData) -> void:
	if quest.id in active_quests or quest.id in completed_quests:
		return
	active_quests[quest.id] = { "quest": quest, "completed_objectives": [] }
	print("Quest started: ", quest.title)
	AudioManager.play_sfx("quest_start")

func complete_objective(quest_id: String, objective_index: int) -> void:
	if quest_id not in active_quests:
		return
	var entry = active_quests[quest_id]
	if objective_index not in entry["completed_objectives"]:
		entry["completed_objectives"].append(objective_index)
		print("Objective completed: ", entry["quest"].objectives[objective_index])
	if entry["completed_objectives"].size() == entry["quest"].objectives.size():
		_complete_quest(quest_id)

func _complete_quest(quest_id: String) -> void:
	var entry = active_quests[quest_id]
	var quest: QuestData = entry["quest"]
	gold += quest.reward_gold
	if quest.reward_item:
		add_item(quest.reward_item, 1)
	completed_quests.append(quest_id)
	active_quests.erase(quest_id)
	print("Quest completed: ", quest.title, " | Rewards: ", quest.reward_gold, " gold")

var relationships: Dictionary = {}  # npc_id -> int (relationship score)

func change_relationship(npc_id: String, amount: int) -> void:
	if npc_id not in relationships:
		relationships[npc_id] = 0
	relationships[npc_id] += amount
	print("Relationship with ", npc_id, ": ", relationships[npc_id])

const SAVE_PATH: String = "user://savegame.json"

func save_game() -> void:
	var player_node = get_tree().current_scene.get_node_or_null("Player")

	var inventory_data: Array = []
	for entry in inventory:
		inventory_data.append({
			"item_id": entry["item"].id,
			"quantity": entry["quantity"]
		})

	var active_quests_data: Dictionary = {}
	for quest_id in active_quests:
		var entry = active_quests[quest_id]
		active_quests_data[quest_id] = {
			"completed_objectives": entry["completed_objectives"]
		}

	var save_data: Dictionary = {
		"player": {
			"name": player_name,
			"position_x": player_node.global_position.x if player_node else 320,
			"position_y": player_node.global_position.y if player_node else 220,
			"current_health": player_node.current_health if player_node else 100,
			"current_mana": player_node.current_mana if player_node else 50,
		},
		"gold": gold,
		"inventory": inventory_data,
		"equipped_weapon_id": equipped_weapon.id if equipped_weapon else "",
		"equipped_armor_id": equipped_armor.id if equipped_armor else "",
		"active_quests": active_quests_data,
		"completed_quests": completed_quests,
		"relationships": relationships,
		"current_scene_path": current_scene_path,
	}

	var json_string: String = JSON.stringify(save_data, "\t")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	print("Game saved to: ", SAVE_PATH)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		print("Failed to parse save file.")
		return

	var save_data: Dictionary = json.data

	player_name = save_data["player"]["name"]
	gold = save_data["gold"]

	inventory.clear()
	for entry in save_data["inventory"]:
		var item: ItemData = load("res://assets/items/%s.tres" % entry["item_id"])
		if item:
			add_item(item, entry["quantity"])

	var weapon_id: String = save_data["equipped_weapon_id"]
	if weapon_id != "":
		equipped_weapon = load("res://assets/items/%s.tres" % weapon_id)

	var armor_id: String = save_data["equipped_armor_id"]
	if armor_id != "":
		equipped_armor = load("res://assets/items/%s.tres" % armor_id)

	active_quests.clear()
	for quest_id in save_data["active_quests"]:
		var quest: QuestData = load("res://assets/quests/%s.tres" % quest_id)
		if quest:
			active_quests[quest_id] = {
				"quest": quest,
				"completed_objectives": save_data["active_quests"][quest_id]["completed_objectives"]
			}

	completed_quests = Array(save_data["completed_quests"], TYPE_STRING, "", null)
	relationships = save_data["relationships"]

	print("Game loaded from: ", SAVE_PATH)

	var target_scene: String = save_data["current_scene_path"]
	if target_scene != "":
		change_scene(target_scene)

	var stored_x: float = save_data["player"]["position_x"]
	var stored_y: float = save_data["player"]["position_y"]
	call_deferred("_restore_player_state", stored_x, stored_y, save_data["player"]["current_health"], save_data["player"]["current_mana"])

func _restore_player_state(pos_x: float, pos_y: float, hp: int, mana: int) -> void:
	await get_tree().process_frame
	while get_tree().current_scene == null:
		await get_tree().process_frame

	var player_node = get_tree().current_scene.get_node_or_null("Player")
	if player_node:
		player_node.global_position = Vector2(pos_x, pos_y)
		player_node.current_health = hp
		player_node.current_mana = mana
	else:
		print("Player node not found after scene load.")

var npc_memory: Dictionary = {}  # npc_id -> { "personality": Array[String], "memories": Array[String] }

func init_npc_memory(npc_id: String, personality: Array) -> void:
	if npc_id not in npc_memory:
		npc_memory[npc_id] = {
			"personality": personality,
			"memories": []
		}

func add_npc_memory(npc_id: String, memory_text: String) -> void:
	if npc_id not in npc_memory:
		init_npc_memory(npc_id, [])
	npc_memory[npc_id]["memories"].append(memory_text)
	print("Memory added for ", npc_id, ": ", memory_text)
	print("Current memories for wizard: ", npc_memory["wizard"]["memories"])
func get_npc_context(npc_id: String) -> Dictionary:
	if npc_id in npc_memory:
		return npc_memory[npc_id]
	return { "personality": [], "memories": [] }
	
var reputation: int = 0  # negative = feared/distrusted, positive = respected
var is_wanted: bool = false

func change_reputation(amount: int) -> void:
	reputation += amount
	print("Reputation changed by ", amount, ". Now: ", reputation)

	if reputation <= -10 and not is_wanted:
		_become_wanted()
	elif reputation > -10 and is_wanted:
		_clear_wanted_status()

func _become_wanted() -> void:
	is_wanted = true
	print("You are now WANTED. Guards will be hostile, merchants may refuse service.")

func _clear_wanted_status() -> void:
	is_wanted = false
	print("Your wanted status has been cleared.")

signal world_event_triggered(event_name: String)

func trigger_world_event(event_name: String) -> void:
	print("World event triggered: ", event_name)
	world_event_triggered.emit(event_name)

func build_world_summary() -> String:
	var lines: Array[String] = []

	lines.append("Player gold: %d" % gold)
	lines.append("Reputation: %d (%s)" % [reputation, "wanted" if is_wanted else "not wanted"])

	if completed_quests.size() > 0:
		lines.append("Completed quests: " + ", ".join(completed_quests))
	else:
		lines.append("Completed quests: none")

	if active_quests.size() > 0:
		var active_titles: Array[String] = []
		for quest_id in active_quests:
			active_titles.append(active_quests[quest_id]["quest"].title)
		lines.append("Active quests: " + ", ".join(active_titles))

	if relationships.size() > 0:
		var rel_lines: Array[String] = []
		for npc_id in relationships:
			rel_lines.append("%s: %d" % [npc_id, relationships[npc_id]])
		lines.append("Relationship scores: " + ", ".join(rel_lines))

	if npc_memory.size() > 0:
		for npc_id in npc_memory:
			var memories: Array = npc_memory[npc_id]["memories"]
			if memories.size() > 0:
				lines.append("What %s remembers: %s" % [npc_id, "; ".join(memories)])

	return "\n".join(lines)
