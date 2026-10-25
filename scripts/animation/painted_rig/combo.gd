extends "res://scripts/animation/painted_rig/running.gd"
const MOTION=preload("res://scripts/animation/hero_motion.gd")
const ARM_TRACKS=[ [-.15,-1.45,-.35,.18,.12,0.0], [.3,.95,-.50,-1.05,-.4,0.0], [-.2,-1.70,-.50,-1.10,-.40,0.0] ]
const BLADE_TRACKS=[ [.39,-1.4,.0,.50,.18,.39], [.39,1.15,-.2,-.85,-.25,.39], [.39,.95,-.55,-1.20,-.35,.39] ]
const TRAIL_LIFE=.12
const COMMAND_ARMS={"wave":[0.0,-1.3,-.4,-.35,-.2,0.0],"spin":[0.0,-1.5,1.0,3.0,4.6,TAU],"rising":[0.0,.9,-1.7,-2.5,-2.6,-.2]}
var command_id=""
# Hurt recoil direction in rig space: -1 knocked back, +1 pushed forward.
var hurt_push=-1.0
var attack_index=0
var attack_elapsed=0.0
var action_state=""
var action_elapsed=0.0
var blade_history=[]
var grounded_override=true
var transition_pose=[]
var transition_elapsed=0.0
const TRANSITION_DURATION=.10
var transition_duration=TRANSITION_DURATION
func begin_transition(duration=TRANSITION_DURATION):
 transition_pose=sampled_pose.duplicate()
 transition_elapsed=0.0
 transition_duration=duration
func blend_transition(dt):
 if transition_pose.size()!=11 or sampled_pose.size()!=11:return
 transition_elapsed+=dt
 var weight=smoothstep(0,transition_duration,transition_elapsed)
 var destination=sampled_pose.duplicate()
 sampled_pose[0]=transition_pose[0].interpolate_with(destination[0],weight)
 # Keep the destination soles while the torso settles into its next pose.
 # Previously only the torso/arms blended, leaving the hips detached from it.
 fit_legs(sampled_pose,destination)
 # Interpolate joint angles, then rebuild each limb from its parent.
 # Independent transform blending would move the elbow away from the upper arm.
 for link in [[9,0,Vector2(68,108)],[7,9,Vector2(64,125)],[10,0,Vector2(122,108)],[8,10,Vector2(124,127)]]:
  var child=link[0];var parent=link[1]
  var start=(transition_pose[parent].affine_inverse()*transition_pose[child]).get_rotation()
  var finish=(destination[parent].affine_inverse()*destination[child]).get_rotation()
  sampled_pose[child]=sampled_pose[parent]*pivot_rotation(link[2],lerp_angle(start,finish,weight))
 # The newest ribbon sample belongs to the pose displayed after blending.
 # Older samples stay fixed so they describe the sword's actual prior path.
 if not blade_history.is_empty() and blade_history.back().age==0:
  blade_history.back().base=weapon_transform(sampled_pose)*Vector2(74,149)
  blade_history.back().tip=weapon_transform(sampled_pose)*Vector2(120,168)
 if transition_elapsed>=transition_duration:transition_pose.clear()
func fit_legs(pose,destination,targets=[]):
 for leg in 2:
  var thigh=1+leg*2;var calf=thigh+1;var foot=5+leg
  var hip=pose[0]*joints[thigh]
  var ankle=targets[leg] if targets.size()==2 else destination[foot]*joints[foot]
  var upper=joints[thigh].distance_to(joints[calf])
  var lower=joints[calf].distance_to(joints[foot])
  var delta=ankle-hip
  var distance=clampf(delta.length(),absf(upper-lower)+.001,upper+lower-.001)
  var axis=delta.normalized()
  ankle=hip+axis*distance
  var along=(upper*upper-lower*lower+distance*distance)/(2*distance)
  var side=Vector2(-axis.y,axis.x)*sqrt(maxf(0,upper*upper-along*along))
  var old_knee=destination[calf]*joints[calf]
  var a=hip+axis*along+side;var b=hip+axis*along-side
  var knee=a if a.distance_squared_to(old_knee)<b.distance_squared_to(old_knee) else b
  pose[thigh]=align_segment(joints[thigh],joints[calf],hip,knee)
  pose[calf]=align_segment(joints[calf],joints[foot],knee,ankle)
  pose[foot]=destination[foot]
  pose[foot].origin=ankle-pose[foot].basis_xform(joints[foot])
