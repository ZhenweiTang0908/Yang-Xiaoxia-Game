extends SceneTree
var game
var frame_index=0
const OUT="res://builds/qa/visual-stability/"
func _initialize():root.unfocusable=true;root.size=Vector2i(960,540);root.content_scale_size=root.size;call_deferred("run")
func shot(label=""):
 game.state="playing";game.hud.canvas.queue_redraw()
 await process_frame
 RenderingServer.force_draw(false)
 var image=root.get_texture().get_image()
 image.save_png(OUT+"video/%04d.png"%frame_index);frame_index+=1
 if label!="":image.save_png(OUT+label+".png")
func freeze():
 game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false)
func run():
 DirAccess.make_dir_recursive_absolute(OUT+"video")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.use_skeletal=false;game.tuning.reset();game.start_new(false);freeze()
 for e in game.enemies:e.dead=true
 var p=game.player;p.position=Vector2(500,450);game.summon.reset(true);game.summon.request();var bull=game.summon.brother;bull.set_physics_process(false);game.summon._physics_process(1.2)
 var c=bull.demon_controller;c.carry_age=1
 for i in 5:await process_frame
 game.hint_time=0;game.stage_banner=-10;game.camera.position=Vector2(500,405);game.camera.zoom=Vector2(3,3);game.camera.reset_smoothing()
 for form in [false,true]:
  p.sheep_time=10 if form else 0;p.set_form_art(form)
  for combo in 3:
   for sample in 18:
    p.combo=combo+1;p.attack_duration=p.MOTION.ATTACKS[combo].duration if form else (.40 if combo==2 else .34);p.attack_elapsed=float(sample)/17*p.attack_duration
    c.rig.tick(.025);c.rig.continuous._process(.025);p._process(0);p.update_animation();p.skeletal_visual._process(.025);p.skeletal_visual.painted_motion._physics_process(.025);p.mounted_spirit._process(.025)
    await shot(("spirit" if form else "hero")+"-"+str(combo)+"-"+str(sample) if sample in [0,7,12] else "")
 if "--mount-only" in OS.get_cmdline_user_args():
  game.audio.stop_all();game.queue_free();await process_frame;print("VISUAL_FIXES_CAPTURE_RESULT frames=",frame_index);quit();return
 c.release_player();p.sheep_time=0;p.set_form_art(false)
 game.jump_to_stage(3);await process_frame;freeze();game.state="playing";game.stage_banner=-10
 var b=game.boss;b.set_physics_process(false);b.active_battle=true;b.position=Vector2(630,450);b.facing=-1;b.cooldown=99
 p=game.player;p.position=Vector2(430,450);p.invincible=999
 game.camera.zoom=Vector2(1.5,1.5);game.camera.position=Vector2(540,330);game.camera.reset_smoothing()
 for index in b.spec.moves.size():
  b.clear_attacks();b.position=Vector2(630,450);b.start_move(index)
  for sample in 48:
   game.hitstop=0;b._physics_process(1.0/30)
   await shot("priest-"+str(b.move.id) if sample==int(b.move.windup*30)+7 else "")
 game.jump_to_stage(4);await process_frame;freeze();game.state="playing";game.stage_banner=-10
 var k=game.boss;k.set_physics_process(false);k.active_battle=true;k.position=Vector2(630,450);k.facing=-1;game.player.position=Vector2(420,450)
 game.camera.zoom=Vector2(1.8,1.8);game.camera.position=Vector2(540,340);game.camera.reset_smoothing()
 for phase in [1,2]:
  if phase==2:k.enter_foot_challenge()
  k.position=Vector2(630,450);k.facing=-1
  for action in (["idle","charge","bow"] if phase==1 else ["idle","thrust","wave","guard"]):
   k.phase=phase;k.action="" if action=="idle" else action
   for sample in 24:
    k.t=float(sample)/24*1.4;k.visual.sync_pose(1.0/30)
    await shot("knight-"+str(phase)+"-"+action if sample==12 else "")
 game.audio.stop_all();game.queue_free();await process_frame
 print("VISUAL_FIXES_CAPTURE_RESULT frames=",frame_index);quit()
