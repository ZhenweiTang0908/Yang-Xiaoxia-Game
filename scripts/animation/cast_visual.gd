extends Node2D
const SHEEP=preload("res://scripts/animation/sheep_motion.gd")
const MOTION=preload("res://scripts/animation/hero_motion.gd")
var actor
var source_art
var species="niu"
var viewport
var model
var camera
var clock=0.0
var phase=0.0
var state="idle"
var age=0.0
var pose={}
var previous={}
var facing=1.0
var preview=false
var preview_state="idle"
var preview_speed=120.0
var preview_attack=.1
var height=66.0
var back_offset=0.0
var eye_history=[]
var last_eye=Vector2.ZERO
var last_facing=1.0
const EYE_LIFETIME=.12
const EYE_LENGTH=13.0
func _ready():
 if not preview:hide()
 viewport=SubViewport.new();viewport.size=Vector2i(224,144) if species=="sheep" else (Vector2i(128,144) if species!="bull" else Vector2i(192,128));viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
 var world=Node3D.new();viewport.add_child(world)
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_CLEAR_COLOR;env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("a5b4b9");env.environment.ambient_light_energy=1.1;world.add_child(env)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-25,-35,0);light.light_energy=1.4;world.add_child(light)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.0 if species!="bull" else 2.15;camera.position=Vector3(0,.70 if species!="bull" else .43,6);world.add_child(camera)
 model=load("res://scripts/animation/cast_model.gd").new();model.species=species;model.source_art=source_art;world.add_child(model)
 pose=sample("idle",0,0,0);previous=pose.duplicate(true);model.apply_pose(pose)
func active_state():
 if preview:return preview_state
 if species=="bull":
  var c=actor.demon_controller
  if c.rush_left>0:return "dash"
  if c.lock_left>0 or c.rush_windup>0:return "charge"
  return "run" if absf(actor.velocity.x)>15 else "idle"
 if species=="niu":
  if actor.summon.phase!="active":return "enter" if actor.summon.phase=="entering" else "leave"
  if actor.attack_anim>0:return "cast"
 elif species=="sheep":
  if actor.hurt_anim>0:return "hurt"
  if actor.dash_time>0:return "dash"
  if actor.charge>0:return "charge"
  if actor.blast_anim>0:return "release"
  if actor.attack_elapsed>=0:return "slash"+str(actor.combo)
  if actor.bow_anim>0:return "cast"
 else:
  if actor.dead:return "leave"
  if actor.hurt>0:return "hurt"
  if actor.windup>0:return "charge"
  if actor.strike>0:return "slash1"
 if species=="sheep" and actor.is_carried():return "ride"
 if not actor.is_on_floor() and species not in ["spirit","bat"]:return "jump" if actor.velocity.y<0 else "fall"
 return "run" if absf(actor.velocity.x)>10 else "idle"
func sample(action,t,gait,speed):
 if species=="sheep":return SHEEP.sample(action,t,gait,speed)
 if species=="bull":
  var p={"offset":Vector3(0,(-.06+sin(gait*2)*.012)*speed,0),"head":Vector3(0,0,-.16 if action in ["dash","charge"] else sin(t*2)*.025),"tail":Vector3(0,0,sin(t*3-.4)*.12)}
  for side in ["far","near"]:
   for end in ["front","rear"]:
    var key=side+"_"+end;var a=gait+(PI if side=="far" else 0)+(PI if end=="rear" else 0)
    var cycle=fposmod(a,TAU)/TAU
    var x=lerpf(.23,-.23,cycle/.55) if cycle<.55 else lerpf(-.23,.23,smoothstep(.55,1,cycle))
    var lift=0.0 if cycle<.55 else sin((cycle-.55)/.45*PI)*.11
    var delta=Vector2(x*speed,-.37-p.offset.y+lift*speed)
    var distance=clampf(delta.length(),.04,.399)
    var bend=acos(distance/.4);var upper=atan2(delta.x,-delta.y)+bend
    p[key]=Vector3(0,0,upper);p[key+"_lower"]=Vector3(0,0,-2*bend)
  return p
 var base=action if action not in ["cast","enter","leave"] else "idle"
 var p=MOTION.sample(base,t,gait,speed)
 p.cape=Vector3(0,0,sin(gait-.6)*.035*speed+sin(clock*2.5-.6)*.025+speed*.12)
 if action=="cast":
  var times=[0.0,.08,.14,.20,.30,.42]
  p.near_arm.z=MOTION.track(times,[.3,-.35,1.45,1.65,1.2,.3],t);p.near_forearm.z=MOTION.track(times,[1.1,1.9,.12,.08,.55,1.1],t);p.near_hand.z=-.1
  p.chest.z=MOTION.track(times,[0.0,.10,-.12,-.16,-.07,0.0],t)
 if action=="ride":
  p.near_thigh=Vector3(0,0,1.1);p.far_thigh=Vector3(0,0,.85);p.near_shin=Vector3(0,0,-1.5);p.far_shin=Vector3(0,0,-1.6);p.near_arm.z=.8;p.near_forearm.z=.45
 if action=="enter":p.offset.y-=.1*(1-smoothstep(0,.6,t));p.far_arm.z=.35
 if action=="leave":p.near_arm.z=lerpf(.3,1.0,smoothstep(0,.35,t));p.near_forearm.z=1.3
 if species=="bat":
  p.near_arm.z=.8+sin(clock*9)*.7;p.far_arm.z=.8+sin(clock*9+.25)*.7;p.offset.y+=sin(clock*4)*.025
 return p