func pose_transforms():
 if attack_index<0 and action_state=="":return super.pose_transforms()
 motion_amount=0;contact_enabled=grounded_override
 var result=super.pose_transforms()
 if action_state!="":return action_pose(result)
 var move=MOTION.ATTACKS[attack_index]
 var chest=-MOTION.track(move.times,move.chest,attack_elapsed)*.95
 var drive=MOTION.track(move.times,[0.0,-2.0,7.0,9.0,5.0,0.0],attack_elapsed)
 result[0].origin+=Vector2(drive,absf(drive)*.35)
 result[0]=result[0]*pivot_rotation(Vector2(96,145),chest)
 command_body(result,move)
 fit_legs(result,result.duplicate())
 var angle=MOTION.track(move.times,COMMAND_ARMS.get(command_id,ARM_TRACKS[attack_index]),attack_elapsed)
 var elbow=MOTION.track(move.times,[.05,.65,.10,.22,.18,0.0],attack_elapsed)
 result[9]=result[0]*pivot_rotation(Vector2(68,108),angle)
 result[7]=result[9]*pivot_rotation(Vector2(64,125),-elbow)
 result[10]=result[0]*pivot_rotation(Vector2(122,108),-chest*2.5)
 result[8]=result[10]*pivot_rotation(Vector2(124,127),.15*sin(PI*clampf(attack_elapsed/move.duration,0,1)))
 if command_id=="":
  # Extend through the strike without jumping into or out of an IK-only pose.
  var extension=smoothstep(move.hit-.09,move.hit,attack_elapsed)*(1-smoothstep(move.hit+.035,move.hit+.15,attack_elapsed))
  var destination=result[0]*Vector2(110,120 if attack_index<2 else 110)
  var extended=result.duplicate()
  fit_arm(extended,9,7,Vector2(68,108),Vector2(64,125),Vector2(74,149),destination)
  var shoulder_start=(result[0].affine_inverse()*result[9]).get_rotation()
  var shoulder_end=(result[0].affine_inverse()*extended[9]).get_rotation()
  var elbow_start=(result[9].affine_inverse()*result[7]).get_rotation()
  var elbow_end=(extended[9].affine_inverse()*extended[7]).get_rotation()
  result[9]=result[0]*pivot_rotation(Vector2(68,108),lerp_angle(shoulder_start,shoulder_end,extension))
  result[7]=result[9]*pivot_rotation(Vector2(64,125),lerp_angle(elbow_start,elbow_end,extension))
 return result
# Command techniques move the whole body, not only the sword arm.
func command_body(result,move):
 var t=attack_elapsed;var hit=move.hit
 match command_id:
  "wave":
   # Crouch and drive forward through the release, then rise out of it.
   var lunge=smoothstep(0,hit,t)*(1-smoothstep(hit+.05,move.duration,t))
   result[0].origin+=Vector2(12,8)*lunge
   result[0]=result[0]*pivot_rotation(Vector2(96,145),.24*lunge)
  "spin":
   var low=sin(PI*clampf(t/move.duration,0,1))
   result[0].origin+=Vector2(0,5)*low
  "rising":
   # Coil low before the launch, then stretch tall and lean back at the top.
   var coil=smoothstep(0,hit*.8,t)*(1-smoothstep(hit*.8,hit,t))
   var stretch=smoothstep(hit*.8,hit+.05,t)*(1-smoothstep(hit+.12,move.duration,t))
   result[0].origin+=Vector2(2*coil,10*coil-7*stretch)
   result[0]=result[0]*pivot_rotation(Vector2(96,145),.20*coil-.32*stretch)
