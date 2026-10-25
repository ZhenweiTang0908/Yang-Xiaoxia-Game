extends CharacterBody2D
var rig
var target
var clock=0.0
var facing=1
var attack=-1
var attack_time=0.0
var queued=false
var struck=false
var swung=false
var previous_blade={}
var coyote=0.0
var buffered_jump=0.0
var amount=0.0
var jump_count=0
var landing_count=0
var contact_fx
var landed_at=-10.0
func sound(path):
 var player=AudioStreamPlayer.new();player.stream=load(path);player.volume_db=-7;add_child(player);player.finished.connect(player.queue_free);player.play()
func stop_sounds():
 for child in get_children():
  if child is AudioStreamPlayer:
   child.stop();child.stream=null
func _ready():
 var shape=CollisionShape2D.new();var box=RectangleShape2D.new();box.size=Vector2(16,43);shape.shape=box;shape.position.y=-21.5;add_child(shape)
 rig=load("res://tests/hero_combo_gait.gd").new();add_child(rig);rig.posing=true;rig.set_process(false);rig.attack_index=-1
 rig.z_index=2
 contact_fx=load("res://tests/motion_contact_fx.gd").new();contact_fx.actor=self;add_child(contact_fx)
func begin_attack(index):
 rig.begin_transition()
 attack=index;attack_time=0;queued=false;struck=false;swung=false;previous_blade={}
func _physics_process(dt):
 clock+=dt
 var floor_before=is_on_floor()
 coyote=.12 if floor_before else maxf(0,coyote-dt)
 buffered_jump=maxf(0,buffered_jump-dt)
 if Input.is_action_just_pressed("jump"):buffered_jump=.15
 if Input.is_action_just_pressed("attack"):
  if attack<0:begin_attack(0)
  else:queued=true
 var direction=Input.get_axis("left","right")
 if direction!=0 and attack<0 and int(signf(direction))!=facing:
  facing=int(signf(direction));rig.planted=[null,null]
 velocity.x=direction*225 if attack<0 else 0
 if buffered_jump>0 and coyote>0:
  velocity.y=-520;buffered_jump=0;coyote=0;jump_count+=1;sound("res://assets/audio/jump.wav")
 if Input.is_action_just_released("jump") and velocity.y< -220:velocity.y=-220
 velocity.y+=1080*dt
 var impact_speed=velocity.y
 move_and_slide()
 if not floor_before and is_on_floor():
  landing_count+=1;rig.planted=[null,null];sound("res://assets/audio/land.wav")
  if impact_speed>=100:landed_at=clock;contact_fx.landed(impact_speed)
 if position.y>750:position=Vector2(80,450);velocity=Vector2.ZERO;rig.planted=[null,null]
 amount=lerpf(amount,absf(velocity.x)/225,1-exp(-dt*16))
 rig.age=clock;rig.travel_x=global_position.x*facing;rig.motion_amount=amount
 rig.scale=Vector2(facing,1)*rig.game_scale
 rig.position=Vector2(-96*facing,-199)*rig.game_scale
 rig.contact_enabled=is_on_floor();rig.air_pose=0 if is_on_floor() else clampf(1-absf(velocity.y)/600,0,1)
 rig.grounded_override=is_on_floor()
 var settle=clock-landed_at
 rig.landing_squash=5*smoothstep(0,.035,settle)*(1-smoothstep(.035,.18,settle)) if is_on_floor() and settle<.18 else 0
 rig.phase_override=-1 if is_on_floor() else .55
 if not is_on_floor():rig.planted=[null,null]
 if attack>=0:
  var move=rig.MOTION.ATTACKS[attack]
  attack_time+=dt;rig.sample_attack(attack,attack_time,dt)
  rig.blend_transition(dt)
  if not swung and attack_time>=move.hit-.045:swung=true;sound("res://assets/audio/melee_swing%d_0.wav"%(attack+1))
  var blade={"base":rig.sampled_pose[7]*Vector2(74,149),"tip":rig.sampled_pose[7]*Vector2(120,168)}
  if target and not struck and not previous_blade.is_empty() and attack_time>=move.hit-.04 and attack_time<=move.hit+.045:
   if preload("res://tests/blade_sweep.gd").circle_hit(previous_blade,blade,rig.to_local(target.global_position),18):
    struck=true;target.strike(24+attack*6);sound("res://assets/audio/melee_stone%d_0.wav"%(attack+1))
  previous_blade=blade
  if attack_time>=move.duration:
   if queued and attack<2:begin_attack(attack+1)
   else:rig.begin_transition();attack=-1;rig.blade_history.clear()
 else:
  rig.attack_index=-1;rig.sampled_pose=rig.pose_transforms();rig.blend_transition(dt);rig.queue_redraw()
 if target:target.step(dt)
 rig.update_secondary(dt)
 contact_fx.step(dt)
