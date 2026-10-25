extends Node2D
# Render-only layer experiment; uses the existing image without rewriting its pixels.
var texture:Texture2D
var parts=[]
var posing=false
var age=0.0
var opaque_pixels=0
var strip_count=0
var soles=[]
var joints=[Vector2.ZERO,Vector2(86,146),Vector2(77,172),Vector2(106,147),Vector2(112,174),Vector2(70,188),Vector2(120,189)]
func _ready():
 texture=load("res://assets/art/hero_2d/hero/00.png")
 var img=texture.get_image();var groups=[]
 for i in 7:groups.append({"v":PackedVector3Array(),"uv":PackedVector2Array(),"ix":PackedInt32Array()})
 for y in img.get_height():
  var x=0
  while x<img.get_width():
   if img.get_pixel(x,y).a<.01:
    x+=1
    continue
   var start=x;var group=group_at(x,y)
   while x<img.get_width() and img.get_pixel(x,y).a>=.01 and group_at(x,y)==group:x+=1
   opaque_pixels+=x-start;strip_count+=1
   var g=groups[group];var base=g.v.size()
   for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
    var q=Vector2(start,y)+corner*Vector2(x-start,1);g.v.append(Vector3(q.x,q.y,0));g.uv.append(q/texture.get_size())
   g.ix.append_array(PackedInt32Array([base,base+1,base+2,base+1,base+3,base+2]))
 for g in groups:
  var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=g.v;arrays[Mesh.ARRAY_TEX_UV]=g.uv;arrays[Mesh.ARRAY_INDEX]=g.ix
  var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);parts.append(mesh)
 for leg in 2:
  var angle=0.0
  var bottom=-INF
  for vertex in groups[5+leg].v:
   bottom=maxf(bottom,(Vector2(vertex.x,vertex.y)-joints[5+leg]).rotated(angle).y)
  soles.append(bottom)
func group_at(x,y):
 var group=0
 if y>=141:
  if x<97:group=1 if y<173 else 2
  else:group=3 if y<176 else 4
 if group==2 and y>=187:group=5
 if group==4 and y>=188:group=6
 var p=Vector2(x,y)
 if p.distance_to(Geometry2D.get_closest_point_to_segment(p,Vector2(67,145),Vector2(121,169)))<5:group=0
 if y<153 and (x<69 or x>121):group=0
 return group
func _process(dt):age+=dt;queue_redraw()
func pivot_rotation(pivot,angle):
 var transform=Transform2D(angle,Vector2.ZERO)
 transform.origin=pivot-transform.basis_xform(pivot)
 return transform
func pose_transforms():
 var phase=fposmod(age/.56,1.0)
 var body=Transform2D(0,Vector2(0,5+2*cos(phase*TAU*2)))
 var transforms=[body,body,body,body,body,body,body]
 for leg in 2:
  var thigh=1+leg*2;var calf=thigh+1;var foot=5+leg
  var t=fposmod(phase+leg*.5,1.0)
  var x=10-40*t if t<.5 else lerpf(-10,10,smoothstep(0,1,(t-.5)*2))
  var lift=0.0 if t<.5 else sin((t-.5)*TAU)*11
  var hip=body*joints[thigh]
  var ankle=Vector2(hip.x+x,199-soles[leg]-lift)
  var upper=joints[thigh].distance_to(joints[calf]);var lower=joints[calf].distance_to(joints[foot])
  var delta=ankle-hip;var distance=clampf(delta.length(),absf(upper-lower)+.01,upper+lower-.01)
  var axis=delta.normalized();ankle=hip+axis*distance
  var along=(upper*upper-lower*lower+distance*distance)/(2*distance)
  var knee=hip+axis*along-Vector2(-axis.y,axis.x)*sqrt(maxf(0,upper*upper-along*along))
  transforms[thigh]=align_segment(joints[thigh],joints[calf],hip,knee)
  transforms[calf]=align_segment(joints[calf],joints[foot],knee,ankle)
  var rotation=0.0
  transforms[foot]=Transform2D(rotation,Vector2.ZERO)
  transforms[foot].origin=ankle-transforms[foot].basis_xform(joints[foot])
 return transforms
func align_segment(a,b,c,d):
 var result=Transform2D((d-c).angle()-(b-a).angle(),Vector2.ZERO)
 result.origin=c-result.basis_xform(a)
 return result
func _draw():
 if parts.is_empty():return
 var transforms=pose_transforms()
 if posing:
  draw_circle(transforms[0]*joints[1],8,Color("29282a"))
  draw_circle(transforms[1]*joints[2],3,Color("29282a"))
  draw_circle(transforms[2]*joints[5],3,Color("d78d66"))
  draw_circle(transforms[3]*joints[4],3.5,Color("d78d66"))
  draw_circle(transforms[4]*joints[6],3,Color("d78d66"))
 for i in [1,2,5,3,4,6,0]:draw_mesh(parts[i],texture,transforms[i])
