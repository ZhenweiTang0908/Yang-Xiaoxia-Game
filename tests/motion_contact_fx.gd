extends Node2D
var actor
var shadow={}
var dust=[]
var landing_emissions=0
func _ready():top_level=true;z_index=1
func ground_hit():
 var query=PhysicsRayQueryParameters2D.create(actor.global_position-Vector2(0,2),actor.global_position+Vector2(0,140),1,[actor.get_rid()])
 return actor.get_world_2d().direct_space_state.intersect_ray(query)
func landed(speed):
 var hit=ground_hit()
 if speed<100 or hit.is_empty() or hit.position.distance_to(actor.global_position)>4 or hit.normal.dot(Vector2.UP)<.7:return
 landing_emissions+=1
 for side in [-1,1]:
  dust.append({"p":hit.position,"age":0.0,"side":side})
 while dust.size()>12:dust.pop_front()
func step(dt):
 shadow=ground_hit()
 for puff in dust:puff.age+=dt
 dust=dust.filter(func(p):return p.age<.24)
 queue_redraw()
func _draw():
 if not shadow.is_empty():
  var distance=maxf(0,shadow.position.y-actor.global_position.y)
  var strength=1-clampf(distance/100,0,1)
  if strength>0:
   draw_set_transform(shadow.position+Vector2(0,-.5),0,Vector2(1,.16))
   draw_circle(Vector2.ZERO,7+distance*.02,Color(0,0,0,.18*strength))
   draw_set_transform(Vector2.ZERO)
 for puff in dust:
  var u=puff.age/.24
  var p=puff.p+Vector2(puff.side*(2+u*9),-1-sin(u*PI)*2)
  draw_circle(p,1.2+u*1.2,Color(.57,.60,.53,.25*(1-u)))
