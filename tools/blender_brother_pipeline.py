"""Author a real Blender armature while preserving the original pixel-art silhouette.
Export Blender mesh topology, UVs, weights and baked joint curves consumed by Godot.
"""
import bpy,json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
frames=json.loads((ROOT/'art_source/brother_mesh_source.json').read_text())
scene=bpy.context.scene;scene.render.fps=60
texture=bpy.data.images.load(str(ROOT/'assets/art/v3/niu_human.png'))
mat=bpy.data.materials.new('Original Niu pixel artwork');mat.use_nodes=True
nodes=mat.node_tree.nodes;nodes.clear();out=nodes.new('ShaderNodeOutputMaterial');em=nodes.new('ShaderNodeEmission');tex=nodes.new('ShaderNodeTexImage');tex.image=texture;tex.interpolation='Closest';mat.node_tree.links.new(tex.outputs['Color'],em.inputs['Color']);mat.node_tree.links.new(em.outputs[0],out.inputs['Surface'])
sep=nodes.new('ShaderNodeSeparateXYZ');mat.node_tree.links.new(tex.outputs['Color'],sep.inputs[0])
minimum=nodes.new('ShaderNodeMath');minimum.operation='MINIMUM';mat.node_tree.links.new(sep.outputs[0],minimum.inputs[0]);mat.node_tree.links.new(sep.outputs[2],minimum.inputs[1])
sub=nodes.new('ShaderNodeMath');sub.operation='SUBTRACT';mat.node_tree.links.new(minimum.outputs[0],sub.inputs[0]);mat.node_tree.links.new(sep.outputs[1],sub.inputs[1])
key=nodes.new('ShaderNodeMath');key.operation='GREATER_THAN';key.inputs[1].default_value=.2;mat.node_tree.links.new(sub.outputs[0],key.inputs[0])
transparent=nodes.new('ShaderNodeBsdfTransparent');mix=nodes.new('ShaderNodeMixShader');mat.node_tree.links.new(key.outputs[0],mix.inputs[0]);mat.node_tree.links.new(em.outputs[0],mix.inputs[1]);mat.node_tree.links.new(transparent.outputs[0],mix.inputs[2]);mat.node_tree.links.new(mix.outputs[0],out.inputs['Surface'])
export=[]
for f,data in enumerate(frames):
 arm=bpy.data.armatures.new(f'Pose {f:02d} bones');rig=bpy.data.objects.new(f'Niu pose {f:02d} rig',arm);scene.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True)
 bpy.ops.object.mode_set(mode='EDIT')
 for i,point in enumerate(data['pivots']):
  bone=arm.edit_bones.new(['Waist','Neck','Coat','Legs'][i]);bone.head=point;bone.tail=(point[0],point[1]+12,point[2])
 bone=arm.edit_bones.new('Rest');bone.head=(0,0,0);bone.tail=(0,12,0)
 bpy.ops.object.mode_set(mode='OBJECT')
 mesh=bpy.data.meshes.new(f'Original silhouette {f:02d}');mesh.from_pydata(data['vertices'],[],[data['indices'][i:i+3] for i in range(0,len(data['indices']),3)]);mesh.update()
 obj=bpy.data.objects.new(f'Pixel skin {f:02d}',mesh);scene.collection.objects.link(obj);obj.data.materials.append(mat)
 layer=mesh.uv_layers.new()
 for poly in mesh.polygons:
  for loop in poly.loop_indices:layer.data[loop].uv=data['uv'][mesh.loops[loop].vertex_index]
 # The Rest group explicitly carries unweighted silhouette pixels.
 groups=[obj.vertex_groups.new(name=n) for n in ['Waist','Neck','Coat','Legs']]
 for v,weights in enumerate(data['weights']):
  for i,w in enumerate(weights):
   if w>0:groups[i].add([v],w,'REPLACE')
 rest=obj.vertex_groups.new(name='Rest')
 for v,weights in enumerate(data['weights']):rest.add([v],max(0,1-sum(weights)),'REPLACE')
 modifier=obj.modifiers.new('Blender armature deformation','ARMATURE');modifier.object=rig
 rig.animation_data_create();action=bpy.data.actions.new(f'Pose_{f:02d}_secondary');rig.animation_data.action=action
 samples=[]
 for tick in range(151):
  t=tick/60;running=6<=f<12;throwing=12<=f<18;amount=.5 if throwing else 1
  angles=[math.sin(t*math.tau/2.5)*.012*amount,math.sin(t*math.tau/2.5-.25)*.010*amount,math.sin(t*(3*math.tau/2.5 if running else math.tau/2.5)-.6)*(.04 if running else .016),math.sin(t*3*math.tau/2.5)*.025 if running else 0]
  for i,bone in enumerate(list(rig.pose.bones)[:4]):bone.rotation_mode='XYZ';bone.rotation_euler.z=-angles[i];bone.keyframe_insert('rotation_euler',frame=tick)
  scene.frame_set(tick);bpy.context.view_layer.update();samples.append([-b.rotation_euler.z for b in list(rig.pose.bones)[:4]])
 action.use_fake_user=True
 export.append(dict(vertices=[[v.co.x,-v.co.y] for v in mesh.vertices],uv=[[u[0],1-u[1]] for u in data['uv']],indices=data['indices'],weights=data['weights'],pivots=[[p[0],-p[1]] for p in data['pivots']],angles=samples))
 obj.hide_render=f!=0;obj.hide_viewport=f!=0;rig.hide_viewport=f!=0;rig.select_set(False)
scene.frame_set(0)
notes=bpy.data.texts.new('PIPELINE');notes.write('Original pixel art with editable Blender armatures for 24 authored poses. The exported meshes and joint curves are read by Godot brother_visual.gd. This is a 2.5D artwork rig, not a volumetric face sculpt.')
(ROOT/'art_source/brother').mkdir(exist_ok=True)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/brother/niu_daxia.blend'))
(ROOT/'assets/animation/brother_blender.json').write_text(json.dumps(dict(fps=60,frames=export),separators=(',',':')))
print('BROTHER_BLENDER_EXPORT',len(export),'poses, 120 editable bones; runtime mesh and animation JSON')
