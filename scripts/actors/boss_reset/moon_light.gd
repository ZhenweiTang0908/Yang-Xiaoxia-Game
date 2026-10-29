extends RefCounted
# Light has direction, a hot centre and a fading wake; it is never a moon-shaped icon.
const SILVER=Color("dcdff3")
const CORE=Color("fff4dc")
const MIST=Color("8d83b6")
const DEEP=Color("665c8d")
static func stroke(n,points,alpha=1.0,width=1.0):
 if points.size()<2:return
 n.draw_polyline(points,Color(DEEP,.11*alpha),width+10,true)
 n.draw_polyline(points,Color(MIST,.12*alpha),width+6,true)
 n.draw_polyline(points,Color(SILVER,.28*alpha),width+2.8,true)
 n.draw_polyline(points,Color(CORE,.84*alpha),width,true)
static func needle(n,p,direction,length,width,alpha=1.0,bend=0.0):
 var d=direction.normalized() if direction.length_squared()>.01 else Vector2.RIGHT
 var side=d.orthogonal();var points=PackedVector2Array()
 for i in 9:
  var u=float(i)/8
  points.append(p-d*length*(1-u)+side*sin(u*PI)*bend)
 for i in range(1,points.size()):
  var strength=alpha*pow(float(i)/8,1.6)
  stroke(n,PackedVector2Array([points[i-1],points[i]]),strength,width*(.35+float(i)/12))
 var crescent=PackedVector2Array([p-d*length*.62+side*width*2.1,p-d*length*.12+side*width*.65,p+d*length*.1,p-d*length*.18-side*width*.55])
 n.draw_colored_polygon(crescent,Color(SILVER,.15*alpha))
 n.draw_circle(p,1.6*width,Color(MIST,.30*alpha));n.draw_circle(p,.65*width,Color(CORE,.95*alpha))
static func gather(n,p,u,clock):
 for i in 8:
  var age=fposmod(clock*.52+i*.137,1)
  var a=i*2.17+clock*(.38 if i%2==0 else -.31)
  var radius=30*(1-age)+3
  var start=p+Vector2(cos(a)*radius,sin(a)*radius*.55)
  var end=start.lerp(p,.48)
  needle(n,end,(p-start).normalized(),7,.48,sin(age*PI)*(.22+u*.48),1.8)
 for orbit in 2:
  var a=clock*(1.2 if orbit==0 else -.8)+orbit*PI
  var radius=10+u*5+orbit*5
  n.draw_arc(p,radius,a,a+PI*1.55,20,Color(SILVER,.24+u*.30),1.1)
 n.draw_circle(p,11+u*8,Color(DEEP,.10+u*.09))
 n.draw_circle(p,6+u*4,Color(MIST,.12+u*.13))
 n.draw_circle(p,2+u*2,Color(SILVER,.22+u*.25))
 n.draw_circle(p,.8+u,Color(CORE,.75))
static func priest_dash_wake(n):
 var progress=clampf(n.action_age/maxf(.01,n.action_duration),0,1)
 var strength=.18+.40*sin(progress*PI)
 var face=n.facing
 var anchor=Vector2(-face*5,-n.body_height*.48)
 for strand in 3:
  var points=PackedVector2Array()
  for i in 9:
   var u=float(i)/8
   var length=27+strand*7
   var offset=(strand-1)*8+sin(n.time*11+u*4+strand)*2.5
   points.append(anchor+Vector2(-face*(6+u*length),offset))
  for i in range(1,points.size()):
   var u=float(i)/(points.size()-1)
   var fade=strength*(1-u*.68)
   var segment=PackedVector2Array([points[i-1],points[i]])
   n.draw_polyline(segment,Color(DEEP,fade*.52),3.8-strand*.5,true)
   n.draw_polyline(segment,Color(MIST,fade*.72),1.8-strand*.22,true)
   n.draw_polyline(segment,Color(SILVER,fade*.72),.55,true)
 var center_angle=PI if face>0 else 0.0
 var wake_center=anchor-Vector2(face*5,0)
 n.draw_arc(wake_center,12+sin(n.time*16)*2,center_angle-.92,center_angle+.92,24,Color(MIST,strength*.60),1.1)
 for i in 4:
  var u=fposmod(progress*1.4+i*.29,1)
  var mote=anchor+Vector2(-face*(8+u*33),(i-1.5)*6+sin(n.time*9+i)*2)
  n.draw_circle(mote,.8+u*.45,Color(CORE,strength*(1-u*.55)))
