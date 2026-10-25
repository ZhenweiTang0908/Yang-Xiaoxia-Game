extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.state="settings"
 var bus=AudioServer.get_bus_index("SFX");var capture=AudioEffectRecord.new();AudioServer.add_bus_effect(bus,capture)
 capture.set_recording_active(true);game.audio.start_audition()
 await create_timer(7.0).timeout
 capture.set_recording_active(false);var clip=capture.get_recording()
 var result=clip.save_to_wav("res://builds/qa/audio/in-game-melee.wav")
 print("AUDIO_CAPTURE ",result," length=",clip.get_length())
 AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame;quit(result)
