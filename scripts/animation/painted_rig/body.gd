extends Node2D
# Render-only layer experiment; uses the existing image without rewriting its pixels.
var texture:Texture2D
var body_pixels:Image
var rebuild_source=false
var leg_texture:Texture2D
var leg_mask=PackedByteArray()
var discarded_leg_pixels=0
var inspect_layers=false
var parts=[]
var posing=false
var age=0.0
var opaque_pixels=0
var strip_count=0
var soles=[]
var leg_height_scale=[1.0,1.0]
var thigh_sources={}
var shorts_weights={}
var shorts_pose={}
var body_source=[]
var body_weights=PackedVector2Array()
var body_cloth=Vector2.INF
var body_hair=Vector2.INF
var secondary=preload("res://scripts/animation/painted_rig/secondary_motion.gd").new()
var secondary_dirty=false
var running=false
var motion_amount=1.0
var contact_enabled=false
var travel_x=0.0
var planted=[null,null]
var released_unreachable=0
var max_pelvis_correction=0.0
var sampled_pose=[]
var air_pose=0.0
var phase_override=-1.0
var landing_squash=0.0
var weapon_visible=true
var cycle=.56
var support_fraction=.5
var stride_half=10.0
var game_scale=52.8/190.0
var joints=[Vector2.ZERO,Vector2(83,145),Vector2(75,173),Vector2(109,146),Vector2(110,174),Vector2(69,192),Vector2(115,192)]
func _ready():
 texture=load("res://assets/art/hero_2d/hero/00.png")
 body_pixels=texture.get_image()
 leg_texture=load("res://assets/art/painted_rig/hero_legs.png")
 if not rebuild_source and ResourceLoader.exists("res://assets/animation/painted_rig/hero.res"):
  var data=load("res://assets/animation/painted_rig/hero.res")
  joints=data.joints.duplicate();soles=data.soles.duplicate();leg_height_scale=data.leg_height_scale.duplicate()
  for index in data.meshes.size():
   # Body and shorts deform per actor; never mutate the shared cache.
   parts.append(data.meshes[index].duplicate() if index in [0,1,3] else data.meshes[index])
   if index==0:body_source=parts[index].surface_get_arrays(0)
   if index in [1,3]:thigh_sources[index]=parts[index].surface_get_arrays(0)
  return
 build_leg_mask(leg_texture.get_image())
 calibrate_leg_height(leg_texture.get_image())
 var groups=[]
 for i in 12:groups.append({"v":PackedVector3Array(),"uv":PackedVector2Array(),"ix":PackedInt32Array()})
 for source in 2:
  var tex=texture if source==0 else leg_texture
  var img=tex.get_image()
  for y in img.get_height():
   var x=0
   while x<img.get_width():
    var group=source_group(x,y,source)
    if group<0 or img.get_pixel(x,y).a<.7 or (source==1 and leg_mask[y*img.get_width()+x]==0):
     x+=1;continue
    var start=x
    while x<img.get_width() and img.get_pixel(x,y).a>=.7 and source_group(x,y,source)==group and (source==0 or (x-start<8 and leg_mask[y*img.get_width()+x]!=0)):x+=1
    opaque_pixels+=x-start;strip_count+=1
    var g=groups[group];var base=g.v.size()
    for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
     var q=Vector2(start,y)+corner*Vector2(x-start,1)
     var p=q if source==0 else q*.18+Vector2(-14,4)
     if source==1:p.y=143+(p.y-143)*leg_height_scale[0 if group in [1,2,5] else 1]
     g.v.append(Vector3(p.x,p.y,0));g.uv.append(q/tex.get_size())
    g.ix.append_array(PackedInt32Array([base,base+1,base+2,base+1,base+3,base+2]))
 for index in groups.size():
  var g=groups[index]
  var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=g.v;arrays[Mesh.ARRAY_TEX_UV]=g.uv;arrays[Mesh.ARRAY_INDEX]=g.ix
  var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);parts.append(mesh)
  if index==0:body_source=arrays
  if index in [1,3]:thigh_sources[index]=arrays
 for leg in 2:
  var angle=0.0
  var bottom=-INF
  for vertex in groups[5+leg].v:
   bottom=maxf(bottom,(Vector2(vertex.x,vertex.y)-joints[5+leg]).rotated(angle).y)
  soles.append(bottom)
