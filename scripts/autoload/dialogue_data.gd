extends Node

# Dialogue data for all NPCs. Structure:
# npc_id -> { node_id -> { speaker, text, choices: [{ text, next_node }] } }

var dialogues: Dictionary = {
	"wizard": {
		"start": {
			"speaker": "Old Wizard",
			"text": "You shouldn't be wandering near the forest tonight...",
			"choices": [
				{ "text": "What happened?", "next_node": "explain" },
				{ "text": "I'll be careful.", "next_node": "dismiss" },
			]
		},
		"explain": {
			"speaker": "Old Wizard",
			"text": "The merchant who passed through hasn't been seen since. Will you look for him?",
			"choices": [
				{ "text": "I'll find him.", "next_node": "quest_accept" },
				{ "text": "Not my problem.", "next_node": null },
			]
		},
		"quest_accept": {
			"speaker": "Old Wizard",
			"text": "Thank you. Start by checking the forest.",
			"choices": [
				{ "text": "I understand.", "next_node": null },
			]
		},
		"dismiss": {
			"speaker": "Old Wizard",
			"text": "Foolish, but it's your choice to make.",
			"choices": [
				{ "text": "...", "next_node": null },
			]
		},
	},
	"guard": {
		"start": {
			"speaker": "Village Guard",
			"text": "Move along, citizen. Nothing to see here.",
			"choices": [
				{ "text": "Just passing through.", "next_node": null },
			]
		},
		"hostile": {
			"speaker": "Village Guard",
			"text": "You! Stop right there — you're wanted for crimes against this village!",
			"choices": [
				{ "text": "...", "next_node": null },
			]
		}
	}
}
