extends Node2D
const GUIDES=preload("res://scripts/animation/hero_2d_pose.gd")
var manifest=[]
var texture
var source
var is_heavy=false
var mesh=ArrayMesh.new()
var cache={}
var current=-1
var points=PackedVector2Array()
var target_points=PackedVector2Array()
var rest=PackedVector2Array()
var uv=PackedVector2Array()
var weights=[]
var indices=PackedInt32Array()
var facing=1.0
var tint=Color.WHITE
var cloth_delta=Vector2.ZERO
var rendered_points=PackedVector2Array()
var sole_cache={}
const NX=24
const NY=32
func baseline(frame):
 var soles=sole_positions(frame)
 return maxf(soles[0],soles[1])
func sole_positions(frame):
 if sole_cache.has(frame):return sole_cache[frame]
 var g=GUIDES.guides(frame,is_heavy)
 var result=[float(g[4][1]),float(g[5][1])]
 if not is_heavy and (frame<32 or frame==35):
  if manifest.is_empty():manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/animation/hero_2d_frames.json"))
  var offset=Vector2(manifest[frame].offset[0],manifest[frame].offset[1])
  var picture=load("res://assets/art/hero_2d/hero/%02d.png"%frame).get_image()
  for foot in 2:
   var guide=Vector2(g[foot+4][0],g[foot+4][1])-offset
   var bottom=-1
   for y in range(maxi(0,int(guide.y)-20),mini(picture.get_height(),int(guide.y)+12)):
    for x in range(maxi(0,int(guide.x)-12),mini(picture.get_width(),int(guide.x)+13)):
     var c=picture.get_pixel(x,y)
     if c.a>.8 and c.r>.35 and c.r>c.g*1.15 and c.r>c.b*1.2:bottom=maxi(bottom,y)
   if bottom>=0:result[foot]=bottom+offset.y
 sole_cache[frame]=result
 return result
func anchors(frame):
 var result=PackedVector2Array()
 var region=source.regions[frame];var used=source.bounds[frame]
 var guides=GUIDES.guides(frame,is_heavy)
 var soles=sole_positions(frame)
 for i in guides.size():
  var p=Vector2(guides[i][0],soles[i-4] if i>=4 else guides[i][1])
  result.append((p-Vector2(region.size.x*.5,baseline(frame)))*source.scale_unit)
 return result
func prepare(frame):
 if manifest.is_empty():manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/animation/"+("uppercut" if is_heavy else "hero")+"_2d_frames.json"))
 if current==frame:return
 current=frame;points=anchors(frame)
 texture=load("res://assets/art/hero_2d/"+("uppercut" if is_heavy else "hero")+"/%02d.png"%frame)
 if cache.has(frame):
  var c=cache[frame];rest=c.rest;uv=c.uv;weights=c.weights;indices=c.indices;return
 rest=PackedVector2Array();uv=PackedVector2Array();weights=[];indices=PackedInt32Array()
 var region=source.regions[frame];var meta=manifest[frame]
 var offset=Vector2(meta.offset[0],meta.offset[1])
 var used=Rect2(Vector2(meta.bounds[0],meta.bounds[1])+offset,Vector2(meta.bounds[2],meta.bounds[3]))
 for y in NY+1:
  for x in NX+1:
   var q=Vector2(float(x)/NX,float(y)/NY)
   var pixel=Vector2(used.position)+Vector2(used.size)*q
   var p=(pixel-Vector2(region.size.x*.5,baseline(frame)))*source.scale_unit
   rest.append(p);uv.append((pixel-offset)/texture.get_size())
   var w=[];var total=0.0
   for a in points:
    var v=1.0/pow(maxf(.8,p.distance_to(a)),3);w.append(v);total+=v
   for i in w.size():w[i]/=total
   # Entire face, skull and collar move as one patch. No facial skinning.
   var rigid=(1-smoothstep(points[0].y,points[0].y+4,p.y))*(1-smoothstep(9,12,absf(p.x-points[0].x)))
   for i in w.size():w[i]=lerpf(w[i],1.0 if i==0 else 0.0,rigid)
   # Keep each sole together instead of letting pelvis/hand weights shear it.
   # Fade above the ankle, leaving the leg free to bend between poses.
   for foot in [4,5]:
    var sole=(1-smoothstep(1.5,3.5,absf(p.x-points[foot].x)))*smoothstep(points[foot].y-3,points[foot].y-1,p.y)
    sole*=1-smoothstep(1,3,p.y-points[foot].y)
    for i in w.size():w[i]=lerpf(w[i],1.0 if i==foot else 0.0,sole)
   weights.append(w)
 for y in NY:
  for x in NX:
   var a=y*(NX+1)+x;indices.append_array(PackedInt32Array([a,a+1,a+NX+1,a+1,a+NX+2,a+NX+1]))
 cache[frame]={"rest":rest,"uv":uv,"weights":weights,"indices":indices}
func cloth_weight(p):
 # Restrict follow-through to the lower shirt, excluding head, collar and legs.
 var top=points[0].y+maxf(4,(points[1].y-points[0].y)*.55)
 var bottom=points[1].y+1
 if bottom<=top or p.y<=top or p.y>=bottom:return 0.0
 var vertical=sin(PI*(p.y-top)/(bottom-top))
 return vertical*(1-smoothstep(5,9,absf(p.x-points[1].x)))
func render_pose(frame,targets):
 prepare(frame);target_points=targets
 rendered_points=PackedVector2Array()
 var vertices=PackedVector3Array()
 for i in rest.size():
  var delta=Vector2.ZERO
  for j in points.size():delta+=(targets[j]-points[j])*weights[i][j]
  var v=rest[i]+delta+cloth_delta*cloth_weight(rest[i])
  rendered_points.append(v)
  vertices.append(Vector3(v.x,v.y,0))
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
 mesh.clear_surfaces();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);queue_redraw()
func _draw():
 if current<0:return
 draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
 draw_mesh(mesh,texture,Transform2D.IDENTITY,tint)
func surface_point(point):
 # Sample the rendered triangle itself: sockets must share the texture's warp.
 var extent=rest[-1]-rest[0]
 var grid=(point-rest[0])/extent*Vector2(NX,NY)
 var x=clampi(int(floor(grid.x)),0,NX-1)
 var y=clampi(int(floor(grid.y)),0,NY-1)
 var f=grid-Vector2(x,y)
 var a=y*(NX+1)+x
 if f.x+f.y<=1:
  return rendered_points[a]*(1-f.x-f.y)+rendered_points[a+1]*f.x+rendered_points[a+NX+1]*f.y
 return rendered_points[a+1]*(1-f.y)+rendered_points[a+NX+1]*(1-f.x)+rendered_points[a+NX+2]*(f.x+f.y-1)
func weapon_socket(tip=false):
 var raw=GUIDES.guides(current,is_heavy)[3]
 if tip:
  if is_heavy:raw=[[350,426],[85,350],[337,389],[407,191],[258,48],[360,0],[381,361],[267,378]][current]
  elif current>=16 and current<24:raw=[[115,158],[82,0],[7,23],[-10,61],[194,70],[204,90],[195,92],[124,164]][current-16]
  elif current>=24 and current<32:raw=[[103,0],[17,25],[142,192],[164,207],[184,215],[179,171],[182,150],[126,182]][current-24]
 var point=(Vector2(raw[0],raw[1])-Vector2(source.regions[current].size.x*.5,baseline(current)))*source.scale_unit
 return surface_point(point)
