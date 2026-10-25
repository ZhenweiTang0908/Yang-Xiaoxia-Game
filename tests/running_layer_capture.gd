extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1200,600);root.content_scale_size=Vector2i(1200,600)
 var background=ColorRect.new();background.color=Color("18262c");background.size=Vector2(1200,600);root.add_child(background)
 var original=Sprite2D.new();original.texture=load("res://assets/art/hero_2d/hero/00.png");original.centered=false;original.position=Vector2(70,80);original.scale=Vector2.ONE*2.4;root.add_child(original)
 var rig=load("res://tests/hero_running_gait.gd").new();rig.position=Vector2(650,80);rig.scale=Vector2.ONE*2.4;root.add_child(rig)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/running-rest.png")
 rig.inspect_layers=true;rig.posing=true;rig.age=.16;rig.set_process(false);rig.queue_redraw()
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/running-layers.png")
 DirAccess.make_dir_recursive_absolute("res://builds/qa/running-frames")
 for i in 0:
  rig.age=i/60.0;rig.queue_redraw()
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/running-frames/%04d.png"%i)
 quit()
