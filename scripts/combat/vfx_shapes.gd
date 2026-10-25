extends RefCounted
# Layered silhouettes, shared by hazards, projectiles and environmental flames.
static func flame(canvas,p,width,height,clock,color=Color("ed884b")):
 for layer in 3:
  var w=width*(1.0-layer*.25);var h=height*(1.0-layer*.28)
  var points=PackedVector2Array([p+Vector2(-w*.5,0)])
  for i in range(9):
   var x=-w*.5+w*i/8.0
   var rise=(.3+.7*absf(sin(i*1.9+clock*9))) * sin(PI*(i+.5)/9)
   points.append(p+Vector2(x,-h*rise))
  points.append(p+Vector2(w*.5,0))
  var shade=color if layer==0 else color.lerp(Color("fff0b2"),layer*.36)
  shade.a=color.a
  canvas.draw_colored_polygon(points,shade)
static func bolt(canvas,start,end,clock,color):
 if start.is_equal_approx(end) or color.a<=0:return
 var direction=(end-start).normalized()
 var normal=Vector2(-direction.y,direction.x)
 var amplitude=minf(12,start.distance_to(end)*.12)
 var points=PackedVector2Array([start])
 for i in range(1,8):points.append(start.lerp(end,i/8.0)+normal*sin(i*17+floor(clock*14))*amplitude)
 points.append(end)
 canvas.draw_polyline(points,Color(color,color.a*.2),9)
 canvas.draw_polyline(points,color,3)
 canvas.draw_polyline(points,Color(Color("fff2cf"),color.a),1)
static func spirit_lightning(canvas,rect,phase,clock,color):
 var u=clampf(phase,0,1);var fade=1-smoothstep(.72,1,u);var x=rect.get_center().x
 var sigil=Vector2(x,rect.position.y+14)
 canvas.draw_arc(sigil,12,0,TAU,16,Color(color,color.a*.72*fade),1.4)
 var diamond=PackedVector2Array([sigil+Vector2(0,-7),sigil+Vector2(7,0),sigil+Vector2(0,7),sigil+Vector2(-7,0),sigil+Vector2(0,-7)])
 canvas.draw_polyline(diamond,Color(.80,.82,.91,.68*fade),1)
 bolt(canvas,sigil+Vector2(0,12),Vector2(x,rect.end.y),clock,Color(color,color.a*fade))
 var ground=Vector2(x,rect.end.y)
 canvas.draw_line(ground-Vector2(12,0),ground+Vector2(12,0),Color(.49,.43,.61,.62*fade),1.5)
 for side in [-1,1]:canvas.draw_line(ground+Vector2(side*3,-1),ground+Vector2(side*9,-5-u*3),Color(.62,.57,.73,.46*fade),1)
static func spirit_beam(canvas,quad,clock,color):
 if quad.is_empty():return
 var start=(quad[0]+quad[3])*.5;var finish=(quad[1]+quad[2])*.5
 var direction=(finish-start).normalized();var normal=Vector2(-direction.y,direction.x)
 var half=quad[0].distance_to(quad[3])*.5
 var core=PackedVector2Array();var upper=PackedVector2Array();var lower=PackedVector2Array()
 for i in 13:
  var t=float(i)/12;var center=start.lerp(finish,t);var wave=sin(clock*15-i*1.3)*minf(2.5,half*.12)*t
  core.append(center+normal*wave)
  upper.append(center+normal*(half*.55+wave));lower.append(center+normal*(-half*.55+wave))
 canvas.draw_polyline(upper,Color(color,color.a*.34),1.3)
 canvas.draw_polyline(lower,Color(color,color.a*.34),1.3)
 canvas.draw_polyline(core,Color(color,color.a*.22),8)
 canvas.draw_polyline(core,Color(.88,.90,.98,color.a*.9),2)
 canvas.draw_arc(start,7,0,TAU,12,Color(color,color.a*.72),1)
static func binding_rune(canvas,rect,phase,clock,color):
 var u=clampf(phase,0,1);var fade=1-smoothstep(.68,1,u);var center=Vector2(rect.get_center().x,rect.end.y-3)
 canvas.draw_set_transform(center,0,Vector2(1,.28))
 canvas.draw_arc(Vector2.ZERO,rect.size.x*.38,0,TAU,24,Color(color,.64*fade),1.4)
 canvas.draw_arc(Vector2.ZERO,rect.size.x*.23,clock*.35,TAU+clock*.35,16,Color(color,.34*fade),1)
 for i in 4:
  var a=i*TAU/4+clock*.12;var inner=Vector2.from_angle(a)*rect.size.x*.13;var outer=Vector2.from_angle(a)*rect.size.x*.34
  canvas.draw_line(inner,outer,Color(.76,.73,.86,.55*fade),1)
 canvas.draw_set_transform(Vector2.ZERO)
 var lift=sin(minf(1,u/.55)*PI)*8
 for side in [-1,1]:canvas.draw_line(center+Vector2(side*9,-lift),center+Vector2(side*13,-lift-5),Color(color,.42*fade),1)
