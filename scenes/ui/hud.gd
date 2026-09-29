extends Control

@onready var health_label: Label = $StatsContainer/HealthLabel
@onready var mana_label: Label = $StatsContainer/ManaLabel

var player_ref: CharacterBody2D

func _ready() -> void:
	player_ref = get_tree().current_scene.get_node("Player")

func _process(_delta: float) -> void:
	health_label.text = "HP: %d / %d" % [player_ref.current_health, player_ref.max_health]
	mana_label.text = "Mana: %d / %d" % [player_ref.current_mana, player_ref.max_mana]
