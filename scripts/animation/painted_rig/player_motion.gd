extends Node2D
const MOTION=preload("res://scripts/animation/hero_motion.gd")
var actor
var rig
var last_state=""
var last_command=""
var last_facing=0.0
var previous_position=Vector2.INF
var amount=0.0
var age=0.0
var step_age=1.0
var step_variant=0
func _ready():
 rig=load("res://scripts/animation/painted_rig/combo.gd").new();add_child(rig)
 rig.posing=true;rig.set_process(false);rig.attack_index=-1
 hide()
func supports(state):
 return state in ["idle","run","jump","fall","land","slash1","slash2","slash3","hurt","roll","dash","charge","bow"]
func _physics_process(dt):
 if not is_instance_valid(actor):return
 if not actor.game.active():return
 if actor.game.hitstop>0:
  # The damage event can stop time before this child displays the impact pose.
  if actor.hurt_anim>0 and rig.action_state!="hurt":
   rig.sample_action("hurt",.07);rig.transition_pose.clear();modulate=actor.render_tint();rig.queue_redraw()
  elif actor.attack_elapsed>=0 and rig.attack_index==actor.combo-1 and (not is_equal_approx(rig.attack_elapsed,actor.attack_elapsed) or rig.command_id!=actor.special_id):
   rig.sample_attack(actor.combo-1,actor.attack_elapsed,0,actor.special_id);rig.blend_transition(0);rig.queue_redraw()
  return
 var state=get_parent().desired_state()
 if state=="dash":state="roll"
 var command=actor.special_id if state.begins_with("slash") else ""
 var allowed=actor.game.use_skeletal and not actor.form_visual and not actor.is_carried() and supports(state)
 if not allowed:
  last_state="";rig.planted=[null,null];rig.blade_history.clear();return
 var flipped=last_facing!=actor.facing
 var teleported=previous_position.is_finite() and previous_position.distance_to(actor.global_position)>80
 if flipped or teleported:
  rig.planted=[null,null];rig.blade_history.clear();rig.transition_pose.clear()
  rig.secondary.reset()
 if last_state!=state or last_command!=command:
  if last_command!=command:rig.blade_history.clear()
  var blend_time=.18 if state=="roll" else (.12 if state in ["hurt","dash"] else rig.TRANSITION_DURATION)
  rig.begin_transition(blend_time)
  if last_state=="":rig.planted=[null,null];rig.secondary.reset()
 age+=dt;step_age+=dt
 var grounded=actor.is_on_floor()
 var before=rig.planted.duplicate()
 amount=lerpf(amount,clampf(absf(actor.velocity.x)/225,0,1),1-exp(-16*dt))
 rig.age=age;rig.motion_amount=amount;rig.travel_x=actor.global_position.x*actor.facing
 rig.rotation=0;rig.scale=Vector2(actor.facing,1)*rig.game_scale
 rig.position=Vector2(-96*actor.facing,-199)*rig.game_scale
 if command=="spin":
  # Fake a full body turn by squashing through the profile and showing the back.
  var turn=cos(clampf(actor.attack_elapsed/actor.attack_duration,0,1)*TAU)
  if absf(turn)<.35:turn=.35 if turn>=0 else -.35
  rig.scale.x*=turn;rig.position.x=-96*rig.scale.x
 rig.contact_enabled=grounded;rig.grounded_override=grounded
 var air_target=clampf(1-absf(actor.velocity.y)/600,0,1)
 rig.air_pose=0.0 if grounded else lerpf(rig.air_pose,air_target,1-exp(-14*dt))
 rig.phase_override=-1 if grounded else .55
 rig.landing_squash=5*sin(PI*clampf(actor.land_anim/.18,0,1)) if grounded else 0.0
 if not grounded:rig.planted=[null,null]
 sample_actor_pose(state,dt)
 rig.blend_transition(dt);rig.update_secondary(dt)
 if state=="roll":
  var u=clampf((.18-actor.dash_time)/.18,0,1)
  var pivot=Vector2(96,173)
  var base=Transform2D(0,Vector2(-96*actor.facing,-199)*rig.game_scale).scaled_local(Vector2(actor.facing,1)*rig.game_scale)
  rig.transform=base*Transform2D(0,pivot)*Transform2D(TAU*u,Vector2.ZERO)*Transform2D(0,-pivot)
  rig.position.y-=sin(PI*u)*22
 rig.queue_redraw()
 if grounded and state=="run" and step_age>.1:
  for leg in 2:
   if before[leg]==null and rig.planted[leg]!=null:
    actor.game.audio.play("step"+str(step_variant%3),-12);step_variant+=1;step_age=0
    var foot=rig.sampled_pose[5+leg]*rig.joints[5+leg]+Vector2(0,rig.soles[leg])
    actor.game.terrain.presence.step(rig.to_global(foot));break
 modulate=actor.render_tint()
 last_state=state;last_command=command;last_facing=actor.facing;previous_position=actor.global_position

func sample_actor_pose(state,dt):
 if state.begins_with("slash"):
  rig.sample_attack(clampi(actor.combo-1,0,2),actor.attack_elapsed,dt,actor.special_id)
 elif state in ["hurt","roll","dash","charge","bow"]:
  var action_time=0.0
  match state:
   "hurt":action_time=actor.hurt_time if actor.hurt_time>=0 else .22-actor.hurt_anim;rig.hurt_push=actor.hurt_push
   "roll","dash":action_time=.18-actor.dash_time
   "charge":action_time=actor.charge if actor.charge>0 else .35-actor.blast_anim+.18
   "bow":action_time=MOTION.BOW_DURATION-actor.bow_anim
  rig.sample_action(state,maxf(0,action_time))
 else:
  rig.weapon_visible=true;rig.attack_index=-1;rig.action_state="";rig.blade_history.clear();rig.sampled_pose=rig.pose_transforms()
