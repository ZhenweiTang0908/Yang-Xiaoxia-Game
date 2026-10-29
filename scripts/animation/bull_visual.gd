extends "res://scripts/animation/brother_visual.gd"
# Original quadruped artwork, with restrained skinning and explicit back/eye sockets.
const MOTION=preload("res://scripts/animation/hero_motion.gd")
const GAIT_KEYS=[0.0,.125,.25,.375,.5,.625,.75,.875,1.0]
const HOOF_TRAVEL=[4.0,0.0,-4.0,-6.0,-4.0,0.0,5.0,7.0,4.0]
const HOOF_LIFT=[0.0,0.0,0.0,.7,2.8,4.0,3.0,.9,0.0]
const BACK=[Vector2(165,195),Vector2(170,190),Vector2(185,195),Vector2(170,190),Vector2(170,150),Vector2(177,155),Vector2(160,174),Vector2(165,190)]
const EYES=[Vector2(324,219),Vector2(311,293),Vector2(325,226),Vector2(329,218),Vector2(322,185),Vector2(337,199),Vector2(317,280),Vector2(289,122)]
var trail=[]
var eye_fx
var last_eye=Vector2.INF
var last_face=1.0
var gait=0.0
var stride=0.0
var crouch=0.0
var recoil=0.0
var gait_rect=Rect2()
var hoof_offsets=[Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO]
var was_rushing=false
var settle_age=1.0
func _ready():
 super._ready();process_priority=-20
 eye_fx=Node2D.new();add_child(eye_fx);eye_fx.draw.connect(draw_eyes)
 var shader=Shader.new();shader.code="""shader_type canvas_item;
 void fragment(){
  vec4 c=texture(TEXTURE,UV);
  float key=1.0-smoothstep(0.12,0.50,min(c.r,c.b)-c.g);
  float l=dot(c.rgb,vec3(.3,.59,.11));
  vec3 ink=vec3(.013,.016,.022)+l*vec3(.34,.35,.38);
  if(c.r>.60 && c.g>.50)ink=c.rgb*.8;
  if(c.g>c.r*1.2 && c.g>c.b*1.15 && c.g>.35)ink=vec3(1.0,.04,.08);
  COLOR=vec4(ink,COLOR.a*key);
 }"""
 material=ShaderMaterial.new();material.shader=shader
func is_enabled():return actor.demon and actor.game.use_skeletal
func rebuild(index):
 super.rebuild(index)
 var region=source_art.regions[index];var used=source_art.bounds[index];var unit=source_art.scale_unit
 var origin=Vector2(-region.size.x*.5,-used.end.y)*unit
 var rect=Rect2(Vector2(used.position)*unit+origin,Vector2(used.size)*unit)
 gait_rect=rect
 pivots=[rect.position+rect.size*Vector2(.5,.4),rect.position+rect.size*Vector2(.80,.32),rect.position+rect.size*Vector2(.15,.37),rect.position+rect.size*Vector2(.5,.72)]
 for i in weights.size():
  var q=(rest[i]-rect.position)/rect.size
  var head=smoothstep(.72,.88,q.x)*(1-smoothstep(.6,.75,q.y))
  weights[i]=[(1-smoothstep(.55,.72,q.y))*(1-head)*.3,head*.45,(1-smoothstep(.09,.22,q.x))*.5,0.0]
 for i in 4:bones[i].position=pivots[i]
func socket(point):
 if current_frame<0:return Vector2.ZERO
 var src=source_art.regions[current_frame];var used=source_art.bounds[current_frame]
 var local=(point-Vector2(src.size.x*.5,used.end.y))*source_art.scale_unit
 return deform(local,[.3,0.0,0.0,0.0])
func seat_position():
 if current_frame<0:return actor.position+Vector2(-actor.facing*8,-43)
 return to_global(socket(BACK[current_frame])*Vector2(actor.facing,1))
