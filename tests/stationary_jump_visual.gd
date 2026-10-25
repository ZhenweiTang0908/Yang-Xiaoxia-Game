extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(960,360);root.content_scale_size=root.size
 var bg=ColorRect.new();bg.size=Vector2(root.size);bg.color=Color("18262c");root.add_child(bg)
 for i in 4:
  var rig=load("res://scripts/animation/painted_rig/combo.gd").new();root.add_child(rig)
  rig.set_process(false);rig.posing=true;rig.attack_index=-1;rig.motion_amount=0;rig.contact_enabled=false;rig.phase_override=.55
  rig.air_pose=[0.0,.5,1.0,.35][i]
  rig.scale=Vector2.ONE*1.2;rig.position=Vector2(120+i*240,300)-Vector2(96,199)*1.2
  rig.sampled_pose=rig.pose_transforms();rig.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/stationary-jump-poses.png")
 quit()