func calibrate_leg_height(img):
 # Both feet must reach the approved silhouette's baseline in the rest pose.
 # Otherwise grounding compresses a taller replacement leg and bends the knee
 # even while idle. Normalize the source geometry before solving any joints.
 var bottoms=[143.0,143.0]
 for y in img.get_height():
  for x in img.get_width():
   if leg_mask[y*img.get_width()+x]==0:continue
   var group=source_group(x,y,1)
   if group in [5,6]:bottoms[group-5]=maxf(bottoms[group-5],(y+1)*.18+4)
 for leg in 2:
  leg_height_scale[leg]=56.0/(bottoms[leg]-143)
  for index in [1+leg*2,2+leg*2,5+leg]:
   joints[index].y=143+(joints[index].y-143)*leg_height_scale[leg]
func build_leg_mask(img):
 var width=img.get_width();var height=img.get_height()
 var pending=PackedByteArray();pending.resize(width*height)
 var total=0
 for y in height:
  for x in width:
   if img.get_pixel(x,y).a>=.7:pending[y*width+x]=1;total+=1
 var largest=PackedInt32Array()
 for seed in pending.size():
  if pending[seed]==0:continue
  var queue=PackedInt32Array([seed]);pending[seed]=0;var cursor=0
  while cursor<queue.size():
   var p=queue[cursor];cursor+=1;var x=p%width
   for n in [p-1 if x>0 else -1,p+1 if x<width-1 else -1,p-width,p+width]:
    if n>=0 and n<pending.size() and pending[n]!=0:
     pending[n]=0;queue.append(n)
  if queue.size()>largest.size():largest=queue
 leg_mask.resize(width*height)
 for p in largest:leg_mask[p]=1
 discarded_leg_pixels=total-largest.size()
func source_group(x,y,source):
 if source==0:
  var pixel=body_pixels.get_pixel(x,y)
  var value=maxf(pixel.r,maxf(pixel.g,pixel.b));var chroma=value-minf(pixel.r,minf(pixel.g,pixel.b))
  var point=Vector2(x,y)
  var blade=point.distance_to(Geometry2D.get_closest_point_to_segment(point,Vector2(67,145),Vector2(121,169)))<6
  var handle=point.distance_to(Geometry2D.get_closest_point_to_segment(point,Vector2(61,140),Vector2(75,153)))<6
  # Keep the dark blade outline with its metal fill when the wrist turns.
  # Otherwise an unmoving outline remains attached to the forearm.
  if (blade and (x>=80 or (value>.32 and chroma<.18))) or (handle and value>.12 and value<.38 and chroma>.04):return 11
  var group=group_at(x,y)
  return group if group in [0,7,8,9,10] else -1
 var p=Vector2(x,y)*.18+Vector2(-14,4)
 if p.y<143 or (p.y<153 and (p.x<72 or p.x>119)):return -1
 if p.x<96:return 1 if p.y<174 or (p.y<180 and p.x>84) else (2 if p.y<192 else 5)
 return 3 if p.y<174 or (p.y<180 and p.x>123) else (4 if p.y<192 else 6)
func group_at(x,y):
 var group=0
 if y>=141:
  if x<97:group=1 if y<173 else 2
  else:group=3 if y<176 else 4
 if group==2 and y>=187:group=5
 if group==4 and y>=188:group=6
 var p=Vector2(x,y)
 if p.distance_to(Geometry2D.get_closest_point_to_segment(p,Vector2(67,145),Vector2(121,169)))<5:group=7
 if y<153 and (x<69 or x>121):group=0
 if y>=108 and y<153 and x<73:group=7
 if y>=108 and y<153 and x>119:group=8
 if group==7 and y<125:group=9
 if group==8 and y<127:group=10
 return group
