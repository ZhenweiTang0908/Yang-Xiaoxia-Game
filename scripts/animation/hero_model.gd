extends Node3D
# Reproducible 3D authoring source. Lengths are fixed; all animation acts on bones.
var skeleton:Skeleton3D
var bones={}
var joints={}
var blade:Node3D
var bow:Node3D
var face:MeshInstance3D
func material(color):
 var m=StandardMaterial3D.new();m.albedo_color=Color(color);m.roughness=.95;m.metallic_specular=0.0;m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
 return m
func bone(label,parent,offset):
 var i=skeleton.add_bone(label);bones[label]=i
 if parent!="":skeleton.set_bone_parent(i,bones[parent])
 skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,offset));skeleton.set_bone_pose_position(i,offset)
 var attachment=BoneAttachment3D.new();attachment.name=label+"_Mesh";skeleton.add_child(attachment);attachment.bone_name=label;joints[label]=attachment
 return attachment
func ellipsoid(parent,at,size,mat):
 var mesh=SphereMesh.new();mesh.radius=.5;mesh.height=1;mesh.radial_segments=16;mesh.rings=8
 var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=mat;node.position=at;node.scale=size;parent.add_child(node);return node
func taper(parent,at,length,top,bottom,mat):
 var mesh=CylinderMesh.new();mesh.height=length;mesh.top_radius=top;mesh.bottom_radius=bottom;mesh.radial_segments=12
 var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=mat;node.position=at;parent.add_child(node);return node
# Smooth elliptical cross sections give clothing an authored silhouette instead of primitive seams.
func profile(parent,label,rings,mat):
 rings=rings.duplicate(true)
 if rings[0][0]>rings[-1][0]:rings.reverse()
 var vertices=PackedVector3Array();var indices=PackedInt32Array();var count=20
 for ring in rings:
  for j in count:
   var a=TAU*j/count
   vertices.append(Vector3(ring[3]+cos(a)*ring[1],ring[0],sin(a)*ring[2]))
 for row in range(rings.size()-1):
  for j in count:
   var a=row*count+j;var b=row*count+(j+1)%count
   indices.append_array(PackedInt32Array([a,b,a+count,b,b+count,a+count]))
 var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for index in indices:surface.add_vertex(vertices[index])
 surface.generate_normals();surface.index()
 var node=MeshInstance3D.new();node.name=label;node.mesh=surface.commit();node.material_override=mat;parent.add_child(node);return node
