extends RefCounted
const MOON=Color("e5ddf5")
const LIGHT=preload("res://scripts/actors/boss_reset/moon_light.gd")
static func rock(n,p,r,alpha=1.0):
 var shape=PackedVector2Array([p+Vector2(-r,-r*.25),p+Vector2(-r*.6,-r*.85),p+Vector2(r*.3,-r),p+Vector2(r*.9,-r*.35),p+Vector2(r,r*.55),p+Vector2(-r*.55,r*.7)])
 n.draw_colored_polygon(shape,Color("777e7b",alpha));n.draw_polyline(PackedVector2Array([shape[0],shape[1],shape[2],shape[3]]),Color("bbc1b5",alpha),2)
 n.draw_polyline(PackedVector2Array([shape[1],p,shape[4]]),Color("48565a",alpha),1.5)
static func rolling_rock(n,p,r,alpha,velocity,age):
 var speed=velocity.length()
 var direction=velocity.normalized() if speed>.1 else Vector2.RIGHT
 var angle=age*maxf(1,speed)/maxf(1,r)
 var points=PackedVector2Array()
 for i in 7:
  var a=TAU*float(i)/6+angle
  var radius=r*(.78+.16*sin(i*4.73+1.2))
  points.append(p+Vector2(cos(a),sin(a))*radius)
 points[6]=points[0]
 var body=PackedVector2Array()
 for i in 6:body.append(points[i])
 var center=p+Vector2(-direction.y,direction.x)*r*.12
 var facet=PackedVector2Array([points[1],points[2],points[3],center])
 var shadow=PackedVector2Array()
 for i in 24:
  var a=TAU*float(i)/23
  shadow.append(p+Vector2(cos(a)*r*1.15,sin(a)*r*.28+r*.78))
 n.draw_colored_polygon(shadow,Color("30343b",.22*alpha))
 n.draw_colored_polygon(body,Color("626c70",alpha))
 n.draw_colored_polygon(facet,Color("9ca69f",.70*alpha))
 n.draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3]]),Color("d0d1c2",.78*alpha),1.6,true)
 n.draw_polyline(PackedVector2Array([points[1],center,points[5],points[4]]),Color("414b51",.86*alpha),1.3,true)
 var side=direction.orthogonal()
 for i in 2:
  var offset=(i*2-1)*r*.32
  var start=p-direction*(r+8+i*4)+side*offset
  var finish=p-direction*(r*.55)+side*offset*.65
  n.draw_line(start,finish,Color("b6b8b2",alpha*(.25-i*.06)),1.0-i*.2,true)
static func stone_surge(n,p,r,alpha,progress):
 var u=clampf(progress,0,1)
 var rise=sin(u*PI)
 for layer in 2:
  var radius=8+u*48+layer*9
  var arc=PackedVector2Array()
  for i in 21:
   var a=lerpf(PI,TAU,float(i)/20)
   arc.append(p+Vector2(cos(a)*radius,12+sin(a)*radius*.22))
  n.draw_polyline(arc,Color("303b40",alpha*(.42-layer*.12)),3.0-layer*.7,true)
  n.draw_polyline(arc,Color("c5c4b4",alpha*(.36-layer*.10)),1.1-layer*.2,true)
 for side in [-1,1]:
  var crack=PackedVector2Array([p+Vector2(side*3,13),p+Vector2(side*(r*.42+u*12),13-rise*3),p+Vector2(side*(r*.68+u*23),12-rise*1.5)])
  n.draw_polyline(crack,Color("414b4e",alpha*.74),1.35,true)
  n.draw_line(crack[0],crack[1],Color("d2d0bf",alpha*.50),.7,true)
 rock(n,p+Vector2(0,9-rise*17),r*(.34+.66*rise),alpha*(.72+.28*rise))
 for side in [-1,1]:
  var shard_p=p+Vector2(side*(8+u*31),8-rise*18)
  var size=2+rise*3
  var shard=PackedVector2Array([shard_p+Vector2(0,-size),shard_p+Vector2(side*size,0),shard_p+Vector2(0,size*.36)])
  n.draw_colored_polygon(shard,Color("bbc0b6",alpha*rise*.82))