static func priest_rift_wake(n):
 var progress=clampf(n.action_age/maxf(.01,n.action_duration),0,1)
 var strength=.22+.38*sin(progress*PI)
 var center=Vector2(-n.facing*3,-n.body_height*.47)
 for layer in 2:
  var radius=lerpf(21+layer*6,9+layer*4,progress)
  var rotation=n.time*(4.2 if layer==0 else -3.1)+layer*PI*.45
  for segment in 3:
   var points=PackedVector2Array()
   var start=rotation+segment*TAU/3+.16
   for i in 9:
    var a=start+float(i)/8*TAU*.47
    points.append(center+Vector2(cos(a)*radius,sin(a)*radius*.58))
   n.draw_polyline(points,Color(DEEP,strength*.54),3.4-layer*.8,true)
   n.draw_polyline(points,Color(MIST,strength*(.60-layer*.12)),1.15,true)
   n.draw_polyline(points,Color(SILVER,strength*(.72-layer*.14)),.48,true)
 for i in 5:
  var a=n.time*5.5+i*TAU/5
  var radial=Vector2(cos(a),sin(a)*.7)
  var start=center+radial*7
  var finish=center+radial*(13+progress*9)
  n.draw_line(start,finish,Color(MIST,strength*.42),.8,true)
  n.draw_circle(finish,.85,Color(CORE,strength*.82))
static func orb(n,p,direction,alpha,clock):
 var d=direction.normalized() if direction.length_squared()>.01 else Vector2.RIGHT
 var side=d.orthogonal()
 var pulse=.5+.5*sin(clock*9)
 n.draw_circle(p,17+pulse*2,Color(DEEP,.08*alpha))
 n.draw_arc(p,15+pulse*1.4,clock*1.5,clock*1.5+TAU*.78,32,Color(MIST,.42*alpha),1.5)
 n.draw_arc(p,11,clock*-1.9+PI,clock*-1.9+PI+TAU*.52,28,Color(CORE,.50*alpha),1.0)
 # A bright lunar face under a drifting eclipse makes the projectile read as a moon.
 n.draw_circle(p,9.4,Color(DEEP,.92*alpha))
 n.draw_circle(p+Vector2(-1.8,-.6),7.5,Color(SILVER,.88*alpha))
 n.draw_circle(p+Vector2(3.5,-1.3),6.7,Color(DEEP,.96*alpha))
 n.draw_arc(p+Vector2(-.4,0),8.3,-PI*.77,PI*.77,24,Color(CORE,.86*alpha),1.15)
 n.draw_circle(p+Vector2(-3.4,-2.5),1.25,Color(CORE,.78*alpha))
 n.draw_circle(p+Vector2(-2.2,3.2),.85,Color(MIST,.74*alpha))
 for i in 3:
  var a=clock*2.3+i*TAU/3
  var mote=p+Vector2(cos(a)*14,sin(a)*8)
  n.draw_circle(mote,1.1,Color(CORE,.78*alpha))
 needle(n,p,d,30,1.8,alpha,sin(clock*4)*4)
 needle(n,p-d*8+side*sin(clock*5)*4,d,20,.6,alpha*.70,-4)
 needle(n,p-d*13-side*sin(clock*5)*4,d,15,.42,alpha*.48,3)
static func orb_trail(n,points,alpha):
 if points.size()<2:return
 for i in range(1,points.size()):
  var progress=float(i)/(points.size()-1)
  var strength=alpha*pow(progress,1.35)
  var segment=PackedVector2Array([points[i-1],points[i]])
  n.draw_polyline(segment,Color(DEEP,.22*strength),6.0*progress,true)
  n.draw_polyline(segment,Color(MIST,.34*strength),3.2*progress,true)
  n.draw_polyline(segment,Color(SILVER,.50*strength),1.0*progress,true)
  n.draw_polyline(segment,Color(CORE,.28*strength),.38*progress,true)