func _process(dt):age+=dt;queue_redraw()
func pivot_rotation(pivot,angle):
 var transform=Transform2D(angle,Vector2.ZERO)
 transform.origin=pivot-transform.basis_xform(pivot)
 return transform
func pose_transforms():
 if running:
  cycle=.4;stride_half=30
  support_fraction=(stride_half*2)/(225/game_scale)/cycle
 var phase=fposmod(age/cycle,1.0)
 if phase_override>=0:phase=phase_override
 var body_y=5+2*cos(phase*TAU*2)
 if running:body_y=8+8*cos((phase-support_fraction*.5)*TAU*2)
 body_y*=1-air_pose*.7
 var amount=clampf(motion_amount,0,1)
 # A stationary jump still needs articulated legs. Horizontal speed controls
 # the gait; airborne tuck supplies its own weight without scaling the body.
 var leg_amount=maxf(amount,air_pose*.65)
 var body=Transform2D(0,Vector2(0,body_y*amount+landing_squash))
 if running:body=body*pivot_rotation(Vector2(96,145),.1*amount)
 var transforms=[body,body,body,body,body,body,body]
 for leg in 2:
  var thigh=1+leg*2;var calf=thigh+1;var foot=5+leg
  var t=fposmod(phase+leg*.5,1.0)
  var swing=clampf((t-support_fraction)/(1-support_fraction),0,1)
  var x=stride_half-2*stride_half*t/support_fraction if t<support_fraction else lerpf(-stride_half,stride_half,smoothstep(0,1,swing))
  var lift=sin(swing*PI)*(18 if running else 11)
  x*=1-air_pose*.4
  lift+=10*air_pose
  var hip=body*joints[thigh]
  var ankle=Vector2(hip.x+x,199-soles[leg]-lift)
  ankle=Vector2(joints[foot].x,199-soles[leg]).lerp(ankle,leg_amount)
  var upper=joints[thigh].distance_to(joints[calf]);var lower=joints[calf].distance_to(joints[foot])
  var delta=ankle-hip;var distance=clampf(delta.length(),absf(upper-lower)+.01,upper+lower-.01)
  var axis=delta.normalized();ankle=hip+axis*distance
  var along=(upper*upper-lower*lower+distance*distance)/(2*distance)
  var knee=hip+axis*along-Vector2(-axis.y,axis.x)*sqrt(maxf(0,upper*upper-along*along))
  transforms[thigh]=align_segment(joints[thigh],joints[calf],hip,knee)
  transforms[calf]=align_segment(joints[calf],joints[foot],knee,ankle)
  if leg_amount<1:
   var thigh_angle=transforms[thigh].get_rotation()
   var knee_angle=transforms[calf].get_rotation()-thigh_angle
   transforms[thigh]=Transform2D(thigh_angle*leg_amount,Vector2.ZERO)
   transforms[thigh].origin=hip-transforms[thigh].basis_xform(joints[thigh])
   transforms[calf]=transforms[thigh]*pivot_rotation(joints[calf],knee_angle*leg_amount)
   ankle=transforms[calf]*joints[foot]
  var rotation=0.0
  transforms[foot]=Transform2D(rotation,Vector2.ZERO)
  transforms[foot].origin=ankle-transforms[foot].basis_xform(joints[foot])
 var arm_swing=sin(phase*TAU)*.24 if running else sin(phase*TAU)*.1
 arm_swing*=amount
 arm_swing*=1-air_pose*.7
 var front_arm=body*pivot_rotation(Vector2(68,108),arm_swing)
 var rear_arm=body*pivot_rotation(Vector2(122,108),-arm_swing)
 var elbow_bend=.18+.10*sin(phase*TAU+.5) if running else .0
 elbow_bend*=amount
 elbow_bend+=air_pose*.45
 transforms.append(front_arm*pivot_rotation(Vector2(64,125),-elbow_bend))
 transforms.append(rear_arm*pivot_rotation(Vector2(124,127),elbow_bend*.6))
 transforms.append(front_arm)
 transforms.append(rear_arm)
 if contact_enabled:constrain_contacts(transforms,phase)
 return transforms
