extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(960,540);root.content_scale_size=root.size
 var bg=ColorRect.new();bg.size=Vector2(960,540);bg.color=Color("18262c");root.add_child(bg)
 for i in 3:
  var rig=load("res://scripts/animation/painted_rig/combo.gd").new();root.add_child(rig);rig.set_process(false);rig.posing=true;rig.attack_index=-1;rig.motion_amount=0
  rig.scale=Vector2.ONE*rig.game_scale*2;rig.position=Vector2(180+i*300,400)-Vector2(96,199)*rig.game_scale*2
  rig.sampled_pose=rig.pose_transforms();rig.queue_redraw()
  var fx=load("res://scripts/combat/effects.gd").new();root.add_child(fx);fx.set_process(false);fx.position=Vector2(180+i*300,400);fx.scale=Vector2.ONE*2
  fx.recovery(Vector2.ZERO);fx.recovery_glints[0].age=[.08,.22,.44][i];fx.queue_redraw()
  var label=Label.new();label.text=["0.08 s","0.22 s","0.44 s"][i];label.position=Vector2(155+i*300,430);root.add_child(label)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/recovery-glints.png")
 quit()
