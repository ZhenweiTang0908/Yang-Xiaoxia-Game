extends Node2D
# Complete painted silhouettes keep the face, neck and collar in one authored image.
const MOTION=preload("res://scripts/animation/hero_motion.gd")
var blade_trail=[]
var actor
var art
var heavy
var preview=false
var playback_rate=1.0
var preview_state="idle"
var preview_time=0.0
var preview_speed=225.0
var preview_ground=true
var state="idle"
var state_age=0.0
var clock=0.0
var body_height=52.8
var facing=1.0
var alpha=1.0
var support_foot=-1
var step_variant=0
var skin
var heavy_skin
var current_targets=PackedVector2Array()
var entry_targets=PackedVector2Array()
var run_phase=0.0
var cloth_anchor=Vector2.INF
var painted_motion
func _ready():
 art=load("res://scripts/actors/atlas_actor.gd").new();add_child(art)
 art.configure("res://assets/art/v2/hero.png",8,5,body_height)
 heavy=load("res://scripts/actors/atlas_actor.gd").new();add_child(heavy)
 heavy.configure("res://assets/art/v2/uppercut.png",4,2,body_height);heavy.hide()
 skin=load("res://scripts/animation/hero_2d_skin.gd").new();skin.source=art;add_child(skin)
 heavy_skin=load("res://scripts/animation/hero_2d_skin.gd").new();heavy_skin.source=heavy;heavy_skin.is_heavy=true;add_child(heavy_skin)
 if not preview:
  painted_motion=load("res://scripts/animation/painted_rig/player_motion.gd").new();painted_motion.actor=actor;add_child(painted_motion)
func desired_state():
 if preview:return preview_state
 if actor.hurt_anim>0:return "hurt"
 if actor.dash_time>0:return "dash" if actor.sprinting else "roll"
 if actor.charge>0 or actor.blast_anim>0:return "charge"
 if actor.bow_anim>0:return "bow"
 if actor.attack_elapsed>=0:return "slash"+str(actor.combo)
 if actor.hurt_time>=0:return "hurt"
 if not actor.is_on_floor():return "jump" if actor.velocity.y<0 else "fall"
 if actor.land_anim>0:return "land"
 return "run" if absf(actor.velocity.x)>12 else "idle"
func attack_frame(t,index):
 var hit=MOTION.ATTACKS[index].hit;var duration=MOTION.ATTACKS[index].duration
 # Deliberate anticipation, quick strike at the damage event, longer recovery.
 var keys=[0.0,hit*.25,hit*.50,hit*.78,hit,hit+.045,lerpf(hit,duration,.64),duration-.035]
 var result=0
 for i in keys.size():
  if t>=keys[i]:result=i
 return result
