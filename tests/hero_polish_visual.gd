extends SceneTree
func _initialize():call_deferred("run")
func shot(name):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/knight/hero-polish-"+name+".png")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);await process_frame
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_size=Vector2i(960,540);root.size=Vector2i(960,540)
 game.player.set_physics_process(false);game.set_physics_process(false);game.set_process(false);game.hint_time=0
 for e in game.enemies:e.set_physics_process(false)
 var p=game.player;p.position=Vector2(400,450);game.camera.position=Vector2(480,270);p.facing=1;p.invincible=0
 var motion=p.skeletal_visual.painted_motion;motion.set_physics_process(false)
 game.use_skeletal=true;p.skeletal_visual.set_process(false);p.skeletal_visual.show();p.skeletal_visual.art.hide();p.skeletal_visual.skin.hide();p.skeletal_visual.heavy_skin.hide();motion.show();p.art.hide();game.camera.zoom=Vector2(2,2);game.camera.position=Vector2(400,420);game.camera.reset_smoothing()
 for state in ["slash1","bow","roll"]:
  p.hurt_anim=0;p.attack_elapsed=-1;p.bow_anim=0;p.dash_time=0
  if state=="slash1":p.combo=1;p.attack_elapsed=.15
  if state=="bow":p.bow_anim=.22
  if state=="roll":p.sprinting=false;p.dash_time=.09
  motion._physics_process(.016);motion.rig.transition_pose.clear();motion._physics_process(.016)
  await shot(state)
 game.state="settings";await shot("settings")
 game.audio.stop_all();game.queue_free();await process_frame;quit()
