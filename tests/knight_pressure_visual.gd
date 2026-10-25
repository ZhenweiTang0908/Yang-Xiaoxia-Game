extends SceneTree
var game
var k
func _initialize():call_deferred("run")
func capture(label):
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/qa/knight/pressure-"+label+".png")
func sample(id,at,label,rage=0):
	game.audio.stop_all();game.subtitle_time=0;game.combat.clear();game.fx.clear();k.soul.clear_attacks();k.motion_trail.clear();game.hitstop=0
	k.action="";k.end_box();k.position=Vector2(700,450);k.facing=-1;k.dead=false;k.idle=100;k.dismount_t=-1;k.weapon=k.weapon_for(id);k.visual.held_action="";k.motion_trail.clear();k.speech_cooldown=99
	k.soul.rage=rage;k.soul.release_ready=rage>=1;k.begin(id,k.prep_for(id))
	for i in int(at*120):
		game.hitstop=0;k._physics_process(1.0/120);game.combat._physics_process(1.0/120)
	await capture(label)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_size=Vector2i(960,540);root.size=Vector2i(960,540)
	game.state="title";await capture("entrances")
	game.start_challenge(4,2);await process_frame
	game.tuning.values.knight_rage_release=100
	k=game.boss;k.active_battle=true;k.set_physics_process(false)
	game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false);game.fx.set_physics_process(false)
	game.player.position=Vector2(300,450);game.player.invincible=99;game.player.facing=1;game.hint_time=0
	game.audio.stop_all();k.speak("foot",true);await capture("foot-entry")
	await sample("spin_rush",.35,"spin-prep")
	await sample("spin_rush",.84,"spin-contact")
	await sample("triple_dash",1.59,"threefold")
	await sample("spear_return",.90,"spear-outbound")
	await sample("spear_return",1.65,"spear-return")
	await sample("bow_volley",.4,"volley-draw")
	await sample("bow_volley",.72,"volley-release")
	await sample("spear_slam",.76,"spear-sweep")
	await sample("lunge",.82,"rage-long-spear",1)
	await sample("bow",.65,"rage-bow-draw",1)
	await sample("bow",.84,"rage-bow-flight",1)
	await sample("spin_rush",.78,"rage-spin",1)
	await sample("triple_dash",1.94,"rage-threefold",1)

	await sample("soul_legion",2.0,"legion-land",3)
	await sample("soul_legion",3.8,"legion-attack",3)
	game.audio.stop_all();game.progress.muted=false;game.progress.sfx=1;game.audio.apply_volumes()
	var capture_audio=AudioEffectCapture.new();capture_audio.buffer_length=2
	AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"),capture_audio)
	k.speech_cooldown=0;k.speak("spin_rush",true)
	await create_timer(.9).timeout
	var pcm=capture_audio.get_buffer(capture_audio.get_frames_available());var peak=0.0
	for pair in pcm:peak=maxf(peak,maxf(absf(pair.x),absf(pair.y)))
	game.state="paused";await process_frame;await process_frame
	var before=game.audio.voice_player.get_playback_position();await create_timer(.25).timeout
	var frozen=absf(game.audio.voice_player.get_playback_position()-before)<.04
	print("KNIGHT_VOICE_CAPTURE frames=",pcm.size()," peak=",peak," pause_frozen=",frozen)
	game.audio.stop_all();game.queue_free();await process_frame
	quit(0 if peak>.001 and frozen else 1)
