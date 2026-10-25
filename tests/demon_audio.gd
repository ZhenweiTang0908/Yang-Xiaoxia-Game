extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 game.progress.muted=false;game.audio.apply_volumes();game.audio.stop_all()
 for e in game.enemies:e.set_physics_process(false)
 var cap=AudioEffectCapture.new();cap.buffer_length=2;AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"),cap)
 game.audio.voice("niu_demon")
 await create_timer(1).timeout
 var data=cap.get_buffer(cap.get_frames_available());var peak=0.0
 for sample in data:peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
 game.state="paused";await process_frame;await process_frame
 var at=game.audio.voice_player.get_playback_position();await create_timer(.25).timeout
 var frozen=absf(game.audio.voice_player.get_playback_position()-at)<.04
 print("DEMON_AUDIO frames=",data.size()," peak=",peak," pause_frozen=",frozen)
 game.audio.stop_all();await create_timer(.2).timeout;game.free();quit(0 if peak>.001 and frozen else 1)