static func pounce_impact(canvas,rect,phase,color):
 var u=clampf(phase,0,1);var fade=1-smoothstep(.62,1,u);var ground=Vector2(rect.get_center().x,rect.end.y)
 for i in 3:
  var side=-1.0+i;var start=ground+Vector2(side*4,-3);var finish=ground+Vector2(side*(13+u*8),-12-u*(5+i%2*3))
  canvas.draw_line(start,finish,Color(color,.72*fade),1.5)
  canvas.draw_line(finish,finish+Vector2(side*3,-2),Color(color,.48*fade),1)
 canvas.draw_arc(ground,lerpf(4,rect.size.x*.38,u),PI,TAU,14,Color(.55,.50,.43,.38*fade),1)
static func blade_sweep(canvas,rect,face,phase,color):
 var reveal=smoothstep(0,.42,clampf(phase,0,1));var center=rect.get_center();var width=rect.size.x
 var upper=PackedVector2Array();var lower=PackedVector2Array();var edge=PackedVector2Array()
 for i in 10:
  var u=reveal*i/9.0;var x=lerpf(-face*width*.48,face*width*.48,u)
  var y=-sin(u*PI)*maxf(7,rect.size.y*.62)
  var thickness=1.0+sin(u*PI)*2.8
  var point=center+Vector2(x,y);edge.append(point-Vector2(0,thickness));upper.append(point-Vector2(0,thickness));lower.append(point+Vector2(0,thickness))
 var shape=upper.duplicate()
 for i in range(lower.size()-1,-1,-1):shape.append(lower[i])
 var fill=Color(color,color.a*.24*(1-smoothstep(.72,1,phase)))
 canvas.draw_colored_polygon(shape,fill)
 canvas.draw_polyline(edge,Color(color,color.a*(1-smoothstep(.82,1,phase))),1.6)
 var tip=edge[-1];canvas.draw_line(tip,tip+Vector2(-face*7,4),Color(color,color.a*.72),1)
static func spectral_horn(canvas,rect,face,phase,color):
 var u=clampf(phase,0,1);var reveal=smoothstep(0,.34,u);var fade=1-smoothstep(.68,1,u)
 var direction=1.0 if face>=0 else -1.0;var start=Vector2(rect.position.x if direction>0 else rect.end.x,rect.end.y-8)
 var finish=Vector2(lerpf(start.x,rect.end.x if direction>0 else rect.position.x,reveal),start.y)
 var length=absf(finish.x-start.x)
 if length<2:return
 var trail=PackedVector2Array();var edge=PackedVector2Array()
 for i in 11:
  var t=float(i)/10;var p=start.lerp(finish,t);var lift=sin(t*PI)*minf(8,rect.size.y*.24)
  trail.append(p-Vector2(0,lift));edge.append(p-Vector2(0,lift+2.2))
 canvas.draw_polyline(trail,Color(color,color.a*.20*fade),7)
 canvas.draw_polyline(edge,Color(color,color.a*.82*fade),1.5)
 # A paired hooked tip reads as spectral horns without filling the lane.
 for side in [-1,1]:
  var root=finish+Vector2(-direction*8,side*3)
  var tip=finish+Vector2(direction*5,side*(6+2*sin(u*PI)))
  canvas.draw_polyline(PackedVector2Array([root,finish+Vector2(-direction*1,side*7),tip]),Color(.86,.88,.96,.82*fade),1.6)
 canvas.draw_line(start-Vector2(0,7),start+Vector2(0,7),Color(color,color.a*.48*fade),1)
static func rift(canvas,rect,phase,color):
 var u=clampf(phase,0,1);var open=sin(u*PI)*minf(10,rect.size.x*.12);var center=rect.get_center()
 var left=PackedVector2Array();var right=PackedVector2Array()
 for i in 8:
  var t=float(i)/7;var jitter=sin(i*9.7)*2.2
  var p=Vector2(center.x+jitter,lerpf(rect.end.y,rect.position.y,t))
  left.append(p-Vector2(open*(.55+.45*sin(t*PI)),0));right.append(p+Vector2(open*(.55+.45*sin(t*PI)),0))
 var void_shape=left.duplicate()
 for i in range(right.size()-1,-1,-1):void_shape.append(right[i])
 # At fully closed endpoints both edges coincide, so there is no valid area to triangulate.
 if open>.5:canvas.draw_colored_polygon(void_shape,Color(.055,.035,.10,.72*(1-u*.35)))
 canvas.draw_polyline(left,Color(color,color.a*(1-u*.35)),1.4);canvas.draw_polyline(right,Color(color,color.a*(1-u*.35)),1.4)
 var slash=center+Vector2(0,lerpf(rect.size.y*.28,-rect.size.y*.22,smoothstep(.1,.65,u)))
 canvas.draw_line(slash-Vector2(rect.size.x*.38,8),slash+Vector2(rect.size.x*.38,-8),Color(.88,.92,1,(1-u)*.78),1.5)
