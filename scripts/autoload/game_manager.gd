extends Node

enum State { MENU, PLAYING, DIALOGUE, PAUSED }

var current_state: State = State.MENU

func set_state(new_state: State) -> void:
	current_state = new_state
	print("Game state changed to: ", State.keys()[current_state])
