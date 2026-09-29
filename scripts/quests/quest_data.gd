extends Resource
class_name QuestData

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var objectives: Array[String] = []
@export var reward_gold: int = 0
@export var reward_item: ItemData
