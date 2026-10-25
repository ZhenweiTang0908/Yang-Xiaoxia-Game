extends RefCounted
# Fixed-step sequence driver. Rendering does not mutate planted-foot state.
const HZ=120.0
var rig
var tick=-1
var previous_speed=0.0
func _init(character):
 rig=character
 rig.contact_enabled=true
 rig.set_process(false)
 rig.planted=[null,null]
 rig.travel_x=0
 rig.sampled_pose=[]
func advance_to(time):
 var target=int(floor(time*HZ+.00001))
 assert(target>=tick,"Timeline must advance monotonically")
 while tick<target:
  tick+=1
  rig.age=tick/HZ
  rig.motion_amount=smoothstep(.3,.65,rig.age)*(1-smoothstep(2.0,2.35,rig.age))
  var speed=225*rig.motion_amount
  if tick>0:rig.travel_x+=(previous_speed+speed)*.5/HZ
  previous_speed=speed
  rig.sampled_pose=rig.pose_transforms()
 rig.queue_redraw()