func constrain_contacts(transforms,phase):
 var correction=0.0
 for leg in 2:
  if motion_amount>=.02 and fposmod(phase+leg*.5,1)>=support_fraction:continue
  var thigh=1+leg*2;var calf=thigh+1;var foot=5+leg
  var hip=transforms[thigh]*joints[thigh]
  var reach=joints[thigh].distance_to(joints[calf])+joints[calf].distance_to(joints[foot])-.001
  var contact_x=(transforms[foot]*joints[foot]).x if planted[leg]==null else (planted[leg]-travel_x)/game_scale
  var dx=contact_x-hip.x
  if absf(dx)<reach:
   correction=maxf(correction,199-soles[leg]-hip.y-sqrt(reach*reach-dx*dx))
 correction=clampf(correction,0,6)
 max_pelvis_correction=maxf(max_pelvis_correction,correction)
 for index in transforms.size():transforms[index].origin.y+=correction
 for leg in 2:
  var thigh=1+leg*2;var calf=thigh+1;var foot=5+leg
  var stance=motion_amount<.02 or fposmod(phase+leg*.5,1)<support_fraction
  if not stance:
   planted[leg]=null;continue
  var hip=transforms[thigh]*joints[thigh]
  var old_knee=transforms[calf]*joints[calf]
  var current=transforms[foot]*joints[foot]
  if planted[leg]==null:planted[leg]=current.x*game_scale+travel_x
  var ankle=Vector2((planted[leg]-travel_x)/game_scale,199-soles[leg])
  var upper=joints[thigh].distance_to(joints[calf]);var lower=joints[calf].distance_to(joints[foot])
  var delta=ankle-hip;var distance=delta.length()
  if distance>=upper+lower-.0001 or distance<=absf(upper-lower)+.0001:
   planted[leg]=null;released_unreachable+=1;continue
  var axis=delta/distance
  var along=(upper*upper-lower*lower+distance*distance)/(2*distance)
  var side=Vector2(-axis.y,axis.x)*sqrt(maxf(0,upper*upper-along*along))
  var knee_a=hip+axis*along+side;var knee_b=hip+axis*along-side
  var knee=knee_a if knee_a.distance_squared_to(old_knee)<knee_b.distance_squared_to(old_knee) else knee_b
  transforms[thigh]=align_segment(joints[thigh],joints[calf],hip,knee)
  transforms[calf]=align_segment(joints[calf],joints[foot],knee,ankle)
  transforms[foot]=Transform2D(0,ankle-joints[foot])
func align_segment(a,b,c,d):
 var result=Transform2D((d-c).angle()-(b-a).angle(),Vector2.ZERO)
 result.origin=c-result.basis_xform(a)
 return result
func update_secondary(dt):
 if sampled_pose.is_empty():return
 secondary.step(sampled_pose[0],dt);secondary_dirty=true
