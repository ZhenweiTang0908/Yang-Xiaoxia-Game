extends SceneTree

var failures=[]

func _initialize():
	call_deferred("run")

func check(condition,label):
	if condition:print("PASS ",label)
	else:failures.append(label);push_error(label)

func run():
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.qa_mode=true;game.start_new(false)
	var audio=game.audio
	for key in ["impact_heavy","boss_release","boss_warning_low","blade_air_heavy","transformation_surge"]:
		check(audio.bank.has(key) and audio.bank[key].get_length()>.35,"authored layer "+key)
	check(audio.ambience_target.ends_with("ambience_stage1.wav"),"stage one has mountain ambience")
	audio.play("boss_warn_priest")
	check(audio.layer_players.any(func(p):return p.playing and p.stream==audio.bank.boss_warning_low),"boss warning gains low pulse")
	audio.play("boss_ritual")
	check(audio.impact_duck>=3.5,"boss release creates short music pocket")
	check(audio.layer_players.any(func(p):return p.playing and p.stream==audio.bank.boss_release),"boss move gains release weight")
	for p in audio.layer_players:p.stop()
	audio.melee_swing(3)
	check(audio.layer_players.any(func(p):return p.playing and p.stream==audio.bank.blade_air_heavy),"combo finisher gains broad blade air")
	audio.change_music(2,false)
	check(audio.ambience_target.ends_with("ambience_stage2.wav"),"stage two switches to wetland ambience")
	audio.change_music(3,false)
	check(audio.ambience_target.ends_with("ambience_stage3.wav"),"stage three switches to altar ambience")
	var ambience_valid=true
	for stage in [1,2,3]:
		var stream=load("res://assets/audio/ambience_stage%s.wav"%stage)
		ambience_valid=ambience_valid and stream.get_length()>=15.9
	check(ambience_valid,"all stage ambience loops have sustained beds")
	var sfx=AudioServer.get_bus_index("SFX")
	check(sfx>=0 and AudioServer.get_bus_effect_count(sfx)>0,"SFX limiter protects layered peaks")
	audio.stop_all();game.queue_free();await process_frame;await process_frame
	print("AUDIO_MIX_EXPANSION failures=",failures)
	quit(0 if failures.is_empty() else 1)
