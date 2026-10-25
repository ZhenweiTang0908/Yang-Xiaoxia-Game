extends RefCounted
static func draw_effect(canvas,e):
 var u=clampf(e.age/.20,0,1)
 var fade=1-u
 var color={"stone":Color("efd29e"),"block":Color("bce9ff"),"boss":Color("ffe5a6")}.get(e.surface,Color("ffd8bd"))
 var direction=Vector2(e.face,0)
 var spread=1.0 if e.surface=="block" else .65
 var count=6 if e.surface=="block" else (4 if e.surface in ["stone","boss"] else 2)
 for i in count:
  var angle=(float(i)/maxi(1,count-1)-.5)*spread*2
  var ray=direction.rotated(angle)
  var start=e.p+ray*(1+u*13)
  var length=(9 if e.surface=="block" else 6)*fade
  canvas.draw_line(start,start+ray*length,Color(color,fade*.95),1.5,true)
 if e.surface=="block":
  var angle=PI if e.face>0 else 0.0
  canvas.draw_arc(e.p,5+u*4,angle-.8,angle+.8,7,Color(color,fade*.6),1)
 elif e.age<.075:
  # A tiny contact slash, not a body-sized flash or a persistent aura.
  var tangent=Vector2(e.face*.5,-1).normalized()
  canvas.draw_line(e.p-tangent*4,e.p+tangent*4,Color("edf1df"),1)
