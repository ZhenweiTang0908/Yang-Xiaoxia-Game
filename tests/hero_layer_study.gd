extends Node2D
# Render-only layer experiment; uses the existing image without rewriting its pixels.
var texture:Texture2D
var parts=[]
var posing=false
var age=0.0
var opaque_pixels=0
var strip_count=0
var joints=[Vector2.ZERO,Vector2(109,109),Vector2(81,125),Vector2(119,111),Vector2(139,139),Vector2(64,125),Vector2(137,153)]
func _ready():
 texture=load("res://assets/art/hero_2d/hero/10.png")
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
func group_at(x,y):
 var group=0
 if y>=106 and (x<151 or y>=135):
  if x<110:group=1 if x>81 else 2
  else:group=3 if y<139 else 4
 if group==2 and x<65:group=5
 if group==4 and y>=153:group=6
 return group
func _process(dt):age+=dt;queue_redraw()
func pivot_rotation(pivot,angle):
 var transform=Transform2D(angle,Vector2.ZERO)
 transform.origin=pivot-transform.basis_xform(pivot)
 return transform
func pose_transforms():
 var bend=sin(age*6)*.25 if posing else 0.0
 var far=pivot_rotation(joints[1],bend)
 var near=pivot_rotation(joints[3],-bend*.5)
 var transforms=[Transform2D.IDENTITY,far,far*pivot_rotation(joints[2],bend*.7),near,near*pivot_rotation(joints[4],bend)]
 for pair in [[2,5],[4,6]]:
  var parent=transforms[pair[0]]
  transforms.append(parent*pivot_rotation(joints[pair[1]],-parent.get_rotation()))
 return transforms
func _draw():
 if parts.is_empty():return
 var transforms=pose_transforms()
 if posing:
  draw_circle(joints[1],8,Color("29282a"))
  draw_circle(transforms[1]*joints[2],3,Color("29282a"))
  draw_circle(transforms[2]*joints[5],3,Color("d78d66"))
  draw_circle(transforms[3]*joints[4],3.5,Color("d78d66"))
  draw_circle(transforms[4]*joints[6],3,Color("d78d66"))
 for i in [1,2,5,3,4,6,0]:draw_mesh(parts[i],texture,transforms[i])
