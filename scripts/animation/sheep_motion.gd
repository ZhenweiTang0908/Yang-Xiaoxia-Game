extends RefCounted
const HERO=preload("res://scripts/animation/hero_motion.gd")
# The spirit blade points along local +X. Keep its direction independent of
# elbow flexion so the wrist does not fold the blade through the body.
static func sample(action,t,gait,speed):
 var base="charge" if action=="release" else ("idle" if action=="cast" else action)
 var p=HERO.sample(base,t,gait,speed)
 var blade_angle=-.32
 if action.begins_with("slash"):
  var index=clampi(int(action.right(1))-1,0,2);var a=HERO.ATTACKS[index]
  # Nine authored poses: gather, coil, lead with elbow, cut, impact,
  # follow-through, recoil, settle, guard. Damage timing remains unchanged.
  var times=[0.0,a.hit*.35,a.hit*.72,a.hit*.92,a.hit,a.hit+.035,lerpf(a.hit,a.duration,.48),lerpf(a.hit,a.duration,.78),a.duration]
  var arms=[ [.35,.12,-.75,.45,1.32,1.60,1.35,.65,.35], [1.1,1.45,1.95,1.50,1.22,.65,.50,.39,.35], [.35,.1,-.65,.25,1.10,2.25,1.80,.82,.35] ]
  var elbows=[ [.65,.82,1.05,.55,.16,.25,.42,.60,.65], [.45,.58,.70,.36,.18,.30,.48,.60,.65], [.65,.90,1.20,.55,.15,.22,.38,.60,.65] ]
  var angles=[ [-.32,-.85,-1.65,-.65,.12,.65,.45,-.05,-.32], [.55,1.05,1.65,.55,-.18,-.75,-.55,-.22,-.32], [-.32,-.75,-1.25,-.25,.55,1.20,.85,.18,-.32] ]
  p.near_arm.z=HERO.track(times,arms[index],t);p.near_forearm.z=HERO.track(times,elbows[index],t)
  blade_angle=HERO.track(times,angles[index],t)
  var weight=HERO.track(times,[0.0,-.015,-.035,.035,.10,.11,.075,.025,0.0],t)
  p.offset.x=weight
  p.far_arm.z=-.25-p.chest.z*.6;p.far_forearm.z=.85
  # A grounded, wide stance keeps a heavy swing from looking like a run cycle.
  HERO.leg(p,"near",Vector2(.16,.055),.555+p.offset.y)
  HERO.leg(p,"far",Vector2(-.15,.055),.555+p.offset.y)
 elif action=="cast":
  var times=[0.0,.075,HERO.BOW_RELEASE,.18,.25,HERO.BOW_DURATION]
  p.chest.z=HERO.track(times,[0.0,.10,-.10,-.14,-.06,0.0],t)
  p.far_arm.z=HERO.track(times,[-.15,.85,1.42,1.55,.75,-.15],t)
  p.far_forearm.z=HERO.track(times,[.65,1.25,.12,.18,.55,.65],t)
  p.near_arm.z=.35;p.near_forearm.z=.65
  p.offset.y=-.035
 elif action=="charge" or action=="release":
  var release=smoothstep(0,.12,t) if action=="release" else 0.0
  var settle=smoothstep(.12,.35,t) if action=="release" else 0.0
  p.chest.z=lerpf(-.10,.12,release)*(1-settle)
  p.near_arm.z=lerpf(.45,1.5,release)*(1-settle)+.35*settle
  p.near_forearm.z=lerpf(1.25,.20,release)*(1-settle)+.65*settle
  p.far_arm.z=lerpf(.40,1.4,release)*(1-settle)-.15*settle
  p.far_forearm.z=lerpf(1.25,.25,release)*(1-settle)+.65*settle
  p.offset.y=-.075*(1-release)+.015*sin(release*PI)*(1-settle)
  blade_angle=lerpf(-1.0,-.2,release)
 elif action=="dash":
  p.chest.z=-.28;p.neck.z=.18;p.near_arm.z=.65;p.near_forearm.z=1.45
  p.far_arm.z=.55;p.far_forearm.z=1.45;blade_angle=.10
 elif action=="idle":
  p.near_arm.z=.35;p.near_forearm.z=.65;p.far_arm.z=-.15;p.far_forearm.z=.65
 elif action=="run":
  p.near_arm.z=.35+sin(gait)*.18*speed;p.near_forearm.z=.65
  blade_angle=-.32+sin(gait-.4)*.09*speed
 elif action in ["jump","fall"]:
  p.near_arm.z=.55;p.near_forearm.z=.70;blade_angle=-.45
 p.near_hand.z=blade_angle-p.near_arm.z-p.near_forearm.z-p.chest.z
 p.neck.z=-p.chest.z*.65;p.head.z=sin(t*2.6)*.008
 p.cape=Vector3(0,0,sin(gait-.6)*.045*speed+sin(t*3-.6)*.025+speed*.12)
 return p
