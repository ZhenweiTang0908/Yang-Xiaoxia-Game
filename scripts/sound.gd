extends Node
var bank = {}
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var muted = false

func _ready():
	for key in ["jump", "dash", "swing", "hit", "hurt", "bow", "land", "step", "enemy", "pickup", "transform", "win", "ui", "death", "charge", "blast"]:
		bank[key] = load("res://assets/audio/" + key + ".wav")
	music = loop_player("music", -14)
	ambience = loop_player("ambience", -12)

func loop_player(key: String, volume: float) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	var stream = load("res://assets/audio/" + key + ".wav") as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = stream.data.size() / 2
	p.stream = stream
	p.volume_db = volume
	add_child(p)
	return p

func start():
	if not music.playing:
		music.play()
		ambience.play()

func play(key: String, volume = -7.0):
	if not bank.has(key): return
	var p = AudioStreamPlayer.new()
	p.stream = bank[key]
	p.volume_db = volume
	if key in ["swing", "hit", "step"]: p.pitch_scale = randf_range(.9, 1.12)
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func toggle():
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
