extends SceneTree
var failures=[]
const ACTIONS={"hurt":.22,"roll":.18,"dash":.18,"charge":.45}
const LINKS=[[1,0,Vector2(83,145)],[3,0,Vector2(109,146)],[9,0,Vector2(68,108)],[7,9,Vector2(64,125)],[10,0,Vector2(122,108)],[8,10,Vector2(124,127)]]
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures.append(label)
func pose_error(rig,pose):
 var result=0.0
 for link in LINKS:result=maxf(result,(pose[link[0]]*link[2]).distance_to(pose[link[1]]*link[2]))
 return result
func run():
 root.size=Vector2i(1200,600);root.content_scale_size=root.size
 var background=ColorRect.new();background.color=Color("18262c");background.size=Vector2(root.size);root.add_child(background)
 var max_joint_error=0.0;var max_foot_error=0.0;var roll_lift=0.0;var roll_end_error=0.0;var index=0
 for state in ACTIONS:
  var rig=load("res://tests/hero_combo_gait.gd").new();root.add_child(rig);rig.set_process(false);rig.posing=true;rig.attack_index=-1;rig.action_state="";rig.motion_amount=0
  var rest=rig.pose_transforms();var feet=[rest[5]*rig.joints[5],rest[6]*rig.joints[6]]
  var state_joint_error=0.0;var state_foot_error=0.0
  for sample in 31:
   rig.sample_action(state,ACTIONS[state]*sample/30.0)
   state_joint_error=maxf(state_joint_error,pose_error(rig,rig.sampled_pose)*rig.game_scale)
   for foot in 2:
    var current=rig.sampled_pose[5+foot]*rig.joints[5+foot]
    if state=="roll":
     roll_lift=maxf(roll_lift,(feet[foot].y-current.y)*rig.game_scale)
     if sample in [0,30]:roll_end_error=maxf(roll_end_error,current.distance_to(feet[foot])*rig.game_scale)
    else:state_foot_error=maxf(state_foot_error,current.distance_to(feet[foot])*rig.game_scale)
  max_joint_error=maxf(max_joint_error,state_joint_error);max_foot_error=maxf(max_foot_error,state_foot_error)
  print("ACTION_GEOMETRY ",state," joint=",state_joint_error," foot=",state_foot_error)
  rig.sample_action(state,ACTIONS[state]*.5);rig.update_secondary(1.0/60)
  rig.scale=Vector2.ONE*.9;rig.position=Vector2(65+index*285,420-199*.9);rig.queue_redraw()
  var label=Label.new();label.text=state;label.position=Vector2(105+index*285,445);label.add_theme_font_size_override("font_size",20);root.add_child(label)
  index+=1
 check(max_joint_error<.05,"painted action limbs stay attached within a subpixel tolerance")
 check(max_foot_error<.01,"painted action feet retain the grounded baseline")
 check(roll_lift>5 and roll_end_error<.01,"roll tucks both legs and reconnects to the same baseline")
 var max_transition_step=0.0;var completed=0
 for fps in [30,60,120]:
  for state in ACTIONS:
   var rig=load("res://tests/hero_combo_gait.gd").new();root.add_child(rig);rig.set_process(false);rig.attack_index=-1;rig.action_state="";rig.motion_amount=0
   rig.sampled_pose=rig.pose_transforms();rig.begin_transition(.18 if state=="roll" else (.12 if state in ["hurt","dash"] else rig.TRANSITION_DURATION))
   var previous=rig.sampled_pose[0]*Vector2(96,42)
   var state_step=0.0
   var audit_time=.20 if state=="roll" else .14
   for frame in range(1,int(ceil(fps*audit_time))+1):
    rig.sample_action(state,minf(ACTIONS[state],float(frame)/fps));rig.blend_transition(1.0/fps)
    var head=rig.sampled_pose[0]*Vector2(96,42)
    state_step=maxf(state_step,head.distance_to(previous)*rig.game_scale);previous=head
   max_transition_step=maxf(max_transition_step,state_step)
   print("ACTION_TRANSITION fps=",fps," state=",state," max_step=",state_step)
   if rig.transition_pose.is_empty():completed+=1
   rig.queue_free()
 check(completed==12,"all action entries finish their blend at 30, 60, and 120 FPS")
 check(max_transition_step<8,"action entry keeps continuous body motion at every tested frame rate")
 if DisplayServer.get_name()!="headless":
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/painted-action-states.png")
 print("PAINTED_ACTION_STATES failures=",failures," joint_error=",max_joint_error," foot_error=",max_foot_error," roll_lift=",roll_lift," roll_end=",roll_end_error," max_step=",max_transition_step)
 quit(0 if failures.is_empty() else 1)