func eye_point():
 var src=source_art.regions[current_frame];var used=source_art.bounds[current_frame]
 var point=(EYES[current_frame]-Vector2(src.size.x*.5,used.end.y))*source_art.scale_unit
 return deform(point,[0.0,.45,0.0,0.0])*Vector2(actor.facing,1)
func _process(dt):
 if is_instance_valid(actor) and actor.game.active() and actor.game.hitstop<=0:
  var c=actor.demon_controller
  var speed=absf(actor.velocity.x)
  stride=lerpf(stride,clampf(speed/200,0,1),1-exp(-12*dt))
  gait+=dt*lerpf(7.0,16.0,clampf(speed/440,0,1))
  for leg in 4:
   var cycle=fposmod(gait/TAU+([.0,.5,.5,.0][leg]),1.0)
   hoof_offsets[leg]=Vector2(MOTION.track(GAIT_KEYS,HOOF_TRAVEL,cycle),-MOTION.track(GAIT_KEYS,HOOF_LIFT,cycle))
  var preparation=0.0
  if c.rush_windup>0:preparation=1-c.rush_windup/c.cfg("rush_windup")
  elif c.lock_left>0:preparation=1-c.lock_left/c.lock_total
  crouch=lerpf(crouch,preparation,1-exp(-18*dt))
  if was_rushing and c.rush_left<=0:settle_age=0.0
  settle_age+=dt;was_rushing=c.rush_left>0
  recoil=sin(PI*clampf(settle_age/.26,0,1)) if settle_age<.26 else 0.0
 super._process(dt)
 if not visible or current_frame<0:trail.clear();return
 if not actor.game.active() or actor.game.hitstop>0:return
 var at=to_global(eye_point())
 if last_face!=actor.facing or (last_eye.is_finite() and last_eye.distance_to(at)>48):trail.clear()
 last_face=actor.facing;last_eye=at
 for point in trail:point.age+=dt
 trail=trail.filter(func(point):return point.age<.12 and point.at.distance_to(at)<=13)
 if absf(actor.velocity.x)>15:trail.append({"at":at,"age":0.0})
 if trail.size()>18:trail.pop_front()
 eye_fx.queue_redraw()
func deform(point,influences):
 var out=super.deform(point,influences)
 if gait_rect.size.y<=0:return out
 var q=(point-gait_rect.position)/gait_rect.size
 var lower=smoothstep(.57,.88,q.y)
 # Four independently phased hooves, each with nine contact/lift/return keys.
 var centers=[.12,.27,.62,.76]
 var travel=Vector2.ZERO;var influence=0.0
 for leg in 4:
  var weight=1-smoothstep(.035,.11,absf(q.x-centers[leg]))
  travel+=hoof_offsets[leg]*weight
  influence+=weight
 if influence>.001:out+=travel/maxf(1.0,influence)*lower*stride
 var upper=1-lower
 out.y+=upper*(sin(gait*2)*.65*stride+2.8*crouch+recoil*1.8)
 out.x-=upper*(crouch*1.8+recoil*2.5)
 # Lower the muzzle into the horn-led push without moving the back socket.
 var head=smoothstep(.73,.91,q.x)*(1-smoothstep(.60,.76,q.y))
 out.y+=head*(crouch*6+stride*1.0)
 return out
func _draw():super._draw()
func draw_eyes():
 if current_frame<0:return
 var previous=eye_point()
 eye_fx.draw_circle(previous,1.6,Color(1,.015,.025,.18))
 eye_fx.draw_line(previous-Vector2(1,0),previous+Vector2(1,-.2),Color(1,.04,.06),1.4)
 eye_fx.draw_circle(previous,.45,Color(1,.65,.5))
 for i in range(trail.size()-1,-1,-1):
  var point=to_local(trail[i].at);var fade=pow(1-trail[i].age/.12,1.5)
  eye_fx.draw_line(previous,point,Color(1,.025,.04,fade*.18),3)
  eye_fx.draw_line(previous,point,Color(1,.03,.05,fade*.75),1.2);previous=point