static func duelist_dart(n,p,direction,alpha,clock,is_returning=false,return_phase=false):
 var d=direction.normalized() if direction.length_squared()>.01 else Vector2.RIGHT
 var side=d.orthogonal()
 var sea=Color("b8d7cd")
 var deep=Color("45696b")
 LIGHT.stroke(n,PackedVector2Array([p-d*20,p-d*12]),alpha*.48,.7)
 n.draw_line(p-d*16+side*3,p-d*5+side*1.6,Color("a8c7bd",alpha*.34),.8,true)
 n.draw_line(p-d*16-side*3,p-d*5-side*1.6,Color("a8c7bd",alpha*.34),.8,true)
 if is_returning:
  var blade=PackedVector2Array()
  for i in 13:
   var a=lerpf(-1.18,1.18,float(i)/12)
   blade.append(p+d*(cos(a)*12)+side*(sin(a)*12))
  for i in range(11,0,-1):
   var t=float(i)/12
   var a=lerpf(-1.18,1.18,t)
   var radius=12-5*sin(t*PI)
   blade.append(p+d*(cos(a)*radius)+side*(sin(a)*radius))
  n.draw_colored_polygon(blade,Color(deep,.82*alpha))
  n.draw_polyline(PackedVector2Array([blade[0],blade[6],blade[12]]),Color(sea,.90*alpha),1.2,true)
  n.draw_line(p-d*1-side*4,p+d*8,Color("eff8df",alpha*.86),.9,true)
  var spin=clock*(-5.5 if return_phase else 4.5)
  n.draw_arc(p,8,spin,spin+PI*1.1,18,Color(sea,.48*alpha),1.0)
 else:
  var spin=clock*8
  var star=PackedVector2Array()
  for i in 7:
   var a=spin+i*TAU/6
   var radius=10.5 if i%2==0 else 3.0
   star.append(p+Vector2(cos(a),sin(a))*radius)
  star[6]=star[0]
  n.draw_colored_polygon(star,Color(deep,.86*alpha))
  for i in 3:
   var a=spin+i*TAU/3
   var tip=p+Vector2(cos(a),sin(a))*10.5
   n.draw_line(p,tip,Color(sea,.8*alpha),.9,true)
   n.draw_circle(tip,1.15,Color("eff8df",alpha*.86))
  n.draw_polyline(star,Color(sea,.84*alpha),1.0,true)
 n.draw_circle(p,2.0,Color("d7ead5",alpha*.9))