func action_pose(result):
 var body=result[0]
 var front_angle=0.0;var front_elbow=0.0
 var rear_angle=0.0;var rear_elbow=0.0
 match action_state:
  "hurt":
   # Snap to the recoil in 0.06 s, then settle back over the remaining recovery.
   var weight=smoothstep(0,.06,action_elapsed)*(1-smoothstep(.10,.42,action_elapsed))
   var shake=sin(action_elapsed*70)*(1-smoothstep(0,.16,action_elapsed))
   var push=hurt_push
   body.origin+=Vector2(push*7+shake*1.5,6)*weight
   body=body*pivot_rotation(Vector2(96,145),(.32*push)*weight)
   # Arms fling away from the blow; the sword arm stays clear of the face.
   front_angle=(-.95 if push<0 else .55)*weight;front_elbow=.75*weight
   rear_angle=(1.05 if push<0 else -.45)*weight;rear_elbow=-.60*weight
  "roll":
   var u=clampf(action_elapsed/.18,0,1)
   var weight=sin(PI*u)
   body.origin+=Vector2(4,12)*weight
   body=body*pivot_rotation(Vector2(96,145),.65*weight)
   front_angle=.75*weight;front_elbow=1.15*weight
   rear_angle=.48*weight;rear_elbow=.95*weight
  "dash":
   var weight=smoothstep(0,.055,action_elapsed)*(1-smoothstep(.13,.18,action_elapsed))
   body.origin+=Vector2(3,5)*weight
   body=body*pivot_rotation(Vector2(96,145),.28*weight)
   front_angle=-.65*weight;front_elbow=.18*weight
   rear_angle=-.95*weight;rear_elbow=.12*weight
  "charge":
   var weight=smoothstep(0,.12,action_elapsed)
   body.origin+=Vector2(1,4)*weight
   body=body*pivot_rotation(Vector2(96,145),.10*weight)
   front_angle=.35*weight;front_elbow=.40*weight
   rear_angle=.52*weight;rear_elbow=-.72*weight
  "bow":
   var aim=smoothstep(0,.08,action_elapsed)*(1-smoothstep(.18,.32,action_elapsed))
   body.origin.y+=aim
   body=body*pivot_rotation(Vector2(96,145),-.025*aim)
   front_angle=-1.08*aim;front_elbow=.08*aim
   rear_angle=2.15*aim;rear_elbow=-1.18*aim
 result[0]=body
 var destination=result.duplicate()
 if action_state=="roll":
  var u=clampf(action_elapsed/.18,0,1);var tuck=sin(PI*u)
  var targets=[]
  for leg in 2:
   var rest=destination[5+leg]*joints[5+leg]
   var curled=body*Vector2(84 if leg==0 else 108,167)
   targets.append(rest.lerp(curled,tuck))
  fit_legs(result,destination,targets)
 else:fit_legs(result,destination)
 result[9]=body*pivot_rotation(Vector2(68,108),front_angle)
 result[7]=result[9]*pivot_rotation(Vector2(64,125),front_elbow)
 result[10]=body*pivot_rotation(Vector2(122,108),rear_angle)
 result[8]=result[10]*pivot_rotation(Vector2(124,127),rear_elbow)
 if action_state=="bow":
  fit_arm(result,9,7,Vector2(68,108),Vector2(64,125),Vector2(74,149),body*Vector2(101,117))
  var draw_x=157.0
  fit_arm(result,10,8,Vector2(122,108),Vector2(124,127),Vector2(130,148),body*Vector2(draw_x,117))
 return result
func fit_arm(pose,upper,lower,shoulder,elbow,hand,target):
 var root=pose[0]*shoulder
 var a=shoulder.distance_to(elbow);var b=elbow.distance_to(hand)
 var delta=target-root;var distance=clampf(delta.length(),absf(a-b)+.1,a+b-.1)
 var axis=delta.normalized();target=root+axis*distance
 var along=(a*a-b*b+distance*distance)/(2*distance)
 var joint=root+axis*along+axis.orthogonal()*sqrt(maxf(0,a*a-along*along))
 pose[upper]=align_segment(shoulder,elbow,root,joint)
 pose[lower]=align_segment(elbow,hand,joint,target)
func weapon_transform(pose):
 var forearm=pose[7]
 if attack_index<0 or action_state!="" or command_id!="":return forearm
 var move=MOTION.ATTACKS[attack_index]
 var angle=MOTION.track(move.times,BLADE_TRACKS[attack_index],attack_elapsed)
 var rest_angle=Vector2(46,19).angle()
 var wrist=clampf(wrapf(angle-forearm.get_rotation()-rest_angle,-PI,PI),-.85,.85)
 var weight=smoothstep(0,.055,attack_elapsed)*(1-smoothstep(move.duration-.08,move.duration,attack_elapsed))
 return forearm*pivot_rotation(Vector2(74,149),wrist*weight)
func sample_attack(index,time,dt,command=""):
 weapon_visible=true;action_state="";attack_index=index;attack_elapsed=time;command_id=command
 sampled_pose=pose_transforms()
 for item in blade_history:item.age+=dt
 blade_history=blade_history.filter(func(item):return item.age<TRAIL_LIFE)
 var hit=MOTION.ATTACKS[index].hit
 if time>=hit-.055 and time<=hit+.09:
  blade_history.append({"base":weapon_transform(sampled_pose)*Vector2(74,149),"tip":weapon_transform(sampled_pose)*Vector2(120,168),"age":0.0,"attack":index})
 queue_redraw()
func sample_action(state,time):
 weapon_visible=state not in ["bow","roll"];attack_index=-1;action_state=state;action_elapsed=time;blade_history.clear()
 sampled_pose=pose_transforms();queue_redraw()
