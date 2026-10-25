extends "res://scripts/actors/atlas_actor.gd"
# A rigid upper silhouette and planted foot strip; small pose curves bridge authored frames.
static var frame_banks={}
var actor
var isolated=[]
var anchors=[]
var cache={}
var mesh=ArrayMesh.new()
var lean=0.0
var sink=0.0
var clock=0.0
var rest=PackedVector2Array()
var current=-1
var arrays=[]
var displayed=PackedVector2Array()
var bridge_from=PackedVector2Array()
var bridge_left=0.0
var bridge_duration=0.0
var hit_direction=1.0
var hit_weight=1.0
const NX=14
const NY=22
func load_frames(folder,count):
 if frame_banks.has(folder):
  var bank=frame_banks[folder];bounds=bank.bounds;regions=bank.regions;isolated=bank.isolated;anchors=bank.anchors;return
 bounds=[];regions=[];isolated=[];anchors=[]
 for i in count:
  var picture=load(folder+"/%02d.png"%i);isolated.append(picture)
  var image=picture.get_image();var used=image.get_used_rect();bounds.append(used);regions.append(Rect2(Vector2.ZERO,picture.get_size()))
  # Support pixels, not a sword or cape extending from the torso, define the origin.
  var sum=0.0;var total=0.0
  for y in range(used.end.y-maxi(3,int(used.size.y*.08)),used.end.y):
   for x in range(used.position.x,used.end.x):
    var weight=image.get_pixel(x,y).a
    if weight>.4:sum+=x*weight;total+=weight
  anchors.append(sum/total if total>0 else used.get_center().x)
 frame_banks[folder]={"bounds":bounds,"regions":regions,"isolated":isolated,"anchors":anchors}
func _process(dt):
 if not is_instance_valid(actor):queue_redraw();return
 if not actor.game.active() or actor.game.hitstop>0 or not actor.visible:return
 position=Vector2.ZERO if actor.dead else preload("res://scripts/combat/hit_feedback.gd").recoil(actor.hurt,.12 if actor.kind=="boss" else .18,hit_direction)*hit_weight
 clock+=dt
 var target_lean=0.0;var target_sink=0.0
 if not actor.dead:
  if actor.windup>0:
   var full=.85 if actor.kind=="guardian" else .65
   if actor.kind=="boss":full=actor.move.get("windup",.8)
   var progress=clampf(1-actor.windup/full,0,1)
   target_lean=.025+progress*.020;target_sink=.5+progress*.8
  elif actor.strike>0:target_lean=-.045;target_sink=.35
  elif actor.hurt>0:target_lean=.025;target_sink=.3
  elif absf(actor.velocity.x)>5:
   target_lean=-.018
   var gait=actor.get("gait_phase")
   target_sink=absf(sin(float(gait)*TAU))*.35 if gait!=null and actor.kind not in ["bat","spirit"] else absf(sin(clock*7))*.35
  else:target_sink=sin(clock*2.5)*.15
 var blend=1-exp(-dt*18)
 lean=lerpf(lean,target_lean,blend);sink=lerpf(sink,target_sink,blend)
 bridge_left=maxf(0,bridge_left-dt)
 queue_redraw()
func transition_duration(index):
 # Release must feel immediate; anticipation and recovery carry more weight.
 match index%6:
  2:return .11
  3:return .055
  4:return .07
  _:return .085
func posed_vertices():
 var result=PackedVector2Array()
 for p in rest:result.append(deform(p))
 return result
func prepare(index):
 if current==index:return
 if current>=0:
  bridge_from=displayed.duplicate() if displayed.size()==rest.size() else posed_vertices()
 current=index
 if cache.has(index):
  rest=cache[index].rest;arrays=cache[index].arrays.duplicate()
  if bridge_from.size()==rest.size():
   bridge_duration=transition_duration(index);bridge_left=bridge_duration
  return
 var used=bounds[index];var picture=isolated[index]
 rest=PackedVector2Array();var uv=PackedVector2Array();var indices=PackedInt32Array()
 for y in NY+1:
  for x in NX+1:
   var pixel=Vector2(used.position)+Vector2(used.size)*Vector2(float(x)/NX,float(y)/NY)
   rest.append((pixel-Vector2(anchors[index],used.end.y))*scale_unit);uv.append(pixel/picture.get_size())
 for y in NY:
  for x in NX:
   var a=y*(NX+1)+x;indices.append_array(PackedInt32Array([a,a+1,a+NX+1,a+1,a+NX+2,a+NX+1]))
 arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
 cache[index]={"rest":rest,"arrays":arrays.duplicate()}
 if bridge_from.size()==rest.size():
  bridge_duration=transition_duration(index);bridge_left=bridge_duration
func deform(p):
 var pivot=Vector2(0,-body_height*.36)
 var weight=smoothstep(0,body_height*.34,-p.y)
 return p+((p-pivot).rotated(lean)+pivot-p+Vector2(0,sink))*weight
func source_socket(index,pixel):
 index=clampi(index,0,bounds.size()-1)
 var local=(pixel-Vector2(anchors[index],bounds[index].end.y))*scale_unit
 return deform(local)*Vector2(facing,1)
func update_pose_mesh():
 if isolated.is_empty():return
 var i=clampi(frame,0,isolated.size()-1);prepare(i)
 var vertices=PackedVector3Array()
 var target=posed_vertices()
 var progress=1.0 if bridge_duration<=0 else 1-bridge_left/bridge_duration
 progress=smoothstep(0,1,clampf(progress,0,1))
 displayed=PackedVector2Array()
 for index in target.size():
  var point=bridge_from[index].lerp(target[index],progress) if bridge_from.size()==target.size() else target[index]
  displayed.append(point);vertices.append(Vector3(point.x,point.y,0))
 arrays[Mesh.ARRAY_VERTEX]=vertices;mesh.clear_surfaces();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
func _draw():
 if isolated.is_empty():return
 update_pose_mesh()
 var i=clampi(frame,0,isolated.size()-1)
 draw_set_transform(Vector2.ZERO,0,Vector2(facing,1));draw_mesh(mesh,isolated[i],Transform2D.IDENTITY,tint)
