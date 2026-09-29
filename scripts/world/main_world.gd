extends Node2D

@onready var forest_zone: ColorRect = $ForestZone

func _ready() -> void:
	GameState.world_event_triggered.connect(_on_world_event)
	AudioManager.play_music("village")

func _on_world_event(event_name: String) -> void:
	match event_name:
		"VILLAGE_ATTACKED":
			_apply_village_attacked()
		"VILLAGE_SAVED":
			_apply_village_saved()

func _apply_village_attacked() -> void:
	forest_zone.color = Color(0.4, 0.1, 0.05)  # scorched/reddish
	print("Visual: forest zone now shows attack aftermath")

func _apply_village_saved() -> void:
	forest_zone.color = Color(0.08, 0.31, 0.14)  # back to normal dark green
	print("Visual: forest zone restored to normal")