func update_body_surface():
 if not secondary_dirty or body_source.is_empty():return
 secondary_dirty=false
 if body_cloth==secondary.cloth and body_hair==secondary.hair:return
 body_cloth=secondary.cloth;body_hair=secondary.hair
 var rest:PackedVector3Array=body_source[Mesh.ARRAY_VERTEX]
 if body_weights.is_empty():
  for vertex in rest:
   var hem=smoothstep(118,141,vertex.y) if vertex.y<=142 and vertex.x>=70 and vertex.x<=121 else 0.0
   var tip=1-smoothstep(19,38,vertex.y) if vertex.y<38 else 0.0
   body_weights.append(Vector2(hem,tip))
 var arrays=body_source.duplicate()
 var vertices=PackedVector3Array()
 vertices.resize(rest.size())
 for i in rest.size():
  var vertex:Vector3=rest[i]
  var weight:Vector2=body_weights[i]
  var p=Vector2(vertex.x,vertex.y)+body_cloth*weight.x+body_hair*weight.y
  vertices[i]=Vector3(p.x,p.y,0)
 arrays[Mesh.ARRAY_VERTEX]=vertices
 parts[0].clear_surfaces();parts[0].add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
func update_shorts(transforms):
 var body:Transform2D=transforms[0]
 for index in [1,3]:
  var thigh:Transform2D=transforms[index]
  var signature=[body,thigh,running]
  if shorts_pose.get(index,[])==signature:continue
  shorts_pose[index]=signature
  var arrays=thigh_sources[index].duplicate()
  var rest:PackedVector3Array=thigh_sources[index][Mesh.ARRAY_VERTEX]
  if not shorts_weights.has(index):
   var weights=PackedVector2Array()
   for vertex in rest:
    var point=Vector2(vertex.x,vertex.y)
    weights.append(Vector2(smoothstep(145,167,point.y),smoothstep(7,24,(point-joints[index]).length())))
   shorts_weights[index]=weights
  var weights:PackedVector2Array=shorts_weights[index]
  var joint:Vector2=joints[index]
  var turn:float=thigh.get_rotation()-body.get_rotation()
  var vertices=PackedVector3Array()
  vertices.resize(rest.size())
  for n in rest.size():
   var vertex:Vector3=rest[n]
   var p=Vector2(vertex.x,vertex.y)
   var target:Vector2
   if running:
    target=body*(joint+(p-joint).rotated(turn*weights[n].y))
   else:
    target=(body*p).lerp(thigh*p,weights[n].x)
   vertices[n]=Vector3(target.x,target.y,0)
  arrays[Mesh.ARRAY_VERTEX]=vertices
  parts[index].clear_surfaces()
  parts[index].add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
func weapon_transform(transforms):return transforms[7]
func _draw():
 if parts.is_empty():return
 var transforms=sampled_pose if not sampled_pose.is_empty() else pose_transforms()
 update_body_surface()
 update_shorts(transforms)
 if posing:
  draw_rect(Rect2(transforms[0]*Vector2(73,140),Vector2(47,13)),Color("29282a"))
  draw_circle(transforms[0]*joints[1],10,Color("29282a"))
  draw_circle(transforms[0]*joints[3],10,Color("29282a"))
  draw_circle(transforms[1]*joints[2],3,Color("29282a"))
  draw_circle(transforms[2]*joints[5],3,Color("d78d66"))
  draw_circle(transforms[3]*joints[4],3.5,Color("d78d66"))
  draw_circle(transforms[4]*joints[6],3,Color("d78d66"))
 if posing:
  draw_circle(transforms[9]*Vector2(64,125),3,Color("d78d66"))
  draw_circle(transforms[10]*Vector2(124,127),2,Color("d78d66"))
 for i in [10,8,1,2,5,3,4,6,0,9,7,11]:
  if i>=parts.size() or (i==11 and not weapon_visible):continue
  var color=[Color.WHITE,Color.RED,Color.ORANGE,Color.GREEN,Color.BLUE,Color.YELLOW,Color.CYAN,Color.MAGENTA,Color.PURPLE,Color.PINK,Color.CORAL,Color.LIME][i]
  draw_mesh(parts[i],null if inspect_layers else (texture if i in [0,7,8,9,10,11] else leg_texture),Transform2D.IDENTITY if i in [1,3] else weapon_transform(transforms) if i==11 else transforms[i],color if inspect_layers else Color.WHITE)
