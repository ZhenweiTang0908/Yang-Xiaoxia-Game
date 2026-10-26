extends SceneTree
var game
var k
func _initialize():call_deferred("run")
func shot(id):
 k.visual.sync_pose(0);k.queue_redraw();k.soul.queue_redraw();game.hud.canvas.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/knight/divine-"+id+".png")
func reset():
 game.hitstop=0;game.combat.clear();game.fx.clear();game.summon.reset(true);game.state="playing"
 k.soul.clear_attacks();k.soul.spend();k.end_box();k.action="";k.pending="";k.phase=2;k.active_battle=true;k.dead=false;k.position=Vector2(690,450);k.facing=-1;k.weapon="spear";k.dismount_t=-1;k.idle=99;k.speech_cooldown=99;k.visual.held_action=""
 game.player.position=Vector2(400,450);game.player.health=100;game.player.hurt_anim=0;game.player.invincible=99;game.subtitle_time=0;game.hint_time=0
func step(seconds):
 for i in int(seconds*120):
  game.hitstop=0;k._physics_process(1.0/120);game.combat._physics_process(1.0/120)
func run():
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_size=Vector2i(960,540);root.size=Vector2i(960,540)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.start_challenge(4,2);await process_frame
 game.world.visible=true;game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false);game.fx.set_process(false)
 k=game.boss;k.set_physics_process(false)
 reset();k.soul.rage=3;k.soul.release_ready=true;k.choose();step(1.50);await shot("regiment")
 step(.35);await shot("regiment-rush")
 reset();k.soul.rage=3;k.weapon="bow";k.choose();step(.8);await shot("eagle-draw")
 step(.43);await shot("eagle-release")
 step(.25);await shot("eagle-impact")
 reset();game.summon.request();game.summon.phase="active";game.summon.remaining=30
 var ally=game.summon.brother;ally.set_physics_process(false);ally.position=Vector2(510,450);ally.invincible=99
 k.on_ally_hit(ally,"knight:thrust",0);k.choose();step(.9);await shot("ancient-descent")
 step(.25);await shot("ancient-pin")
 step(1);await shot("bound-ally")
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame;quit()
