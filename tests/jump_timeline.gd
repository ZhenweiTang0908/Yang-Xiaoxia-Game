extends RefCounted
const HZ=120.0
const TAKEOFF=.6
const FLIGHT=1040.0/1080.0
var rig
var tick=-1
var height=0.0
func _init(character):
 rig=character;rig.set_process(false);rig.planted=[null,null];rig.travel_x=0
func advance_to(time):
 var target=int(floor(time*HZ+.00001))
 while tick<target:
  tick+=1;var t=tick/HZ
  rig.age=t;rig.motion_amount=1
  if tick>0:rig.travel_x+=225/HZ
  var air_time=t-TAKEOFF
  var airborne=air_time>=0 and air_time<FLIGHT
  if airborne:
   rig.contact_enabled=false;rig.planted=[null,null]
   height=(-520*air_time+540*air_time*air_time)/rig.game_scale
   rig.air_pose=smoothstep(0,.12,air_time)*(1-smoothstep(FLIGHT-.16,FLIGHT,air_time))
   rig.phase_override=.5+air_time*.15
  else:
   height=0;rig.air_pose=0;rig.phase_override=-1;rig.contact_enabled=true
   var landed_for=air_time-FLIGHT
   if landed_for>=0 and landed_for<.16:
    var start_phase=.5+FLIGHT*.15
    var run_phase=fposmod(t/.4,1)
    rig.phase_override=fposmod(lerp_angle(start_phase*TAU,run_phase*TAU,smoothstep(0,.16,landed_for))/TAU,1)
  rig.sampled_pose=rig.pose_transforms()
 rig.queue_redraw()