static func shard_warning(n,p,progress,clock):
 var target=p+Vector2(0,320)
 var strength=.12+.22*progress
 n.draw_line(p,target,Color(MIST,strength*.45),1.0,true)
 for i in 9:
  var t=fposmod(clock*1.1+i/9.0,1.0)
  var mote=p.lerp(target,t)
  n.draw_circle(mote,.8+progress*.35,Color(SILVER,strength*(.35+.45*sin(t*PI))))
 needle(n,p,Vector2.DOWN,13,.55,strength+.10,sin(clock*4)*1.5)
 var radius=10+progress*12
 for ring in 2:
  var r=radius*(.72+ring*.36)
  var ellipse=PackedVector2Array()
  for i in 33:
   var a=TAU*float(i)/32+clock*(.38 if ring==0 else -.24)
   ellipse.append(target+Vector2(cos(a)*r,sin(a)*r*.22))
  n.draw_polyline(ellipse,Color(MIST,strength*(.46 if ring==0 else .24)),.9,true)
 for i in 4:
  var a=i*PI*.5+clock*.18
  var d=Vector2(cos(a),sin(a)*.22)
  n.draw_line(target+d*radius*.78,target+d*radius*1.18,Color(CORE,strength*.82),.9,true)
 var ground=PackedVector2Array()
 for i in 19:
  var angle=lerpf(-PI,0,float(i)/18)
  ground.append(target+Vector2(cos(angle)*radius,sin(angle)*radius*.34))
 n.draw_polyline(ground,Color(MIST,strength*.9),1.2,true)
 n.draw_polyline(PackedVector2Array([target-Vector2(radius+3,0),target-Vector2(radius,0)]),Color(CORE,strength),1.1,true)
 n.draw_polyline(PackedVector2Array([target+Vector2(radius,0),target+Vector2(radius+3,0)]),Color(CORE,strength),1.1,true)
static func falling_shard(n,p,alpha,clock):
 var sway=sin(clock*14)*1.8
 var top=p+Vector2(sway,-12)
 var points=PackedVector2Array([top+Vector2(-3.1,2),top+Vector2(.9,-7),top+Vector2(3.8,2),top+Vector2(2.0,14),top+Vector2(0,19),top+Vector2(-3.2,10)])
 var inner=PackedVector2Array([top+Vector2(-1.0,0),top+Vector2(.8,-3.2),top+Vector2(1.5,10),top+Vector2(0,15)])
 stroke(n,PackedVector2Array([p+Vector2(0,-28),top+Vector2(0,14)]),alpha*.88,1.55)
 stroke(n,PackedVector2Array([p+Vector2(-3.5,-19),top+Vector2(-2.6,3)]),alpha*.34,.65)
 stroke(n,PackedVector2Array([p+Vector2(3.5,-19),top+Vector2(2.6,3)]),alpha*.34,.65)
 n.draw_colored_polygon(points,Color(DEEP,.62*alpha))
 n.draw_colored_polygon(inner,Color(SILVER,.88*alpha))
 n.draw_line(top+Vector2(-.7,1),top+Vector2(.8,9),Color(CORE,alpha),.9,true)
 n.draw_circle(top+Vector2(0,-8),2.2,Color(MIST,.48*alpha))
 n.draw_circle(top+Vector2(0,-8),.8,Color(CORE,.9*alpha))
 needle(n,p+Vector2(sway,-14),Vector2.DOWN,16,.42,alpha*.42,-1.5)
static func shard_impact(n,p,progress,alpha,clock):
 var u=clampf(progress,0,1)
 var bloom=sin(u*PI)
 var radius=lerpf(5,28,smoothstep(0,1,u))
 var floor=p+Vector2(0,2)
 for layer in 2:
  var ellipse=PackedVector2Array()
  for i in 25:
   var a=lerpf(PI,TAU,float(i)/24)+clock*(.14 if layer==0 else -.10)
   ellipse.append(floor+Vector2(cos(a)*radius*(.72 if layer==0 else 1.0),sin(a)*radius*.24))
  n.draw_polyline(ellipse,Color(MIST,alpha*(.42-layer*.11)),2.0-layer*.65,true)
  n.draw_polyline(ellipse,Color(SILVER,alpha*(.54-layer*.16)),.8,true)
 for i in 7:
  var a=lerpf(PI,TAU,float(i)/6)+sin(clock*8+i)*.04
  var d=Vector2(cos(a),sin(a)*.62).normalized()
  var start=floor+d*(radius*(.18+.12*(i%2)))
  var length=5+bloom*(7+fposmod(i*2.3,5))
  needle(n,start,d,length,.38,alpha*(.28+.58*bloom),sin(clock*5+i)*.5)
 n.draw_line(floor-Vector2(0,2+bloom*8),floor+Vector2(0,1),Color(CORE,alpha*(.48+.5*bloom)),.9,true)
 n.draw_circle(floor,1.2+bloom*1.4,Color(CORE,alpha*(.56+.4*bloom)))