static func duelist_blade(n,hand,tip,alpha,clock,move_id,progress,face):
 var d=(tip-hand).normalized()
 if d.length_squared()<.01:return
 var side=d.orthogonal()
 var steel=Color("9bb8b1")
 var glint=Color("e3edda")
 n.draw_line(hand,tip,Color("4f7474",.30*alpha),4.6,true)
 n.draw_colored_polygon(PackedVector2Array([hand+side*2.7,tip,hand-side*1.15]),Color("577575",.62*alpha))
 n.draw_line(hand+side*.7,tip-side*.55,Color(steel,.88*alpha),1.45,true)
 n.draw_line(hand+side*1.35,tip-side*.9,Color(glint,.80*alpha),.65,true)
 var guard=hand.lerp(tip,.18)
 n.draw_line(guard-side*4.3,guard+side*4.3,Color("bfd4c6",.82*alpha),1.1,true)
 n.draw_circle(tip,1.7,Color(glint,.94*alpha))
 var u=clampf(progress,0,1)
 if move_id=="low_sweep":
  var intensity=alpha*sin(u*PI)
  if intensity>.01:
   var center=hand.lerp(tip,.64)
   var start=d.angle()-face*1.35
   var finish=d.angle()+face*(.12+u*1.25)
   var outer=PackedVector2Array()
   var inner=PackedVector2Array()
   for i in 17:
    var a=lerpf(start,finish,float(i)/16)
    var radial=Vector2(cos(a),sin(a))
    outer.append(center+radial*(29+u*7))
    inner.append(center+radial*(22+u*5))
   var ribbon=outer.duplicate()
   for i in range(inner.size()-1,-1,-1):ribbon.append(inner[i])
   n.draw_colored_polygon(ribbon,Color("638d88",.18*intensity))
   n.draw_polyline(outer,Color(steel,.78*intensity),1.25,true)
   n.draw_polyline(inner,Color(glint,.60*intensity),.75,true)
 elif move_id=="triple":
  var reach=lerpf(5,18,smoothstep(0,1,u))
  var end=tip+d*reach
  n.draw_line(tip,end,Color("90b7aa",alpha*.58),3.2,true)
  n.draw_line(tip,end,Color(glint,alpha*.88),1.05,true)
  n.draw_line(tip+side*2,end,Color(steel,alpha*.52),.7,true)
 elif move_id in ["flash","shadow","feint"]:
  var intensity=alpha*sin(u*PI)
  var center=hand.lerp(tip,.68)
  var start=d.angle()-face*1.10
  var finish=d.angle()+face*(.18+u*.95)
  var outer=PackedVector2Array()
  var inner=PackedVector2Array()
  for i in 19:
   var a=lerpf(start,finish,float(i)/18)
   var radial=Vector2(cos(a),sin(a))
   outer.append(center+radial*(31+u*7))
   inner.append(center+radial*(22+u*5))
  var ribbon=outer.duplicate()
  for i in range(inner.size()-1,-1,-1):ribbon.append(inner[i])
  n.draw_colored_polygon(ribbon,Color("638d88",.23*intensity))
  n.draw_polyline(outer,Color("527a7a",.42*intensity),4.0,true)
  n.draw_polyline(outer,Color(steel,.88*intensity),1.25,true)
  n.draw_polyline(inner,Color(glint,.64*intensity),.65,true)
static func duelist_dash_wake(n):
 var progress=clampf(n.action_age/maxf(.01,n.action_duration),0,1)
 var strength=.16+.44*sin(progress*PI)
 var face=n.facing
 var anchor=Vector2(0,-n.body_height*.48)
 for i in 6:
  var u=float(i)/5
  var y=lerpf(-n.body_height*.43,-n.body_height*.06,u)
  var length=22+(1-u)*30+sin(n.time*15+i*1.7)*4
  var start=anchor+Vector2(-face*6,y)
  var finish=anchor+Vector2(-face*length,y+sin(n.time*12+i)*3)
  n.draw_line(start,finish,Color("527a7a",strength*(.38+u*.1)),2.8-u*.2,true)
  n.draw_line(start,finish,Color("bed7c9",strength*(.72-u*.18)),.8,true)
 for i in 3:
  var y=-n.body_height*.36+i*n.body_height*.13
  var p=anchor+Vector2(-face*(14+i*6),y)
  n.draw_circle(p,1.0,Color("e0ebd6",strength*.72))
static func duelist_charge(n,progress):
 var segment=n.art.weapon_segment()
 var hand=segment[0]-n.position
 var tip=segment[1]-n.position
 var d=(tip-hand).normalized()
 var u=clampf(progress,0,1)
 var radius=lerpf(24,11,u)
 var spin=n.time*(.65+u*1.8)
 n.draw_arc(tip,radius,spin,spin+PI*1.42,32,Color("729b94",.30+.28*u),1.4)
 n.draw_arc(tip,radius*.66,-spin*1.2+PI,-spin*1.2+PI+PI*.86,24,Color("d5e5d6",.24+.42*u),1.0)
 for i in 7:
  var a=spin+i*TAU/7
  var radial=Vector2(cos(a),sin(a))
  var start=tip+radial*(radius+2)
  var finish=tip+radial*(radius*(.48-.18*u))
  n.draw_line(start,finish,Color("b7d0c4",(.18+.34*u)*(.6+.4*sin(n.time*4+i))),.8,true)
  n.draw_circle(finish,1.05,Color("e8efdc",.32+.5*u))
 if d.length_squared()>.01:
  n.draw_line(hand,tip,Color("8db1a7",.12+.2*u),2.2,true)
