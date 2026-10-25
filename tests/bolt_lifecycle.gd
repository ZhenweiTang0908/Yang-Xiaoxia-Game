extends SceneTree
class Recorder:
 extends RefCounted
 var lines=[]
 func draw_polyline(points,color,width):lines.append({"points":points,"color":color,"width":width})
func _initialize():
 var shapes=load("res://scripts/combat/vfx_shapes.gd")
 var errors=0
 for end in [Vector2(200,0),Vector2(0,200),Vector2(120,160)]:
  for alpha in [0.0,.2,.8,1.0]:
   var canvas=Recorder.new()
   shapes.bolt(canvas,Vector2.ZERO,end,.4,Color(1,.6,.3,alpha))
   if alpha==0:
    if not canvas.lines.is_empty():errors+=1
    continue
   if canvas.lines.size()!=3:errors+=1
   for i in canvas.lines.size():
    var line=canvas.lines[i]
    if not is_equal_approx(line.color.a,alpha*(.2 if i==0 else 1.0)):errors+=1
    if line.points[0]!=Vector2.ZERO or line.points[-1]!=end:errors+=1
    for j in range(1,8):
     var delta=line.points[j]-end*j/8.0
     if absf(delta.dot(end.normalized()))>.001:errors+=1
 var empty=Recorder.new();shapes.bolt(empty,Vector2.ONE,Vector2.ONE,0,Color.WHITE)
 if not empty.lines.is_empty():errors+=1
 print("BOLT_LIFECYCLE cases=13 errors=",errors)
 quit(errors)