static func wave(n,p,life,u,face):
 var progress=clampf(u,0,1)
 var rise=sin(progress*PI)
 var width=lerpf(19,31,progress)
 var drift=face*lerpf(-8,11,progress)
 var tide=PackedVector2Array()
 var hollow=PackedVector2Array()
 for i in 17:
  var t=float(i)/16
  var x=lerpf(-width,width,t)
  var crest=sin(t*PI)
  var shimmer=sin(t*TAU+progress*5)*2.0*crest
  tide.append(p+Vector2(drift+x*face,13-crest*(21+rise*9)-shimmer))
  hollow.append(p+Vector2(drift+x*face,13-crest*(8+rise*5)))
 var surf=tide.duplicate()
 for i in range(hollow.size()-1,-1,-1):surf.append(hollow[i])
 n.draw_colored_polygon(surf,Color(DEEP,.14*life*rise))
 n.draw_polyline(tide,Color(MIST,.40*life*rise),3.2,true)
 n.draw_polyline(tide,Color(SILVER,.56*life*rise),1.05,true)
 var inner_surf=PackedVector2Array()
 var inner_lower=PackedVector2Array()
 for i in 17:
  var t=float(i)/16
  var x=lerpf(-width*.74,width*.74,t)
  inner_surf.append(p+Vector2(drift+x*face,13-sin(t*PI)*(10+rise*7)))
  inner_lower.append(p+Vector2(drift+x*face,13-sin(t*PI)*3))
 var inner_ribbon=inner_surf.duplicate()
 for i in range(inner_lower.size()-1,-1,-1):inner_ribbon.append(inner_lower[i])
 n.draw_colored_polygon(inner_ribbon,Color(SILVER,.10*life*rise))
 for layer in 4:
  var points=PackedVector2Array()
  for i in 25:
   var t=float(i)/24;var x=lerpf(-width,width,t)*face+drift
   var y=14-sin(t*PI)*rise*(29-layer*5)+sin(t*TAU+progress*4+layer)*layer*1.5
   points.append(p+Vector2(x,y))
  stroke(n,points,life*(.34-layer*.065),1.5-layer*.2)
 n.draw_arc(p+Vector2(0,15),9+u*23,PI,TAU,24,Color("c9c0e9",life*(.24+.28*rise)),1.25)
 n.draw_arc(p+Vector2(0,15),5+u*15,PI,TAU,20,Color("fff0ce",life*.34*rise),.9)
 for side in [-1,1]:
  var a=p+Vector2(drift+side*(width*.72),8)
  needle(n,a,Vector2(face*side,-.12),14+rise*4,.65,life*(.32+.32*rise),side*2.5)
 for i in 3:
  var t=fposmod(progress*1.5+i*.34,1)
  var q=p+Vector2(drift+face*(t-.5)*width*1.7,-4-sin(t*PI)*12)
  n.draw_circle(q,1.3,Color(CORE,life*sin(t*PI)*.75*rise))
static func ritual_blade(n,p,direction,alpha,clock):
 var d=direction.normalized() if direction.length_squared()>.01 else Vector2.RIGHT
 var side=d.orthogonal();var angle=d.angle()
 var pulse=.5+.5*sin(clock*13)
 var outer=PackedVector2Array()
 var inner=PackedVector2Array()
 for i in 13:
  var a=lerpf(angle-.92,angle+1.02,float(i)/12)
  var radial=Vector2(cos(a),sin(a))
  outer.append(p-d*2+radial*(15+pulse*1.5))
  inner.append(p-d*2+radial*8)
 var wake=outer.duplicate()
 for i in range(inner.size()-1,-1,-1):wake.append(inner[i])
 n.draw_colored_polygon(wake,Color(MIST,.18*alpha))
 n.draw_polyline(outer,Color(SILVER,.34*alpha),.85,true)
 needle(n,p,d,27,1.35,alpha,sin(clock*4)*3.5)
 n.draw_arc(p-d*3,14,angle-.82,angle+.93,20,Color(DEEP,.50*alpha),3.2)
 n.draw_arc(p-d*3,11,angle-.72,angle+.75,18,Color(SILVER,.82*alpha),1.4)
 n.draw_arc(p-d*3,7,angle-.52,angle+.48,14,Color(CORE,.74*alpha),.9)
 var flash=p+d*(8+pulse*3)
 n.draw_circle(flash,1.1+pulse*.5,Color(CORE,.8*alpha))
 for side_sign in [-1,1]:
  var mote=p-d*(10+fposmod(clock*16+side_sign*7,15))+side*side_sign*8
  n.draw_circle(mote,1.5,Color(CORE,.72*alpha))