static func landing_impact(n,p,live,life,alpha):
 var u=clampf(live/maxf(.01,life),0,1)
 var pulse=sin(u*PI)
 var color=Color("9ca8a1") if n.spec.id=="lantern" else Color("91b5aa")
 var floor=p+Vector2(0,20)
 for layer in 2:
  var radius=8+u*39+layer*8
  var ellipse=PackedVector2Array()
  for i in 33:
   var a=TAU*float(i)/32+u*(.25 if layer==0 else -.18)
   ellipse.append(floor+Vector2(cos(a)*radius,sin(a)*radius*.25))
  n.draw_polyline(ellipse,Color(color,alpha*(.54-layer*.16)),2.4-layer*.7,true)
  n.draw_polyline(ellipse,Color("e5eee0",alpha*(.46-layer*.14)),.85,true)
 for i in 8:
  var a=TAU*i/8+u*.5
  var direction=Vector2(cos(a),sin(a)*.25)
  var start=floor+direction*(10+u*10)
  var finish=start+Vector2(direction.x*(5+u*7),-pulse*(5+fposmod(i*2.7,5)))
  n.draw_line(start,finish,Color(color,alpha*pulse*.72),1.25,true)
  n.draw_circle(finish,1.0+pulse*.5,Color("eff3df",alpha*pulse*.76))
 n.draw_arc(floor,4+u*7,PI,TAU,20,Color("f0f1de",alpha*(.38+.34*pulse)),1.0)
