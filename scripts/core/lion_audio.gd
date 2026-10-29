extends RefCounted
## Parent owns timing: tick only advances while game.active(); clear at every
## interruption/phase boundary. Beats are 1-based. impact is damage-confirmed only.
## Attack stages: warning, charge, release, impact, landing, recover.
## cue("M08", 2, "release") addresses the second independent step.
## Extra contacts: cue("step_left", 1..3, "material"); other variant counts
## are in assets/audio/lion_catalogue.json. cue("effort_hei", 1..2, "effort")
## plays actual recorded short vocals, mutually exclusive with dialogue.
## Director integration: add "lion_" to is_boss_voice() for AI/classic routing.
## No SFX bank changes needed: this helper owns its material playback players.
const DIALOGUE = preload("res://scripts/core/boss_dialogue.gd")
var game
var catalogue: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var seen: Dictionary = {}
var last_lines: Dictionary = {}
var current_move := ""
var finished := false
var cooldown := 0.0
var speech_rank := -1
var effort_cooldown := 0.0

func setup(owner_game):
	clear()
	game = owner_game
	catalogue = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/lion_catalogue.json"))
	cooldown = 0.0
	effort_cooldown = 0.0
	last_lines.clear()

func cue(move_id: String, beat: int, stage: String, volume: float = 0.0) -> bool:
	if not is_instance_valid(game) or not game.active():return false
	if stage == "effort":return _effort(move_id, beat, volume)
	# Accept design IDs as well as descriptive actor action IDs.
	if move_id.begins_with("M") and move_id.substr(1).is_valid_int():
		var definition = preload("res://scripts/actors/lion_moves.gd").MOVES.get(move_id, {})
		if definition.is_empty():return false
		move_id = definition.voice
	var event = "lion:%s:%d:%s" % [move_id, beat, stage]
	var key = catalogue.get("events", {}).get(event, "")
	if key == "":return false
	if stage == "warning" and beat == 1 and (current_move != move_id or finished):
		seen.clear()
		current_move = move_id
		finished = false
	# Material events (walking etc.) are discrete contacts, not attack stages.
	if stage != "material" and seen.has(event):return false
	var stream = load(catalogue.assets[key].path)
	if stream == null:return false
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = stream
	player.volume_db = {"warning":-11.0,"charge":-12.0,"release":-5.0,"impact":-1.0,"landing":-9.0,"recover":-12.0,"material":-10.0}.get(stage,-10.0) + volume
	game.add_child(player)
	players.append(player)
	player.play()
	seen[event] = true
	if stage == "recover" and beat == int(catalogue.moves.get(move_id, 0)):finished = true
	return true

func speak(event: String, priority: bool = false) -> bool:
	if not is_instance_valid(game):return false
	if not game.active() and not (event=="player_death" and game.state=="dead"):return false
	var bank = DIALOGUE.BOSSES.get("lion", {})
	var pool = bank.get("groups", {}).get(event, [])
	if pool.is_empty():return false
	var rank := 2 if event in ["intro","phase_2","defeat"] else (1 if event.begins_with("counter_") else 0)
	if not priority and cooldown > 0.0:return false
	var voice = game.audio.voice_player
	if voice.playing:
		# Never interrupt brother, previews or another speaker; priority may only
		# supersede this elder's lower-ranked line. Dropped events are never queued.
		if not game.audio.voice_identity.begins_with("lion_") or game.audio.voice_preview:return false
		if not priority or rank <= speech_rank:return false
	var available: Array = []
	for line in pool:
		if line != last_lines.get(event, "") and ResourceLoader.exists(game.audio.voice_path("lion_" + line)):
			available.append(line)
	if available.is_empty():return false
	var line = available[randi() % available.size()]
	if not game.say_line("衔灯狮叟：" + bank.lines[line], "lion_" + line):return false
	for player in players:
		if is_instance_valid(player) and player.has_meta("lion_effort"):player.stop()
	last_lines[event] = line
	cooldown = 12.0
	speech_rank = rank
	return true

func tick(dt: float):
	if not is_instance_valid(game):return
	var paused: bool = not game.active()
	if not paused:
		cooldown = maxf(0.0, cooldown - maxf(dt, 0.0))
		effort_cooldown = maxf(0.0, effort_cooldown - maxf(dt, 0.0))
	for index in range(players.size()-1, -1, -1):
		var player = players[index]
		if not is_instance_valid(player):
			players.remove_at(index)
		elif player.has_meta("lion_effort") and game.audio.voice_player.playing:
			player.stop()
			player.queue_free()
			players.remove_at(index)
		elif not player.playing and not player.stream_paused:
			player.queue_free()
			players.remove_at(index)
		else:
			# Reassigning this property restarts playback on some Godot backends.
			if player.stream_paused != paused:player.stream_paused = paused

func _effort(id: String, variant: int, volume: float) -> bool:
	if effort_cooldown > 0.0 or game.audio.voice_player.playing:return false
	if variant < 1 or variant > 2:return false
	var line := id + ("_b" if variant == 2 else "")
	if not DIALOGUE.BOSSES.lion.efforts.has(line):return false
	var path := "res://assets/voice/ai/lion_" + line + ".wav"
	if not ResourceLoader.exists(path):return false
	for existing in players:
		if is_instance_valid(existing) and existing.has_meta("lion_effort") and existing.playing:return false
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	if player.stream == null:
		player.free()
		return false
	player.bus = "SFX"
	player.volume_db = -7.0 + volume
	player.set_meta("lion_effort", true)
	game.add_child(player)
	players.append(player)
	player.play()
	effort_cooldown = 0.8
	return true

func clear():
	for player in players:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	players.clear()
	seen.clear()
	current_move = ""
	finished = false
	if is_instance_valid(game) and is_instance_valid(game.audio):
		if game.audio.voice_identity.begins_with("lion_"):
			game.audio.voice_player.stop()
			game.audio.voice_identity = ""
			game.subtitle_time = 0.0
	speech_rank = -1