static func ritual_warning(n,p,direction,progress,clock):
 var d=direction.normalized() if direction.length_squared()>.01 else Vector2.RIGHT
 var alpha=clampf(progress,0,1)
 var side=d.orthogonal();var angle=d.angle()
 var start=p+d*4
 var tip=p+d*(11+alpha*7)
 var radius=lerpf(5,13,alpha)
 var sector=PackedVector2Array([p+d*2])
 var rim=PackedVector2Array()
 for i in 11:
  var a=lerpf(angle-.82,angle+.82,float(i)/10)+sin(clock*5)*.025
  var q=p+Vector2(cos(a),sin(a))*radius
  sector.append(q);rim.append(q)
 n.draw_colored_polygon(sector,Color(MIST,.07+.10*alpha))
 n.draw_polyline(rim,Color(MIST,.24+.26*alpha),.8,true)
 n.draw_line(start,tip,Color(MIST,.20+.22*alpha),.8+alpha*.45,true)
 needle(n,tip,d,8+alpha*3,.38,.16+.22*alpha,sin(clock*12)*.8)
 n.draw_line(tip-side*2.5,tip+side*2.5,Color(CORE,.18+.36*alpha),.8,true)
 n.draw_arc(p+d*2,3+alpha*2,angle-.9+clock*.3,angle+.9+clock*.3,16,Color(SILVER,.17+.20*alpha),.7)
static func crescent_blade(n,p,direction,alpha,clock):
 var travel=direction.normalized() if direction.length_squared()>.01 else Vector2.RIGHT
 var spin=clock*TAU*.85
 var d=travel.rotated(spin+sin(clock*8)*.035)
 var side=d.orthogonal()
 var blade=PackedVector2Array()
 for i in 13:
  var a=lerpf(-1.15,1.15,float(i)/12)
  blade.append(p+d*(cos(a)*14)+side*(sin(a)*14))
 for i in range(11,0,-1):
  var t=float(i)/12
  var a=lerpf(-1.15,1.15,t)
  var radius=14-6*sin(t*PI)
  blade.append(p+d*(cos(a)*radius)+side*(sin(a)*radius))
 var shadow=PackedVector2Array()
 for q in blade:shadow.append(q+Vector2(1.2,1.5))
 n.draw_colored_polygon(shadow,Color(DEEP,.64*alpha))
 n.draw_colored_polygon(blade,Color(MIST,.88*alpha))
 var rim=PackedVector2Array()
 for i in 13:rim.append(blade[i])
 n.draw_polyline(rim,Color(SILVER,.94*alpha),1.25,true)
 n.draw_line(p+d*10-side*5,p+d*13,Color(CORE,.88*alpha),.9,true)
 stroke(n,PackedVector2Array([p-travel*23,p-travel*13]),alpha*.42,.7)
 for side_sign in [-1,1]:
  var orbit=spin+side_sign*PI*.5
  var mote=p+Vector2(cos(orbit)*17,sin(orbit)*10)
  n.draw_circle(mote,.9,Color(CORE,.70*alpha))
static func staff_sweep(n,hand,tip,face,progress,alpha):
 var swing=sin(clampf(progress,0,1)*PI)*alpha
 if swing<=.01:return
 var staff=(tip-hand).normalized()
 var center=hand.lerp(tip,.78)
 var start=staff.angle()-face*1.45
 var finish=staff.angle()+face*(.1+progress*1.35)
 var outer=PackedVector2Array()
 var inner=PackedVector2Array()
 for i in 19:
  var a=lerpf(start,finish,float(i)/18)
  var radial=Vector2(cos(a),sin(a))
  outer.append(center+radial*38)
  inner.append(center+radial*28)
 var blade=outer.duplicate()
 for i in range(inner.size()-1,-1,-1):blade.append(inner[i])
 n.draw_colored_polygon(blade,Color(MIST,.22*swing))
 stroke(n,outer,swing*.80,1.0)
 stroke(n,inner,swing*.58,.55)
 n.draw_polyline(inner,Color(CORE,.28*swing),.55,true)
 for i in 3:
  var t=fposmod(n.time*.68+i/3.0,1.0)
  var a=lerpf(start,finish,t)
  var radial=Vector2(cos(a),sin(a))
  var spark=center+radial*(34+sin(n.time*8+i)*2.5)
  needle(n,spark,radial,3.5,.22,swing*.40,0)
 var tip_point=outer[outer.size()-1]
 needle(n,tip_point,Vector2(cos(finish),sin(finish)),7,.42,swing*.55,0)
