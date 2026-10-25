extends SceneTree
# Deterministic in-engine art review, every frame saved for an MP4/contact sheet.
var game
var k
var folder="/private/tmp/knight-painted-frames/"
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
	await sequence("idle",.8,1,"spear",{12:"mounted-idle"})
	await sequence("charge",1.4,1,"spear",{15:"mounted-lance"})
	await sequence("rear",1.5,1,"spear",{16:"horse-rear"})
	await sequence("kick",1.25,1,"spear",{16:"horse-kick"})
	k.action="";k.begin_dismount()
	for i in 78:
		game.hitstop=0;k._physics_process(1.0/30);game.player.health=100
		game.summon._physics_process(1.0/30);game.player.hurt_anim=maxf(0,game.player.hurt_anim-1.0/30)
		await save_frame("dismount" if i==22 else ("landing" if i==29 else ""))
	await sequence("idle",.7,2,"spear",{12:"foot-idle"})
	await sequence("thrust",1.15,2,"spear",{12:"spear-prep",14:"spear-contact"})
	k.wave_uses=0
	await sequence("wave",3.3,2,"spear",{4:"wave-raised",12:"wave-contact"})
	await sequence("bow",1.6,2,"bow",{17:"bow-draw",21:"bow-release"})
	await sequence("draw_slash",1.24,2,"sword",{12:"sword-prep",14:"sword-contact"})
	await sequence("drag",2.4,2,"sword",{15:"sword-drag",31:"sword-raised",35:"sword-heavy"})
	k.wave_uses=1
	await sequence("wave",4.2,2,"spear",{90:"delayed-third-prep"})
	# Additional right-facing pose catches asymmetric/stowed-weapon mistakes.
	k.action="";k.phase=2;k.landed=true;k.weapon="spear";k.facing=1;k.visual.held_action="";k.visual.sync_pose(0)
	await save_frame("foot-right")
	game.audio.stop_all();game.queue_free();await process_frame
	print("KNIGHT_PAINTED_SHOWCASE_FRAMES ",frame);quit()