func _draw():
 draw_blade_trail()
 super._draw()
 if attack_index>=0 and action_state=="" and sampled_pose.size()==11:
  var hit=MOTION.ATTACKS[attack_index].hit
  var weight=1-smoothstep(hit+.065,hit+.14,attack_elapsed)
  if attack_elapsed>=hit-.04 and weight>0:
   var base=weapon_transform(sampled_pose)*Vector2(74,149);var tip=weapon_transform(sampled_pose)*Vector2(120,168)
   draw_line(base.lerp(tip,.22),tip,Color(.98,.82,.43,.65*weight),5,true)
   draw_line(base.lerp(tip,.3),tip,Color(1.0,.98,.85,.95*weight),2,true)
 if action_state=="charge" and sampled_pose.size()==11:
  var base=weapon_transform(sampled_pose)*Vector2(74,149);var tip=weapon_transform(sampled_pose)*Vector2(120,168)
  var direction=(tip-base).normalized()
  for i in 2:
   var u=fposmod(action_elapsed*.9+i*.43,1.0)
   var p=base.lerp(tip,u);var radius=2.5+sin(u*PI)*1.5
   var color=Color(.67,.88,.79,.34+sin(u*PI)*.38)
   draw_colored_polygon(PackedVector2Array([p+Vector2(0,-radius),p+Vector2(radius,0),p+Vector2(0,radius),p+Vector2(-radius,0)]),color)
   draw_line(p-direction*5,p+direction*2,Color(.88,.97,.90,color.a*.7),1)
 if action_state=="bow" and sampled_pose.size()==11:
  var painted_hand=sampled_pose[8]*Vector2(130,148)
  var grip=painted_hand
  var drawing_hand=weapon_transform(sampled_pose)*Vector2(74,149)
  var top=grip+Vector2(-3,-42);var bottom=grip+Vector2(-3,42)
  var bow=PackedVector2Array([top,grip+Vector2(10,-24),grip+Vector2(14,0),grip+Vector2(10,24),bottom])
  draw_polyline(bow,Color("594331"),4.0,true)
  draw_polyline(bow,Color("c99d61"),2.0,true)
  draw_line(painted_hand,grip,Color("57352c"),5.0)
  draw_line(painted_hand,grip,Color("d88e68"),3.0)
  draw_line(grip+Vector2(10,-5),grip+Vector2(10,5),Color("e0c58c"),2.4)
  var release=MOTION.bow_released(action_elapsed)
  var vibration=sin((action_elapsed-MOTION.BOW_RELEASE)*85)*2*(1-smoothstep(MOTION.BOW_RELEASE,.23,action_elapsed)) if release else 0.0
  var string_center=grip+Vector2(vibration,0) if release else drawing_hand
  draw_polyline(PackedVector2Array([top,string_center,bottom]),Color(.84,.88,.78,.78),.8)
  if action_elapsed>=.035 and not release:
   var arrow_tip=grip+Vector2(48,0)
   draw_line(drawing_hand,arrow_tip,Color("9ccfc0"),2.0)
   draw_polyline(PackedVector2Array([arrow_tip+Vector2(-7,-4),arrow_tip,arrow_tip+Vector2(-7,4)]),Color("e2ead8"),1.5)
func draw_blade_trail():
 for i in range(1,blade_history.size()):
  var a=blade_history[i-1];var b=blade_history[i]
  if a.attack!=b.attack:continue
  var fade=1-b.age/TRAIL_LIFE
  var va=a.tip-a.base;var vb=b.tip-b.base
  var turn=wrapf(vb.angle()-va.angle(),-PI,PI)
  var steps=maxi(1,int(ceil(absf(turn)/.12)))
  for section in steps:
   var u=float(section)/steps;var v=float(section+1)/steps
   var base_a=a.base.lerp(b.base,u);var base_b=a.base.lerp(b.base,v)
   var blade_a=Vector2.from_angle(va.angle()+turn*u)*lerpf(va.length(),vb.length(),u)
   var blade_b=Vector2.from_angle(va.angle()+turn*v)*lerpf(va.length(),vb.length(),v)
   var points=PackedVector2Array([base_a+blade_a*.35,base_a+blade_a,base_b+blade_b,base_b+blade_b*.35])
   # Consecutive samples can be identical at an animation boundary. Godot cannot
   # triangulate that zero-area quad, so omit the invisible trail segment.
   if not Geometry2D.triangulate_polygon(points).is_empty():
    draw_colored_polygon(points,Color(.98,.77,.36,.48*fade))
    draw_line(base_a+blade_a,base_b+blade_b,Color(1.0,.96,.76,.85*fade),2,true)
