extends RefCounted
static func pieces(h):
 var r=h.rect;var phase=clampf(h.age/maxf(.01,h.total),0,1)
 var count=clampi(ceili(r.size.x/24),2,5)
 var result=[]
 for i in count:
  var t=clampf((phase-i*.018)/(1-i*.018),0,1)
  var lift=4*t*(1-t)*minf(12+(i%3)*4,maxf(4,r.size.y-14))
  var scale=(.65+(i%3)*.13)*(1-smoothstep(.78,1,t)*.55)
  var turn=(1 if i%2==0 else -1)*t*(.45+i*.08)
  var base=Vector2(r.position.x+(i+.5)*r.size.x/count,r.end.y-lift)
  var points=PackedVector2Array()
  for local in [Vector2(-7,0),Vector2(-5,-9),Vector2(2,-14),Vector2(8,-6),Vector2(6,1)]:
   var p=base+(local-Vector2(0,-6)).rotated(turn)*scale+Vector2(0,-6)*scale
   p.y=minf(p.y,r.end.y);points.append(p)
  result.append({"points":points,"shade":Color("718480").darkened(i%2*.08)})
 return result
static func draw_effect(canvas,h):
 for piece in pieces(h):
  canvas.draw_colored_polygon(piece.points,piece.shade)
  canvas.draw_line(piece.points[1],piece.points[2],Color("b3c2b8"),1)
 var phase=clampf(h.age/maxf(.01,h.total),0,1)
 for side in [-1,1]:
  var p=h.rect.get_center()+Vector2(side*h.rect.size.x*.3,h.rect.size.y*.5-2)
  canvas.draw_set_transform(p+Vector2(side*phase*7,0),0,Vector2(1.7,1))
  canvas.draw_circle(Vector2.ZERO,2+phase*3,Color(.47,.55,.54,(1-phase)*.18))
 canvas.draw_set_transform(Vector2.ZERO)
