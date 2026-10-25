extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(960,540);root.content_scale_size=root.size
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false)
 game.set_process(false);game.set_physics_process(false);game.combat.set_physics_process(false);game.player.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false);e.dead=true
 var p=game.player;p.reset(Vector2(500,450),true);p.sheep_time=10;p.set_form_art(true);p.invincible=0;p.facing=1
 game.hint_time=0;game.camera.position=Vector2(540,400);game.camera.zoom=Vector2(2.5,2.5);game.camera.reset_smoothing()
 var spirit
 for child in p.get_children():
  if child.get_script() and child.get_script().resource_path.ends_with("cast_visual.gd"):spirit=child
 for action in ["slash","cast","release","left"]:
  p.cancel_action();game.combat.clear();game.fx.clear();game.hitstop=0
  if action in ["slash","left"]:
   p.facing=-1 if action=="left" else 1;p.combo=2;p.combo_window=1;p.start_attack()
   for i in 24:p._physics_process(.01);game.hitstop=0
  elif action=="cast":
   p.enqueue("bow");p.bow_cd=0
   for i in 16:p._physics_process(.01);game.hitstop=0
  else:
   p.blast_anim=.28;game.combat.blast(p,.8)
  p.update_animation();spirit._process(.16)
  for i in 4:await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/sheep-gameplay-"+action+".png")
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame;quit()
