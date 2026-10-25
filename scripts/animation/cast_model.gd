extends "res://scripts/animation/hero_model.gd"
# Continuous articulated silhouettes; existing atlas heads retain character identity.
var species="niu"
var source_art
var head_card
var card
func _ready():
 skeleton=Skeleton3D.new();skeleton.name="CastSkeleton";add_child(skeleton)
 var palettes={"niu":["293437","913b3c","d5b899"],"sheep":["263532","426255","788f79"],"imp":["314c47","425b50","567361"],"spirit":["354c58","56757b","8caeaa"],"guardian":["454a4a","66716a","7d8980"],"pouncer":["464334","75694b","98865e"],"bat":["383342","5f5369","807b8e"],"dart":["303a43","536273","a6a094"],"shield":["3c4846","66776b","8d9b7e"],"shaman":["373447","666074","aca79e"],"lantern":["414840","677358","b1a374"],"duelist":["303b46","627783","a7b6b1"],"priest":["313c3e","617268","9ba894"],"bull":["090b10","171b23","72717a"]}
 var colors=palettes.get(species,palettes.imp);var dark=material(colors[0]);var cloth=material(colors[1]);var skin=material(colors[2])
 bone("root","",Vector3.ZERO)
 if species=="bull":build_bull(dark,cloth,skin);return
 var hips=bone("hips","root",Vector3(0,.59,0));ellipsoid(hips,Vector3.ZERO,Vector3(.30,.19,.27),dark)
 var chest=bone("chest","hips",Vector3(0,.14,0))
 var wide=1.3 if species in ["guardian","shield","lantern"] else 1.0
 profile(chest,"Quiet torso",[[-.14,.16*wide,.14,0.0],[.05,.17*wide,.14,0.0],[.25,.19*wide,.14,0.0],[.31,.09,.09,0.0]],dark)
 if species=="sheep":
  profile(chest,"Spirit mantle",[[.05,.18,.15,0.0],[.20,.22,.17,0.0],[.27,.20,.15,0.0],[.29,.11,.10,0.0]],cloth)
  profile(chest,"Jade waist sash",[[-.12,.175,.15,0.0],[-.065,.18,.155,0.0]],skin)
 if species=="niu":profile(chest,"Red shirt",[[-.11,.07,.153,.06],[.24,.065,.153,.03]],cloth)
 bone("neck","chest",Vector3(0,.32,0));var head=bone("head","neck",Vector3.ZERO)
 add_head(head)
 var cape=bone("cape","chest",Vector3(-.12,.24,-.04))
 if species in ["niu","sheep","shaman","priest","duelist","spirit"]:
  profile(cape,"Plain flowing coat",[[-.46,.15,.085,-.10],[-.27,.115,.10,-.055],[.015,.06,.07,0.0]],dark)
 for side in ["far","near"]:
  var z=-.12 if side=="far" else .12
  var arm=bone(side+"_arm","chest",Vector3(0,.24,z))
  taper(arm,Vector3(0,-.12,0),.25,.065*wide,.051,dark)
  var forearm=bone(side+"_forearm",side+"_arm",Vector3(0,-.25,0))
  taper(forearm,Vector3(0,-.105,0),.22,.053,.035,skin if species=="niu" else cloth)
  var hand=bone(side+"_hand",side+"_forearm",Vector3(0,-.22,0));ellipsoid(hand,Vector3(0,-.025,0),Vector3(.08,.09,.07),skin)
  var thigh=bone(side+"_thigh","hips",Vector3(0,-.035,z*.65));taper(thigh,Vector3(0,-.13,0),.265,.082*wide,.064,dark)
  var shin=bone(side+"_shin",side+"_thigh",Vector3(0,-.265,0));taper(shin,Vector3(0,-.118,0),.235,.065,.04,dark)
  var foot=bone(side+"_foot",side+"_shin",Vector3(0,-.235,0));ellipsoid(foot,Vector3(.045,-.015,0),Vector3(.18,.075,.11),dark)
 blade=Node3D.new();joints.near_hand.add_child(blade)
 if species in ["sheep","duelist","priest","dart"]:
  var edge_material=material("9ec4ac" if species=="sheep" else colors[2])
  if species=="sheep":
   blade.scale.x=1.35
   taper(blade,Vector3(.015,0,0),.12,.023,.023,material("34463e")).rotation.z=PI/2
   guard_node(blade,skin)
   edge_material.emission_enabled=true;edge_material.emission=Color("386a4e");edge_material.emission_energy_multiplier=.6
  for i in 8:
   var u=float(i)/8;var v=float(i+1)/8
   var a=Vector3(u*.56,-sin(u*PI)*.07,0);var b=Vector3(v*.56,-sin(v*PI)*.07,0)
   var edge=taper(blade,(a+b)*.5,a.distance_to(b),lerpf(.027,.005,v),lerpf(.027,.005,u),edge_material);edge.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
 if species=="shield":ellipsoid(joints.far_hand,Vector3(.04,.02,0),Vector3(.13,.42,.30),cloth)
 card=Node3D.new();joints.near_hand.add_child(card)
 var quad=BoxMesh.new();quad.size=Vector3(.10,.15,.014);var mesh=MeshInstance3D.new();mesh.mesh=quad;mesh.material_override=material("dfe4cd");card.add_child(mesh);card.position=Vector3(.015,-.07,.015);card.visible=species=="niu"
 bow=Node3D.new();add_child(bow)
 if species=="bat":
  for side in ["far","near"]:
   var wing=profile(joints[side+"_arm"],"Wing",[[-.42,.01,.015,-.28],[-.20,.24,.015,-.10],[.015,.06,.02,0.0]],cloth)
   wing.rotation.z=.6
