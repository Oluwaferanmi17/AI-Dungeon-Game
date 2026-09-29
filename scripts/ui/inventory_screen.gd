extends Control

@onready var item_list: VBoxContainer = $ItemList

func _ready() -> void:
	visible = false
	refresh()

func refresh() -> void:
	for child in item_list.get_children():
		child.queue_free()

	for entry in GameState.inventory:
		var item: ItemData = entry["item"]
		var qty: int = entry["quantity"]
		var button: Button = Button.new()
		button.text = "%s x%d" % [item.display_name, qty]
		button.pressed.connect(_on_item_pressed.bind(item))
		item_list.add_child(button)

	var gold_label: Label = Label.new()
	gold_label.text = "Gold: %d" % GameState.gold
	item_list.add_child(gold_label)

func _on_item_pressed(item: ItemData) -> void:
	if item.item_type == "weapon" or item.item_type == "armor":
		GameState.equip_item(item)
		print("Equipped: ", item.display_name)
	elif item.item_type == "consumable":
		print("Used: ", item.display_name, " (consumable logic comes later)")
		
func toggle() -> void:
	visible = not visible
	if visible:
		refresh()
