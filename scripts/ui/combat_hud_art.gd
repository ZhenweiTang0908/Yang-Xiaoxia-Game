extends RefCounted
# Drawn at HUD resolution so bottle details and bevels stay crisp at any viewport scale.
const BRASS=Color("a68c60")
const INK=Color("101f27")
static func bevel(rect:Rect2,cut=3.0):
 var p=rect.position;var e=rect.end
 return PackedVector2Array([p+Vector2(cut,0),Vector2(e.x-cut,p.y),Vector2(e.x,p.y+cut),e-Vector2(0,cut),e-Vector2(cut,0),Vector2(p.x+cut,e.y),Vector2(p.x,e.y-cut),p+Vector2(0,cut)])
static func bar(canvas,rect:Rect2,value:float,color:Color,lag=-1.0):
 var outline=bevel(rect.grow(2),3)
 canvas.draw_colored_polygon(bevel(Rect2(rect.position+Vector2(0,2),rect.size).grow(3),4),Color(0,0,0,.30))
 canvas.draw_colored_polygon(outline,INK)
 var rim=outline.duplicate();rim.append(outline[0]);canvas.draw_polyline(rim,Color(BRASS,.65),1,true)
 canvas.draw_rect(rect,Color("253039"))
 var fraction=clampf(value,0,1)
 if lag>fraction:canvas.draw_rect(Rect2(rect.position,Vector2(rect.size.x*minf(lag,1),rect.size.y)),Color("dbbda2"))
 var w=rect.size.x*fraction
 if w>0:
  var fill=Rect2(rect.position,Vector2(w,rect.size.y))
  canvas.draw_polygon(PackedVector2Array([fill.position,Vector2(fill.end.x,fill.position.y),fill.end,Vector2(fill.position.x,fill.end.y)]),PackedColorArray([color.lightened(.14),color.lightened(.14),color.darkened(.24),color.darkened(.24)]))
  canvas.draw_line(fill.position+Vector2(0,1),Vector2(fill.end.x,fill.position.y+1),Color(1,.95,.82,.23),1)
  if fraction<1:canvas.draw_line(Vector2(fill.end.x,fill.position.y),fill.end,Color(1,.93,.77,.6),1)
 for i in range(1,4):
  var x=rect.position.x+rect.size.x*i/4
  canvas.draw_line(Vector2(x,rect.position.y),Vector2(x,rect.end.y),Color(INK,.30),1)
static func bottle(canvas,at:Vector2,full:bool):
 var rim=PackedVector2Array([Vector2(-3,-13),Vector2(3,-13),Vector2(3,-9),Vector2(7,-5),Vector2(7,5),Vector2(4,8),Vector2(-4,8),Vector2(-7,5),Vector2(-7,-5),Vector2(-3,-9)])
 for i in rim.size():rim[i]+=at
 canvas.draw_colored_polygon(rim,Color("253c42") if full else Color("1e2c33"))
 var outline=rim.duplicate();outline.append(rim[0]);canvas.draw_polyline(outline,Color("8eaeaa") if full else Color("526369"),1,true)
 if full:
  var liquid=PackedVector2Array([Vector2(-5,-2),Vector2(0,-1),Vector2(5,-2),Vector2(5,4),Vector2(3,6),Vector2(-3,6),Vector2(-5,4)])
  for i in liquid.size():liquid[i]+=at
  canvas.draw_colored_polygon(liquid,Color("78b9aa"))
  canvas.draw_line(at+Vector2(-4,-2),at+Vector2(4,-2),Color("c4ece0"),1)
  canvas.draw_circle(at+Vector2(1,3),.8,Color("c4ece0"))
 canvas.draw_rect(Rect2(at+Vector2(-4,-15),Vector2(8,3)),Color("a98a5d") if full else Color("6f6451"))
 canvas.draw_line(at+Vector2(-4,-15),at+Vector2(3,-15),Color("dac094"),1)
 canvas.draw_line(at+Vector2(-3,-10),at+Vector2(3,-10),Color("ba9d6c"),1)
 canvas.draw_line(at+Vector2(-4,-5),at+Vector2(-4,2),Color(1,1,1,.45 if full else .14),1.5,true)
 canvas.draw_line(at+Vector2(-2,-7),at+Vector2(-1,-8),Color(1,1,1,.45 if full else .14),1,true)