func _process(dt):
 if not preview:
  var enabled=actor.game.use_skeletal
  if species=="sheep":enabled=enabled and actor.form_visual and not actor.is_carried()
  if species=="niu":enabled=enabled and not actor.demon
  if species not in ["niu","sheep","bull"]:enabled=enabled and absf(actor.position.x-actor.game.player.position.x)<800
  visible=enabled;source_art.self_modulate.a=0 if enabled else 1
  viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED
  if not enabled:eye_history.clear();state="idle";age=0;return
  if not actor.game.active():return
  # Sample the new impact pose once before freezing it for hitstop.
  if actor.game.hitstop>0:dt=0
  facing=actor.facing
  scale=source_art.scale if species=="niu" else Vector2.ONE
 clock+=dt
 var next=active_state()
 if next!=state:previous=pose.duplicate(true);state=next;age=0
 age+=dt
 var speed=preview_speed if preview else absf(actor.velocity.x)
 var amount=clampf(speed/200.0,0,1);phase+=dt*TAU*speed/(height*1.95 if species!="bull" else height*.65)
 var t=age
 if not preview:
  if species=="niu" and state=="cast":t=.42-actor.attack_anim
  elif species=="sheep" and state.begins_with("slash"):t=actor.attack_elapsed
  elif species=="sheep" and state=="cast":t=MOTION.BOW_DURATION-actor.bow_anim
  elif species=="sheep" and state=="release":t=.35-actor.blast_anim
  elif state=="slash1" and species not in ["niu","sheep","bull"]:t=.12+(.45-actor.strike)*.55
 elif state=="cast" or state.begins_with("slash"):t=fposmod(age,.9)
 var target=sample(state,t,phase,amount);var blend=smoothstep(0,MOTION.ATTACKS[clampi(int(state.right(1))-1,0,2)].hit*.55,t) if state.begins_with("slash") and species=="sheep" else smoothstep(0,.12,age)
 pose={}
 for key in target:pose[key]=previous.get(key,Vector3.ZERO).lerp(target[key],blend)
 if species=="sheep" and not preview and actor.is_carried():
  pose.near_thigh=Vector3(0,0,1.1);pose.far_thigh=Vector3(0,0,.85)
  pose.near_shin=Vector3(0,0,-1.5);pose.far_shin=Vector3(0,0,-1.6)
  pose.near_foot=Vector3(0,0,.4);pose.far_foot=Vector3(0,0,.5)
 model.apply_pose(pose)
 if model.card:model.card.visible=species=="niu" and (state!="cast" or t<.14 or t>.34)
 back_offset=39+project_model(Vector3(0,.725+pose.get("offset",Vector3.ZERO).y,0)).y if species=="bull" else 0
 if species=="bull":update_eye(dt,speed)
 queue_redraw()
func render_size():
 if species=="sheep":return Vector2(height*1.64*224.0/144.0,height*1.64)
 return Vector2(height*1.46,height*1.64) if species!="bull" else Vector2(height*2.4,height*1.6)
func project_model(point):
 return (camera.unproject_position(point)-camera.unproject_position(Vector3.ZERO))/Vector2(viewport.size)*render_size()
func hand_position():
 var point=model.global_transform*model.skeleton.get_bone_global_pose(model.bones.near_hand)*Vector3(0,-.05,0)
 return to_global(project_model(point)*Vector2(actor.facing,1))
func eye_point():
 var point=model.global_transform*model.skeleton.get_bone_global_pose(model.bones.head)*Vector3(.125,.035,.175)
 return project_model(point)*Vector2(facing,1)
func update_eye(dt,speed):
 var at=to_global(eye_point())
 if last_facing!=facing or (last_eye!=Vector2.ZERO and last_eye.distance_to(at)>48):eye_history.clear()
 last_facing=facing;last_eye=at
 for point in eye_history:point.age+=dt
 eye_history=eye_history.filter(func(point):return point.age<EYE_LIFETIME and point.at.distance_to(at)<=EYE_LENGTH)
 if speed>15:
  eye_history.append({"at":at,"age":0.0})
  if eye_history.size()>18:eye_history.pop_front()
func draw_eye(alpha):
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 var at=eye_point();var previous_point=at
 for i in range(eye_history.size()-1,-1,-1):
  var sample=eye_history[i];var point=to_local(sample.at)
  if preview:point-=Vector2(facing*minf(EYE_LENGTH,sample.age*preview_speed),0)
  var fade=pow(1-sample.age/EYE_LIFETIME,1.5)*alpha
  draw_line(previous_point,point,Color(1,.015,.045,fade*.18),3.5)
  draw_line(previous_point,point,Color(1,.07,.10,fade*.85),1.0)
  previous_point=point
 draw_circle(at,2.7,Color(1,.01,.02,alpha*.12))
 draw_line(at-Vector2(1.1,0),at+Vector2(.9,-.25),Color(1,.12,.16,alpha),1.1)
 draw_rect(Rect2(at-Vector2(.35,.35),Vector2(.7,.7)),Color(1,.65,.50,alpha))
func _draw():
 if not viewport:return
 var size=render_size()
 var anchor=-camera.unproject_position(Vector3.ZERO)/Vector2(viewport.size)*size
 if state=="ride" or (species=="sheep" and not preview and actor.is_carried()):anchor-=project_model(model.skeleton.get_bone_global_pose(model.bones.hips).origin)
 var tint=Color.WHITE if preview else source_art.tint
 draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
 draw_texture_rect(viewport.get_texture(),Rect2(anchor,size),false,tint)
 if species=="bull":draw_eye(tint.a)
 if species=="sheep" and state in ["cast","charge","release"]:
  var hand=model.skeleton.get_bone_global_pose(model.bones.far_hand).origin
  var at=project_model(hand)
  var pulse=.65+.2*sin(clock*9)
  draw_circle(at,5,Color(.52,.83,.65,.12*pulse))
  draw_circle(at,2.0,Color(.75,.96,.77,.65*pulse))
