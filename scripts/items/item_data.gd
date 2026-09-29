extends Resource
class_name ItemData

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export_enum("weapon", "armor", "consumable", "misc") var item_type: String = "misc"
@export var stack_size: int = 1

# Combat-relevant stats (only used if item_type is weapon/armor)
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var heal_amount: int = 0
