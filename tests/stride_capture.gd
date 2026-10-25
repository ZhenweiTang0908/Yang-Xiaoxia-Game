extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(960,540)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.open_animation_lab()
 await process_frame
 var lab=game.animation_lab;lab.set_process(false)
 var old=lab.rig;lab.remove_child(old);old.free()
 lab.rig=load("res://tests/hero_stride_experiment.gd").new();lab.rig.preview=true;lab.rig.position=Vector2(680,372);lab.rig.scale=Vector2.ONE*3;lab.add_child(lab.rig)
 DirAccess.make_dir_recursive_absolute("res://builds/qa/stride/frames")
 for i in 360:
  lab._process(1.0/60);lab.rig.set_process(false);lab.rig._process(1.0/60)
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/stride/frames/%04d.png"%i)
 game.queue_free();await process_frame;quit()
