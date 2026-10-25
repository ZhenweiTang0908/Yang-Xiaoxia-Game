extends CharacterBody2D
var rig
var elapsed=0.0
var landed_count=0
var reached_platform=false
var airborne_ticks=0
var airborne_locks=0
var landing_time=-10.0
func _ready():
 var shape=CollisionShape2D.new();var box=RectangleShape2D.new();box.size=Vector2(16,43);shape.shape=box;shape.position.y=-21.5;add_child(shape)
 rig=load("res://tests/hero_running_gait.gd").new();add_child(rig)
 rig.scale=Vector2.ONE*rig.game_scale;rig.position=Vector2(-96,-199)*rig.game_scale;rig.posing=true;rig.set_process(false)
func _physics_process(dt):
 var was_floor=is_on_floor();var old_time=elapsed;elapsed+=dt
 velocity.x=225 if elapsed<2.6 else 0
 if old_time<.6 and elapsed>=.6 and was_floor:velocity.y=-520
 velocity.y+=1080*dt;move_and_slide()
 if not was_floor and is_on_floor():
  landed_count+=1;landing_time=elapsed;rig.planted=[null,null]
  if position.y<400:reached_platform=true
 rig.age=elapsed;rig.travel_x=global_position.x;rig.motion_amount=1 if elapsed<2.6 else 0
 rig.contact_enabled=is_on_floor()
 if not is_on_floor():
  airborne_ticks+=1;rig.planted=[null,null]
  rig.air_pose=clampf(1-absf(velocity.y)/600,0,1)
  rig.phase_override=.55
 else:
  rig.air_pose=0
  rig.phase_override=fposmod(lerp_angle(.55*TAU,fposmod(elapsed/.4,1)*TAU,smoothstep(0,.16,elapsed-landing_time))/TAU,1) if elapsed-landing_time<.16 else -1
 rig.sampled_pose=rig.pose_transforms();rig.queue_redraw()
 if not is_on_floor() and (rig.planted[0]!=null or rig.planted[1]!=null):airborne_locks+=1