func _ready():
 skeleton=Skeleton3D.new();skeleton.name="HeroSkeleton";add_child(skeleton)
 var skin=material("d89a73");var orange=material("d95027");var cream=material("e8d8b9");var shorts=material("252c32")
 bone("root","",Vector3.ZERO)
 var hips=bone("hips","root",Vector3(0,.59,0))
 ellipsoid(hips,Vector3(0,.015,0),Vector3(.30,.135,.29),shorts)
 var chest=bone("chest","hips",Vector3(0,.14,0))
 profile(chest,"Tailored shirt",[
  [-.14,.155,.135,0.0],[-.125,.169,.15,0.0],[-.065,.17,.15,.005],
  [.035,.168,.145,.012],[.15,.163,.15,.008],[.225,.176,.15,0.0],
  [.27,.15,.13,-.005],[.305,.079,.078,.0],[.31,.061,.067,0.0]],cream)
 var neck=bone("neck","chest",Vector3(0,.34,0))
 taper(neck,Vector3(0,.035,0),.10,.065,.075,skin)
 var head=bone("head","neck",Vector3(.015,.025,0))
 # Keep the existing face drawing on an articulated head card instead of changing identity.
 var head_texture=AtlasTexture.new();head_texture.atlas=load("res://assets/art/v2/hero.png");head_texture.region=Rect2(59,5,83,78)
 var face_mat=StandardMaterial3D.new();face_mat.albedo_texture=head_texture.atlas;face_mat.uv1_scale=Vector3(83.0/head_texture.atlas.get_width(),78.0/head_texture.atlas.get_height(),1);face_mat.uv1_offset=Vector3(59.0/head_texture.atlas.get_width(),5.0/head_texture.atlas.get_height(),0);face_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;face_mat.alpha_scissor_threshold=.5;face_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;face_mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;face_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 face=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2(.49,.46);face.mesh=quad;face.material_override=face_mat;face.position=Vector3(.035,.205,.16);head.add_child(face)
 # Simple shirt emblem retains the orange/cream silhouette and bear recognition point.
 var patch_texture=AtlasTexture.new();patch_texture.atlas=head_texture.atlas;patch_texture.region=Rect2(91,94,23,32)
 var patch_mat=face_mat.duplicate();patch_mat.albedo_texture=head_texture.atlas;patch_mat.uv1_scale=Vector3(23.0/head_texture.atlas.get_width(),32.0/head_texture.atlas.get_height(),1);patch_mat.uv1_offset=Vector3(91.0/head_texture.atlas.get_width(),94.0/head_texture.atlas.get_height(),0)
 var patch=MeshInstance3D.new();var patch_quad=QuadMesh.new();patch_quad.size=Vector2(.115,.145);patch.mesh=patch_quad;patch.material_override=patch_mat;patch.position=Vector3(.068,.105,.153);chest.add_child(patch)
 for side in ["far","near"]:
  var z=-.14 if side=="far" else .14
  var upper=bone(side+"_arm","chest",Vector3(0,.24,z))
  profile(upper,side+" raglan sleeve",[[.04,.02,.025,0.0],[.025,.065,.063,0.0],[-.035,.078,.076,0.0],[-.10,.078,.07,0.0],[-.14,.069,.061,0.0],[-.15,.065,.057,0.0]],orange)
  profile(upper,side+" upper arm",[[-.13,.057,.052,0.0],[-.17,.054,.049,.003],[-.22,.047,.045,.005],[-.27,.042,.041,0.0]],skin)
  var elbow=bone(side+"_forearm",side+"_arm",Vector3(0,-.25,0))
  ellipsoid(elbow,Vector3.ZERO,Vector3(.089,.085,.085),skin)
  profile(elbow,side+" forearm",[[.015,.041,.04,0.0],[-.045,.05,.043,.005],[-.10,.045,.038,.005],[-.17,.033,.03,0.0],[-.225,.029,.027,0.0]],skin)
  var hand=bone(side+"_hand",side+"_forearm",Vector3(0,-.22,0))
  ellipsoid(hand,Vector3(0,-.025,0),Vector3(.075,.09,.065),skin)
  var thigh=bone(side+"_thigh","hips",Vector3(0,-.035,z*.62))
  profile(thigh,side+" shorts",[[.045,.087,.081,0.0],[.0,.096,.084,0.0],[-.08,.096,.082,0.0],[-.18,.088,.076,.004],[-.235,.079,.069,.008],[-.245,.072,.065,.008]],shorts)
  var knee=bone(side+"_shin",side+"_thigh",Vector3(0,-.265,0))
  ellipsoid(knee,Vector3.ZERO,Vector3(.105,.105,.10),skin)
  profile(knee,side+" calf",[[.015,.049,.046,0.0],[-.045,.056,.046,-.006],[-.10,.046,.038,-.01],[-.17,.032,.03,0.0],[-.235,.029,.028,.006]],skin)
  var foot=bone(side+"_foot",side+"_shin",Vector3(0,-.235,0))
  ellipsoid(foot,Vector3(.055,-.015,0),Vector3(.18,.072,.105),skin)
 blade=Node3D.new();blade.name="Sword";blade.scale.x=1.25;joints.near_hand.add_child(blade)
 var metal=material("c0d4d6");var edge=material("ecf3e9");var grip=material("554536")
 taper(blade,Vector3(.03,0,0),.11,.018,.018,grip).rotation.z=PI/2
 var guard=BoxMesh.new();guard.size=Vector3(.025,.12,.045)
 var guard_node=MeshInstance3D.new();guard_node.mesh=guard;guard_node.material_override=metal;guard_node.position.x=.10;blade.add_child(guard_node)
 var sword_mesh=ArrayMesh.new();var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(.11,-.025,0),Vector3(.11,.04,0),Vector3(.56,.025,0),Vector3(.63,0,0),Vector3(.56,-.027,0)])
 arrays[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.FORWARD,Vector3.FORWARD,Vector3.FORWARD,Vector3.FORWARD,Vector3.FORWARD])
 arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,0,2,3,0,3,4]);sword_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var sword=MeshInstance3D.new();sword.mesh=sword_mesh;metal.cull_mode=BaseMaterial3D.CULL_DISABLED;sword.material_override=metal;blade.add_child(sword)
 var highlight=BoxMesh.new();highlight.size=Vector3(.43,.012,.006);var strip=MeshInstance3D.new();strip.mesh=highlight;strip.material_override=edge;strip.position=Vector3(.33,-.024,.005);blade.add_child(strip)
 bow=Node3D.new();bow.name="Bow";joints.far_hand.add_child(bow);bow.hide()
 for i in 10:
  var a=-PI*.5+i*PI/10;var b=a+PI/10
  var start=Vector3(cos(a)*.13,sin(a)*.32,0);var end=Vector3(cos(b)*.13,sin(b)*.32,0)
  var segment=taper(bow,(start+end)*.5,start.distance_to(end),.012,.012,grip)
  segment.quaternion=Quaternion(Vector3.UP,(end-start).normalized())
 taper(bow,Vector3.ZERO,.64,.003,.003,cream)
func apply_pose(pose):
 for key in bones:
  var value=pose.get(key,Vector3.ZERO)
  skeleton.set_bone_pose_rotation(bones[key],Quaternion.from_euler(value))
 skeleton.set_bone_pose_position(bones.hips,Vector3(0,.59,0)+pose.get("offset",Vector3.ZERO))
 skeleton.force_update_all_bone_transforms()