static func ground_rift(canvas,rect,phase,color):
 var u=clampf(phase,0,1);var reveal=smoothstep(0,.18,u);var fade=1-smoothstep(.72,1,u)
 var ground=rect.end.y;var crack=PackedVector2Array()
 for i in 7:
  var t=float(i)/6;var x=lerpf(rect.position.x,rect.end.x,t)
  var y=ground-2-sin(i*7.3)*minf(4,rect.size.y*.15)*reveal
  crack.append(Vector2(x,y))
 canvas.draw_polyline(crack,Color(.08,.06,.12,.9*fade),4)
 canvas.draw_polyline(crack,Color(color,color.a*.78*fade),1.3)
 var lift=sin(clampf(u/.42,0,1)*PI)*minf(15,rect.size.y*.55)
 for i in 3:
  var x=rect.position.x+(i+.5)*rect.size.x/3
  var base=Vector2(x,ground-2);var width=4+i%2*2;var height=(7+i*3)*reveal
  var shard=PackedVector2Array([base+Vector2(-width,0),base+Vector2(-2,-height*.45-lift),base+Vector2(2,-height-lift),base+Vector2(width,0)])
  canvas.draw_colored_polygon(shard,Color(.24,.21,.32,.82*fade))
  canvas.draw_line(shard[1],shard[2],Color(color,color.a*.62*fade),1)
static func moon_ritual(canvas,rect,phase,clock,color):
 var u=clampf(phase,0,1);var fade=1-smoothstep(.72,1,u)
 var ground=rect.end.y;var boundary=Color(color,color.a*.58*fade)
 canvas.draw_line(Vector2(rect.position.x,rect.position.y+18),Vector2(rect.position.x,ground),boundary,1)
 canvas.draw_line(Vector2(rect.end.x,rect.position.y+18),Vector2(rect.end.x,ground),boundary,1)
 var count=mini(8,maxi(2,int(ceil(rect.size.x/82.0))))
 for i in count:
  var x=rect.position.x+(i+.5)*rect.size.x/count
  var fall=fposmod(clock*.38+i*.31,1.0)
  var y=lerpf(rect.position.y+12,ground-18,fall)
  var thread=Color(.68,.65,.80,(.22+.34*(1-fall))*fade)
  canvas.draw_line(Vector2(x,y-18),Vector2(x+sin(i*2.4+clock*2)*2,y+9),thread,1)
  canvas.draw_circle(Vector2(x+sin(i*2.4+clock*2)*2,y+10),1.7,Color(.78,.81,.88,.72*fade))
 var moon=Vector2(rect.get_center().x,rect.position.y+42)
 canvas.draw_arc(moon,14,-PI*.45,PI*.55,16,Color(.72,.70,.84,.62*fade),2)
 canvas.draw_arc(moon+Vector2(5,0),10,-PI*.45,PI*.55,14,Color(.32,.28,.44,.75*fade),2)
 var runes=mini(6,maxi(2,int(ceil(rect.size.x/115.0))))
 for i in runes:
  var x=rect.position.x+(i+.5)*rect.size.x/runes
  var pulse=.68+.16*sin(clock*5+i*1.7)
  var rune_color=Color(.52,.48,.66,pulse*fade)
  canvas.draw_arc(Vector2(x,ground-5),8,-PI*.18,PI*.82,9,rune_color,1.2)
  canvas.draw_line(Vector2(x-6,ground-2),Vector2(x+7,ground-2),Color(rune_color,rune_color.a*.55),1)
 canvas.draw_line(Vector2(rect.position.x,ground-1),Vector2(rect.end.x,ground-1),Color(.25,.20,.34,.34*fade),3)
static func breath(canvas,mouth,length,height,face,clock,color):
 for layer in 3:
  var points=PackedVector2Array([mouth])
  var reach=length*(1-layer*.08)
  for i in range(1,13):
   var t=i/12.0
   points.append(mouth+Vector2(face*reach*t,-height*.2*t+sin(clock*18-i*1.7)*height*.08*t))
  for i in range(12,0,-1):
   var t=i/12.0
   points.append(mouth+Vector2(face*reach*t,height*(.8-layer*.23)*t+sin(clock*16-i*2)*height*.08*t))
  var shade=color.lerp(Color("fff1b5"),layer*.34);shade.a=color.a
  canvas.draw_colored_polygon(points,shade)