func _process(dt):
 if not preview:
  visible=is_instance_valid(actor) and actor.game.use_skeletal and not actor.form_visual and not actor.is_carried()
  if not visible:blade_trail.clear();cloth_anchor=Vector2.INF;support_foot=-1;return
  # Render ownership must not depend on a player physics tick (initialization,
  # paused previews, and screenshots may render before that tick ever runs).
  actor.art.hide();actor.heavy_art.hide()
  if not actor.game.active() or actor.game.hitstop>0:return
  facing=actor.facing;alpha=.65 if actor.invincible>0 and int(actor.anim_clock*20)%2==0 else 1
 else:dt*=playback_rate
 clock+=dt
 var desired=desired_state()
 if painted_motion:
  painted_motion.visible=painted_motion.supports(desired)
  if painted_motion.visible:
   art.hide();heavy.hide();skin.hide();heavy_skin.hide();blade_trail.clear();support_foot=-1
   state=desired;entry_targets.clear();queue_redraw();return
 if state!=desired:
  entry_targets=current_targets.duplicate();state=desired;state_age=0
 state_age+=dt
 var t=preview_time if preview else state_age
 var frames=[0];var keys=[0.0]
 match state:
  "run":
   var speed=preview_speed if preview else absf(actor.velocity.x)
   run_phase+=dt*clampf(speed/225.0,.35,1.5)
   # Frames 8 and 9 contain a second sword in the painted source.
   # Group the three front-foot and three rear-foot support poses into two steps.
   t=fposmod(run_phase,.56);frames=[10,13,14,11,12,15,10];keys=[0.0,.56/6,.56/3,.28,.56*2/3,.56*5/6,.56]
  "jump":frames=[32,33];keys=[0.0,.19]
  "fall":frames=[33,34];keys=[0.0,.25]
  "land":frames=[35,35,0];keys=[0.0,.045,.18]
  "hurt":frames=[36]
  "dash","roll":frames=[37]
  "charge":frames=[24]
  "bow":frames=[38,39];keys=[0.0,MOTION.BOW_RELEASE]
  "slash1","slash2","slash3":
   var index=int(state.right(1))-1
   t=preview_time if preview else actor.attack_elapsed
   var hit=MOTION.ATTACKS[index].hit;var duration=MOTION.ATTACKS[index].duration
   keys=[0.0,hit*.25,hit*.50,hit*.78,hit,hit+.045,lerpf(hit,duration,.64),duration-.001]
   frames=[]
   for i in 8:frames.append(i+(16+index*8 if index<2 else 0))
 var use_heavy=state=="slash3"
 art.hide();heavy.hide();skin.visible=not use_heavy;heavy_skin.visible=use_heavy
 var drawing=heavy_skin if use_heavy else skin
 var a=0
 for i in keys.size():
  if t>=keys[i]:a=i
 var b=mini(a+1,frames.size()-1)
 var u=0.0 if a==b else smoothstep(keys[a],keys[b],t)
 var first=drawing.anchors(frames[a]);var second=drawing.anchors(frames[b])
 current_targets=PackedVector2Array()
 for i in first.size():
  var target=first[i].lerp(second[i],u)
  if state=="idle":
   if i==0:target.y+=sin(clock*2.6)*.18
   elif i in [2,3]:target.y+=sin(clock*2.6-.3)*.08
  if entry_targets.size()==first.size():target=entry_targets[i].lerp(target,smoothstep(0,.035 if state=="land" else .09,state_age))
  current_targets.append(target)
 if state=="land":
  current_targets[3].y-=4.5*(1-smoothstep(.06,.16,t))
 # Crossfading two different support feet otherwise lifts both above the floor.
 # Translate the whole pose: never stretch the neck or lengthen a planted leg.
 if state=="run" and (preview_ground if preview else actor.is_on_floor()):
  var floor_shift=-maxf(current_targets[4].y,current_targets[5].y)
  for i in current_targets.size():current_targets[i].y+=floor_shift
 drawing.facing=facing;drawing.tint=Color(1,1,1,alpha)
 if not cloth_anchor.is_finite():cloth_anchor=current_targets[1]
 cloth_anchor=cloth_anchor.lerp(current_targets[1],1-exp(-dt*22))
 drawing.cloth_delta=((cloth_anchor-current_targets[1])*.35).limit_length(.4)
 drawing.render_pose(frames[a if u<.5 else b],current_targets)
 for sample in blade_trail:sample.age+=dt
 blade_trail=blade_trail.filter(func(sample):return sample.age<.075)
 if state.begins_with("slash"):
  var hit=MOTION.ATTACKS[int(state.right(1))-1].hit
  if absf(t-hit)<.055:
   blade_trail.append({"tip":to_global(drawing.weapon_socket(true)*Vector2(facing,1)),"base":to_global(drawing.weapon_socket(false)*Vector2(facing,1)),"age":0.0,"attack":state,"facing":facing})
 queue_redraw()
 var foot=consume_foot_contact(state=="run" and (preview_ground if preview else actor.is_on_floor()))
 if foot>=0 and not preview:
  actor.game.audio.play("step"+str(step_variant%3),-12);step_variant+=1
  actor.game.terrain.presence.step(to_global(current_targets[foot]*Vector2(facing,1)))

func consume_foot_contact(grounded):
 if not grounded or current_targets.size()<6:
  support_foot=-1;return -1
 var candidate=4 if current_targets[4].y>=current_targets[5].y else 5
 # Hysteresis prevents duplicate contacts while both soles share the floor.
 if support_foot>=0 and current_targets[candidate].y-current_targets[support_foot].y<.25:return -1
 if candidate==support_foot:return -1
 support_foot=candidate
 return candidate

func trail_sections(a,b):
 if a.attack!=b.attack or a.facing!=b.facing:return []
 var av=a.tip-a.base;var bv=b.tip-b.base
 var turn=wrapf(bv.angle()-av.angle(),-PI,PI)
 # A discontinuous painted pose cannot establish the missing swing direction.
 if absf(turn)>PI*.65 or a.base.distance_to(b.base)>18:return []
 var count=maxi(1,int(ceil(absf(turn)/.15)))
 var sections=[]
 for j in count+1:
  var u=float(j)/count
  var hand=a.base.lerp(b.base,u)
  var blade=Vector2.from_angle(av.angle()+turn*u)*lerpf(av.length(),bv.length(),u)
  sections.append([hand+blade*.68,hand+blade])
 return sections

func _draw():
 for i in range(1,blade_trail.size()):
  var a=blade_trail[i-1];var b=blade_trail[i]
  var at=to_local(a.tip);var bt=to_local(b.tip)
  if at.distance_to(bt)<.3 or at.distance_to(bt)>55:continue
  var fade=(1-a.age/.075)*.28
  var sections=trail_sections(a,b)
  for j in range(1,sections.size()):
   var inner_a=to_local(sections[j-1][0]);var outer_a=to_local(sections[j-1][1])
   var inner_b=to_local(sections[j][0]);var outer_b=to_local(sections[j][1])
   draw_colored_polygon(PackedVector2Array([inner_a,outer_a,outer_b]),Color(.67,.87,.83,fade))
   draw_colored_polygon(PackedVector2Array([inner_a,outer_b,inner_b]),Color(.67,.87,.83,fade))
   draw_line(outer_a,outer_b,Color(.90,.98,.93,fade*1.7),.6)
