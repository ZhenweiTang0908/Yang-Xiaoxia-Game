extends RefCounted
static func falling_blade(canvas,rect,alpha=1.0):
 var x=rect.get_center().x;var y=rect.position.y;var tip=rect.end.y
 canvas.draw_colored_polygon(PackedVector2Array([Vector2(x-4,y+10),Vector2(x+4,y+10),Vector2(x+3,tip-10),Vector2(x,tip),Vector2(x-3,tip-10)]),Color(Color("bac5ca"),alpha))
 canvas.draw_line(Vector2(x,y+12),Vector2(x,tip-3),Color(Color("f0eee0"),alpha),1)
 canvas.draw_line(Vector2(x-7,y+9),Vector2(x+7,y+9),Color(Color("a9a185"),alpha),2)
 canvas.draw_line(Vector2(x,y),Vector2(x,y+8),Color(Color("666c7d"),alpha),3)
# Small semantic after-effects. These have no collision and never extend damage time.
static func draw_finish(canvas,e):
 var u=clampf(e.age/e.life,0,1);var fade=1-u
 var r=e.rect
 match e.kind:
  "rain":falling_blade(canvas,r,fade*fade)
  "fire","breath":
   var count=mini(5,maxi(2,int(r.size.x/75)))
   for i in count:
    var x=lerpf(r.position.x+5,r.end.x-5,(i+.5)/count)
    var y=r.end.y-4-u*(12+i%2*7)
    canvas.draw_line(Vector2(x,y),Vector2(x+sin(i*2.1+u*3)*3,y-2),Color(.87,.49,.29,fade*.65),1)
  "spirit_beam":
   var y=r.get_center().y
   for i in 4:
    var x=lerpf(r.position.x+8,r.end.x-8,(i+.5)/4)
    canvas.draw_line(Vector2(x-4-u*5,y+(i%2*2-1)*5),Vector2(x+4+u*5,y+(i%2*2-1)*5),Color(.60,.55,.73,fade*.38),1)
  "ritual":
   var count=mini(5,maxi(2,int(r.size.x/100)))
   for i in count:
    var x=lerpf(r.position.x+8,r.end.x-8,(i+.5)/count)
    var y=r.end.y-4-u*(9+i%2*6)
    canvas.draw_line(Vector2(x-3-u*3,y),Vector2(x+2+u*4,y-3),Color(.57,.53,.70,fade*.48),1)
  "stone_wave","stone_impact":
   for i in 3:
    var x=r.get_center().x+(i-1)*(8+u*12)
    var p=Vector2(x,r.end.y-2-sin(u*PI)*3)
    canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-2,0),p+Vector2(-1,-3),p+Vector2(2,-1),p+Vector2(2,1)]),Color(.40,.48,.47,fade*.65))
  "antler_sweep":
   for i in 4:
    var direction=-1.0+i/1.5
    var p=Vector2(r.get_center().x+direction*(16+u*24),r.end.y-3-u*(4+i%2*3))
    canvas.draw_line(p,p+Vector2(direction*4,-2),Color(.68,.77,.73,fade*.48),1)
  "blade_sweep":
   var center=r.get_center()
   for i in 3:
    var x=(i-1)*(9+u*12)
    canvas.draw_line(center+Vector2(x,-2-u*4),center+Vector2(x+5,-5-u*7),Color(.76,.84,.80,fade*.42),1)
  "spectral_horn":
   var center=Vector2(r.get_center().x,r.end.y-7)
   for i in 3:
    var side=-1 if i%2==0 else 1
    var p=center+Vector2((i-1)*(12+u*8),side*(2+u*3))
    canvas.draw_line(p-Vector2(4+u*4,0),p+Vector2(4+u*4,side*2),Color(.60,.56,.72,fade*.42),1)
  "binding_rune":
   var center=Vector2(r.get_center().x,r.end.y-3)
   canvas.draw_set_transform(center,0,Vector2(1,.28))
   canvas.draw_arc(Vector2.ZERO,r.size.x*(.38+u*.08),0,TAU,20,Color(.56,.51,.68,fade*.32),1)
   canvas.draw_set_transform(Vector2.ZERO)
  "pounce_impact":
   var center=Vector2(r.get_center().x,r.end.y)
   for side in [-1,1]:canvas.draw_line(center+Vector2(side*(5+u*9),-2),center+Vector2(side*(8+u*13),-4-u*3),Color(.58,.54,.47,fade*.38),1)
  "rift":
   var center=r.get_center()
   for i in 4:
    var side=-1 if i%2==0 else 1
    var p=center+Vector2(side*(3+u*(7+i*2)),(i-1.5)*8-u*5)
    canvas.draw_line(p,p+Vector2(side*3,-3),Color(.55,.49,.69,fade*.5),1)
  "ground_rift":
   var center=Vector2(r.get_center().x,r.end.y-2)
   for i in 3:
    var p=center+Vector2((i-1)*(7+u*4),-u*(2+i%2*3))
    canvas.draw_line(p-Vector2(2,0),p+Vector2(2,-2),Color(.48,.42,.60,fade*.48),1)
  "spirit_lightning":
   var center=Vector2(r.get_center().x,r.end.y-1)
   canvas.draw_line(center-Vector2(10+u*4,0),center+Vector2(10+u*4,0),Color(.34,.29,.43,fade*.5),1)
   for side in [-1,1]:canvas.draw_line(center+Vector2(side*2,0),center+Vector2(side*(7+u*3),-3-u*3),Color(.55,.49,.68,fade*.42),1)
