extends SceneTree
# Deterministic in-engine art review, every frame saved for an MP4/contact sheet.
var game
var k
var folder="/private/tmp/knight-arsenal-frames/"
var frame=0
var shots={}
func _initialize():call_deferred("run")
func save_frame(label=""):
	await process_frame;await RenderingServer.frame_post_draw
	var image=game.get_viewport().get_texture().get_image()
	image.resize(960,540,Image.INTERPOLATE_LANCZOS)
	image.save_png(folder+"frame_%05d.png"%frame)
	if label!="":image.save_png("res://builds/qa/knight/"+label+".png")
	frame+=1
func sequence(id,duration,phase,weapon,labels={}):
	k.action="";k.phase=phase;k.weapon=weapon;k.landed=phase==2;k.dismount_t=-1
	k.horse_away=-1;k.position=Vector2(605,450);k.facing=-1;k.visual.held_action=""
	game.combat.clear();game.fx.clear();k.idle=duration+1
	if id!="idle":k.begin(id,k.prep_for(id))
	for i in int(duration*30):
		game.hitstop=0;k._physics_process(1.0/30)
		game.combat._physics_process(1.0/30);game.summon._physics_process(1.0/30)
		game.player.hurt_anim=maxf(0,game.player.hurt_anim-1.0/30)
		game.player.health=100;game.player.invincible=0
		await save_frame(labels.get(i,""))
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_size=Vector2i(960,540)
	root.size=Vector2i(960,540)
	game.start_new(false);await process_frame;game.start_challenge();await process_frame
	k=game.boss;k.active_battle=true;k.set_physics_process(false)
	game.player.set_physics_process(false);game.player.position=Vector2(305,450);game.player.facing=1
	game.combat.set_physics_process(false);game.summon.set_physics_process(false)
	game.fx.set_physics_process(false)
	game.hint_time=0
	game.player.position.x=430
	await sequence("advance",2.0,1,"spear",{8:"arsenal-hoof-raised",19:"arsenal-hoof-contact"})
	await sequence("uppercut",1.2,1,"spear",{12:"arsenal-uppercut-prep",22:"arsenal-uppercut"})
	await sequence("lunge",1.5,2,"spear",{12:"arsenal-lunge-prep",26:"arsenal-lunge"})
	await sequence("kick_thrust",1.9,2,"spear",{8:"arsenal-knee",16:"arsenal-kick",41:"arsenal-followup"})
	await sequence("bow_double",2.1,2,"bow",{12:"arsenal-bow-draw",22:"arsenal-bow-first",49:"arsenal-bow-second"})
	await sequence("cross_cut",2.0,2,"sword",{8:"arsenal-sword-prep",17:"arsenal-sword-first",44:"arsenal-sword-return"})
	game.audio.stop_all();game.queue_free();await process_frame
	print("KNIGHT_ARSENAL_SHOWCASE_FRAMES ",frame);quit()
