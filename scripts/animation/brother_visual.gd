extends Node2D
const CARD_MOTION=preload("res://scripts/animation/card_motion.gd")
# Keep the original painted silhouette. A small CPU-skinned rig adds secondary
# motion to its authored poses without replacing face, hair, clothes or hands.
var actor
static var blender_data={}
var authored_frame={}
var source_art
var mesh=ArrayMesh.new()
var rest=PackedVector2Array()
var uv=PackedVector2Array()
var triangles=PackedInt32Array()
var pivots=[]
var weights=[]
var angles=[0.0,0.0,0.0,0.0]
var bones=[]
var current_frame=-1
var clock=0.0
var motion_lean=0.0
var landing_sink=0.0
var preview=false
var preview_frame=0
var preview_state=""
var preview_speed=0.0
var height=88.0
var preview_facing=1.0
const GRID_X=18
const GRID_Y=28
func _ready():
 if blender_data.is_empty():blender_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/animation/brother_blender.json"))
 material=source_art.material.duplicate()
 for name in ["Waist","Neck","Coat","Legs"]:
  var joint=Bone2D.new();joint.name=name;joint.set_autocalculate_length_and_angle(false);joint.length=16;add_child(joint);bones.append(joint)
func rebuild(index):
 if get_script().resource_path.ends_with("/brother_visual.gd") and not blender_data.is_empty():
  current_frame=index;authored_frame=blender_data.frames[index];rest.clear();uv.clear();pivots=[]
  for p in authored_frame.vertices:rest.append(Vector2(p[0],p[1]))
  for p in authored_frame.uv:uv.append(Vector2(p[0],p[1]))
  for p in authored_frame.pivots:pivots.append(Vector2(p[0],p[1]))
  triangles=PackedInt32Array(authored_frame.indices);weights=authored_frame.weights
  for i in 4:bones[i].position=pivots[i]
  return
 current_frame=index;rest.clear();uv.clear();triangles.clear();weights.clear()
 var region=source_art.regions[index];var used=source_art.bounds[index]
 var baseline=float(used.end.y);var unit=source_art.scale_unit
 var origin=Vector2(-region.size.x*.5,-baseline)*unit
 var rect=Rect2(Vector2(used.position)*unit+origin,Vector2(used.size)*unit)
 # Pivots stay at the character's waist and neck, not the image cell corners.
 pivots=[Vector2(rect.get_center().x,rect.position.y+rect.size.y*.58),Vector2(rect.get_center().x,rect.position.y+rect.size.y*.29),Vector2(rect.position.x+rect.size.x*.36,rect.position.y+rect.size.y*.34),Vector2(rect.get_center().x,rect.position.y+rect.size.y*.60)]
 for y in GRID_Y+1:
  for x in GRID_X+1:
   var q=Vector2(float(x)/GRID_X,float(y)/GRID_Y)
   var point=rect.position+rect.size*q;rest.append(point)
   uv.append((region.position+Vector2(used.position)+Vector2(used.size)*q)/source_art.texture.get_size())
   var head=1-smoothstep(.24,.34,q.y)
   var upper=(1-smoothstep(.54,.68,q.y))*(1-head)
   var coat=(1-smoothstep(.32,.52,q.x))*smoothstep(.34,.48,q.y)*(1-smoothstep(.60,.72,q.y))*.4
   var leg=smoothstep(.66,.76,q.y)*(1-smoothstep(.90,1.0,q.y))*.24
   weights.append([upper*(1-coat),head,coat,leg])
 for y in GRID_Y:
  for x in GRID_X:
   var a=y*(GRID_X+1)+x;var b=a+1;var c=a+GRID_X+1
   triangles.append_array(PackedInt32Array([a,b,c,b,c+1,c]))
 for i in 4:bones[i].position=pivots[i]
func deform(point,influences):
 var out=point
 for i in 4:out+=(bones[i].transform*(point-pivots[i])-point)*influences[i]
 # Translate the head/neck/torso together; only the lower legs absorb the
 # small landing displacement, with the sole region completely pinned.
 out.y+=landing_sink*(1-smoothstep(-30,-4,point.y))
 return out
