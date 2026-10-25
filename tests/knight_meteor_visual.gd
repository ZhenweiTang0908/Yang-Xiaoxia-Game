extends SceneTree
var game
var k
var failures=[]
var captures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
 if ok:print("PASS ",label)
 else:failures.append(label);push_error(label)
func capture(name):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/knight/meteor-"+name+".png")
func sample(id,at,name):
 game.player.hurt_anim=0;game.player.health=100;game.player.invincible=999
 game.audio.stop_all();game.subtitle_time=0;game.combat.clear();game.fx.clear();game.hitstop=0
 k.soul.clear_attacks();k.soul.rage=0;k.motion_trail.clear();k.strike_fx.clear();k.action="";k.end_box();k.position=Vector2(530,450);k.facing=-1;k.dead=false;k.phase=2;k.dismount_t=-1;k.weapon="spear";k.visual.held_action="";k.idle=99;k.speech_cooldown=99
 k.begin(id,k.prep_for(id))
 for i in int(at*120):
  k._physics_process(1.0/120);game.combat._physics_process(1.0/120);game.hitstop=0
 await capture(name)
func record(capture_audio,key,stage):
 capture_audio.clear_buffer();game.audio.enemy_recent.clear();game.audio.enemy_cue("knight:"+key,stage,-2)
 await create_timer(.50).timeout
 var pcm=capture_audio.get_buffer(capture_audio.get_frames_available());var peak=0.0
 for pair in pcm:peak=maxf(peak,maxf(absf(pair.x),absf(pair.y)))
 verify(pcm.size()>4000 and peak>.001,"actual SFX output: "+key+" / "+stage)
 captures.append({"name":key+"_"+stage,"frames":pcm.size(),"peak":peak})
 return pcm
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false);await process_frame
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_size=Vector2i(960,540);root.size=Vector2i(960,540)
 game.start_challenge(4,2);await process_frame;game.tuning.reset()
 game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 k=game.boss;k.set_physics_process(false);k.active_battle=true;game.player.position=Vector2(300,450);game.player.invincible=999;game.hint_time=0
 game.camera.position=Vector2(480,365);game.camera.zoom=Vector2(1.45,1.45);game.camera.reset_smoothing()
 await sample("spear_chain",.36,"chain-coil")
 await sample("spear_chain",.65,"chain-thrust")
 await sample("spear_chain",1.98,"chain-lift")
 await sample("dragon_sweep",.72,"low-sweep")
 await sample("dragon_sweep",1.59,"high-return")
 await sample("dragon_rise",1.5,"spiral")
 await sample("dragon_rise",2.34,"rising")
 await sample("dragon_break",2.38,"king-raise")
 await sample("dragon_break",2.69,"king-release")
 await sample("lunge",.55,"pierce-coil")
 game.audio.stop_all();game.progress.muted=false;game.progress.music=0;game.progress.ambience=0;game.progress.sfx=.65;game.audio.apply_volumes()
 var capture_audio=AudioEffectCapture.new();capture_audio.buffer_length=1.5;var bus=AudioServer.get_bus_index("SFX");AudioServer.add_bus_effect(bus,capture_audio)
 print("METEOR_AUDIO_DRIVER ",AudioServer.get_driver_name()," rate=",AudioServer.get_mix_rate())
 await create_timer(.25).timeout
 var all=PackedVector2Array()
 for id in k.SPEAR.MOVES:
  for stage in ["warning","release","impact"]:all.append_array(await record(capture_audio,id,stage))
 game.audio.stop_all();k.speech_cooldown=0;capture_audio.clear_buffer();k.speak("dragon_break",true)
 await create_timer(1.0).timeout
 var pcm=capture_audio.get_buffer(capture_audio.get_frames_available());var peak=0.0
 for pair in pcm:peak=maxf(peak,maxf(absf(pair.x),absf(pair.y)))
 verify(peak>.001 and game.subtitle.contains(k.DIALOGUE.LINES.dragon_break),"new Chinese line is audible and has matching subtitles")
 all.append_array(pcm);game.state="paused";await process_frame;await process_frame
 var position=game.audio.voice_player.get_playback_position();await create_timer(.22).timeout
 verify(absf(position-game.audio.voice_player.get_playback_position())<.04,"pause freezes new dialogue")
 var bytes=PackedByteArray();bytes.resize(all.size()*4)
 for i in all.size():
  bytes.encode_s16(i*4,int(clampf(all[i].x,-1,1)*32767));bytes.encode_s16(i*4+2,int(clampf(all[i].y,-1,1)*32767))
 var wav=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=int(AudioServer.get_mix_rate());wav.stereo=true;wav.data=bytes;
 if not all.is_empty():wav.save_to_wav("res://builds/qa/knight/meteor-audition.wav")
 var manifest=FileAccess.open("res://builds/qa/knight/meteor-playback.json",FileAccess.WRITE);manifest.store_string(JSON.stringify({"driver":AudioServer.get_driver_name(),"mix_rate":AudioServer.get_mix_rate(),"segments":captures}," "));manifest.close()
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("KNIGHT_METEOR_VISUAL failures=",failures," captured_frames=",all.size());quit(0 if failures.is_empty() else 1)
