extends SceneTree
const MOTION=preload("res://scripts/animation/hero_motion.gd")
const TIMES=[0.0,.05,.10,.129,.14,.24]
const LINKS=[[1,0,Vector2(83,145)],[3,0,Vector2(109,146)],[9,0,Vector2(68,108)],[7,9,Vector2(64,125)],[10,0,Vector2(122,108)],[8,10,Vector2(124,127)]]
var failures=[]
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures.append(label)
func run():
 root.size=Vector2i(1200,520);root.content_scale_size=root.size
 var background=ColorRect.new();background.color=Color("18262c");background.size=Vector2(root.size);root.add_child(background)
 var max_joint_error=0.0;var max_foot_error=0.0;var all_hidden=true;var separate_blade=false
 for index in TIMES.size():
  var rig=load("res://tests/hero_combo_gait.gd").new();root.add_child(rig);rig.set_process(false);rig.posing=true;rig.attack_index=-1;rig.motion_amount=0
  separate_blade=rig.parts.size()==12 and rig.parts[11].get_surface_count()==1
  var rest=rig.pose_transforms();var feet=[rest[5]*rig.joints[5],rest[6]*rig.joints[6]]
  rig.sample_action("bow",TIMES[index]);rig.update_secondary(1.0/60)
  all_hidden=all_hidden and not rig.weapon_visible
  for link in LINKS:max_joint_error=maxf(max_joint_error,(rig.sampled_pose[link[0]]*link[2]).distance_to(rig.sampled_pose[link[1]]*link[2])*rig.game_scale)
  for foot in 2:max_foot_error=maxf(max_foot_error,(rig.sampled_pose[5+foot]*rig.joints[5+foot]).distance_to(feet[foot])*rig.game_scale)
  rig.scale=Vector2.ONE*.68;rig.position=Vector2(25+index*195,355-199*.68);rig.queue_redraw()
  var label=Label.new();label.text="%0.3f%s"%[TIMES[index]," release" if MOTION.bow_released(TIMES[index]) else ""]
  label.position=Vector2(50+index*195,375);label.add_theme_font_size_override("font_size",16);root.add_child(label)
 check(separate_blade,"cached rig contains a separate blade mesh")
 check(all_hidden,"every bow phase hides only the blade mesh")
 check(not MOTION.bow_released(.129) and MOTION.bow_released(.13),"visual and gameplay release share the exact 0.13 second boundary")
 check(max_joint_error<.05,"bow limbs remain attached within a subpixel tolerance")
 check(max_foot_error<.01,"bow draw and release keep both feet planted")
 if DisplayServer.get_name()!="headless":
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/painted-bow-sequence.png")
 print("PAINTED_BOW_SEQUENCE failures=",failures," joint_error=",max_joint_error," foot_error=",max_foot_error)
 quit(0 if failures.is_empty() else 1)