static func paint(n):
 if not n.active_battle:return
 if n.spec.id=="duelist" and n.dash_left>0 and n.move.id in ["flash","shadow","feint"]:
  duelist_dash_wake(n)
 if n.spec.id=="priest" and n.dash_left>0 and n.move.id=="horn":
  LIGHT.priest_dash_wake(n)
 if n.spec.id=="priest" and n.dash_left>0 and n.move.id=="rift":
  LIGHT.priest_rift_wake(n)
 if n.spec.id=="duelist" and n.windup>0:
  duelist_charge(n,1-n.windup/maxf(.01,n.move.windup))
 if n.spec.id=="priest" and n.moon_visible>0:
  var p=Vector2(n.arena.get_center().x,110)-n.position
  var moon_scale=lerpf(.72,1.0,smoothstep(0,1,n.moon_visible))
  for i in range(7,0,-1):n.draw_circle(p,(105+i*5)*moon_scale,Color(.66,.62,.9,(.012+i*.002)*n.moon_visible))
  n.draw_arc(p,(116+sin(n.time*1.3)*3)*moon_scale,n.time*.12,n.time*.12+TAU*.86,64,Color("c9c2e9",.40*n.moon_visible),1.4)
  n.draw_arc(p,122*moon_scale,n.time*-.18+PI,n.time*-.18+PI+TAU*.72,56,Color("8f85b8",.29*n.moon_visible),1.0)
  if n.art.moon_texture:
   var moon_extent=105*moon_scale
   n.draw_texture_rect(n.art.moon_texture,Rect2(p-Vector2.ONE*moon_extent,Vector2.ONE*moon_extent*2),false,Color(1,1,1,n.moon_visible))
  else:
   n.draw_circle(p,100*moon_scale,Color(MOON,n.moon_visible));n.draw_circle(p+Vector2(-30,10)*moon_scale,38*moon_scale,Color("aaa3bd",n.moon_visible*.4))
  var eclipse_x=sin(n.time*.48)*49*moon_scale
  n.draw_circle(p+Vector2(eclipse_x,-3*moon_scale),83*moon_scale,Color("211f31",.22*n.moon_visible))
  n.draw_arc(p+Vector2(eclipse_x,-3*moon_scale),84*moon_scale,-PI*.42,PI*.42,36,Color("fff0ca",.40*n.moon_visible),1.2)
  for i in 5:
   var angle=n.time*(.42 if i%2==0 else -.31)+i*TAU/5
   var mote=p+Vector2(cos(angle)*119,sin(angle)*49)*moon_scale
   n.draw_line(mote-Vector2(3,0),mote+Vector2(3,0),Color("fff4dc",.62*n.moon_visible),1.2)
   n.draw_line(mote-Vector2(0,3),mote+Vector2(0,3),Color(MOON,.48*n.moon_visible),1.2)
  var focus=Vector2(-n.facing*25,-14) if n.recall_age>=0 else Vector2(0,-n.body_height*.55)
  for i in 6:
   var points=PackedVector2Array()
   for j in 16:
    var a=float(j)/15*PI*1.15+n.time*.7+i*TAU/6
    points.append(focus+Vector2(cos(a)*58,sin(a)*22)*moon_scale+Vector2(0,sin(a*2+n.time)*7*moon_scale))
   n.draw_polyline(points,Color(MOON,(.20+i*.025)*n.art.tint.a*(.45 if n.recall_age>=0 else 1.0)),1.3)
 if n.recall_age>=0:
  var moon=Vector2(n.arena.get_center().x,110)-n.position
  var u=clampf((n.recall_age-.7)/.6,0,1)*(1-clampf((n.recall_age-5.8)/.6,0,1))
  var fallen=Vector2(-n.facing*25,-14)
  var curtain=PackedVector2Array([moon+Vector2(-32,12),moon+Vector2(32,12),fallen+Vector2(94,16),fallen+Vector2(-94,16)])
  n.draw_colored_polygon(curtain,Color("8c81b7",.075*u))
  n.draw_colored_polygon(PackedVector2Array([moon+Vector2(-12,16),moon+Vector2(12,16),fallen+Vector2(52,8),fallen+Vector2(-52,8)]),Color(MOON,.10*u))
  if n.recall_age>1.3 and n.recall_age<5.8:
   for i in 48:
    var t=clampf((n.recall_age-1.3-float(i%12)*.075)/3.1,0,1)
    if t<=0 or t>=1:continue
    var start=fallen+Vector2(sin(i*2.4+n.time)*40,-cos(i)*11)
    var p=start.lerp(moon,t*t)+Vector2(sin(t*TAU+i+n.time*.7)*36*sin(t*PI),-sin(t*PI)*24)
    var alpha=sin(t*PI)*u
    n.draw_line(p,p-Vector2(4,14).rotated(t+i),Color("9c91c7",alpha*.64),3.5,true)
    n.draw_line(p,p-Vector2(2,8).rotated(t+i),Color(MOON,alpha*.92),1.2,true)
    n.draw_circle(p,2.4,Color("8e83b9",alpha*.55))
    n.draw_circle(p,1.15,Color("fff4dd",alpha))
  var pulse=.5+.5*sin(n.time*3.2)
  n.draw_arc(fallen+Vector2(0,14),24+pulse*15,0,TAU,40,Color("a59bc9",u*(.22+pulse*.16)),1.2)
  n.draw_arc(moon,110+pulse*7,n.time*.18,n.time*.18+TAU*.72,48,Color("fff0ce",u*(.3+pulse*.18)),1.5)
  return
 if n.windup>0 and n.spec.id=="priest":
  var u=1-n.windup/maxf(.01,n.move.windup);var focus=n.art.weapon_segment()[1]-n.position
  LIGHT.gather(n,focus,u,n.time)
 for e in n.effects:
  var p=e.p-n.position;var live=e.age-e.delay;var remaining=e.life-live
  var tail=clampf(1-maxf(0,-remaining)/.16,0,1)
  if e.type=="moon_column":
   var rect=n.effect_rect(e);rect.position-=n.position
   if live<0:
    var u=clampf(e.age/maxf(.01,e.delay),0,1)
    var width=e.size.x*(.24+.76*u)
    n.draw_colored_polygon(PackedVector2Array([p-Vector2(1,0),p+Vector2(1,0),p+Vector2(width*.5,320),p+Vector2(-width*.5,320)]),Color("8c82b5",.035+u*.075))
    n.draw_colored_polygon(PackedVector2Array([p-Vector2(1,0),p+Vector2(1,0),p+Vector2(width*.22,320),p+Vector2(-width*.22,320)]),Color(MOON,.035+u*.10))
    n.draw_line(p,p+Vector2(0,320),Color("fff2d4",.15+u*.16),1+u*2)
    for i in 3:
     var angle=n.time*1.4+i*TAU/3
     var q=p+Vector2(cos(angle)*width*.26,38+i*14)
     LIGHT.needle(n,q,Vector2(sin(angle),1),8,.55,u*.62,1.2)
    n.draw_arc(p+Vector2(0,318),e.size.x*.48,PI,TAU,28,Color("c8bee8",u*.38),1.4)
    n.draw_arc(p+Vector2(0,318),e.size.x*.32,PI,TAU,24,Color("fff1ce",u*.55),1.0)
    var ground=p+Vector2(0,318)
    for ring in 2:
     var radius=e.size.x*(.18+.16*ring+.12*u)
     var ellipse=PackedVector2Array()
     for j in 33:
      var angle=TAU*float(j)/32+n.time*(.35 if ring==0 else -.24)
      ellipse.append(ground+Vector2(cos(angle)*radius,sin(angle)*radius*.18))
     n.draw_polyline(ellipse,Color("d4cced",u*(.16 if ring==0 else .10)),1.0,true)
    for i in 8:
     var a=TAU*i/8+n.time*.22
     var direction=Vector2(cos(a),sin(a)*.28)
     var q=ground+direction*e.size.x*.28
     LIGHT.needle(n,q,direction,4+u*4,.32,u*.34,sin(n.time*3+i)*.5)
   elif live<=e.life:
    var fade=tail*(.86+.14*sin(live*24))
    var shaft=PackedVector2Array([p+Vector2(-e.size.x*.5,0),p+Vector2(e.size.x*.5,0),p+Vector2(e.size.x*.30,320),p+Vector2(-e.size.x*.30,320)])
    n.draw_colored_polygon(shaft,Color("8c82b5",.18*fade))
    var inner=PackedVector2Array([p-Vector2(e.size.x*.16,0),p+Vector2(e.size.x*.16,0),p+Vector2(e.size.x*.10,320),p+Vector2(-e.size.x*.10,320)])
    n.draw_colored_polygon(inner,Color(MOON,.19*fade))
    for layer in range(4,0,-1):
     n.draw_line(p,p+Vector2(0,320),Color(MOON,.035*(5-layer)*fade),e.size.x*layer/5)
    LIGHT.stroke(n,PackedVector2Array([p,p+Vector2(0,320)]),fade,maxf(2,e.size.x*.095))
    for i in 7:
     var y=18+fposmod(live*360+i*43,284)
     var drift=sin(live*15+i*2.1)*8
     var q=p+Vector2(drift,y)
     LIGHT.needle(n,q,Vector2.DOWN,11,.62,fade*.78,drift*.08)
    var impact=p+Vector2(0,318)
    n.draw_arc(impact,e.size.x*(.40+.05*sin(live*18)),PI,TAU,28,Color("fff0ce",fade*.70),1.6)
    n.draw_arc(impact,e.size.x*.27,PI,TAU,24,Color("b5aad8",fade*.50),1.1)
    var burst=sin(clampf(live/e.life,0,1)*PI)
    for i in 10:
     var a=TAU*i/10+live*1.8
     var direction=Vector2(cos(a),sin(a)*.38)
     var start=impact+direction*(8+burst*5)
     LIGHT.needle(n,start,direction,7+burst*(8+fposmod(i*3.7+live*5,6)),.42,fade*(.24+.42*burst),sin(live*8+i)*1.2)
    n.draw_circle(impact,3+burst*2,Color("fff4dc",fade*(.32+.48*burst)))
   else:
    var fade=clampf(1-(live-e.life)/n.cfg("moon_afterglow"),0,1)
    var length=lerpf(20,320,fade)
    n.draw_colored_polygon(PackedVector2Array([p-Vector2(1,0),p+Vector2(1,0),p+Vector2(4,length),p+Vector2(-4,length)]),Color(MOON,.08*fade))
    n.draw_line(p,p+Vector2(0,length),Color(MOON,.22*fade),2.4*fade)
    n.draw_arc(p+Vector2(0,318),e.size.x*.42*(.8+fade*.2),PI,TAU,24,Color("c8bee8",fade*.3),1.0)
   continue
  if live<0:
   if e.type=="moon_shard":LIGHT.shard_warning(n,p,clampf(e.age/maxf(.01,e.delay),0,1),n.time)
   elif e.type=="crescent" and e.identity.ends_with(":ritual"):
    LIGHT.ritual_warning(n,p,e.v,clampf(e.age/maxf(.01,e.delay),0,1),e.age)
   continue
  match e.type:
   "boulder":rolling_rock(n,p,17,tail,e.v,e.age)
   "stone_wave":stone_surge(n,p,20,tail,live/maxf(.01,e.life))
   "impact":
    landing_impact(n,p,live,e.life,tail)
   "dart","return_dart":duelist_dart(n,p,e.v,tail,e.age,e.type=="return_dart",e.get("returned",false))
   "weapon":
    if n.spec.id!="lantern":
     var segment=n.art.weapon_segment();var tip=segment[1]-n.position;var hand=segment[0]-n.position
     var strength=maxf(0,1-live/e.life)
     if n.spec.id=="priest":
      var staff=PackedVector2Array([hand,tip])
      LIGHT.stroke(n,staff,strength*.78,1.7)
      n.draw_arc(tip,5+sin(n.time*14)*1.4,0,TAU,20,Color("cfc6ef",strength*.76),1.1)
      n.draw_circle(tip,2.2,Color("fff2d2",strength*.9))
      if e.identity.ends_with(":four_slash"):
       LIGHT.staff_sweep(n,hand,tip,e.face,clampf(live/maxf(.01,e.life),0,1),strength)
      elif e.identity.ends_with(":horn"):
       LIGHT.staff_thrust(n,hand,tip,clampf(live/maxf(.01,e.life),0,1),strength)
     else:duelist_blade(n,hand,tip,strength,n.time,e.identity.get_slice(":",1),clampf(live/maxf(.01,e.life),0,1),e.face)
   "beam":LIGHT.beam(n,p,e.face,e.size.x,tail,n.time)
   "moon_wave":LIGHT.wave(n,p,tail,clampf(live/maxf(.01,e.life),0,1),e.face)
   "crescent":
    if e.identity.ends_with(":ritual"):LIGHT.ritual_blade(n,p,e.v,tail,e.age)
    elif e.identity.ends_with(":ring"):LIGHT.crescent_blade(n,p,e.v,tail,e.age)
    else:LIGHT.needle(n,p,e.v,24,1.15,tail,sin(e.age*5)*2.2)
   "moon_orb":
    var direction=e.v.normalized() if e.v.length_squared()>.01 else Vector2.RIGHT
    var orb_path=PackedVector2Array()
    for point in e.get("trail",PackedVector2Array()):orb_path.append(point-n.position)
    LIGHT.orb_trail(n,orb_path,tail)
    LIGHT.orb(n,p,direction,tail,e.age)
   "moon_shard":
    var landing_y=e.origin.y+320
    var impact_time=maxf(0,e.p.y-landing_y)/maxf(1,absf(e.v.y))
    var impact_progress=clampf(impact_time/.24,0,1)
    var fall_alpha=tail*(1-smoothstep(0,18,maxf(0,e.p.y-landing_y)))
    LIGHT.falling_shard(n,p,fall_alpha,n.time)
    if e.p.y>=landing_y:
     LIGHT.shard_impact(n,Vector2(e.p.x,landing_y)-n.position,impact_progress,tail*(1-impact_progress),n.time)
