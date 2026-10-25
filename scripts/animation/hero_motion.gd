extends RefCounted
# Non-uniform authoring times: anticipation, fast release, impact, follow-through, recovery.
const RUN_PERIOD=.36
const SUPPORT=.21
const BOW_DURATION=.32
const BOW_RELEASE=.13
const ATTACKS=[
 {"duration":.38,"chain":.27,"hit":.15,"times":[0.0,.10,.15,.20,.29,.38],"arm":[.25,-1.65,1.35,1.65,1.2,.25],"elbow":[.35,.55,.12,.18,.4,.35],"chest":[0.0,.16,-.18,-.24,-.12,0.0]},
 {"duration":.41,"chain":.29,"hit":.17,"times":[0.0,.11,.17,.22,.31,.41],"arm":[1.3,2.25,1.05,.4,.3,.22],"elbow":[.4,.8,.2,.15,.35,.4],"chest":[0.0,-.14,.19,.22,.08,0.0]},
 {"duration":.49,"chain":.49,"hit":.22,"times":[0.0,.15,.22,.28,.38,.49],"arm":[.25,-.8,1.35,2.6,1.65,.25],"elbow":[.35,1.25,.18,.12,.4,.35],"chest":[0.0,.25,-.24,-.19,-.08,0.0]}
]
static func track(times,values,t):
 for i in range(1,times.size()):
  if t<=times[i]:
   var u=clampf((t-times[i-1])/(times[i]-times[i-1]),0,1)
   return lerpf(values[i-1],values[i],u*u*(3-2*u))
 return values.back()
static func bow_released(t):return t>=BOW_RELEASE
static func leg(pose,side,foot,hip_y):
 var upper=.265;var lower=.235
 var delta=foot-Vector2(0,hip_y)
 var distance=clampf(delta.length(),.03,upper+lower-.001)
 var base=atan2(delta.x,-delta.y)
 var bend=acos(clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1))
 var thigh=base+bend
 var knee=-(PI-acos(clampf((upper*upper+lower*lower-distance*distance)/(2*upper*lower),-1,1)))
 pose[side+"_thigh"]=Vector3(0,0,thigh)
 pose[side+"_shin"]=Vector3(0,0,knee)
 pose[side+"_foot"]=Vector3(0,0,-thigh-knee)
static func sample(state,t,phase=0.0,amount=1.0):
 var p={"offset":Vector3.ZERO,"chest":Vector3.ZERO,"neck":Vector3.ZERO,"head":Vector3.ZERO,"near_arm":Vector3(0,0,.22),"far_arm":Vector3(0,0,-.10),"near_forearm":Vector3(0,0,.35),"far_forearm":Vector3(0,0,.15),"near_hand":Vector3(0,0,-.95)}
 var crouch=.015;var lean=sin(t*2.6)*.014
 var near=Vector2(.025,.055);var far=Vector2(-.07,.055)
 if state=="run":
  crouch=.075+.015*(1-cos(phase*2));lean=-.14*amount
  for side in ["near","far"]:
   var cycle=fposmod(phase+(0 if side=="near" else PI),TAU)/TAU
   var foot=Vector2.ZERO
   if cycle<SUPPORT:foot=Vector2(lerpf(.25,-.25,cycle/SUPPORT),.055)
   else:
    var swing=(cycle-SUPPORT)/(1-SUPPORT)
    foot=Vector2(lerpf(-.25,.25,swing),.055+pow(sin(swing*PI),2)*.17)
   foot.x*=amount
   if side=="near":near=foot
   else:far=foot
  p.near_arm.z=.20+sin(phase)*.35*amount;p.far_arm.z=.05-sin(phase)*.8*amount
  p.near_forearm.z=.65;p.far_forearm.z=.65
  p.near_hand.z=-.95-sin(phase)*.22*amount
 elif state=="jump":
  var u=smoothstep(0,.20,t);var apex=smoothstep(.22,.48,t)
  crouch=lerpf(.005,.03,u);lean=lerpf(-.13,.025,apex)
  near=Vector2(lerpf(.04,.19,u),lerpf(.07,.24,u)-apex*.065)
  far=Vector2(lerpf(-.15,-.06,apex),lerpf(.07,.15,u))
  p.near_arm.z=lerpf(.2,.65,u);p.far_arm.z=lerpf(-.8,-.35,apex);p.near_forearm.z=.55
 elif state=="fall":
  var u=smoothstep(0,.27,t)
  crouch=lerpf(.03,.012,u);lean=lerpf(.025,.08,u)
  near=Vector2(lerpf(.19,.13,u),lerpf(.175,.065,u));far=Vector2(lerpf(-.06,-.14,u),lerpf(.15,.075,u))
  p.near_arm.z=lerpf(.65,.85,u);p.far_arm.z=lerpf(-.35,-.5,u);p.near_forearm.z=lerpf(.55,.35,u)
 elif state=="land":
  var times=[0.0,.035,.085,.135,.18]
  crouch=track(times,[.015,.125,.075,.009,.015],t);lean=track(times,[.08,-.14,-.07,.018,0.0],t)
  var settle=smoothstep(.035,.18,t)
  near=Vector2(lerpf(.13,.025,settle),.055);far=Vector2(lerpf(-.14,-.07,settle),.055)
  p.near_arm.z=track(times,[.8,.5,.3,.20,.22],t);p.far_arm.z=track(times,[-.45,-.6,-.25,-.08,-.1],t)
 elif state.begins_with("slash"):
  var a=ATTACKS[clampi(int(state.right(1))-1,0,2)]
  lean=track(a.times,a.chest,t);crouch=.035+sin(clampf(t/a.duration,0,1)*PI)*.035
  p.near_arm.z=track(a.times,a.arm,t);p.near_forearm.z=track(a.times,a.elbow,t)
  p.near_hand.z=track(a.times,[-.95,-1.0,-1.4,-1.4,-1.1,-.95],t) if state=="slash2" else -p.near_arm.z*.45-.2
  p.far_arm.z=-lean*2-.2;p.far_forearm.z=.8
  p.chest.y=sin(t/a.duration*TAU)*.2
  near=Vector2(.18,.055);far=Vector2(-.16,.055)
 elif state=="roll":
  crouch=.13;lean=-.25;near=Vector2(.13,.25);far=Vector2(-.08,.22)
  p.near_arm.z=.65;p.near_forearm.z=1.9;p.far_arm.z=.5;p.far_forearm.z=1.8
 elif state=="dash":
  crouch=.12;lean=-.42;near=Vector2(.24,.10);far=Vector2(-.23,.08)
  p.near_arm.z=-.7;p.far_arm.z=-1.1
 elif state=="charge":
  crouch=.08;lean=-.17;p.near_arm.z=-.7;p.near_forearm.z=1.1
 elif state=="bow":
  lean=.04;p.near_arm.z=1.0;p.near_forearm.z=track([0.0,.09,.13,.17,.25,.32],[.65,1.7,1.7,1.05,1.2,1.1],t);p.far_arm.z=1.45;p.far_forearm.z=.1;p["far_hand"]=Vector3(0,0,-1.55)
 elif state=="hurt":
  lean=.20;crouch=.05;p.near_arm.z=-.25;p.far_arm.z=.55
 p.offset=Vector3(0,-crouch,0);p.chest.z=lean;p.neck.z=-lean*.65
 p.head.z=sin(t*2.6-.3)*.008
 leg(p,"near",near,.555-crouch);leg(p,"far",far,.555-crouch)
 return p