func guard_node(parent,mat):
 var guard=BoxMesh.new();guard.size=Vector3(.035,.14,.055)
 var mesh=MeshInstance3D.new();mesh.mesh=guard;mesh.material_override=mat;mesh.position.x=.09;parent.add_child(mesh)
func add_head(parent):
 if not source_art:return
 var row={"niu":0,"sheep":0,"imp":0,"spirit":1,"guardian":2,"pouncer":3,"bat":4,"dart":5,"shield":6,"shaman":7,"lantern":0,"duelist":1,"priest":2}.get(species,0)
 var index=row*source_art.columns;var used=source_art.bounds[index];var region=source_art.regions[index]
 var height=used.size.y*(.39 if species=="sheep" else .31)
 var rect=Rect2(region.position+Vector2(used.position),Vector2(used.size.x,height))
 if species=="niu":rect=Rect2(88,29,89,76)
 if species=="sheep":rect=Rect2(82,28,98,85)
 var shader=Shader.new();shader.code="shader_type spatial; render_mode unshaded,cull_disabled; uniform sampler2D atlas:filter_nearest; uniform vec4 region; void fragment(){vec4 c=texture(atlas,region.xy+UV*region.zw); if(c.a<0.5 || (min(c.r,c.b)-c.g)>0.2)discard; ALBEDO=c.rgb; ALPHA=1.0;}"
 var mat=ShaderMaterial.new();mat.shader=shader;mat.set_shader_parameter("atlas",source_art.texture)
 var size=source_art.texture.get_size();mat.set_shader_parameter("region",Vector4(rect.position.x/size.x,rect.position.y/size.y,rect.size.x/size.x,rect.size.y/size.y))
 head_card=MeshInstance3D.new();var q=QuadMesh.new();q.size=Vector2(.43*rect.size.x/rect.size.y,.43);head_card.mesh=q;head_card.material_override=mat;head_card.position=Vector3(.01,.17,.18);parent.add_child(head_card)
func build_bull(dark,cloth,horn):
 var body=bone("hips","root",Vector3(0,.48,0))
 var torso=profile(body,"Black bull silhouette",[[-.54,.035,.06,0.0],[-.45,.17,.17,0.0],[-.28,.21,.20,0.0],[.06,.20,.20,0.0],[.30,.27,.22,0.0],[.43,.22,.18,0.0],[.50,.12,.12,0.0]],dark);torso.rotation.z=-PI/2
 ellipsoid(body,Vector3(.28,.11,-.02),Vector3(.38,.30,.34),dark)
 var head=bone("head","hips",Vector3(.49,.04,0))
 var skull=profile(head,"Angular brow and jaw",[[-.23,.045,.055,.18],[-.18,.10,.12,.16],[-.05,.14,.15,.085],[.09,.14,.145,0.0],[.15,.07,.09,-.025]],dark)
 ellipsoid(head,Vector3(.205,-.16,.015),Vector3(.19,.11,.22),cloth)
 for z in [-.12,.12]:
  var h=taper(head,Vector3(-.045 if z<0 else .065,.20,z),.20,.022,.045,horn);h.rotation.z=.35 if z<0 else -.40
  var tip=taper(head,Vector3(-.09 if z<0 else .115,.30,z),.14,.004,.024,horn);tip.rotation.z=.8 if z<0 else -.8
  var red=material("ff292f");red.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;red.emission_enabled=true;red.emission=Color("ed0719")
  var eye=ellipsoid(head,Vector3(.125,.035,z*1.35),Vector3(.075,.029,.028),red);eye.rotation.z=-.20
  var brow=taper(head,Vector3(.11,.065,z*1.4),.11,.019,.025,dark);brow.rotation.z=1.25
 for side in ["far","near"]:
  for end in ["front","rear"]:
   var key=side+"_"+end;var upper=bone(key,"hips",Vector3(.35 if end=="front" else -.36,-.08,.135 if side=="near" else -.135))
   taper(upper,Vector3(0,-.10,0),.22,.068,.048,dark)
   var lower=bone(key+"_lower",key,Vector3(0,-.20,0));taper(lower,Vector3(0,-.10,0),.20,.045,.034,cloth);ellipsoid(lower,Vector3(.025,-.20,0),Vector3(.13,.065,.10),dark)
 var tail=bone("tail","hips",Vector3(-.52,.075,0));var t=taper(tail,Vector3(-.09,-.10,0),.29,.022,.014,dark);t.rotation.z=-.7
func apply_pose(p):
 super.apply_pose(p)
 if species=="bull":skeleton.set_bone_pose_position(bones.hips,Vector3(0,.48,0)+p.get("offset",Vector3.ZERO));skeleton.force_update_all_bone_transforms()
