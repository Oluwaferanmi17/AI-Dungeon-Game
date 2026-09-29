extends Node

# Config-driven: add a sound by adding a line here, no other code changes.
const MUSIC: Dictionary = {
	"village": "res://assets/audio/music/village.mp3",
	"forest": "res://assets/audio/music/forest.mp3",
}

const SFX: Dictionary = {
	"footstep": "res://assets/audio/sfx/footstep.wav",
	"dialogue_open": "res://assets/audio/sfx/dialogue_open.mp3",
	"quest_start": "res://assets/audio/sfx/quest_start.mp3",
}

var music_player: AudioStreamPlayer
var current_music: String = ""

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

func play_music(music_name: String) -> void:
	if music_name == current_music:
		return
	if not MUSIC.has(music_name):
		print("AudioManager: unknown music '", music_name, "'")
		return
	var path: String = MUSIC[music_name]
	if not ResourceLoader.exists(path):
		print("AudioManager: missing file ", path)
		return
	var stream: AudioStream = load(path)
	if "loop" in stream:
		stream.loop = true
	music_player.stream = stream
	music_player.play()
	current_music = music_name

func play_sfx(sfx_name: String) -> void:
	if not SFX.has(sfx_name):
		print("AudioManager: unknown sfx '", sfx_name, "'")
		return
	var path: String = SFX[sfx_name]
	if not ResourceLoader.exists(path):
		print("AudioManager: missing file ", path)
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = load(path)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
