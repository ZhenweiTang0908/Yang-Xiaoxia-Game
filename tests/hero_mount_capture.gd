extends SceneTree
var game
func _initialize():call_deferred("run")
func shot(label):
 game.state="playing";game.hud.canvas.queue_redraw()
 for i in 4:
  game.state="playing";await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/mount-polish-"+label+".png")
func run():
 root.unfocusable=true;root.size=Vector2i(960,540);root.content_scale_size=root.size
 DirAccess.make_dir_recursive_absolute("res://builds/qa")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.use_skeletal=true;game.tuning.reset();game.start_new(false)
 game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false);e.dead=true
 var p=game.player;p.position=Vector2(500,450);game.summon.reset(true);game.summon.request();var b=game.summon.brother;b.set_physics_process(false);game.summon._physics_process(1.2)
 var c=b.demon_controller;c.carry_age=1
 game.hint_time=0;game.camera.position=Vector2(500,405);game.camera.zoom=Vector2(3.4,3.4);game.camera.reset_smoothing()
 await process_frame
 for form in [false,true]:
  p.sheep_time=10 if form else 0;p.set_form_art(form)
  for index in 3:
   for sample in 7:
    game.state="playing"
    p.combo=index+1;p.attack_elapsed=float(sample)/6*p.MOTION.ATTACKS[index].duration;p.attack_duration=p.MOTION.ATTACKS[index].duration
    c.rig.tick(.04);c.rig.continuous._process(.04);p._process(0);p.update_animation()
    p.skeletal_visual._process(.04);p.skeletal_visual.painted_motion._physics_process(.04)
    await shot(("spirit" if form else "hero")+"-"+str(index)+"-"+str(sample))
 p.sheep_time=0;p.set_form_art(false);p.attack_elapsed=-1;c.release_player();p.position=Vector2(550,450)
 for sample in 8:
  game.state="playing"
  b.velocity.x=220;c.rig.tick(.065);c.rig.continuous._process(.065)
  await shot("bull-gait-"+str(sample))
 c.attack_target=null;c.queue_blink(b.position+Vector2(60,0))
 for sample in 7:
  game.state="playing"
  c.tick_blink(.05);await shot("blink-"+str(sample))
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("MOUNT_CAPTURE_RESULT frames=57");quit()