static func staff_thrust(n,hand,tip,progress,alpha):
 var d=(tip-hand).normalized()
 if d.length_squared()<.01:return
 var side=d.orthogonal()
 var u=clampf(progress,0,1)
 var reach=lerpf(8,30,smoothstep(0,1,u))
 var end=tip+d*reach
 var width=lerpf(4.2,2.0,u)
 var power=alpha*(.34+.66*sin(u*PI))
 var silhouette=PackedVector2Array([tip+side*width,end,tip-side*width])
 n.draw_colored_polygon(silhouette,Color(DEEP,.34*power))
 stroke(n,PackedVector2Array([tip+side*.7,end]),power*.94,1.1)
 n.draw_arc(end,3+sin(u*PI)*3,-PI*.72,PI*.72,16,Color(SILVER,.68*power),1.0)
 needle(n,end,d,7,.36,power*.62,0)
static func beam(n,p,face,length,alpha,clock):
 var tip=p+Vector2(face*length,0)
 var pulse=sin(clock*11)
 var path=PackedVector2Array()
 var upper=PackedVector2Array()
 var lower=PackedVector2Array()
 for i in 17:
  var u=float(i)/16
  var q=p.lerp(tip,u)+Vector2(0,sin(clock*8-u*2.4)*2.2*u)
  var envelope=sin(pow(u,.72)*PI)
  var ripple=sin(clock*13-u*TAU*2.6)*1.6
  upper.append(q+Vector2(0,-(4+envelope*5+ripple)))
  lower.append(q+Vector2(0,4+envelope*5+ripple))
  path.append(q)
 var silhouette=upper.duplicate()
 for i in range(lower.size()-1,-1,-1):silhouette.append(lower[i])
 n.draw_colored_polygon(silhouette,Color(DEEP,.18*alpha))
 n.draw_polyline(upper,Color(MIST,.34*alpha),2.0,true)
 n.draw_polyline(lower,Color(MIST,.34*alpha),2.0,true)
 n.draw_polyline(path,Color(DEEP,.26*alpha),26,true)
 n.draw_polyline(path,Color(MIST,.30*alpha),17,true)
 n.draw_polyline(path,Color(SILVER,.48*alpha),9,true)
 n.draw_polyline(path,Color(CORE,.92*alpha),2.4,true)
 for i in 7:
  var u=fposmod(clock*1.9+i/7.0,1.0)
  var q=p.lerp(tip,u)+Vector2(0,sin(clock*8-u*2.4)*2.2*u)
  var strength=alpha*(.34+.66*sin(u*PI))
  needle(n,q,Vector2(face,0),15+sin(clock*9+i)*3,.48,strength,sin(clock*7+i)*1.4)
 for i in 4:
  var u=(i+1)/5.0
  var q=p.lerp(tip,u)+Vector2(0,sin(clock*8-u*2.4)*2.2*u)
  var radius=4.5+sin(clock*7+i)*1.1
  n.draw_arc(q,radius,clock*1.3+i,clock*1.3+i+PI*1.62,18,Color(SILVER,.56*alpha),1.05)
  n.draw_circle(q,1.15,Color(CORE,.72*alpha))
 # A rotating halo at the staff end sells the cast; the far end blooms on every pulse.
 n.draw_arc(p,9+pulse,clock*1.6,clock*1.6+PI*1.55,24,Color(MIST,.48*alpha),1.8)
 n.draw_arc(p,5,clock*-1.2,clock*-1.2+PI*1.25,18,Color(CORE,.64*alpha),1.0)
 var bloom=10+sin(clock*10)*2
 n.draw_arc(tip,bloom,clock*2,clock*2+TAU*.82,28,Color(SILVER,.72*alpha),1.5)
 for i in 8:
  var a=TAU*i/8+clock*.65
  var direction=Vector2(cos(a),sin(a))
  needle(n,tip+direction*(3+sin(clock*9+i)*1.5),direction,8 if i%2==0 else 5,.65,alpha*(.45 if i%2==0 else .27),0)
 n.draw_circle(tip,2.4,Color(CORE,.88*alpha))
