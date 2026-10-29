extends Node2D
# A seated 2D silhouette with the atlas' actual shoulder/weapon poses.
var actor
var current_frame=0
var state="idle"
var head_guides={}
var blade_guides={}
var unit=1.0
var hip=Vector2.ZERO
var crop=Rect2()
var blade_tip=Vector2.ZERO
func _ready():
 material=ShaderMaterial.new();material.shader=load("res://scripts/animation/mounted_spirit.gdshader")
 hide()
func guide(index):
 if head_guides.has(index):return head_guides[index]
 var image=actor.art.texture.get_image();var region=actor.art.regions[index];var used=actor.art.bounds[index]
 var blade_pixels=[];var warm={}
 for y in range(int(used.position.y),int(used.end.y)):
  for x in range(int(used.position.x),int(used.end.x)):
   var c=image.get_pixel(int(region.position.x)+x,int(region.position.y)+y)
   if c.a>.5 and c.r>.62 and c.g>.52 and c.b>.25 and c.r>c.g*.99 and c.r>c.b*1.08 and c.g>c.b*1.05:warm[Vector2i(x,y)]=true
   if c.a>.5 and c.g>.5 and c.g>c.r*1.3 and c.g>c.b*1.1:blade_pixels.append(Vector2(x,y))
 # Horn and muzzle form a connected ivory region. Belt/feet are separate paint.
 var largest=[]
 while not warm.is_empty():
  var start=warm.keys()[0];var stack=[start];var component=[];warm.erase(start)
  while not stack.is_empty():
   var point=stack.pop_back();component.append(point)
   for delta in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1)]:
    var next=point+delta
    if warm.has(next):warm.erase(next);stack.append(next)
  if component.size()>largest.size():largest=component
 var lo=Vector2.INF;var hi=Vector2.ZERO
 for point in largest:lo=lo.min(Vector2(point));hi=hi.max(Vector2(point)+Vector2.ONE)
 var rect=Rect2(lo,hi-lo) if lo.is_finite() and hi.y>lo.y else Rect2(used.position,Vector2(used.size.x*.5,used.size.y*.4))
 head_guides[index]=rect
 var seat=Vector2(rect.get_center().x-rect.size.y*.13,rect.end.y+rect.size.y*.85)
 var tip=seat
 for point in blade_pixels:
  if point.distance_squared_to(seat)>tip.distance_squared_to(seat):tip=point
 blade_guides[index]=tip
 return rect
func _process(_dt):
 visible=is_instance_valid(actor) and actor.form_visual and actor.is_carried()
 if not visible:return
 actor.art.hide();actor.heavy_art.hide();actor.rider_art.hide()
 state="idle"
 current_frame=0
 if actor.blast_anim>0:state="release";current_frame=22
 elif actor.charge>0:state="charge";current_frame=23
 elif actor.bow_anim>0:state="cast";current_frame=21
 elif actor.attack_elapsed>=0:
  state="slash"+str(actor.combo)
  var index=clampi(actor.combo-1,0,2)
  current_frame=actor.timed_frame(actor.SHEEP_SLASHES[index],actor.SHEEP_HIT_FRAME[index],actor.attack_elapsed,actor.MOTION.ATTACKS[index].hit,actor.attack_duration)
 var head=guide(current_frame);unit=20.0/maxf(1,head.size.y)
 hip=Vector2(head.get_center().x-head.size.y*.13,head.end.y+head.size.y*.85)
 var region=actor.art.regions[current_frame];var used=actor.art.bounds[current_frame]
 crop=Rect2(region.position+Vector2(used.position),Vector2(used.size))
 material.set_shader_parameter("seat_line",(region.position.y+hip.y+head.size.y*.07)/actor.art.texture.get_height())
 # A visual endpoint used by the rider regression/capture; the blade is in the authored PNG.
 blade_tip=(blade_guides.get(current_frame,hip)-hip)*unit*Vector2(actor.facing,1)
 modulate=actor.render_tint();queue_redraw()
func _draw():
 if not visible or not crop.has_area():return
 draw_set_transform(Vector2.ZERO,0,Vector2(actor.facing,1))
 # The two folded legs stay attached to the back socket during every upper-body frame.
 for side in [-1,1]:
  var at=Vector2(side*3,0);var knee=at+Vector2(8,6);var ankle=at+Vector2(4,16)
  var color=Color("252d29") if side==1 else Color("1a2320")
  draw_line(at,knee,Color("101817"),10,true);draw_circle(knee,5,Color("101817"))
  draw_line(knee,ankle,Color("101817"),8,true);draw_circle(ankle,4,Color("101817"))
  draw_line(at,knee,color,7,true);draw_circle(knee,3.5,color)
  draw_line(knee,ankle,color,5,true)
  draw_line(ankle,ankle+Vector2(5,1),Color("101817"),5,true)
  draw_line(ankle+Vector2(4,0),ankle+Vector2(6,1),Color("667166"),1,true)
 var region=actor.art.regions[current_frame]
 var local=crop.position-region.position-hip
 draw_texture_rect_region(actor.art.texture,Rect2(local*unit,crop.size*unit),crop)
