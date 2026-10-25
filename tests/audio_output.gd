extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);game.state="paused"
	game.progress.muted=false;game.audio.apply_volumes()
	var captures={}
	for bus in ["Music","SFX","Ambience"]:
		var capture=AudioEffectCapture.new();capture.buffer_length=2.0;AudioServer.add_bus_effect(AudioServer.get_bus_index(bus),capture);captures[bus]=capture
	game.audio.play("card_fan")
	await create_timer(1.2).timeout
	var failures=[]
	for bus in captures:
		var data=captures[bus].get_buffer(captures[bus].get_frames_available());var peak=0.0
		for sample in data:peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		print("AUDIO_BUS ",bus," frames=",data.size()," peak=",peak)
		if peak<.0001:failures.append(bus)
	game.audio.stop_all();await create_timer(.1).timeout;game.free();await process_frame
	print("AUDIO_RESULT failures=",failures);quit(0 if failures.is_empty() else 1)
