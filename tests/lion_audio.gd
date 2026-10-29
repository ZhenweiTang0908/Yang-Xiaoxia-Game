extends SceneTree
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error("FAIL "+label)
func run():
	var bank=preload("res://scripts/core/boss_dialogue.gd").BOSSES.get("lion",{})
	verify(bank.get("lines",{}).size()==68 and bank.get("groups",{}).size()==34,"all68 dialogue lines and34 events")
	for id in bank.get("lines",{}):
		for folder in ["res://assets/voice/ai/","res://assets/voice/"]:
			var path=folder+"lion_"+id+".wav"
			verify(ResourceLoader.exists(path),"voice exists "+path)
			if ResourceLoader.exists(path):verify(load(path).get_length()>.1,"voice contains actual samples "+path)
	var catalogue=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/lion_catalogue.json"))
	verify(catalogue is Dictionary,"Foley catalogue loads")
	if not catalogue is Dictionary:finish();return
	for key in catalogue.events:
		verify(catalogue.assets.has(catalogue.events[key]),"stage maps to existing asset "+key)
	for entry in catalogue.assets.values():verify(ResourceLoader.exists(entry.path),"Foley imported "+entry.path)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.state="playing"
	var helper=preload("res://scripts/core/lion_audio.gd").new();helper.setup(game)
	verify(game.audio.is_boss_voice("lion_intro"),"AI/classic director recognizes elder")
	verify(helper.speak("intro",true),"intro actually plays through director")
	verify(not helper.speak("pounce"),"ordinary dialogue respects12s cooldown")
	var time=helper.cooldown;game.state="paused";helper.tick(1)
	verify(helper.cooldown==time,"paused dialogue cooldown frozen")
	game.state="playing";helper.tick(1);verify(helper.cooldown<time,"cooldown resumes")
	verify(helper.cue("M08",1,"warning"),"first step warning plays")
	verify(helper.cue("M08",2,"release") and helper.cue("M08",3,"release"),"each step release independent")
	verify(not helper.cue("M08",3,"release"),"same beat release cannot duplicate")
	helper.clear();verify(helper.players.is_empty() and not game.audio.voice_player.playing,"interrupt cleans all elder sound players and speech")
	game.audio.voice_player.stream=load("res://assets/voice/lion_intro.wav");game.audio.voice_player.play();game.audio.voice_identity="brother_intro"
	verify(not helper.speak("phase_2",true),"priority phase speech never steals brother voice")
	helper.clear();game.audio.stop_all();game.queue_free();await process_frame
	finish()
func finish():
	print("LION_AUDIO_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
