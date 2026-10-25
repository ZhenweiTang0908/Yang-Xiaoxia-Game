import bpy, bmesh, math
from pathlib import Path
root=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(root/'art_source/hero/yang_xiaoxia.blend'))
# Refine the existing identity instead of replacing it with a new primitive body.
for obj in bpy.data.objects:
 if obj.type=='MESH' and obj.parent_type=='BONE':
  bone=obj.parent_bone
  if bone in ('hips','chest') and 'shirt' in obj.name.lower():
   for vertex in obj.data.vertices:
    # A loose child-size shirt: softly rounded lower torso, not a tapered adult waist.
    fullness=math.exp(-((vertex.co.z-.025)/.13)**2)
    vertex.co.x*=.95+.045*fullness
    vertex.co.y*=.96+.035*fullness
    vertex.co.x+=.010*fullness
  elif 'arm' in bone or 'thigh' in bone or 'shin' in bone:
   for vertex in obj.data.vertices:vertex.co.x*=.88;vertex.co.y*=.90
  elif bone=='neck':
   # Bury the lower rim inside the collar; the previous cylinder floated above it.
   low=min(v.co.z for v in obj.data.vertices);high=max(v.co.z for v in obj.data.vertices)
   for vertex in obj.data.vertices:
    weight=(high-vertex.co.z)/max(.001,high-low)
    vertex.co.z-=.045*weight
    vertex.co.x*=.90;vertex.co.y*=.90
  elif bone=='head':
   obj.scale*=.94
   obj.location.z-=.018
   # Subdivide the original face card and gently widen the cheeks only.
   # UVs remain attached to the same pixels; eyes, hair and overall head height stay put.
   bm=bmesh.new();bm.from_mesh(obj.data)
   bmesh.ops.subdivide_edges(bm,edges=list(bm.edges),cuts=10,use_grid_fill=True)
   for v in bm.verts:
    cheek=math.exp(-((v.co.z+.095)/.070)**2)
    v.co.x*=1+.085*cheek
   bm.to_mesh(obj.data);bm.free();obj.data.update()
# Keep all original editable animation clips in the delivered Blender file.
scene=bpy.context.scene
scene.frame_set(0)
for obj in list(bpy.data.objects):
 if obj.type in ('CAMERA','LIGHT'):bpy.data.objects.remove(obj,do_unlink=True)
for obj in bpy.data.objects:
 obj.hide_viewport=False;obj.hide_render=False
 if obj.animation_data:
  for track in obj.animation_data.nla_tracks:track.mute=True
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(root/'art_source/hero/yang_xiaoxia_refined.blend'))
(root/'assets/animation').mkdir(exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(root/'assets/animation/hero_blender.glb'),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_yup=True)
print('RUNTIME_BLENDER_GLB',len(bpy.data.actions))