func is_enabled():return not actor.demon and actor.game.use_skeletal
func _process(dt):
 if not preview:
  visible=is_enabled()
  source_art.self_modulate.a=0 if visible else 1
  if not visible:return
  if not actor.game.active() or actor.game.hitstop>0:return
 clock+=dt
 if not preview:
  var landing_age=.18-actor.landing_time
  landing_sink=2.0*sin(PI*clampf(landing_age/.18,0,1)) if actor.landing_time>0 else 0.0
 if preview and preview_state!="":
  match preview_state:
   "run","dash":preview_frame=6+int(clock*11)%6
   "cast":preview_frame=CARD_MOTION.frame_at(fposmod(clock,.9))
   "charge":preview_frame=20
   _:preview_frame=int(clock*6)%6
 var frame=preview_frame if preview else source_art.frame
 if frame!=current_frame:rebuild(frame)
 var running=frame>=6 and frame<12
 var throwing=frame>=12 and frame<18
 var amount=.5 if throwing else 1.0
 var desired=[sin(clock*2.5)*.012*amount,sin(clock*2.5-.25)*.010*amount,sin(clock*(8 if running else 2.5)-.6)*(.04 if running else .016),sin(clock*8)*.025 if running else 0.0]
 if not authored_frame.is_empty():
  var sample=fposmod(clock,2.5)*60;var first=int(sample);var second=mini(first+1,150)
  for i in 4:desired[i]=lerpf(authored_frame.angles[first][i],authored_frame.angles[second][i],sample-first)
 # Ease the torso into locomotion without moving the pinned feet or smearing poses.
 var lean_target=-.025 if running else (.018 if throwing else 0.0)
 motion_lean=lerpf(motion_lean,lean_target,1-exp(-10*dt))
 desired[0]+=motion_lean
 desired[1]-=motion_lean*.65
 for i in 4:
  angles[i]=lerpf(angles[i],desired[i],1-exp(-18*dt));bones[i].rotation=angles[i]
 update_surface()
 scale=Vector2.ONE*height/source_art.body_height if preview else source_art.scale
 queue_redraw()
func update_surface():
 var vertices=PackedVector3Array()
 for i in rest.size():
  var at=deform(rest[i],weights[i]);vertices.append(Vector3(at.x,at.y,0))
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=triangles
 mesh.clear_surfaces();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
func release_pose(index):
 if current_frame!=index:rebuild(index)
 # Release runs on the physics tick. Upload the matching pose immediately so
 # the card cannot leave the new socket while the previous pose is still drawn.
 update_surface()
 queue_redraw()
func mesh_socket(point):
 # Match the exact triangle interpolation used by the rendered mesh.
 for i in range(0,triangles.size(),3):
  var a=triangles[i];var b=triangles[i+1];var c=triangles[i+2]
  var ab=rest[b]-rest[a];var ac=rest[c]-rest[a];var delta=point-rest[a]
  var area=ab.cross(ac)
  if absf(area)<.000001:continue
  var beta=delta.cross(ac)/area;var gamma=ab.cross(delta)/area;var alpha=1-beta-gamma
  if minf(alpha,minf(beta,gamma))<-.00001:continue
  return deform(rest[a],weights[a])*alpha+deform(rest[b],weights[b])*beta+deform(rest[c],weights[c])*gamma
 return Vector2.INF
func hand_position():
 # Authored throwing poses use a stable hand socket at the release frame.
 var sockets={12:Vector2(105,108),13:Vector2(110,105),14:Vector2(190,78),15:Vector2(198,78),16:Vector2(193,86),17:Vector2(116,105)}
 var index=source_art.frame
 if not sockets.has(index):return actor.position+Vector2(actor.facing*13,-49)
 var used=source_art.bounds[index];var region=source_art.regions[index]
 var point=(sockets[index]-Vector2(region.size.x*.5,used.end.y))*source_art.scale_unit
 if current_frame!=index:rebuild(index)
 var attached=mesh_socket(point)
 if attached.is_finite():point=attached
 return to_global(point*Vector2(actor.facing,1))
func _draw():
 if current_frame<0:return
 var face=preview_facing if preview else actor.facing
 draw_set_transform(Vector2.ZERO,0,Vector2(face,1))
 draw_mesh(mesh,source_art.texture,Transform2D.IDENTITY,source_art.tint)