static func warning(canvas,h):
 var r=h.rect;var total=maxf(.001,h.get("warning_total",h.delay))
 var u=clampf(1-h.delay/total,0,1)
 var stone=h.kind in ["stone_wave","stone_impact","antler_sweep"]
 var c=Color("b5c7c0") if stone or h.kind=="blade_sweep" else Color("edb080")
 if h.kind=="ground_rift":
  c=Color("9484b2")
  var reveal=clampf(u,0,1);var crack=PackedVector2Array()
  for i in 6:
   var t=float(i)/5
   crack.append(Vector2(lerpf(r.position.x,r.end.x,t),r.end.y-1-sin(i*6.4)*3*reveal))
  canvas.draw_polyline(crack,Color(c,.25+reveal*.48),1)
 elif h.kind=="ritual":
  c=Color("9b8fbc")
  canvas.draw_line(Vector2(r.position.x,r.position.y+18),Vector2(r.position.x,r.end.y),Color(c,.18+u*.28),1)
  canvas.draw_line(Vector2(r.end.x,r.position.y+18),Vector2(r.end.x,r.end.y),Color(c,.18+u*.28),1)
  canvas.draw_line(Vector2(r.position.x,r.end.y-1),Vector2(r.end.x,r.end.y-1),Color(c,.34+u*.36),1)
  var count=mini(6,maxi(2,int(ceil(r.size.x/100.0))))
  for i in count:
   var x=r.position.x+(i+.5)*r.size.x/count
   canvas.draw_arc(Vector2(x,r.end.y-4),6,-PI*.18,PI*.82,7,Color(c,.28+u*.34),1)
 elif h.kind=="rift":
  var center=Vector2(r.get_center().x,r.end.y)
  var points=PackedVector2Array([center,center+Vector2(-2,-7-u*3),center+Vector2(2,-14-u*5),center+Vector2(-1,-22-u*6)])
  canvas.draw_polyline(points,Color(.61,.55,.73,.35+u*.45),1.2)
  canvas.draw_line(center-Vector2(12,0),center+Vector2(12,0),Color(.61,.55,.73,.25+u*.35),1)
 elif h.kind=="blade_sweep":
  var face=float(h.get("face",1.0));var center=r.get_center();var length=r.size.x*.42
  canvas.draw_line(center-Vector2(face*length,-4),center+Vector2(face*length,-4),Color(c,.22+u*.36),1)
  var tip=center+Vector2(face*length,-4)
  canvas.draw_line(tip-Vector2(face*7,4),tip,Color(c,.45+u*.35),1)
 elif h.kind=="antler_sweep":
  var center=Vector2(r.get_center().x,r.end.y+8)
  for side in [-1,1]:
   var points=PackedVector2Array([center+Vector2(side*8,-2),center+Vector2(side*25,-8-u*4),center+Vector2(side*45,-4-u*7)])
   canvas.draw_polyline(points,Color(c,.38+u*.42),1.5)
   var tine=points[1]
   canvas.draw_line(tine,tine+Vector2(side*8,-7),Color(c,.30+u*.35),1)
 elif h.kind=="spectral_horn":
  c=Color("9f94be");var y=r.end.y-8;var face=float(h.get("face",1.0))
  canvas.draw_line(Vector2(r.position.x,y),Vector2(r.end.x,y),Color(c,.26+u*.36),1)
  for i in 3:
   var x=lerpf(r.position.x,r.end.x,(i+1)/4.0)
   canvas.draw_polyline(PackedVector2Array([Vector2(x-face*5,y-4),Vector2(x,y),Vector2(x-face*5,y+4)]),Color(c,.42+u*.32),1)
 elif h.kind=="binding_rune":
  c=Color("9b8fbc");var center=Vector2(r.get_center().x,r.end.y-2)
  canvas.draw_set_transform(center,0,Vector2(1,.28))
  canvas.draw_arc(Vector2.ZERO,lerpf(5,r.size.x*.38,u),0,TAU,20,Color(c,.28+u*.5),1)
  canvas.draw_set_transform(Vector2.ZERO)
  for i in 4:
   var a=i*TAU/4;var p=center+Vector2.from_angle(a)*8*Vector2(1,.28)
   canvas.draw_circle(p,1,Color(c,.35+u*.4))
 elif h.kind=="pounce_impact":
  c=Color("c0b6a0");var center=Vector2(r.get_center().x,r.end.y-1)
  canvas.draw_line(center-Vector2(r.size.x*.35,0),center+Vector2(r.size.x*.35,0),Color(c,.25+u*.5),1)
  for side in [-1,1]:canvas.draw_polyline(PackedVector2Array([center+Vector2(side*5,-1),center+Vector2(side*10,-5-u*3),center+Vector2(side*14,-2)]),Color(c,.28+u*.45),1)
 elif h.kind in ["beam","breath","spirit_beam"]:
  if h.kind=="spirit_beam":c=Color("a99bc7")
  var y=r.get_center().y
  canvas.draw_line(Vector2(r.position.x,y),Vector2(r.end.x,y),Color(c,.35+u*.4),1)
  var face=h.get("face",1.0)
  for i in 3:
   var x=r.position.x+r.size.x*(i+1)/4
   canvas.draw_polyline(PackedVector2Array([Vector2(x-face*4,y-4),Vector2(x,y),Vector2(x-face*4,y+4)]),Color(c,.6),1)
 elif h.kind in ["lightning","spirit_lightning","rain"]:
  if h.kind=="spirit_lightning":c=Color("9f94be")
  var x=r.get_center().x
  canvas.draw_line(Vector2(x,r.position.y),Vector2(x,r.end.y),Color(c,.2+u*.25),1)
  canvas.draw_line(Vector2(r.position.x,r.end.y),r.end,Color(c,.8),2)
  if h.kind in ["lightning","spirit_lightning"]:
   var y=r.position.y+3
   if h.kind=="spirit_lightning":
    var center=Vector2(x,y+10)
    canvas.draw_arc(center,9,0,TAU,12,Color(c,.42+u*.38),1)
    canvas.draw_polyline(PackedVector2Array([center+Vector2(0,-5),center+Vector2(5,0),center+Vector2(0,5),center+Vector2(-5,0),center+Vector2(0,-5)]),Color(c,.48+u*.35),1)
   else:canvas.draw_polyline(PackedVector2Array([Vector2(x+3,y),Vector2(x-3,y+7),Vector2(x+2,y+7),Vector2(x-2,y+15)]),Color(c,.55+u*.3),1.5)
  else:
   # A hanging blade identifies sword rain before it drops; the ground line
   # still marks the exact threatened width without filling the safe space.
   var y=r.position.y+3+u*3
   canvas.draw_colored_polygon(PackedVector2Array([Vector2(x-2,y),Vector2(x+2,y),Vector2(x+1,y+10),Vector2(x,y+14),Vector2(x-1,y+10)]),Color(c,.55+u*.3))
   canvas.draw_line(Vector2(x-4,y),Vector2(x+4,y),Color(c,.8),1)
   canvas.draw_line(Vector2(x,y-4),Vector2(x,y),Color(c,.8),1)
 else:
  canvas.draw_line(Vector2(r.position.x,r.end.y-1),r.end-Vector2(0,1),Color(c,.55+u*.3),1+u)
  var count=mini(10,maxi(2,int(r.size.x/36)))
  if h.kind=="fire":count=mini(5,maxi(1,int(ceil(r.size.x/60))))
  for i in count:
   var x=r.position.x+(i+.5)*r.size.x/count
   if stone:canvas.draw_polyline(PackedVector2Array([Vector2(x-4,r.end.y-1),Vector2(x,r.end.y-5-u*2),Vector2(x+4,r.end.y-2)]),Color(c,.6),1)
   elif h.kind=="fire":
    var base=Vector2(x,r.end.y-2);var height=3+u*6
    canvas.draw_colored_polygon(PackedVector2Array([base+Vector2(-3,0),base+Vector2(-2,-height*.5),base+Vector2(1,-height),base+Vector2(1,-height*.4),base+Vector2(3,-height*.65),base+Vector2(3,0)]),Color(c,.3+u*.35))
   else:canvas.draw_line(Vector2(x,r.end.y-2),Vector2(x,r.end.y-4-u*3),Color(c,.55),1)
