extends RefCounted
# All light follows a weapon or a released strike; no pre-painted danger zones.
static func weapon_axis(k):
 var v=k.visual;var art=v.selected;var frame=v.selected_frame
 if art==v.foot and frame==3:return [v.foot_socket(3,"hand"),v.foot_socket(3,"spear_tip")]
 var points=[]
 if art==v.foot:
  if frame==4:points=[Vector2(205,112),Vector2(10,67)]
  elif frame==5:points=[Vector2(220,70),Vector2(9,55)]
 elif art==v.arsenal:
  if frame==4:points=[Vector2(212,87),Vector2(10,80)]
  elif frame==5:points=[Vector2(185,73),Vector2(10,68)]
 elif art==v.pressure:
  match frame:
   0:points=[Vector2(68,218),Vector2(14,9)]
   2:points=[Vector2(187,104),Vector2(9,9)]
   3:points=[Vector2(216,80),Vector2(10,86)]
   4:points=[Vector2(210,115),Vector2(10,216)]
   11:points=[Vector2(145,36),Vector2(9,9)]
 if points.is_empty():return []
 return [art.position+art.source_socket(frame,points[0]),art.position+art.source_socket(frame,points[1])]
static func draw(k):
 var blue=Color("a9dfef") if not k.empowered else Color("d4b5ef")
 if k.action in k.SPEAR.MOVES or k.action=="lunge":
  var beats=k.spear.times(k.action) if k.action!="lunge" else [k.prep_for("lunge")];var before=99.0
  for at in beats:
   if at>k.t:before=at-k.t;break
  if before<.42:
   var axis=weapon_axis(k)
   if not axis.is_empty():
    var strength=smoothstep(.42,.03,before)*.22
    k.draw_line(axis[0],axis[1],Color(blue,strength),3.2,true)
    k.draw_line(axis[0],axis[1],Color(blue,strength*1.7),.9,true)
 for fx in k.strike_fx:
  if not fx.kind.begins_with("spear_") and fx.kind!="dragon_release":continue
  var u=clampf(fx.age/fx.life,0,1);var fade=1-u
  var origin=Vector2(fx.x-k.position.x,0);var dir=fx.dir
  match fx.kind:
   "spear_point":
    var end=origin+Vector2(dir*(146+u*18),-30)
    k.draw_colored_polygon(PackedVector2Array([origin+Vector2(dir*26,-33),end,origin+Vector2(dir*26,-27)]),Color(blue,fade*.28))
    k.draw_line(origin+Vector2(dir*38,-30),end,Color(.94,.99,1,fade*.8),1.2,true)
   "spear_low","spear_high","spear_lift":
    var points=PackedVector2Array();var lift=fx.kind=="spear_lift"
    for i in 25:
     var progress=float(i)/24
     var angle=lerpf(.9,-1.35,progress*(.7+u*.3)) if lift else lerpf(-.8,.8,progress)
     var x=cos(angle)*(125 if lift else 155)
     var y=(-62+sin(angle)*74) if lift else ((-20 if fx.kind=="spear_low" else -90)+sin(angle)*14)
     points.append(origin+Vector2(dir*(x+8),y))
    k.draw_polyline(points,Color(blue,fade*.20),5,true)
    k.draw_polyline(points,Color(blue,fade*.8),1.6,true)
   "spear_spiral":
    for ribbon in 3:
     var points=PackedVector2Array()
     for i in 25:
      var angle=float(i)/24*PI*1.7+u*1.6+ribbon*.22
      points.append(origin+Vector2(dir*(18+cos(angle)*110),-51+sin(angle)*43))
     k.draw_polyline(points,Color(blue,fade*(.5-ribbon*.13)),2.0-ribbon*.4,true)
   "dragon_release":
    for ribbon in 3:
     var points=PackedVector2Array()
     for i in 25:
      var progress=float(i)/24
      points.append(origin+Vector2(dir*(38+progress*230+u*160),-7+sin(progress*TAU*1.3+u*4+ribbon*.65)*(1-progress)*17))
     k.draw_polyline(points,Color(blue,fade*(.62-ribbon*.16)),2.8-ribbon*.7,true)
