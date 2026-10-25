extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(900,330);root.content_scale_size=root.size
 var bg=ColorRect.new();bg.size=Vector2(root.size);bg.color=Color("14232c");root.add_child(bg)
 var source=load("res://scripts/actors/atlas_actor.gd").new();root.add_child(source);source.configure("res://assets/art/v3/niu_human.png",6,4,88);source.hide()
 for i in 4:
  var visual=load("res://scripts/animation/brother_visual.gd").new();visual.source_art=source;visual.preview=true;root.add_child(visual);visual.set_process(false)
  visual.rebuild(0);visual.landing_sink=[0.0,1.4,2.0,0.0][i];visual.update_surface()
  visual.position=Vector2(100+i*230,295);visual.scale=Vector2.ONE*2.6;visual.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/brother-landing-poses.png");quit()
