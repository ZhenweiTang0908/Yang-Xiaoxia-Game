extends RefCounted
const HZ=120.0
var rig
var tick=-1
var height=0.0
var events=[]
var fired={}
var was_airborne=false
var last_step=-10.0
var hits={}
var previous_blade={}
var previous_attack=-1
const TARGET_TRAVEL=438.75
func _init(character):
 rig=character;rig.set_process(false);rig.planted=[null,null];rig.travel_x=0;rig.attack_index=-1
func advance_to(time):
 while tick<int(floor(time*HZ+.00001)):
  tick+=1;var t=tick/HZ;rig.age=t
  rig.attack_index=-1
  var amount=smoothstep(.1,.35,t)*(1-smoothstep(2.0,2.35,t))
  rig.motion_amount=amount
  if tick>0:rig.travel_x+=225*amount/HZ
  var jump_t=t-.6;var flight=1040.0/1080.0
  var flying=jump_t>=0 and jump_t<flight
  var previous_contacts=rig.planted.duplicate()
  var landed=was_airborne and not flying
  if flying and not was_airborne:events.append({"time":t,"path":"res://assets/audio/jump.wav"})
  if landed:events.append({"time":t,"path":"res://assets/audio/land.wav"})
  was_airborne=flying
  height=(-520*jump_t+540*jump_t*jump_t)/rig.game_scale if flying else 0
  rig.air_pose=smoothstep(0,.12,jump_t)*(1-smoothstep(flight-.16,flight,jump_t)) if flying else 0
  rig.phase_override=.5+jump_t*.15 if flying else -1
  rig.contact_enabled=not flying
  if flying:rig.planted=[null,null]
  elif jump_t>=flight and jump_t<flight+.16:
   rig.phase_override=fposmod(lerp_angle((.5+flight*.15)*TAU,fposmod(t/.4,1)*TAU,smoothstep(0,.16,jump_t-flight))/TAU,1)
  var attack_time=t-2.5;var selected=-1
  for index in 3:
   var move=rig.MOTION.ATTACKS[index]
   if attack_time>=0 and attack_time<=move.duration:
    selected=index;break
   attack_time-=move.duration
  if selected!=previous_attack:rig.begin_transition()
  if selected>=0:
   rig.sample_attack(selected,attack_time,1/HZ)
   rig.blend_transition(1/HZ)
   var blade={"base":rig.sampled_pose[7]*Vector2(74,149),"tip":rig.sampled_pose[7]*Vector2(120,168)}
   var hit_time=rig.MOTION.ATTACKS[selected].hit
   if previous_attack==selected and not hits.has(selected) and attack_time>=hit_time-.04 and attack_time<=hit_time+.045:
    var center=Vector2(134+(TARGET_TRAVEL-rig.travel_x)/rig.game_scale,135)
    if preload("res://tests/blade_sweep.gd").circle_hit(previous_blade,blade,center,18):
     hits[selected]=true;events.append({"time":t,"path":"res://assets/audio/melee_stone%d_0.wav"%(selected+1),"damage":24+selected*6})
   previous_blade=blade;previous_attack=selected
   if attack_time>=rig.MOTION.ATTACKS[selected].hit-.045 and not fired.has(selected):
    fired[selected]=true;events.append({"time":t,"path":"res://assets/audio/melee_swing%d_0.wav"%(selected+1)})
  else:
   rig.blade_history.clear();rig.sampled_pose=rig.pose_transforms();rig.blend_transition(1/HZ)
   previous_attack=-1
  rig.update_secondary(1/HZ)
  if not flying and not landed and amount>.15 and t-last_step>.1:
   for leg in 2:
    if previous_contacts[leg]==null and rig.planted[leg]!=null:
     events.append({"time":t,"path":"res://assets/audio/step%d.wav"%(tick%3)});last_step=t;break
 rig.queue_redraw()
